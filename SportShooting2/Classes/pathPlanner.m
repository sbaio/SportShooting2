//
//  pathPlanner.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/16/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//
#define bindBetween(a,b,c) ((a > c) ? c: ((a<b)? b:a))
#define RADIAN(x) ((x)*M_PI/180.0)
#define sign(a) ( ( (a) < 0 )  ?  -1   : ( (a) > 0 ) )
#define DV_FLOATING_WINDOW_ENABLE 1

#import "pathPlanner.h"

@implementation pathPlanner

-(id) init{
    self = [super init];
    
    [[DJIMissionManager sharedInstance] setDelegate:self];
    
    mapView = [[Menu instance] getMapView];
    mapVC = [[Menu instance] getMapVC];
    
    yellowColorString = @"RGB 212 175 55";
    redColorString = @"RGB 222 22 22";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRCSwitchChangedNotif:) name:@"RCSwitchStateChanged" object:nil];
    
    return self;
}


#pragma mark - method 1 of path planning

-(void) follow:(CLLocation*) carLoc onCircuit:(Circuit*) circ drone:(Drone*) drone{

    carLocation = carLoc;
    circuit = circ;
    _drone = drone;
    
    _carIndexOnCircuit = [self carIndexOnCircuit:circ forCarLoc:carLoc];
    
    [_drone calculateDroneInfoOnCircuit:circ forCarLocation:carLoc carIndex:_carIndexOnCircuit calcIndex:YES];
    [mapView movePinNamed:@"droneIndexLoc" toCoord:_drone.droneIndexLocation andColor:@"RGB 0 255 0"];
    
    
    [self updatePredictedDrone:_drone];
   
    
    [self setCloseTrackingOrShortcutting:carLoc drone:_drone onCircuit:circ];

//    _drone.isCloseTracking = YES;
    if (_drone.isCloseTracking) {
        [self performCloseTracking];
    }
    else{
        [self performShortcutting];
    }
}

-(void) updatePredictedDrone:(Drone*) drone{

    CLLocation* predictLoc = [[Calc Instance] locationFrom:drone.droneLoc atDistance:drone.droneLoc.speed*1.5 atBearing:drone.droneLoc.course];
    
    CLLocation* dronePredictedLocation = [[CLLocation alloc] initWithCoordinate:predictLoc.coordinate altitude:drone.droneLoc.altitude horizontalAccuracy:0 verticalAccuracy:0 course:drone.droneLoc.course speed:drone.droneLoc.speed timestamp:drone.droneLoc.timestamp];
    
    if (!_predictedDrone) {
        _predictedDrone = [[Drone alloc] initWithLocation:dronePredictedLocation];
    }
    else{
        [_predictedDrone updateDroneStateWithLoc:dronePredictedLocation andYaw:dronePredictedLocation.course];
    }
    
    _predictedDrone.droneIndexOnCircuit = drone.droneIndexOnCircuit;
    
    [_predictedDrone calculateDroneInfoOnCircuit:circuit forCarLocation:carLocation carIndex:_carIndexOnCircuit calcIndex:NO];
    
    [mapView movePinNamed:@"dronePredictedLoc" toCoord:dronePredictedLocation andColor:@"RGB 129 22 89"];
    [mapView updateDroneSensCircuit_PerpAnnotations:_predictedDrone];
}


