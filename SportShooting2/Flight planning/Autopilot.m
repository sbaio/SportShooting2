//
//  Autopilot.m
//  SportShooting2
//
//  Created by Othman Sbai on 1/25/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//


#define sign(a) ( ( (a) < 0 )  ?  -1   : ( (a) > 0 ) )

#define DEGREE(x) ((x)*180.0/M_PI)
#define RADIAN(x) ((x)*M_PI/180.0)

#define bindBetween(a,b,c) ((a > c) ? c: ((a<b)? b:a))
#define DV_FLOATING_WINDOW_ENABLE 1

#import "Autopilot.h"
#import "Calc.h"
#import "alert.h"

@implementation Autopilot

-(id) init{
    self = [super init];

    [[DJIMissionManager sharedInstance] setDelegate:self];
    
    [self initFlightVariables];

    frontVC = [[Menu instance] getFrontVC];
    mapView = [[Menu instance] getMapView];
    
    [self addObserver:self forKeyPath:@"isVirtualStickModeEnabled" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (([keyPath isEqual:@"isVirtualStickModeEnabled"]) && object == self) {
        BOOL oldBool = [[change objectForKey:@"old"] boolValue];
        BOOL newBool = [[change objectForKey:@"new"] boolValue];
        
        if (oldBool != newBool) {
            if(newBool){
                DVLog(@"virtual stick mode enabled");
            }
            else{
                DVLog(@"virtual stick mode disabled");
            }
        }
    }
    
}

-(void) initFlightVariables{
    radiusBrakingZone = 60;
    
    _avoidObstacles = NO;
    _droneYawMode = 2; // drone yaw in respect with gimbal yaw
    _gimbalYawMode = 1;
}


-(void) sendFlightCtrlCommands:(DJIVirtualStickFlightControlData) ctrlData{
    DJIFlightController* fc = [ComponentHelper fetchFlightController];
    
//    DVLog([self stringFromFlightcontrollerState:fc]);
    
    if (fc) {
        fc.yawControlMode = DJIVirtualStickYawControlModeAngularVelocity;
        fc.verticalControlMode = DJIVirtualStickVerticalControlModePosition;
        fc.rollPitchControlMode = DJIVirtualStickRollPitchControlModeVelocity;
        fc.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystemGround;
        self.isVirtualStickModeEnabled = fc.isVirtualStickControlModeAvailable;
        
        if (fc.isVirtualStickControlModeAvailable) {
            
            [fc sendVirtualStickFlightControlData:ctrlData withCompletion:nil];
        }
        else{
            DVLog(@"virtual stick mode not available");
            [self enterVirtualStickControlMode];
        }
    }
    else{
//        DVLog(@"no FC in sendFlightCommands");
    }
    
    
    
}


-(void) goWithSpeed:(float)speed atBearing:(float)bearing atAltitude:(float) altitude andYaw:(float) yaw{
    
    // bearing should be -180..180
    if (bearing > 180 || bearing < -180) {
        DVLog(@"bearing %0.3f out of interval -180..180",bearing);
        return;
    }
    
    if (speed < 0) {
        speed = fabsf(speed);
        bearing = [[Calc Instance] angle180Of330Angle:(bearing+180)];;
    }
    
    speed = bindBetween(speed, 0, 15);
    
    
    // earth coord sys
    float northSpeed = speed*cosf(RADIAN(bearing));
    float eastSpeed = speed*sinf(RADIAN(bearing));
    
    DJIVirtualStickFlightControlData ctrlData = {0};
    ctrlData.pitch = eastSpeed;
    ctrlData.roll = northSpeed;
    ctrlData.verticalThrottle = altitude;
    ctrlData.yaw = 0;
    
    [self sendFlightCtrlCommands:ctrlData];
    
    return;
//    // commands
//    struct PitchRoll pitchRollCommands = {eastSpeed,northSpeed,NO,NO};
//    struct Altitude altitudeCommand = {altitude,YES};
//    struct Yaw yawCommand = {[self droneCommandYawForDroneTargetYaw:0],YES};
//    
//    [self sendFlightCtrlCommands:pitchRollCommands withAltitude:altitudeCommand andYaw:yawCommand];
    
}

#pragma mark - Gimbal control methods
-(void) updateZoneOfGimbalForDrone:(Drone*) drone withGimbalState:(DJIGimbalState*) gimbalState{
    
    drone.gimbalYawEarth = gimbalState.attitudeInDegrees.yaw;
    drone.previousGDDiffAngle = drone.gimbalCurrentBearingInDroneBC;
    
    drone.gimbalCurrentBearingInDroneBC = [[Calc Instance] closestDiffAngle:drone.gimbalYawEarth toAngle:drone.droneYaw];
    
    if (fabs(drone.gimbalCurrentBearingInDroneBC)<29) {
        drone.gimbalZone = 0;
    }
    else if (fabs(drone.gimbalCurrentBearingInDroneBC)>110){
        
        if (sin(drone.previousGDDiffAngle*M_PI/180)*sin(drone.gimbalCurrentBearingInDroneBC*M_PI/180)<0) {
            drone.gimbalZone = drone.gimbalZone + sign(sin(drone.previousGDDiffAngle*M_PI/180));
        }
    }
    
    drone.gimbalCurrent330yaw = [[Calc Instance] angle330OfAngle:gimbalCurrentBearingInDroneBC withZone:gimbalZone];
}



#pragma mark - Mission manager methods

-(void) prepareTakeoffMissionWithCompletion:(void (^)(NSError* error))callback {
    
    [[DJIMissionManager sharedInstance] setDelegate:self];
    
    takeOffMissionSteps = [[NSMutableArray alloc] init];
    takeOffstepNames = [NSArray arrayWithObjects:@"Taking off",@"going Up to 11m", nil];
    
    DJIMissionStep* takeoffStep = [[DJITakeoffStep alloc] init];
    [takeOffMissionSteps addObject:takeoffStep];

    DJIMissionStep* goUpStep = [[DJIGoToStep alloc] initWithCoordinate:[[Menu instance]getFrontVC].FCcurrentState.aircraftLocation altitude:11];
    [takeOffMissionSteps addObject:goUpStep];
    
    _takeOffMission = [[DJICustomMission alloc] initWithSteps:takeOffMissionSteps];
    
    [[DJIMissionManager sharedInstance] prepareMission:_takeOffMission withProgress:^(float progress) {
        
        
    } withCompletion:^(NSError * _Nullable error) {
        callback(error);
    }];
}

-(void) takeOffWithCompletion:(void(^)(NSError * _Nullable error))callback{
    
    [self prepareTakeoffMissionWithCompletion:^(NSError *error) {
        if (error) {
            ShowResult(@"ERROR: prepareMission:withProgress:withCompletion:. %@", error.description);
            callback(error);
        }
        else {
            
            [[DJIMissionManager sharedInstance] startMissionExecutionWithCompletion:^(NSError * _Nullable error) {
                callback(error);
                if (error) {
                    if ([error.localizedDescription containsString:@"please switch to 'F' mode"]) {
                        ShowResult(@"Please switch Remote controller to F mode and retry");
                    }
                    else{
                        ShowResult(@"Error starting takeoff mission %@", error.localizedDescription);
                    }
                    
                    
                }
                else {
                    // takeoffmission started .. we should check if it will succeed
                }
            }];
            
        }
    }];
}

// This is DJI follow me mission, we don't use it, we just tried it, and found tht it is limited to 10m/s which is not good for our use case
-(void) startFollowMissionWithCompletion:(void (^)(NSError* error))callback{
    if (!_followMeMission) {
        _followMeMission = [[DJIFollowMeMission alloc] init];
        _followMeMission.followMeCoordinate = [[Menu instance] getFrontVC].realDrone.droneLoc.coordinate;
        _followMeMission.followMeAltitude = 10.5;
        _followMeMission.heading = DJIFollowMeHeadingTowardFollowPosition;
    }
    [[DJIMissionManager sharedInstance] prepareMission:_followMeMission withProgress:^(float progress) {
        
    } withCompletion:^(NSError * _Nullable error) {
        if (error) {
            ShowResult(@"error preparing follow mission : %@",error.localizedDescription);
        }
        else{ // start follow mission
            [[DJIMissionManager sharedInstance] startMissionExecutionWithCompletion:^(NSError * _Nullable error) {
                
                if (error) {
                    ShowResult(@"error starting follow mission : %@",error.localizedDescription);
                }
                else {
                    DVLog(@"SUCCESS: start follow Mission ");
                    
                    [self startUpdateFollowMeTimer];
                }
            }];
        }
    }];
}

-(void) startUpdateFollowMeTimer{
    NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onUpdateTimer:) userInfo:nil repeats:YES];
    
    [timer fire];
}