-(void) performCloseTracking{
    
    //  close tracking should be independent from drone index info (because very non continuous) !!  but more dependent on drone-car distance and bearing  through a PID controller that will decide the target bearing and target speed in coordinance with the turns found in the circuit
    
    
    NSMutableArray* carIndexDistances = circuit.interIndexesDistance[_carIndexOnCircuit];
    
    
    NSArray* sortedByNext = [circuit.turnLocs sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSUInteger index1 = [circuit.locations indexOfObject:obj1];
        NSUInteger index2 = [circuit.locations indexOfObject:obj2];
        float dist1 = [[carIndexDistances objectAtIndex:index1] floatValue]-carLocation.speed*2;
        float dist2 = [[carIndexDistances objectAtIndex:index2] floatValue]-carLocation.speed*2;
        
        if (dist1*dist2 >= 0) {
            
            if (fabsf(dist1) > fabsf(dist2)) {
                return NSOrderedDescending;
            }
            else if(fabsf(dist1) < fabsf(dist2)){
                return NSOrderedAscending;
            }
            else{
                return NSOrderedSame;
            }
            
        }
        else{
            if (dist1 > dist2) {
                return NSOrderedAscending;
            }
            else if (dist1 < dist2){
                return  NSOrderedDescending;
            }
            else{
                return NSOrderedSame;
            }
        }
    }];
    
    CLLocation* nextCenter = [circuit.turnCenters objectAtIndex:[circuit.turnLocs indexOfObject:sortedByNext[0]]];
    
    [mapView movePinNamed:@"nextCenter" toCoord:nextCenter andColor:@"RGB 17 170 184"];
    Vec* index_center = [[Vec alloc] initWithNorm:1 andAngle:[[Calc Instance] headingTo:nextCenter.coordinate fromPosition:_predictedDrone.droneIndexLocation.coordinate]];
    if ([_predictedDrone.versCircuit dotProduct:index_center]>=0) {
        _predictedDrone.sensNextCenter = _predictedDrone.versCircuit;
    }
    else{
        _predictedDrone.sensNextCenter = [[Vec alloc] initWithNorm:-1 andAngle:_predictedDrone.versCircuit.angle];
    }
    
    CLLocation* locFrontCar = [[Calc Instance] locationFrom:carLocation atDistance:30 atBearing:[[Calc Instance] headingTo:nextCenter.coordinate fromPosition:carLocation.coordinate]];
    Vec* car_LocFront = [[Vec alloc] initWithNorm:[[Calc Instance] distanceFromCoords2D:carLocation.coordinate toCoords2D:locFrontCar.coordinate] andAngle:[[Calc Instance] headingTo:locFrontCar.coordinate fromPosition:carLocation.coordinate]];
    float dist = [_predictedDrone.sensNextCenter dotProduct:car_LocFront];
    
    CLLocation* locBis = [[Calc Instance] locationFrom:_predictedDrone.droneIndexLocation atDistance:dist atBearing:_predictedDrone.sensNextCenter.angle];
    
    [mapView movePinNamed:@"locBis" toCoord:locBis andColor:@"RGB 20 199 230"];
    

    Vec* locBis_predDrone = [[Vec alloc] initWithNorm:[[Calc Instance]distanceFromCoords2D:locBis.coordinate toCoords2D:_predictedDrone.droneLoc.coordinate] andAngle:[[Calc Instance]headingTo:_predictedDrone.droneLoc.coordinate fromPosition:locBis.coordinate]];
    
    float distErrorToCirc = [locBis_predDrone dotProduct:_predictedDrone.sensNextCenter];
    
    Vec* perpSpeed_pred = [[Vec alloc] initWithNorm:[_predictedDrone.droneSpeed_Vec dotProduct:_predictedDrone.sensNextCenter] andAngle:_predictedDrone.sensNextCenter.angle];
    
    float derivError = 0;
    if ([perpSpeed_pred dotProduct:locBis_predDrone] >= 0) {
        derivError = perpSpeed_pred.norm; // s'eloigne
    }
    else{
        derivError = -perpSpeed_pred.norm;// se rapproche
    }
    // if drone should strictly follow the circuit locations then choose

    [mapView movePinNamed:@"predictedindex" toCoord:_predictedDrone.droneIndexLocation andColor:@"RGB 216 179 19"];
    
    integralDistError += distErrorToCirc;
    
    if (fabsf(distErrorToCirc) <= 5) {
        integralDistError = 0;
    }
    integralDistError = bindBetween(integralDistError, -100, 100);
    
    // Kp = 0.33 ; Ki = 0.11 , Kd = 0.15 ...
    float targ_V_perp = -0.4* distErrorToCirc + 0.11*derivError - 0.15*integralDistError;
    
    targ_V_perp = bindBetween(targ_V_perp, -16, 16);
    