-(void) onUpdateTimer:(id)sender{
    if (!self.followLoc) {
        _followLoc = frontVC.phoneLocation;
    }
//    _followMeMission.followMeCoordinate = self.followLoc.coordinate;
    _followMeMission.followMeCoordinate = frontVC.phoneLocation.coordinate;
    
    [DJIFollowMeMission updateFollowMeCoordinate:self.followLoc.coordinate altitude:11 withCompletion:^(NSError * _Nullable error) {
        if (error) {
            DVLog(@"error updating follow me coord %@",error.localizedDescription);
        }
    }];
    
    [mapView movePinNamed:@"followMeCoord" toCoord:[[Calc Instance] locationWithCoordinates:_followMeMission.followMeCoordinate] andColor:@"RGB 255 255 255"];
    
    _followMeMission.heading = DJIFollowMeHeadingTowardFollowPosition;
}


-(void)missionManager:(DJIMissionManager *)manager missionProgressStatus:(DJIMissionProgressStatus *)missionProgress {

    if (manager.currentExecutingMission) {
        currentMission = manager.currentExecutingMission;
    }
    else{
        // no mission
    }
    
    if (manager.currentExecutingMission ==  _takeOffMission) {
        
            DJICustomMissionStatus* cmStatus = (DJICustomMissionStatus*)missionProgress;
        
        if ([takeOffMissionSteps containsObject:cmStatus.currentExecutingStep]) {
            
            NSUInteger index = [takeOffMissionSteps indexOfObject:cmStatus.currentExecutingStep];
            [[[Menu instance] getTopMenu] setStatusLabelText:[takeOffstepNames objectAtIndex:index]];
            
        }
        else{
            // mission step not recognized
        }
        

    }
    
    return;
}

- (void)missionManager:(DJIMissionManager *_Nonnull)manager didFinishMissionExecution:(NSError *_Nullable)error{
    
    if (currentMission == _takeOffMission) {
//        ShowResult(@"takeoff finished");
        
        [frontVC.topMenu setStatusLabelText:@"Hovering"];
        
        // after successful takeoff (good check point), check that no timer is firing , and also set the UI as it should be
        
        
        [frontVC showGoButton];
    }
    else{
        ShowResult(@"smth else finished %@,%@",currentMission,_takeOffMission);
    }
}











// OLD methods



#pragma mark - flight control methods
-(void) sendFlightCtrlCommands:(struct PitchRoll) pitchAndRoll withAltitude:(struct Altitude) altitude andYaw:(struct Yaw) yaw{
    
    // with this centralized flight ctrl sending we can modify commands for NoFlyZone or for geoFencing ...
    if (!_flightController) {
        _flightController = [ComponentHelper fetchFlightController];
        if (!_flightController) {
            
            return;
        }
    }
    
    if (!_flightController.isVirtualStickControlModeAvailable) {
        //        DVLog(@"virtual stick not available .. trying to enable it");
        
        [_flightController enableVirtualStickControlModeWithCompletion:^(NSError *error) {
            if (error) {
                //                DVLog(@"Enter Virtual Stick Mode:%@", error.description);
            }
            else
            {
                //                DVLog(@"Enter Virtual Stick Mode:Succeeded");
            }
        }];
    }
    
    {
        DJIVirtualStickVerticalControlMode altitudeMode = (altitude.position) ? DJIVirtualStickVerticalControlModePosition:DJIVirtualStickVerticalControlModeVelocity;
        
        DJIVirtualStickYawControlMode yawMode = (yaw.palstance) ? DJIVirtualStickYawControlModeAngularVelocity:DJIVirtualStickYawControlModeAngle;
        
        DJIVirtualStickRollPitchControlMode pitchRollMode = (pitchAndRoll.angleOrVelocity) ? DJIVirtualStickRollPitchControlModeAngle:DJIVirtualStickRollPitchControlModeVelocity;
        
        DJIVirtualStickFlightCoordinateSystem FlightCoordinateSystem = (pitchAndRoll.coordSystem) ? DJIVirtualStickFlightCoordinateSystemBody:DJIVirtualStickFlightCoordinateSystemGround;
        
        
        if (_flightController.verticalControlMode != altitudeMode) {
            _flightController.verticalControlMode = altitudeMode;
        }
        if (_flightController.yawControlMode != yawMode) {
            _flightController.yawControlMode = yawMode;
        }
        if (_flightController.rollPitchControlMode != pitchRollMode) {
            _flightController.rollPitchControlMode = pitchRollMode;
        }
        if (_flightController.rollPitchCoordinateSystem != FlightCoordinateSystem) {
            _flightController.rollPitchCoordinateSystem = FlightCoordinateSystem;
        }
    }
    DJIVirtualStickFlightControlData flightCtrlData = {0};
    
    flightCtrlData.pitch = pitchAndRoll.pitch;
    flightCtrlData.roll = pitchAndRoll.roll;
    flightCtrlData.yaw = yaw.yaw;
    if (_flightController.verticalControlMode == DJIVirtualStickVerticalControlModePosition) {
        flightCtrlData.verticalThrottle = bindBetween(altitude.altitude, 3, 100) ;
    }
    else if (_flightController.verticalControlMode == DJIVirtualStickVerticalControlModeVelocity){
        flightCtrlData.verticalThrottle = bindBetween(altitude.altitude, -5, 5);
    }
    
    
    
    //    DVLog(@"sending : pitch %f , roll %f , yaw %f , altitude ,%f ",pitchAndRoll.pitch,pitchAndRoll.roll, yaw.yaw,altitude.altitude );
    
    if (_flightController && _flightController.isVirtualStickControlModeAvailable) {
        [_flightController enableVirtualStickControlModeWithCompletion:^(NSError *error) {
            if (error) {
                // DVLog(@"Enter Virtual Stick Mode:%@", error.description);
            }
            else
            {
                //DVLog(@"Enter Virtual Stick Mode:Succeeded");
            }
        }];
        
        [_flightController sendVirtualStickFlightControlData:flightCtrlData withCompletion:nil];
    }
    else{
        [_flightController enableVirtualStickControlModeWithCompletion:^(NSError *error) {
            if (error) {
                // DVLog(@"Enter Virtual Stick Mode:%@", error.description);
            }
            else
            {
                //  DVLog(@"Enter Virtual Stick Mode:Succeeded");
            }
        }];
    }
}