//    NSLog(@"targV_perp --> %0.3f , prop -->%0.3f , deriv --> %0.3f ,integral --> %0.3f",targ_V_perp,_Kp*distErrorToCirc,-_Kd*_predictedDrone.V_perp ,_Ki*integralDistError);
   

    [mapView movePinNamed:@"targPosition" toCoord:locFrontCar andColor:@"RGB 239 28 29"];
    Vec* drone_carFrontLoc = [[Vec alloc] initWithNorm:[[Calc Instance] distanceFromCoords2D:_predictedDrone.droneLoc.coordinate toCoords2D:locFrontCar.coordinate] andAngle:[[Calc Instance] headingTo:locFrontCar.coordinate fromPosition:_predictedDrone.droneLoc.coordinate]];
    
    float diffPosition = [drone_carFrontLoc dotProduct:_predictedDrone.sensCircuit]; // positif lorsque la voiture en avance
    float diffSpeed = [_predictedDrone.carSpeed_Vec dotProduct:_predictedDrone.sensCircuit] - [_predictedDrone.droneSpeed_Vec dotProduct:_predictedDrone.sensCircuit]; // positif si voiture plus rapide que le drone
    
    if (fabsf(diffPosition)< 5) {
//        integralDistErrorSensCircuit = 0;
    }
    else{
        integralDistErrorSensCircuit+= diffPosition;
    }
    
    float targ_V_para = _Kp*diffPosition + _Kd*diffSpeed + _Ki*integralDistErrorSensCircuit;
    
//    NSLog(@"diffPosition , %0.3f,diffSpeed , %0.3f", diffPosition,diffSpeed);
//    NSLog(@"targV_para , %0.3f , prop , %0.3f , der  , %0.3f ",targ_V_para , _Kp*diffPosition,_Kd*diffSpeed);
    
    float diffSp = _drone.carSpeed_Vec.norm - _drone.V_parralele;
    float totalDist = _drone.distanceOnCircuitToCar-20*(1+diffSp/10);
    
    float speedFromDist = -16*sign(totalDist)*(1-expf(-fabsf(totalDist)/25));
    float targ_V_Parallel = speedFromDist + _drone.carSpeed_Vec.norm;
    
    // --> chgmt
    targ_V_Parallel = targ_V_para;
    
    targ_V_Parallel = bindBetween(targ_V_Parallel, -sqrt(256-targ_V_perp*targ_V_perp), sqrt(256-targ_V_perp*targ_V_perp));
    
    
    Vec* V_parallele_Vec = [[Vec alloc] initWithNorm:targ_V_Parallel andAngle:_predictedDrone.sensCircuit.angle];
    Vec* V_Perp_Vec = [[Vec alloc] initWithNorm:targ_V_perp andAngle:_predictedDrone.sensNextCenter.angle];
    Vec* targetDroneSpeed_Vec = [V_parallele_Vec addVector:V_Perp_Vec];
    
    _drone.targSp = targetDroneSpeed_Vec.norm;
    _drone.targHeading = targetDroneSpeed_Vec.angle;
}

-(void) performShortcutting{
    
    _drone.targSp = 16;
    _drone.targHeading = _drone.droneCar_Vec.angle;
    CLLocation* target = [self shortcuttingPhase:carLocation drone:_drone onCircuit:circuit];
    
    if (target) {
        float dist = [[Calc Instance] distanceFromCoords2D:_drone.droneLoc.coordinate toCoords2D:target.coordinate];
        float bearing = [[Calc Instance] headingTo:target.coordinate fromPosition:_drone.droneLoc.coordinate];
        
        
        _drone.targHeading = bearing;
        _drone.targSp = 16*(1-expf(-dist/16));
        
        
        [mapView movePinNamed:@"shortcuttingPin" toCoord:target andColor:yellowColorString];
    }
}