-(void) goWithSpeed:(float) speed atBearing:(float) bearing{
    // speed should be reasonable 0.. 17
    speed = bindBetween(speed, 0, 17);
    
    // bearing should be -180..180
    if (bearing > 180 || bearing < -180) {
        DVLog(@"bearing %0.3f out of interval -180..180",bearing);
        bearing = bindBetween(bearing, -180, 180);
    }
    
    // earth coord sys
    float northSpeed = speed*cosf(RADIAN(bearing));
    float eastSpeed = speed*sinf(RADIAN(bearing));
    
    // HAD TO SWITH NORTH AND EAST ...
    struct PitchRoll pitchRollCommands = {eastSpeed,northSpeed,NO,NO};
    struct Altitude altitudeCommand = {10,YES};
    struct Yaw yawCommand = {[self droneCommandYawForDroneTargetYaw:0],YES};
    
    [self sendFlightCtrlCommands:pitchRollCommands withAltitude:altitudeCommand andYaw:yawCommand];
    
//    Vec* droneSpeed_Vec = [[Vec alloc] initWithNorthComponent:_FCcurrentState.velocityX andEastComponent:_FCcurrentState.velocityY];
    
    
}

-(void) goUpWithSpeed_altitude:(float) speed{
    // speed should be reasonable 0.. 4 .. 5??
    speed = bindBetween(speed, 0, 4);
    
    // HAD TO SWITH NORTH AND EAST ...
    struct PitchRoll pitchRollCommands = {0,0,NO,NO};
    struct Altitude altitudeCommand = {10,NO};
    struct Yaw yawCommand = {[self droneCommandYawForDroneTargetYaw:0],YES};
    
    [self sendFlightCtrlCommands:pitchRollCommands withAltitude:altitudeCommand andYaw:yawCommand];
    
}

-(void) goWithNorthSpeed:(float) northSpeed andEastSpeed:(float) eastSpeed{
    
    Vec* targetSpeed_vec = [[Vec alloc] initWithNorthComponent:northSpeed andEastComponent:eastSpeed];
    Vec* droneSpeed_Vec = [[Vec alloc] initWithNorthComponent:_FCcurrentState.velocityX andEastComponent:_FCcurrentState.velocityY];
    
    // HAD TO SWITH NORTH AND EAST ...
    struct PitchRoll pitchRollCommands = {eastSpeed,northSpeed,NO,NO};
    struct Altitude altitudeCommand = {10,YES};
    struct Yaw yawCommand = {[self droneCommandYawForDroneTargetYaw:0],YES};
    
    [self sendFlightCtrlCommands:pitchRollCommands withAltitude:altitudeCommand andYaw:yawCommand];
    
    // *******  NORTH EAST COMPONENTS  LOG *******
    
    // ******** NORM ANGLE COMPONENTS  LOG ********
    
//    DVLoggerLog(@"goWithSpeed", [NSString stringWithFormat:@"speed,%0.3f, angle , %0.3f, realSpeed, %0.3f, realAngle,%0.3f ",targetSpeed_vec.norm,targetSpeed_vec.angle,droneSpeed_Vec.norm,droneSpeed_Vec.angle]);
}

-(void) goWithSpeed:(float)speed atBearing:(float)bearing andAcc:(float) acc{
    
    speed = bindBetween(speed, 0, 16);
    
    acc = bindBetween(acc, 0, 2);
    Vec* currentDroneSpeed = [[Vec alloc] initWithNorthComponent:_FCcurrentState.velocityX andEastComponent:_FCcurrentState.velocityY];
    Vec* targetDroneSpeed = [[Vec alloc] initWithNorm:speed andAngle:bearing];
    
    float diffNorthSp = targetDroneSpeed.N - currentDroneSpeed.N;
    float diffEastSp = targetDroneSpeed.E - currentDroneSpeed.E;
    
    float nextNorthSp = currentDroneSpeed.N + diffNorthSp*acc;
    float nextEastSp = currentDroneSpeed.E + diffEastSp*acc;
    
    Vec* nextDroneSpeed = [[Vec alloc] initWithNorthComponent:nextNorthSp andEastComponent:nextEastSp];
    
    float nextSpeed = nextDroneSpeed.norm;
    float nextAngle = nextDroneSpeed.angle;
    [self goWithSpeed:nextSpeed atBearing:nextAngle];
    
//    DVLoggerLog(@"goWithSpeed", [NSString stringWithFormat:@"current , %0.3f , %0.3f , target , %0.3f , %0.3f ,diiff , %0.3f , %0.3f , next NE, %0.3f ,%0.3f, next, %0.3f ,%0.3f",currentDroneSpeed.norm,currentDroneSpeed.angle,targetDroneSpeed.norm,targetDroneSpeed.angle,diffNorthSp,diffEastSp,nextNorthSp,nextEastSp, nextSpeed,nextAngle]);
//    DVLoggerLog(@"goWithSpeed", [NSString stringWithFormat:@"targetSp,%0.3f, targetAngle , %0.3f, realSpeed, %0.3f, realCourse,%0.3f  ,nextSp, %0.3f, nextAngle ,%0.3f",targetDroneSpeed.norm,targetDroneSpeed.angle,currentDroneSpeed.norm,currentDroneSpeed.angle,nextSpeed,nextAngle]);
}



-(void) followLocation:(CLLocation *) location withDroneYawMode:(int) droneYawMode andTargetAltitude:(float) targetAltitude{
    currentDroneCoordinate = _FCcurrentState.aircraftLocation;
    droneCurrentYawEarth = _FCcurrentState.attitude.yaw;
    
    Vec * displacementDroneToLocation_Vec = [self displacementVectorFromStartCoordinate:_FCcurrentState.aircraftLocation toCoordinate:location.coordinate];
    
    [self moveByVectorInEarthCoordinate:displacementDroneToLocation_Vec withDroneYawMode:droneYawMode andTargetAltitude:targetAltitude];
    
    // ***** Log *******
    // necessary for command decel acceleration
    distanceTotarget = [[Calc Instance] distanceFromCoords2D:_FCcurrentState.aircraftLocation toCoords2D:location.coordinate];

}

-(void) moveByVectorInEarthCoordinate:(Vec *) MovEarth_vec withDroneYawMode:(int) droneYawMode andTargetAltitude:(float) targetAltitude{
    Vec * MovDroneBC_Vec = [MovEarth_vec rotateByAngle:-_FCcurrentState.attitude.yaw];
    [self moveByVectorInDroneBC:MovDroneBC_Vec withDroneYawMode:droneYawMode andTargetAltitude:targetAltitude];
}