-(CLLocation*) shortcuttingPhase:(CLLocation*) carLoc drone:(Drone*) drone onCircuit:(Circuit*) circ{
    CLLocation* target = nil;
    
    // WHEN SHORTCUTTING MAX ALT
    
    // FIND TARGET SPEED AND BEARING
    
    for (int i=0; i< circ.locations.count; i++) { // OUTPUTS target loc
        
        CLLocation* loci = [circ locationAtIndex:(_carIndexOnCircuit+i+1)];
        float carDistanceToLoci = [circ distanceOnCircuitfromIndex:_carIndexOnCircuit toIndex:(_carIndexOnCircuit+i+1)];
        
        float carTimeToReachLoci = carDistanceToLoci/(carLoc.speed+0.5);
        
        
        Vec* droneToLoci = [drone.drone_Loc0_Vec addVector:circ.Loc0_Loci_Vecs[i]];
        
        float droneTimeToReachLoci = [drone timeForDroneToReachLoc:loci andTargetSpeed:0];
        
        
        
        if (carTimeToReachLoci < droneTimeToReachLoci) {
            continue;
        }
        else{
            if (droneTimeToReachLoci +1.5 < carTimeToReachLoci ) { // drone arrives very early .. then there to go
                target = loci;

                if (droneTimeToReachLoci < 2) {
                    //                    isShortcutting = NO;
                    //                    isCloseTracking = YES;
//                    NSLog(@"droneTime , %0.3f",droneTimeToReachLoci);
//                    NSLog(@"close Tracking .. target almost reached");
                }
                
    
                
                
                break;
            }
            else{
                continue;
            }
        }
    }
    
    
    return target;
}


-(void) setDrone:(Drone*) drone TargetSpeedAndTargetBearingwithTargetLoc:(CLLocation*) target {
    float dist = [[Calc Instance] distanceFromCoords2D:drone.droneLoc.coordinate toCoords2D:target.coordinate];
    float bearing = [[Calc Instance] headingTo:target.coordinate fromPosition:drone.droneLoc.coordinate];
    
    drone.targSp = 16*(1-expf(-dist/16));
    drone.targHeading = bearing;
}


#pragma mark - method 2 of path planning

-(void) follow2:(CLLocation*) carLoc onCircuit:(Circuit*) circ drone:(Drone*) drone{
    
    {
        lastFollowDate = [NSDate new];
        _status.isRunning = YES;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (-[lastFollowDate timeIntervalSinceNow]> 0.2) {
                if (_status.isRunning) {
                    DVLog(@"path planner stopped");
                    _status.isRunning = NO;
                }
            }
        });
    }
    
    carLocation = carLoc;
    circuit = circ;
    _drone = drone;
    
    _carIndexOnCircuit = [self carIndexOnCircuit:circ forCarLoc:carLoc];
    
    [_drone calculateDroneInfoOnCircuit:circ forCarLocation:carLoc carIndex:_carIndexOnCircuit calcIndex:YES];
    
    [mapView movePinNamed:@"droneIndexLoc" toCoord:_drone.droneIndexLocation andColor:@"RGB 0 255 0"];
    
    [self updatePredictedDrone:_drone];
    
    
    [self setCloseTrackingOrShortcutting:carLoc drone:drone onCircuit:circ];

 
    if (_drone.isCloseTracking) {
        // clean after shortcutting phase
        [mapVC.topMenu setStatusLabelText:@"Close tracking"];
        [mapView removePinsNamed:@"shortcuttingPin"];
        [self radialCloseTracking:carLoc onCircuit:circ drone:drone];
    }
    else{
        [mapVC.topMenu setStatusLabelText:@"Shortcutting"];
        [mapView removePinsNamed:@"nextCenter"]; // should be cleaned  differently
        [self performShortcutting];
    }
    
}