-(void) moveByVectorInDroneBC:(Vec *) MovDroneBC_Vec withDroneYawMode:(int) droneYawMode andTargetAltitude:(float) targetAltitude{
    
    //global variables : avoidObstacles, targetSpeed, targetPitchSpeed(Roll),pitchSpeed (Roll), targetSpeed_Vec,gimbalBearingInDroneBC for compensation
    if (MovDroneBC_Vec.norm > 1000) {
        [MovDroneBC_Vec updateWithNorm:0 andAngle:0];
        //DVLog(@"far target");
        return;
    }
    Vec * outputNFZ_Vec;
    
    if (_avoidObstacles) {
        outputNFZ_Vec = [self updateMoveVectorInDroneBodyCoordWithNoFlyZones:MovDroneBC_Vec];
    }
    else
    {
        outputNFZ_Vec = MovDroneBC_Vec;
    }
    
    //Modif ...
    if (outputNFZ_Vec.norm < 0.5) {
        outputNFZ_Vec =0;
    }
    
    targetSpeed = [self targetSpeedForDistance:outputNFZ_Vec.norm];
    
    targetSpeed_Vec = [[Vec alloc] initWithNorm:targetSpeed andAngle:outputNFZ_Vec.angle];
    
    targetPitchSpeed = targetSpeed_Vec.N;
    targetRollSpeed = targetSpeed_Vec.E;
    
    pitchSpeed = _FCcurrentState.velocityX*cos(RADIAN(droneCurrentYawEarth))+_FCcurrentState.velocityY*sin(RADIAN(droneCurrentYawEarth));
    rollSpeed = -_FCcurrentState.velocityX*sin(RADIAN(droneCurrentYawEarth))+_FCcurrentState.velocityY*cos(RADIAN(droneCurrentYawEarth));
    
    float commandePitch = [self commandForTargetSpeed:targetPitchSpeed fromSpeed:pitchSpeed];
    float commandeRoll = [self commandForTargetSpeed:targetRollSpeed fromSpeed:rollSpeed];
    
    float targetYawAngle;
    float diffAngleToYaw; // specifies if cw or ccw when in mode compensation
    
    struct PitchRoll pitchRollCommands = {commandePitch,-commandeRoll,YES,YES};
    struct Altitude altitudeCommand = {35,YES};
    struct Yaw yawCommand = {0,YES}; // yaw to be set with switch, default no yaw
    
    //DVLog(@"sending, pitch,%0.3f,roll,%0.3f,pitchSp, %0.3f,rollSp,%0.3f, targetPSp,%0.3f,targetRollSp, %0.3f,targetSp,%0.3f,norm,%0.3f, droneYaw,%0.3f",pitchRollCommands.pitch,pitchRollCommands.roll, pitchSpeed,rollSpeed,targetPitchSpeed,targetRollSpeed,targetSpeed,outputNFZ_Vec.norm,droneCurrentYawEarth);
    
    switch (droneYawMode) {
        case 0: //towards user ... UNSTABLE WHEN CLOSE TO USER -- DO NOT USE
            targetYawAngle = [[Calc Instance] headingTo:_userLocation.coordinate fromPosition:_FCcurrentState.aircraftLocation]; // angle in earth coord
            diffAngleToYaw = [[Calc Instance] closestDiffAngle:targetYawAngle toAngle:_FCcurrentState.attitude.yaw];
            
            yawCommand.yaw = [self yawCommandToAdjustDroneDiffAngleToYaw:diffAngleToYaw];
            
            [self sendFlightCtrlCommands:pitchRollCommands withAltitude:altitudeCommand andYaw:yawCommand];
            
            break;
            
        case 1: //towards output_movVec angle
            
            diffAngleToYaw = outputNFZ_Vec.angle;
            yawCommand.yaw = [self yawCommandToAdjustDroneDiffAngleToYaw:diffAngleToYaw];
            
            [self sendFlightCtrlCommands:pitchRollCommands withAltitude:altitudeCommand andYaw:yawCommand];
            
            break;
            
            
        case 2: // towards gimbalBearingInDroneBC with respect to gimbal yaw, compensation // ******** Gimbal controls drone yaw **********
            //HERE
            altitudeCommand.altitude = targetAltitude;
            yawCommand.yaw = [self droneCommandYawForDroneTargetYaw:0];
            [self sendFlightCtrlCommands:pitchRollCommands withAltitude:altitudeCommand andYaw:yawCommand];
            
            break;
            
        case 3: // no yaw
        default:
            yawCommand.yaw = 0;
            [self sendFlightCtrlCommands:pitchRollCommands withAltitude:altitudeCommand andYaw:yawCommand];
            
            break;
    }
    
    DVLoggerLog(@"flight", [NSString stringWithFormat:@"distTT , %0.3f , bearing , %0.3f ,, veloN , %0.3f , veloE , %0.3f ,,pitchSp , %0.3f , rollSp ,  %0.3f ,yaw , %0.3f ,, targetPSp , %0.3f , targetRSp , %0.3f ",outputNFZ_Vec.norm,outputNFZ_Vec.angle,_FCcurrentState.velocityX,_FCcurrentState.velocityY,pitchSpeed,rollSpeed, droneCurrentYawEarth, targetPitchSpeed,targetRollSpeed]);
    
}

-(void) gimbalGoToAbsolutePitch2:(float) targetPitch andYaw:(float) targetYaw{
    __weak DJIGimbal* gimbal = [ComponentHelper fetchGimbal];
    if (gimbal) {
        targetPitch = bindBetween(targetPitch, -90, 30);
        targetYaw = bindBetween(targetYaw, -180, 180);
        
        DJIGimbalRotateAngleMode angleMode = DJIGimbalAngleModeAbsoluteAngle;
        
        //pitch
        DJIGimbalAngleRotation pitchRotation;
        pitchRotation.direction = (targetPitch <= 0) ? DJIGimbalRotateDirectionCounterClockwise:DJIGimbalRotateDirectionClockwise;
        pitchRotation.angle = targetPitch;
        pitchRotation.enabled = YES;
        
        //roll
        DJIGimbalAngleRotation rollRotation;
        rollRotation.direction = DJIGimbalRotateDirectionClockwise;
        rollRotation.angle = 0;
        rollRotation.enabled = NO;
        
        // yaw
        DJIGimbalAngleRotation yawRotation;
        yawRotation.angle = targetYaw;
        yawRotation.enabled = YES;
        yawRotation.direction = (targetYaw >=0) ? DJIGimbalRotateDirectionClockwise:DJIGimbalRotateDirectionCounterClockwise;
        
        // send gimbal commands
        [gimbal rotateGimbalWithAngleMode:angleMode pitch:pitchRotation roll:rollRotation yaw:yawRotation withCompletion:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"ERROR: rotateGimbalInAngle. %@", error.description);
            }
        }];
        
        DVLog(@"yaw , %0.3f , gimbalYaw, %0.3f ,compTime , %0.3f,", targetYaw,_gimbal.attitudeInDegrees.yaw,_gimbal.completionTimeForControlAngleAction);
    }
}

-(void) gimbalGoToAbsolutePitch:(float) targetPitch andRoll:(float) targetRoll andYaw:(float) target330Yaw{
    //    NSLog(@"trying absolute once");
    __weak DJIGimbal* gimbal = [ComponentHelper fetchGimbal];
    if (gimbal) {
        targetPitch = bindBetween(targetPitch, -90, 30);
        targetRoll = bindBetween(targetRoll, -15, 15);
        target330Yaw = bindBetween(target330Yaw, -330, 330);
        
        DJIGimbalRotateAngleMode angleMode = DJIGimbalAngleModeAbsoluteAngle;
        
        //pitch
        DJIGimbalAngleRotation pitchRotation;
        pitchRotation.direction = (targetPitch <= 0) ? DJIGimbalRotateDirectionCounterClockwise:DJIGimbalRotateDirectionClockwise;
        pitchRotation.angle = targetPitch;
        pitchRotation.enabled = YES;
        
        //roll
        DJIGimbalAngleRotation rollRotation;
        rollRotation.direction = (targetRoll <= 0) ? DJIGimbalRotateDirectionCounterClockwise:DJIGimbalRotateDirectionClockwise;
        rollRotation.angle = targetRoll;
        rollRotation.enabled = NO;
        
        //yaw
        float possible330 = bindBetween(target330Yaw, gimbalCurrent330Yaw-179, gimbalCurrent330Yaw+179);
        
        DJIGimbalAngleRotation yawRotation;
        
        yawRotation.angle = possible330;
        yawRotation.enabled = YES;
        yawRotation.direction = (possible330 >=0) ? DJIGimbalRotateDirectionClockwise:DJIGimbalRotateDirectionCounterClockwise;
        
        // send gimbal commands
        [gimbal rotateGimbalWithAngleMode:angleMode pitch:pitchRotation roll:rollRotation yaw:yawRotation withCompletion:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"ERROR: rotateGimbalInAngle. %@", error.description);
            }
        }];
    }
    
}

// cant be called once
-(void) gimbalMoveWithSpeed:(float) pitchSp andRoll:(float) rollSp andYaw:(float) yawSp{
    __weak DJIGimbal* gimbal = [ComponentHelper fetchGimbal];
    if (gimbal){
        pitchSp = bindBetween(pitchSp, -180, 180);
        yawSp = bindBetween(yawSp, -180, 180);
        
        DJIGimbalSpeedRotation pitchRotation;
        pitchRotation.angleVelocity = pitchSp;
        pitchRotation.direction = (pitchSp >=0) ? DJIGimbalRotateDirectionClockwise:DJIGimbalRotateDirectionCounterClockwise;
        
        DJIGimbalSpeedRotation rollRotation;
        rollRotation.angleVelocity = 0.0;
        rollRotation.direction = (rollSp >=0) ? DJIGimbalRotateDirectionClockwise:DJIGimbalRotateDirectionCounterClockwise;
        
        DJIGimbalSpeedRotation yawRotation;
        yawRotation.angleVelocity = yawSp;
        yawRotation.direction = (yawSp >=0) ? DJIGimbalRotateDirectionClockwise:DJIGimbalRotateDirectionCounterClockwise;
        
        [gimbal rotateGimbalBySpeedWithPitch:pitchRotation roll:rollRotation yaw:yawRotation withCompletion:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"ERROR: rotateGimbalInSpeed. %@", error.description);
            }
        }];
        
    }
}

// use only once !!!!
-(void) gimbalMoveWithRelativeAngle:(float) pitchAngle andRoll:(float) rollAngle andYaw:(float) yawAngle withCompletionTime:(float) compTime{
    __weak DJIGimbal* gimbal = [ComponentHelper fetchGimbal];
    if (gimbal) {
        // completion time for gimbal in angle mode is 1.0 second
        
        if (compTime!=1) {
            compTime = bindBetween(compTime, 0.1, 25.5);
            gimbal.completionTimeForControlAngleAction = compTime;
        }
        
        pitchAngle = bindBetween(pitchAngle,-180,180);
        rollAngle = bindBetween(rollAngle, -180, 180);
        yawAngle = bindBetween(yawAngle, -180, 180);
        
        //pitch
        DJIGimbalAngleRotation pitchRotation;
        pitchRotation.angle = pitchAngle;
        pitchRotation.enabled = YES;
        pitchRotation.direction = (pitchAngle >=0) ? DJIGimbalRotateDirectionClockwise:DJIGimbalRotateDirectionCounterClockwise;;
        
        
        //yaw
        DJIGimbalAngleRotation yawRotation;
        
        yawRotation.angle = yawAngle;
        yawRotation.enabled = YES;
        yawRotation.direction = (yawAngle >=0) ? DJIGimbalRotateDirectionClockwise:DJIGimbalRotateDirectionCounterClockwise;;
        
        //roll
        DJIGimbalAngleRotation rollRotation;
        rollRotation.angle = 0.0;
        rollRotation.enabled = NO;
        rollRotation.direction = DJIGimbalRotateDirectionClockwise;
        
        DJIGimbalRotateAngleMode angleMode = DJIGimbalAngleModeRelativeAngle;
        
        [gimbal rotateGimbalWithAngleMode:angleMode pitch:pitchRotation roll:rollRotation yaw:yawRotation withCompletion:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"ERROR: rotateGimbalInAngle. %@", error.description);
            }
        }];
    }
}

#pragma mark -  flight help methods

-(void) enableVirtualStickControlMode{
//    DJIFlightController* flightController = [ComponentHelper fetchFlightController];
    if (_flightController) {
        [_flightController enableVirtualStickControlModeWithCompletion:nil];
    }
    else{
    }
}

-(void) disableVirtualStickControlMode{
    
    if (_flightController) {
        [_flightController disableVirtualStickControlModeWithCompletion:nil];
    }
    else{
//        DVLog(@"no flight controller");
    }
}



-(float) targetSpeedForDistance:(float) distance{
    
    if (fabsf(distance) > radiusBrakingZone) {//60 in init
        return 25*sign(distance);
    }
    else
        return sign(distance)*fabsf(distance)/3;
    
}

-(float) commandForTargetSpeed:(float) targSpeed fromSpeed:(float) sp{ // voir decel accel generalisee.xlsx
    //Now having the targetPitchSpeed and pitchSpeed
    float decel;
    float commandeAngle;
    float accel;
    
    float dt =1 ;
    
    if (sp == 0) {
        sp = 0.001;
    }
    
    if (fabsf(targSpeed)==25) { // (0) // >= 18
        commandeAngle = -sign(targSpeed)*30;
    }
    else{
        
        if ((fabsf(targSpeed) < fabsf(sp) )&& targSpeed*sp > 0) { // (1)
            //In this case we want a deceleration of (targetPitchspeed-pitchSpeed)/dt
            
            decel = -fabsf(targSpeed - sp)/dt;
            commandeAngle = sign(sp)*[self angleForDeceleration:decel];
        }
        else  //acceleration pure //(2)
        {
            accel = (targSpeed-sp)/dt;
            
            if (distanceTotarget < 20) {
                accel = bindBetween(accel, -1, 1);
            }
            
            if (accel > 0) { // (2.1)
                if (accel > 1) {
                    commandeAngle = -4.5662*accel -13.8789; // 1 --> 9.3127 .. not good //(2.1.1)
                }
                else
                {
                    commandeAngle = -10*accel; // commande angle negatif .. avance en avant // (2.1.2)
                    
                }
            }
            else //accel en marche arriere // (2.2)
            {
                if (accel < -1.6) {
                    commandeAngle = -6.1162*accel+8.1847; // (2.2.1)
                }
                else
                {
                    commandeAngle = -11.25*accel; // (2.2.2)
                }
            }
        }
    }
    
    
    commandeAngle = bindBetween(commandeAngle, -30, 30);
    return commandeAngle;
}