-(void) radialCloseTracking:(CLLocation*) carLoc onCircuit:(Circuit*) circ drone:(Drone*) drone{
    
    // determine the suitable turn center

    NSMutableArray* carIndexDistances = circ.interIndexesDistance[_carIndexOnCircuit];
    
    
    NSArray* sortedByNext = [circ.turnLocs sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSUInteger index1 = [circ.locations indexOfObject:obj1];
        NSUInteger index2 = [circ.locations indexOfObject:obj2];
        float dist1 = [[carIndexDistances objectAtIndex:index1] floatValue]-carLoc.speed*2;
        float dist2 = [[carIndexDistances objectAtIndex:index2] floatValue]-carLoc.speed*2;
        
        if (dist1*dist2 >= 0) {
            
            if (fabsf(dist1) > fabsf(dist2)) {
                return NSOrderedDescending;
            }
            else if(fabsf(dist1) < fabsf(dist2)){
                return NSOrderedAscending;
            }
            else{
                return NSOrderedSame;
            }
            
        }
        else{
            if (dist1 > dist2) {
                return NSOrderedAscending;
            }
            else if (dist1 < dist2){
                return  NSOrderedDescending;
            }
            else{
                return NSOrderedSame;
            }
        }
    }];
    
    CLLocation* nextCenter = [circ.turnCenters objectAtIndex:[circ.turnLocs indexOfObject:sortedByNext[0]]];
    
    [mapView movePinNamed:@"nextCenter" toCoord:nextCenter andColor:@"RGB 17 170 184"];
    

    float car_NextCenterBearing = [[Calc Instance] headingTo:nextCenter.coordinate fromPosition:carLoc.coordinate];
    float car_DroneBearing = [[Calc Instance] headingTo:drone.droneLoc.coordinate fromPosition:carLoc.coordinate];
    float diffBearing = [[Calc Instance] closestDiffAngle:car_NextCenterBearing toAngle:car_DroneBearing];
    
//    if (fabsf(diffBearing) > 90) {
//        CLLocation* targetLoc = [[Calc Instance] locationFrom:carLoc atDistance:20 atBearing:car_NextCenterBearing];
//        
//        [self setDrone:drone TargetSpeedAndTargetBearingwithTargetLoc:targetLoc];
//    }
//    else{

        if ((drone.distanceToCar < 20.5 && drone.distanceToCar > 20) || drone.distanceToCar ==0) {
            integralError = 0;
        }
        float distOnCircCarNextCenter = [[carIndexDistances objectAtIndex:[circ.locations indexOfObject: sortedByNext[0]]] floatValue];
        float timeForCarToReachNextCenterLoc = distOnCircCarNextCenter/(carLoc.speed+0.1);
        
        float angularSpeed = diffBearing/timeForCarToReachNextCenterLoc;
        float orthoSpeed = 0;//angularSpeed*drone.distanceToCar;
        
        
        float error =  -(drone.distanceToCar - 20);
        
        derivativeError = error - previousError;
        integralError += error;
        integralError = bindBetween(integralError, 0, 1000);
        
        previousError = error;
        Vec* radialVec = [[Vec alloc] initWithNorm:1 andAngle:car_DroneBearing];
        Vec* orthoRadialVec = [[Vec alloc] initWithNorm:1 andAngle:[[Calc Instance] angle180Of330Angle:(car_DroneBearing+90)]];

        float currentRadialSpeed = [drone.droneSpeed_Vec dotProduct:radialVec];
        float currentOrthoRadialSpeed = [drone.droneSpeed_Vec dotProduct:orthoRadialVec];
        
        
        float targetRadialSpeed =  _Kp*error +_Kd*derivativeError + _Ki*integralError ;//+ 0.005*integralError ;//+10*derivativeError;
//        NSLog(@"error , %0.3f , integral , %0.3f , deriv , %0.3f , target , %0.3f",error,integralError,derivativeError,targetRadialSpeed);
        targetRadialSpeed = bindBetween(targetRadialSpeed, -16, 16);
        float limit = sqrtf(16*16 - targetRadialSpeed*targetRadialSpeed);
        orthoSpeed = bindBetween(orthoSpeed, -limit, limit);
        