-(float) droneCommandYawForDroneTargetYaw:(float) targetDYaw{ //with respect to gimbalCurrent330Yaw .. speed command not angle
    
    float mYaw = 0;
    //jouer sur angle limite en real time pour voir quel bonne valeur correspond
    float angle330Limite = 90; //140
    float maxYawSp = 100;
    float minYawSp = 0; // try with 0 in place of 40 to smooth transition ...
    
    float a = (maxYawSp-minYawSp)/(330-angle330Limite);
    float b = (330*minYawSp-maxYawSp*angle330Limite)/(330-angle330Limite);
    
    if (!_realDrone) {
        return 0;
    }
    if (fabsf(_realDrone.gimbalCurrent330yaw)>angle330Limite) {
        mYaw = a*_realDrone.gimbalCurrent330yaw +sign(_realDrone.gimbalCurrent330yaw)*b;
        
    }
    else
    {//tester d'abord sans cette condition else
        if (targetDYaw) { // si target yaw n'est pas spécifié on envoie 0
            if ([[Calc Instance] angle:_realDrone.gimbalYawEarth isBetween:_realDrone.droneYaw andAngle:targetDYaw]) {
                mYaw = sign([[Calc Instance] isAngle:_realDrone.gimbalYawEarth toTheRightOfAngle:_realDrone.droneYaw]-0.5)*minYawSp/2 + _realDrone.gimbalCurrent330yaw*minYawSp/(2*angle330Limite);
            }
            else if([[Calc Instance] angle:targetDYaw isBetween:_realDrone.gimbalYawEarth andAngle:_realDrone.droneYaw])
            {
                mYaw = [[Calc Instance] closestDiffAngle:targetDYaw toAngle:_realDrone.droneYaw];
            }
            else
            {
                mYaw = -sign([[Calc Instance] isAngle:_realDrone.gimbalYawEarth toTheRightOfAngle:_realDrone.droneYaw]-0.5)*minYawSp/2 - _realDrone.gimbalCurrent330yaw*minYawSp/(2*angle330Limite);
            }
        }
    }
    
    //DVLoggerLog(@"droneYawForGimbal330", [NSString stringWithFormat:@"%0.3f,%0.3f,%0.3f,%0.3f,%0.3f,%0.3f,%0.3f",gimbalTargetBearingEarth,distanceToGimbalTarget,gimbalCurrentYawEarth,gimbalCurrent330Yaw,droneCurrentYawEarth,mYaw,targetDYaw]);
    
    return mYaw;
}

-(float) yawCommandToAdjustDroneDiffAngleToYaw:(float) diffAngleToYa{
    //input is a difference angle to yaw
    
    float cuttingAngleDifference = 90;
    float maxYawSpeed = 60;
    
    float myaw = ((fabs(diffAngleToYa) > cuttingAngleDifference) ? sign(diffAngleToYa)*maxYawSpeed : diffAngleToYa*maxYawSpeed/cuttingAngleDifference);
    
    return myaw;
}


#pragma mark - gimbla angle help methods

-(float) commandFrom330Angle:(float) angle330{
    
    float commandYaw;
    float angle180Ofinput330= [[Calc Instance] angle180Of330Angle:angle330];
    
    if (angle330>=0 && angle330 < 180) { // 0 ..180
        commandYaw = angle330;
    }
    else if (angle330<0 && angle330>-180) // -180..0
    {
        commandYaw = -360+fabs(angle180Ofinput330);
    }
    else if (angle330<-180 && angle330>-330) // -330..-180
    {
        commandYaw = 360+angle330;
    }
    else if (angle330>180 && angle330< 330) // 180 .. 330
    {
        commandYaw = 360-fabs(angle180Ofinput330);
    }
    else
        DVLog(@"angle330 should be between -330 and 330, angle sent %0.1f :", angle330);
    
    return commandYaw;
}

#pragma mark - vector methods

-(Vec *) displacementVectorFromStartCoordinate:(CLLocationCoordinate2D) startCoord toCoordinate:(CLLocationCoordinate2D) targetCoord
{
    Vec * displacementVector = [[Vec alloc] init];
    float distance = [[Calc Instance] distanceFromCoords2D:startCoord toCoords2D:targetCoord];
    float heading = [[Calc Instance] headingTo:targetCoord fromPosition:startCoord];
    
    [displacementVector updateWithNorm:distance andAngle:heading];
    
    return  displacementVector;
}

#pragma mark NFZ

-(Vec *) updateMoveVectorInDroneBodyCoordWithNoFlyZones:(Vec *) inputNFZ_Mov_vec{
    // relies on the current position of the drone, information about obstacles (2D pos and altitude) , and intended move vector ...
    // one obstacle for the moment, later create a list of obstacles {CLLcoordinate, radiusObstacle}
    CLLocationCoordinate2D obstacleCoord = CLLocationCoordinate2DMake(37.410842, -122.023530);
    float radiusObstacle = 15;
    //float obstacleAltitude = 40;
    float fictiveRadius = radiusObstacle+20;
    
    Vec * outputNFZ_Vec = [[Vec alloc] initWithNorm:inputNFZ_Mov_vec.norm andAngle:inputNFZ_Mov_vec.angle];
    
    float bearingToObstacleInEarthCoord = [[Calc Instance] headingTo:obstacleCoord fromPosition:currentDroneCoordinate];
    float bearingToObstacleCenter = [[Calc Instance] closestDiffAngle:bearingToObstacleInEarthCoord toAngle:_FCcurrentState.attitude.yaw]; // OK
    float distanceToObstacle = [[Calc Instance] distanceFromCoords2D:currentDroneCoordinate toCoords2D:obstacleCoord];
    
    float smallAngleCorrection = 0;
    
    float angleLeft;
    float angleRight;
    
    BOOL isGoingInNFZ = NO;
    BOOL isInNFZ = NO;
    BOOL inFictiveRadiusZone = NO;
    BOOL isRight = NO;
    
    Vec *vecRight = [[Vec alloc] initWithNorm:1 andAngle:0];
    Vec *vecLeft = [[Vec alloc] initWithNorm:1 andAngle:0];
    
    float angleOfMove;
    
    if (distanceToObstacle < radiusObstacle) //(1)
    {
        isInNFZ = YES;
        [outputNFZ_Vec updateWithNorm:0 andAngle:inputNFZ_Mov_vec.angle];
    }
    else if(distanceToObstacle < fictiveRadius) //(2)
    {
        smallAngleCorrection = atan(radiusObstacle/distanceToObstacle)*180.0/M_PI;
        
        angleLeft = [[Calc Instance] angle180Of330Angle:(bearingToObstacleCenter - smallAngleCorrection)];
        angleRight = [[Calc Instance] angle180Of330Angle:(bearingToObstacleCenter + smallAngleCorrection)];
        
        [vecRight updateWithNorm:1 andAngle:angleRight];
        [vecLeft updateWithNorm:1 andAngle:angleLeft];
        
        //RIGHT OR LEFT
        if(fabsf([[Calc Instance] closestDiffAngle:vecLeft.angle toAngle:inputNFZ_Mov_vec.angle])< fabsf([[Calc Instance] closestDiffAngle:vecRight.angle toAngle:inputNFZ_Mov_vec.angle]))
        {
            isRight = NO;
            angleOfMove = angleLeft;
        }
        else
        {
            isRight = YES;
            angleOfMove = angleRight;
        }
        
        inFictiveRadiusZone =YES;
        
        if (isRight) {
            angleOfMove = [[Calc Instance] angle180Of330Angle:(bearingToObstacleCenter +90)];
            [outputNFZ_Vec updateWithNorm:inputNFZ_Mov_vec.norm andAngle:angleOfMove];
        }
        else
        {
            angleOfMove = [[Calc Instance] angle180Of330Angle:(bearingToObstacleCenter -90)];
            [outputNFZ_Vec updateWithNorm:inputNFZ_Mov_vec.norm andAngle:angleOfMove];
        }
    }
    else //(3)
    {
        smallAngleCorrection = acosf(sqrtf(distanceToObstacle*distanceToObstacle-fictiveRadius*fictiveRadius)/distanceToObstacle)*180.0/M_PI;
        
        angleLeft = [[Calc Instance] angle180Of330Angle:bearingToObstacleCenter - smallAngleCorrection];
        angleRight = [[Calc Instance] angle180Of330Angle:bearingToObstacleCenter + smallAngleCorrection];
        
        [vecRight updateWithNorm:1 andAngle:angleRight];
        [vecLeft updateWithNorm:1 andAngle:angleLeft];
        
        //RIGHT OR LEFT
        if(fabsf([[Calc Instance] closestDiffAngle:vecLeft.angle toAngle:inputNFZ_Mov_vec.angle])< fabsf([[Calc Instance] closestDiffAngle:vecRight.angle toAngle:inputNFZ_Mov_vec.angle]))
        {
            isRight = NO;
            angleOfMove = angleLeft;
        }
        else
        {
            isRight = YES;
            angleOfMove = angleRight;
        }
        
        if (isRight) {
            angleOfMove = angleRight;
        }
        else {
            angleOfMove = angleLeft;
        }
        
        if([vecRight dotProduct:inputNFZ_Mov_vec]*[vecLeft dotProduct:inputNFZ_Mov_vec] > 0 && [vecRight dotProductWithNormalEastToVector:inputNFZ_Mov_vec]*[vecLeft dotProductWithNormalEastToVector:inputNFZ_Mov_vec]< 0  && inputNFZ_Mov_vec.norm > (distanceToObstacle-fictiveRadius))
        {
            isGoingInNFZ = YES;
            [outputNFZ_Vec updateWithNorm:inputNFZ_Mov_vec.norm andAngle:angleOfMove];
        }
        else
        {
            isGoingInNFZ = NO;
            [outputNFZ_Vec updateWithNorm:inputNFZ_Mov_vec.norm andAngle:inputNFZ_Mov_vec.angle];
        }
    }
    
    DVLoggerLog(@"obstacleAvoidance", [NSString stringWithFormat:@"%0.3f,%0.3f,%0.3f,%0.3f,%d,%0.3f,%0.3f,%0.3f,%0.3f,%0.3f,%d",inputNFZ_Mov_vec.angle,inputNFZ_Mov_vec.norm,distanceToObstacle,bearingToObstacleCenter,isGoingInNFZ,outputNFZ_Vec.angle,outputNFZ_Vec.norm,smallAngleCorrection,angleRight,angleLeft,isInNFZ]);
    
    return  outputNFZ_Vec;
}