//        NSLog(@"targ , %0.3f , cur , %0.3f ,  error, %0.3f , derErrc , %0.3f",targetRadialSpeed,currentRadialSpeed,error,5*derivativeError);
        
        orthoSpeed_Vec = [[Vec alloc] initWithNorm:orthoSpeed andAngle:orthoRadialVec.angle];
        radialSpeed_Vec = [[Vec alloc] initWithNorm:targetRadialSpeed andAngle:radialVec.angle];
        
        Vec* targSpeed_Vec = [orthoSpeed_Vec addVector:radialSpeed_Vec];
        
        drone.targSp = targSpeed_Vec.norm;
        drone.targHeading = targSpeed_Vec.angle;
        
        
        if (!orthoVec_Anno) {
            orthoVec_Anno = [[Aircraft_Camera_Car_Annotation alloc] initWithCoordiante:drone.droneLoc.coordinate andType:8];
        }
        else{
            [orthoVec_Anno updateHeading:RADIAN(orthoSpeed_Vec.angle) andScale:orthoSpeed_Vec.norm/16];
            [orthoVec_Anno setCoordinate:drone.droneLoc.coordinate];
            [mapView addAnnotation:orthoVec_Anno];
        }
        
        if (!radialVec_Anno) {
            radialVec_Anno = [[Aircraft_Camera_Car_Annotation alloc] initWithCoordiante:drone.droneLoc.coordinate andType:8];
        }
        else{
            [radialVec_Anno updateHeading:RADIAN(radialSpeed_Vec.angle) andScale:radialSpeed_Vec.norm/16];
            [radialVec_Anno setCoordinate:drone.droneLoc.coordinate];
            [mapView addAnnotation:radialVec_Anno];
        }
        
//        CLLocation* targetLoc = [[Calc Instance] locationFrom:carLoc atDistance:20 atBearing:car_NextCenterBearing];
//        
//        [self setDrone:drone TargetSpeedAndTargetBearingwithTargetLoc:targetLoc];
//    }
    
    
    
    
//    NSLog(@"orthoSpeed , %0.3f , diffBearing , %0.3f , time , %0.3f",orthoSpeed,diffBearing,timeForCarToReachNextCenterLoc);
    
    
}

-(void) aubevoyeCloseTracking:(CLLocation*) carLoc onCircuit:(Circuit*) circ drone:(Drone*) drone{
    
    float targ_V_perp = _predictedDrone.droneDistToItsIndex/2;
    
    targ_V_perp = bindBetween(targ_V_perp, 0, 16); // doit être continue
    
    float diffSp = drone.carSpeed_Vec.norm - drone.V_parralele;
    float totalDist = drone.distanceOnCircuitToCar-20*(1+diffSp/10);
    
    float speedFromDist = -16*sign(totalDist)*(1-expf(-fabsf(totalDist)/25));
    float targ_V_Parallel = speedFromDist + drone.carSpeed_Vec.norm;
    
    
    targ_V_Parallel = bindBetween(targ_V_Parallel, -sqrt(256-targ_V_perp*targ_V_perp), sqrt(256-targ_V_perp*targ_V_perp));
    
    
    Vec* V_parallele_Vec = [[Vec alloc] initWithNorm:targ_V_Parallel andAngle:drone.sensCircuit.angle];
    Vec* V_Perp_Vec = [[Vec alloc] initWithNorm:targ_V_perp andAngle:drone.versCircuit.angle];
    Vec* targetDroneSpeed_Vec = [V_parallele_Vec addVector:V_Perp_Vec];
    
    drone.targSp = targetDroneSpeed_Vec.norm;
    drone.targHeading = targetDroneSpeed_Vec.angle;
}

#pragma mark - help methods