#pragma mark comportement dynamique

-(float) angleForDeceleration:(float) decel
{
    // decel should be negative !!!!
    //autrement dit for difference speed during dt
    if (decel <-2) {
        return -6.3775*decel-10.6568;// (1.1)
    }
    else
    { // (1.2)
        return -1.3125*decel; //2.625 est l'angle de la decel -2
    }
}


#pragma mark - unused
// unused before using adapt variable with drone ones ...
-(void) adjustGimbalToLocation:(CLLocation*) location{
    // inputs
    float gimbalCompletionTime = [_gimbal completionTimeForControlAngleAction]; // 0.7 s
    //currentDroneCoordinate = _FCcurrentState.aircraftLocation;
    droneCurrentYawEarth = _FCcurrentState.attitude.yaw;
    
    //gimbalCurrentYawEarth
    gimbalTargetBearingEarth = [[Calc Instance] headingTo:location.coordinate fromPosition:_FCcurrentState.aircraftLocation]; // absolute gimbal angle not with BC
    distanceToGimbalTarget = [[Calc Instance] distanceFromCoords2D:currentDroneCoordinate toCoords2D:location.coordinate];
    gimbalTargetBearingInDroneBC = [[Calc Instance] closestDiffAngle:gimbalTargetBearingEarth toAngle:droneCurrentYawEarth];
    //    float firstAngle = gimbalTargetBearingEarth - gimbalCurrentYawEarth; // need to be 330
    
    //*******************************************
    // find the nearest angle330 not to have a lot of rotation ... ugly
    float angle330_0 = bindBetween([[Calc Instance] angle330OfAngle:gimbalTargetBearingInDroneBC withZone:0],-180,180);
    float angle330_1 = bindBetween([[Calc Instance] angle330OfAngle:gimbalTargetBearingInDroneBC withZone:1],180,330);
    float angle330_m1 = bindBetween([[Calc Instance] angle330OfAngle:gimbalTargetBearingInDroneBC withZone:-1],-330,-180);
    
    float diff0 = fabsf(angle330_0 - gimbalCurrent330Yaw);
    float diff1 = fabsf(angle330_1 - gimbalCurrent330Yaw);
    float diffm1 = fabsf(angle330_m1 - gimbalCurrent330Yaw);
    
    float minDiff = MIN(MIN(diff0, diff1), diffm1) ;
    
    if (minDiff == diffm1) {
        gimbalTarget330Yaw = angle330_m1;
    }
    else if (minDiff == diff1)
    {
        gimbalTarget330Yaw = angle330_1;
    }
    else
    {
        gimbalTarget330Yaw = angle330_0;
    }
    //*******************************************
    float firstAngle = gimbalTarget330Yaw - gimbalCurrent330Yaw;
    
    float speed = location.speed;// if speed < 0 return only the normal correction
    float input_course = location.course;
    if (speed <= 0 || input_course < 0) {
        [self adjustGimbalAttitudeTo:location.coordinate];
        return;
    }
    float course = (input_course <= 180) ? input_course:input_course-360;
    
    float Vr = -speed*cos(RADIAN(course))*sin(RADIAN(gimbalTargetBearingEarth)) + speed*sin(RADIAN(course))*cos(RADIAN(gimbalTargetBearingEarth)); // projection of the speed on the orthRadial component
    float angularVel = Vr/distanceToGimbalTarget;
    
    float angularVel_Deg = angularVel*180.0/M_PI; //  car speed info
    float angularVel_first = firstAngle/gimbalCompletionTime; // position info
    //DVLog(@"omega %0.3f,first ang %0.3f",angularVel_Deg, angularVel_first);
    //    DVLog(@"comp %0.3f",gimbalCompletionTime);
    float previousAngularSpeed = targetAngularSpeed;
    targetAngularSpeed = angularVel_Deg + angularVel_first;
    //    targetAngularSpeed = bindBetween(angularVel_Deg + angularVel_first, previousAngularSpeed- 10,previousAngularSpeed+10) ;
    DVLog(@"diff %0.3f",targetAngularSpeed-previousAngularSpeed);
    [self gimbalMoveWithSpeed:0 andRoll:0 andYaw:targetAngularSpeed];
    
}