-(int) carIndexOnCircuit:(Circuit*) circ forCarLoc:(CLLocation*) carLoc{
    int carIndex = 0;
    
    // sort with distance
    NSArray* sortedWithDistance = [circ.locations sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
        CLLocation* loc1 = (CLLocation*)obj1;
        CLLocation* loc2 = (CLLocation*)obj2;
        
        float dist1 = [[Calc Instance] distanceFromCoords2D:carLoc.coordinate toCoords2D:loc1.coordinate];
        float dist2 = [[Calc Instance] distanceFromCoords2D:carLoc.coordinate toCoords2D:loc2.coordinate];
        
        if (dist1 < dist2) {
            return NSOrderedAscending;
        } else if (dist1 > dist2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    float carCourse = carLoc.course;
    
    CLLocation* loci = sortedWithDistance[0];
    int index = (int)[circ.locations indexOfObject:loci];
    
    
    carIndex = index;
    
    // search in the closest locations which one has the same course ...
    for (int i = 0 ; i < sortedWithDistance.count; i++) {
        
        CLLocation* loci = sortedWithDistance[i];
        int index = (int)[circ.locations indexOfObject:loci];
        
        
        float dist = [[Calc Instance] distanceFromCoords2D:carLoc.coordinate toCoords2D:loci.coordinate];
        
        if (dist < 50) {
            
            Vec* courseVec = [[Vec alloc] initWithNorm:1 andAngle:carCourse];
            Vec* sensCircuitVec = [[Vec alloc] initWithNorm:1 andAngle:[circ.interAngle[index] floatValue]];
            float dot = [sensCircuitVec dotProduct:courseVec];
            
            if (dot > 0.9) {
                
                carIndex = index;
                break;
            }
            else {
                continue;
            }
        }
        else{
            break;
        }
    }
    
    // DISPLAY
    CLLocation* loc = circ.locations[carIndex];
//    [mapView movePinNamed:@"carIndex" toCoord:loc andColor:redColorString];
    
    return carIndex;
}

-(void) setCloseTrackingOrShortcutting:(CLLocation*) carLoc drone:(Drone*) drone onCircuit:(Circuit*) circ{
    if (carLoc.speed == 0) {
        if (!_status.carStopped) {
            DVLog(@"carStopped");
            // launch sequence to go in front of the car !!!
        }
        _status.carStopped = YES;
        _status.carIsComing = NO;
        
        if (_drone.distanceToCar < 20) { // should enter close tracking differently
            _drone.isCloseTracking = YES;
        }
    }
    else{
        _status.carStopped = NO;
        if (_drone.distanceOnCircuitToCar > carLoc.speed*2 && _drone.distanceOnCircuitToCar/carLoc.speed < 15 && _drone.droneDistToItsIndex < 100) {
            lastCarIsComingNotifDate = [NSDate new];
            if (!_status.carIsComing && !_drone.isCloseTracking){// && !_status.isDroneCloseTracking) {
                
                if (_status.isDroneCloseToItsIndex) {
                    // switch to close tracking
                    DVLog(@"car is coming : YES--> closeTracking");
                    _drone.isCloseTracking = YES;
                }
                else{
                    DVLog(@"car is coming : YES --> drone far from index");
                }
                _status.carIsComing = YES;
                _status.carLeft = NO;
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (_status.isRunning) {
                    
                    if ((-[lastCarIsComingNotifDate timeIntervalSinceNow] >0.3) && _status.carIsComing) {
                        DVLog(@"car is coming : NO");
                        _status.carIsComing = NO;
                    }
                }
            });
        }
        
        // CAR LEFT
        if (_drone.distanceOnCircuitToCar > -75 && _drone.distanceOnCircuitToCar < 35) {
            // en fct de la vitesse de la voiture dire si la voiture est partie...
            float droneSpeedSensCircuit = [drone.droneSpeed_Vec dotProduct:drone.sensCircuit];
            
            float diffSp = drone.carSpeed_Vec.norm - droneSpeedSensCircuit;
            
            if (diffSp > 0.5*drone.distanceOnCircuitToCar +20) {
                lastCarHasLeftNotifDate = [NSDate new];
                if (!_status.carLeft && _drone.isCloseTracking) {
                    DVLog(@"car left : YES --> shortcutting");
                    _status.carLeft = YES;
                    _status.carIsComing = NO;
                    _drone.isCloseTracking = NO;
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (_status.isRunning) {
                        if ((-[lastCarHasLeftNotifDate timeIntervalSinceNow] >0.3) && _status.carLeft) {
                            _status.carLeft = NO;
                        }
                    }
                    
                });
            }
            
            else if (_drone.distanceOnCircuitToCar < 0 && _drone.distanceOnCircuitToCar > -40 ){
                
                // can be done with time to shortcutting location !!!!
                if (diffSp < 2) {
                    lastCatchingCarNotifDate = [NSDate new];
                    if (!_status.catchingCar && !_drone.isCloseTracking) {
                        _status.catchingCar = YES;
                        _drone.isCloseTracking = YES;
                        _status.carLeft = NO;
                        DVLog(@"catching car");
                    }
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (_status.isRunning) {
                            if ((-[lastCatchingCarNotifDate timeIntervalSinceNow] >0.3) && _status.catchingCar) {
                                _status.catchingCar = NO;
                            }
                        }
                        
                    });
                    
                }
            }
        }
        
    }
    
    
    if (_drone.droneDistToItsIndex > 50) { // sets max eloignement lors du close tracking
        if (_status.isDroneCloseToItsIndex && _drone.isCloseTracking) {
            DVLog(@"drone far from its index --> shotcutting");
            _drone.isCloseTracking = NO;
        }
        _status.isDroneCloseToItsIndex = NO;
        
    }
    else if(_drone.droneDistToItsIndex < 40){
        _status.isDroneCloseToItsIndex = YES;
        
        if (_status.carIsComing) {
            if (!_drone.isCloseTracking) {
                _drone.isCloseTracking = YES;
                DVLog(@"drone close to its index, car is coming --> close tracking");
            }
            
            
        }
    }
    
    
    if (_drone.isCloseTracking) {
        // clean after shortcutting phase
        [mapVC.topMenu setStatusLabelText:@"Close tracking"];
        [mapView removePinsNamed:@"shortcuttingPin"];
    }
    else{
        [mapVC.topMenu setStatusLabelText:@"Shortcutting"];
        [mapView removePinsNamed:@"nextCenter"]; // should be cleaned  differently
    }
}
#pragma mark - RC hardware update 

-(void) onRCSwitchChangedNotif:(NSNotification*) notif{
    if ([notif.name isEqualToString:@"RCSwitchStateChanged"]) {
        if ([[Menu instance] getAppDelegate].isRCSwitch_F) {
            // prepare follow me mission possible
            [self prepareFollowMeMission];
        }
    }
}

-(void) prepareFollowMeMission{
    DVLog(@"prepare for follow me mission");
    
    if (!_followMeMission) {
        _followMeMission = [[DJIFollowMeMission alloc] init];
    }
    if (![[[Menu instance] getAppDelegate] isReceivingFlightControllerStatus]) {
        DVLog(@"not receiving flight controller status");
    }
    else{
        _followMeMission.followMeCoordinate = mapVC.realDrone.droneLoc.coordinate;
        _followMeMission.followMeAltitude = 12;
        _followMeMission.heading = DJIFollowMeHeadingTowardFollowPosition;
        DVLog(@"here");
    }
    
    
    
    [[DJIMissionManager sharedInstance] prepareMission:_followMeMission withProgress:^(float progress) {
        
    } withCompletion:^(NSError * _Nullable error) {
        if (error) {
            DVLog(@"error preparing mission : %@",error.localizedDescription);
        }
        else{
            [[DJIMissionManager sharedInstance] startMissionExecutionWithCompletion:^(NSError * _Nullable error) {
                if (error) {
                    DVLog(@"ERROR: startMissionExecutionWithCompletion:. %@", error.description);
                }
                else {
                    DVLog(@"SUCCESS: startMissionExecutionWithCompletion:. ");
                }
            }];
        }
    }];
}
@end