-(void) adjustGimbalAttitudeTo_new16:(CLLocationCoordinate2D)targetBearingCoordForGimbal{
    float altitude = _FCcurrentState.altitude;
    currentDroneCoordinate = _FCcurrentState.aircraftLocation;
    droneCurrentYawEarth = _FCcurrentState.attitude.yaw;
    
    if(!CLLocationCoordinate2DIsValid(targetBearingCoordForGimbal) || targetBearingCoordForGimbal.latitude ==0 || targetBearingCoordForGimbal.longitude ==0) {
        DVLog(@"targetBearingCoordForGimbal invalid");
        return;
    }
    
    gimbalTargetBearingEarth = [[Calc Instance] headingTo:targetBearingCoordForGimbal fromPosition:_FCcurrentState.aircraftLocation];
    gimbalTargetBearingInDroneBC = [[Calc Instance] closestDiffAngle:gimbalTargetBearingEarth toAngle:droneCurrentYawEarth];
    
    if (!arrayGimbalBearing) {
        arrayGimbalBearing = [[NSMutableArray alloc] init];
    }
    avgGimbalBearing = [[Calc Instance] filterVar:gimbalTargetBearingInDroneBC inArray:arrayGimbalBearing angles:YES withNum:3];
    
    distanceToGimbalTarget = [[Calc Instance] distanceFromCoords2D:currentDroneCoordinate toCoords2D:targetBearingCoordForGimbal];
    gimbalPitchToTargetOnTheGround = -atanf(altitude/(distanceToGimbalTarget))*180/M_PI;
    
    [self gimbalGoToAbsolutePitch:gimbalPitchToTargetOnTheGround andRoll:0 andYaw:avgGimbalBearing];
}
-(void) adjustGimbalAttitudeTo:(CLLocationCoordinate2D) targetBearingCoordForGimbal {
    //global var : distanceToGimbalTarget, gimbalTargetBearingEarth
    
    float altitude = _FCcurrentState.altitude;
    currentDroneCoordinate = _FCcurrentState.aircraftLocation;
    droneCurrentYawEarth = _FCcurrentState.attitude.yaw;
    
    // find  gimbalTargetBearingInDroneBC
    
    switch (_gimbalYawMode) {
        case 0://towards user
            //            gimbalTargetBearingEarth = [[Calc Instance] headingTo:_userLocation.coordinate fromPosition:_FCcurrentState.aircraftLocation];
            //            gimbalTargetBearingInDroneBC = [[Calc Instance] closestDiffAngle:gimbalTargetBearingEarth toAngle:droneCurrentYawEarth];
            //
            //
            //            distanceToGimbalTarget = [self distanceFromCoords2D:_FCcurrentState.aircraftLocation toCoords2D:_userLocation.coordinate];
            //            gimbalPitchToTargetOnTheGround = -atanf(altitude/distanceToGimbalTarget)*180/M_PI;
            
            break;
        case 1: // gimbal to targetCamera and controls the drone ...
            
            // HERE
            
            if(!CLLocationCoordinate2DIsValid(targetBearingCoordForGimbal) || targetBearingCoordForGimbal.latitude ==0 || targetBearingCoordForGimbal.longitude ==0) {
                DVLog(@"targetBearingCoordForGimbal invalid");
                return;
            }
            
            gimbalTargetBearingEarth = [[Calc Instance] headingTo:targetBearingCoordForGimbal fromPosition:_FCcurrentState.aircraftLocation];
            gimbalTargetBearingInDroneBC = [[Calc Instance] closestDiffAngle:gimbalTargetBearingEarth toAngle:droneCurrentYawEarth];
            
            distanceToGimbalTarget = [[Calc Instance] distanceFromCoords2D:currentDroneCoordinate toCoords2D:targetBearingCoordForGimbal];
            //            gimbalPitchToTargetOnTheGround = -atanf(altitude/(distanceToGimbalTarget+1.5))*180/M_PI;
            gimbalPitchToTargetOnTheGround = -atanf(altitude/(distanceToGimbalTarget))*180/M_PI;
            
            break;
        case 2: // towards drone yaw
            //            gimbalTargetBearingInDroneBC = 0;
            //            gimbalPitchToTargetOnTheGround = -10;
            break;
            
        default:
            break;
            
    }
    
    // find the nearest angle330 not to have a lot of rotation ... ugly
    float angle330_0 = bindBetween([[Calc Instance] angle330OfAngle:gimbalTargetBearingInDroneBC withZone:0],-180,180);
    float angle330_1 = bindBetween([[Calc Instance] angle330OfAngle:gimbalTargetBearingInDroneBC withZone:1],180,330);
    float angle330_m1 = bindBetween([[Calc Instance] angle330OfAngle:gimbalTargetBearingInDroneBC withZone:-1],-330,-180);
    
    float diff0 = fabsf(angle330_0 - gimbalCurrent330Yaw);
    float diff1 = fabsf(angle330_1 - gimbalCurrent330Yaw);
    float diffm1 = fabsf(angle330_m1 - gimbalCurrent330Yaw);
    
    float minDiff = MIN(MIN(diff0, diff1), diffm1) ;
    
    if (minDiff == diffm1) {
        gimbalTarget330Yaw = angle330_m1;
    }
    else if (minDiff == diff1)
    {
        gimbalTarget330Yaw = angle330_1;
    }
    else
    {
        gimbalTarget330Yaw = angle330_0;
    }
    
    
    
    [self gimbalGoToAbsolutePitch:gimbalPitchToTargetOnTheGround andRoll:0 andYaw:gimbalTarget330Yaw];
    
}


#pragma mark - unused

-(void) enterVirtualStickControlMode{
    DJIFlightController* fc = [ComponentHelper fetchFlightController];
    if (fc) {
        fc.yawControlMode = DJIVirtualStickYawControlModeAngularVelocity;
        fc.rollPitchControlMode = DJIVirtualStickRollPitchControlModeVelocity;
        fc.verticalControlMode = DJIVirtualStickVerticalControlModeVelocity;
        
        [fc enableVirtualStickControlModeWithCompletion:^(NSError *error) {
            if (error) {
//                ShowResult(@"Enter Virtual Stick Mode:%@", error.description);
            }
            else
            {
                ShowResult(@"Enter Virtual Stick Mode:Succeeded");
            }
        }];
    }
    else
    {
        ShowResult(@"Component not exist.");
    }
}
-(void) exitVirtualStickControlMode{
    DJIFlightController* fc = [ComponentHelper fetchFlightController];
    if (fc) {
        
        [fc disableVirtualStickControlModeWithCompletion:^(NSError *error) {
            if (error) {
                ShowResult(@"Enter Virtual Stick Mode:%@", error.debugDescription);
            }
            else
            {
                ShowResult(@"Enter Virtual Stick Mode:Succeeded");
            }
        }];
    }
    else
    {
        ShowResult(@"Component not exist.");
    }
}
-(NSString*) stringFromFlightcontrollerState:(DJIFlightController*) fc{
    
    NSString* yawMode = (fc.yawControlMode == DJIVirtualStickYawControlModeAngle)? @"yAngle":@"ySpeed";
    NSString* vertMode = (fc.verticalControlMode == DJIVirtualStickVerticalControlModePosition)? @"vPosition":@"verticalVelocity";
    NSString* rpMode = (fc.rollPitchControlMode == DJIVirtualStickYawControlModeAngle)? @"rpAngle":@"rpSpeed";
    NSString* coordMode = (fc.rollPitchCoordinateSystem == DJIVirtualStickFlightCoordinateSystemGround)? @"ground":@"body";
    
    return [NSString stringWithFormat:@"yaw , %@ , alt , %@ , rp , %@ ,coord , %@ , %d",yawMode,vertMode,rpMode,coordMode,fc.isVirtualStickControlModeAvailable];
}
@end
