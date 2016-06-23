//
//  Drone.m
//  SportShooting2
//
//  Created by Othman Sbai on 5/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#define DEGREE(x) ((x)*180.0/M_PI)
#define RADIAN(x) ((x)*M_PI/180.0)

#define bindBetween(a,b,c) ((a > c) ? c: ((a<b)? b:a))

#import "Drone.h"
#import "MapVC.h"


@implementation Drone

-(void) initWithDrone:(DJIAircraft*) realDrone{
    DVLog(@"setting real drone as drone");
    
}

-(id) initWithLocation:(CLLocation*) loc{
    
    self = [super init];
    
    self.droneLoc = loc;
    self.droneYaw = 0;

    freqCalcIndex = 0;
    
    return self;
}

-(void) updateDroneStateWithLoc:(CLLocation*) droneLoc andYaw:(float) yaw{
    self.droneLoc = droneLoc;
    self.droneYaw = yaw;
    // droneAnno
    [self.droneAnno setCoordinate:droneLoc.coordinate];
    [self.droneAnno.annotationView updateHeading:RADIAN(yaw)];
    // droneSpeedAnno
    [self.droneSpeed_vecAnno setCoordinate:droneLoc.coordinate];
    [self.droneSpeed_vecAnno.annotationView updateHeading:RADIAN(droneLoc.course) andScale:droneLoc.speed/17.0];
}

-(void) setDroneIndex:(Circuit*) circuit forCarLocation:(CLLocation*) carLoc carIndex:(int) carIndex{
    
    NSMutableArray* distToDroneArray = [[NSMutableArray alloc]init];
    NSMutableArray* distOnCircToCar = [[NSMutableArray alloc] init];
    NSMutableArray* startIndexArray = circuit.interIndexesDistance[carIndex];
    
    for (CLLocation* loc in circuit.locations) {
        float distDr = [[Calc Instance] distanceFromCoords2D:self.droneLoc.coordinate toCoords2D:loc.coordinate];
        
        [distToDroneArray addObject:[NSNumber numberWithFloat:distDr]];
        
        float distCar = [[startIndexArray objectAtIndex:[circuit.locations indexOfObject:loc]] floatValue];
        
        [distOnCircToCar addObject:[NSNumber numberWithFloat:distCar]];
    }
    
    NSArray* sortedWithDistanceToDrone = [circuit.locations sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
        NSUInteger index1 = [circuit.locations indexOfObject:obj1];
        NSUInteger index2 = [circuit.locations indexOfObject:obj2];
        
        float distLoc1ToDrone = [distToDroneArray[index1] floatValue];
        float distLoc2ToDrone = [distToDroneArray[index2] floatValue];
        
        if (distLoc1ToDrone < distLoc2ToDrone) {
            return NSOrderedAscending;
        }
        else if (distLoc1ToDrone > distLoc2ToDrone){
            return NSOrderedDescending;
        }
        else{
            return NSOrderedSame;
        }
    }];
    
    NSMutableArray* indexes = [[NSMutableArray alloc] init];
    NSMutableArray* distances = [[NSMutableArray alloc] init];
    int min = 100;
    if (sortedWithDistanceToDrone.count<min) {
        min = (int)sortedWithDistanceToDrone.count;
    }
    for (int i = 0; i < 100; i++) {
        [indexes addObject:[NSNumber numberWithInt:(int)[circuit.locations indexOfObject:sortedWithDistanceToDrone[i]]]];
        
        [distances addObject:distToDroneArray[[circuit.locations indexOfObject:sortedWithDistanceToDrone[i]]]];
    }
    
    // RECUPERER les tetes de groupes
    NSMutableArray* teteDeGroupes = [[NSMutableArray alloc] init];
    
    [teteDeGroupes addObject:indexes[0]];
    
    for (int i = 0; i< indexes.count && teteDeGroupes.count < 2; i++) {
        BOOL fitsInAGroup = NO;
        for (int j=0; j< teteDeGroupes.count;j++) {
            int indexj = [[teteDeGroupes objectAtIndex:j] intValue];
            int indexi = [[indexes objectAtIndex:i] intValue];
            
            NSMutableArray* startj = circuit.interIndexesDistance[indexj];
            
            float dist = [[startj objectAtIndex:indexi] floatValue];
            if (fabsf(dist) < 150) {
                fitsInAGroup = YES;
            }
        }
        if (!fitsInAGroup ) {
            [teteDeGroupes addObject:indexes[i]];
        }
    }
    
    _arrayOfKeyLocations = [[NSMutableArray alloc] init];
    
    for (int i =0; i< teteDeGroupes.count; i++) {
        int indexi = [teteDeGroupes[i] intValue];
        CLLocation* loci = circuit.locations[indexi];
        
        [_arrayOfKeyLocations addObject:loci];
    }
    
    if (_arrayOfKeyLocations.count == 1) {
        // droneIndex is no doubt this value ...
        int index = [teteDeGroupes[0] intValue];
        CLLocation* loc0 = _arrayOfKeyLocations[0];
        float distDrone = [[Calc Instance] distanceFromCoords2D:loc0.coordinate toCoords2D:self.droneLoc.coordinate];
        
        self.droneIndexOnCircuit = index;
    }
    else if(_arrayOfKeyLocations.count == 2){
        CLLocation* lockey0 = _arrayOfKeyLocations[0];
        CLLocation* lockey1 = _arrayOfKeyLocations[1];
        float dist0 = [[Calc Instance] distanceFromCoords2D:self.droneLoc.coordinate toCoords2D:lockey0.coordinate];
        float dist1 = [[Calc Instance] distanceFromCoords2D:self.droneLoc.coordinate toCoords2D:lockey1.coordinate];
        float dist01 = [[Calc Instance] distanceFromCoords2D:lockey0.coordinate toCoords2D:lockey1.coordinate];
        
        
        if (dist0 == 0) {
            self.droneIndexOnCircuit = (int)[circuit.locations indexOfObject:lockey0];
        }
        else{
            float ratio = dist1/dist0;
            if (ratio > 2 || dist01 < dist1 || dist1 <10) {
                self.droneIndexOnCircuit = (int)[circuit.locations indexOfObject:lockey0];
            }
            else{

                NSArray* sortedWithDistOnCircuit = [teteDeGroupes sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
                    int index1 = [obj1 intValue];
                    int index2 = [obj2 intValue];
                    
                    
                    float dist1 = [[startIndexArray objectAtIndex:index1] floatValue];
                    float dist2 = [[startIndexArray objectAtIndex:index2] floatValue];
                    
                    CLLocation* loc1 = circuit.locations[index1];
                    CLLocation* loc2 = circuit.locations[index2];
                    float distDrone1 = [[Calc Instance] distanceFromCoords2D:self.droneLoc.coordinate toCoords2D:loc1.coordinate];
                    float distDrone2 = [[Calc Instance] distanceFromCoords2D:self.droneLoc.coordinate toCoords2D:loc2.coordinate];
                    
                    if (dist1*dist2 <= 0) {
                        float distance = 1000 + 20*carLoc.speed;
                        if (dist1 > 0) { // dist2 < 0
                            
                            if (dist1 < distance || dist2 < -150) {
                                return NSOrderedAscending;
                            }
                            else{
                                if (distDrone1 < distDrone2) {
                                    return NSOrderedAscending;
                                }else{
                                    return NSOrderedDescending;
                                }
                            }
                        }
                        else{ //dist1 < 0 dist2 positif
                            float distance = 1000 + 20*carLoc.speed;
                            if (dist2 < distance || dist1 < -150) {
                                return NSOrderedDescending;
                            }
                            else{
                                if (distDrone1 < distDrone2) {
                                    return NSOrderedDescending;
                                }else{
                                    return NSOrderedAscending;
                                }
                            }
                        }
                    }
                    else if (dist2 > 0){
                        if (dist1 < dist2) {
                            return NSOrderedAscending;
                        }
                        else{
                            return NSOrderedDescending;
                        }
                    }
                    else{ // les deux negatifs
                        if (dist2 < dist1) {
                            return NSOrderedAscending;
                        }
                        else{
                            return NSOrderedDescending;
                        }
                    }
                }];
                
                int index = 0;
                
                index = [sortedWithDistOnCircuit[0] intValue];
               
                self.droneIndexOnCircuit = index;
            }
        }
    }
    
    self.distanceOnCircuitToCar = [[startIndexArray objectAtIndex:self.droneIndexOnCircuit] floatValue];
    
}

-(void) calculateDroneInfoOnCircuit:(Circuit*) circuit forCarLocation:(CLLocation*) carLoc carIndex:(int) carIndex calcIndex:(BOOL) calc{
    // this method sets self.droneIndexOnCircuit,self.droneDistToItsIndex, self.distanceOnCircuitToCar
    // and also
    // self.carSpeed_Vec, self.droneSpeed_Vec, self.droneCar_Vec

    CLLocation* loc0 = circuit.locations[0];
    self.drone_Loc0_Vec = [[Vec alloc] initWithNorm:[[Calc Instance] distanceFromCoords2D:self.droneLoc.coordinate toCoords2D:loc0.coordinate] andAngle:[[Calc Instance] headingTo:loc0.coordinate fromPosition:self.droneLoc.coordinate]];
    
    freqCalcIndex++;
    if (freqCalcIndex%10 == 0 && calc) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self setDroneIndex:circuit forCarLocation:carLoc carIndex:carIndex];
        });
    }else{
        int maxIndex = 0;
        
        NSMutableArray* arrayOfIndexesDrone = [circuit.interIndexesDistance objectAtIndex:self.droneIndexOnCircuit];
        
        for (int i = 1; i< circuit.locations.count; i++) {
            NSUInteger indexip = (self.droneIndexOnCircuit+i)%circuit.locations.count;
            NSUInteger indexim = (self.droneIndexOnCircuit-i+circuit.locations.count)%circuit.locations.count;

            float distToLocip = [[arrayOfIndexesDrone objectAtIndex:indexip] floatValue];
            float distToLocim = [[arrayOfIndexesDrone objectAtIndex:indexim] floatValue];
            
            if (distToLocip > 20 && distToLocim <-20) {
                maxIndex = i;
                
                break;
            }
        }
        NSMutableArray* closeIndexLocs = [[NSMutableArray alloc] init];
        
        for ( int i = -maxIndex; i<maxIndex ; i++) {
                CLLocation* loci = [circuit.locations objectAtIndex:(self.droneIndexOnCircuit+circuit.locations.count+i)%circuit.locations.count];
                [closeIndexLocs addObject:loci];
        }
        
        NSArray* sortedWithDistToDrone = [closeIndexLocs sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            CLLocation* loc1 = (CLLocation*) obj1;
            CLLocation* loc2 = (CLLocation*) obj2;
            
            float dist1 = [[Calc Instance] distanceFromCoords2D: loc1.coordinate toCoords2D:self.droneLoc.coordinate];
            float dist2 = [[Calc Instance] distanceFromCoords2D: loc2.coordinate toCoords2D:self.droneLoc.coordinate];
            if (dist1 < dist2) {
                return NSOrderedAscending;
            }
            else if (dist2 < dist1){
                return NSOrderedDescending;
            }
            else{
                return NSOrderedSame;
            }
        }];
        
        CLLocation* closestLoc = sortedWithDistToDrone[0];
        int newIndex = (int)[circuit.locations indexOfObject:closestLoc];
        self.droneIndexOnCircuit = newIndex;
        
    }
    
    
    self.droneIndexLocation = circuit.locations[self.droneIndexOnCircuit];
    self.droneDistToItsIndex = [[Calc Instance] distanceFromCoords2D:self.droneIndexLocation.coordinate toCoords2D:self.droneLoc.coordinate];
    
     self.distanceToCar = [[Calc Instance] distanceFromCoords2D:self.droneLoc.coordinate toCoords2D:carLoc.coordinate];
    self.bearingToCar = [[Calc Instance] headingTo:carLoc.coordinate fromPosition:self.droneLoc.coordinate];
    self.carSpeed_Vec = [[Vec alloc] initWithNorm:carLoc.speed andAngle:carLoc.course];
    self.droneSpeed_Vec = [[Vec alloc] initWithNorm:self.droneLoc.speed andAngle:self.droneLoc.course];
    self.droneCar_Vec = [[Vec alloc] initWithNorm:self.distanceToCar andAngle:self.bearingToCar];
    
    
    float angleSens = [circuit.interAngle[self.droneIndexOnCircuit%circuit.locations.count] floatValue];
    self.sensCircuit = [[Vec alloc] initWithNorm:1 andAngle:angleSens];
    self.versCircuit = [[Vec alloc] initWithNorm:1 andAngle:angleSens];
    
    
    Vec* versCircuiTest90 = [[Vec alloc] initWithNorm:1 andAngle:[[Calc Instance] angle180Of330Angle:angleSens+90]];
    Vec* droneVersCircuit = [[Vec alloc] initWithNorm:self.droneDistToItsIndex andAngle:[[Calc Instance] headingTo:_droneIndexLocation.coordinate fromPosition:self.droneLoc.coordinate]];
    
    if ([versCircuiTest90 dotProduct:droneVersCircuit] > 0) {
        [self.versCircuit updateWithNorm:1 andAngle:[[Calc Instance] angle180Of330Angle:(angleSens+90)]];
    }
    else {
        [self.versCircuit updateWithNorm:1 andAngle:[[Calc Instance] angle180Of330Angle:(angleSens-90)]];
    }
    
    self.V_perp = [self.droneSpeed_Vec dotProduct:self.versCircuit];
    self.V_parralele = [self.droneSpeed_Vec dotProduct:self.sensCircuit];
    
}

-(void) estimateDroneYawSpeed:(float) currentYaw{
    // filter drone yaw with kalman filtering and deduce the speed
    if (!arrayOfDroneYawDiff) {
        arrayOfDroneYawDiff = [[NSMutableArray alloc] init];
        prevDroneYaw = currentYaw;
        _droneYawSpeed = 0;
    }
    else{
        float diffAngle = [[Calc Instance] closestDiffAngle:currentYaw toAngle:prevDroneYaw];
        
        // premier filtrage a éliminer quand utilise kalman
        float droneYawSp = diffAngle/0.1;
        
        droneYawSp = [[Calc Instance] filterVar:diffAngle inArray:arrayOfDroneYawDiff angles:NO withNum:2];
        droneYawSp /= 0.1;
        droneYawSp = bindBetween(droneYawSp, -120, 120);
        if (!arrayOfDroneYawSp) {
            arrayOfDroneYawSp = [[NSMutableArray alloc] init];
        }else{
            droneYawSp = [[Calc Instance] filterVar:droneYawSp inArray:arrayOfDroneYawSp angles:NO withNum:2];
        }
        
        prevDroneYaw = currentYaw;
        self.droneYawSpeed = droneYawSp;
    }
}

-(void) updateDroneStateWithFlightControllerState:(DJIFlightControllerCurrentState *)state{
    // assuming self is already init
    
    if (!CLLocationCoordinate2DIsValid(state.aircraftLocation) || !state.aircraftLocation.latitude || !state.aircraftLocation.longitude) {
        DVLog(@"invalid drone coord");
        return;
    }
    
    NSDate* now = [[NSDate alloc] init];
    float speed = sqrtf(state.velocityX*state.velocityX +state.velocityY*state.velocityY);
    float angle = [[Calc Instance] angleFromNorthOfVectorWithNorthComponent:state.velocityX EastComponent:state.velocityY];
    
    CLLocation* realDroneLocation = [[CLLocation alloc] initWithCoordinate:state.aircraftLocation altitude:state.altitude horizontalAccuracy:1 verticalAccuracy:1 course:angle speed:speed timestamp:now];
    
    
    
    [self estimateDroneYawSpeed:state.attitude.yaw];
    
    // updating
    self.droneLoc = realDroneLocation;
    self.droneYaw = state.attitude.yaw;
    
}

#pragma mark - simulation
-(Drone*) newDroneStateFrom:(Drone*) currentDroneState withTargetSpeed:(float) targSp andTargetAngle:(float) targHeading andTargAltitude:(float) targAlt during:(float) dt{
    
    Drone* newState = currentDroneState;
    
    CLLocation* newLoc = [self newDroneStateFromState:currentDroneState.droneLoc targetSpeed:targSp targetAngle:targHeading targetAltitude:targAlt];
    
    newState.droneLoc = newLoc;
    
    return newState;
}

-(Vec*) newDroneSpeedFromSpeed:(CLLocation*) droneLoc targetSpeed:(float) targSp targetAngle:(float) targAngle{
    
    Vec* initialSpeed_vec = [[Vec alloc] initWithNorm:droneLoc.speed andAngle:droneLoc.course];
    Vec* targetSpeed_vec = [[Vec alloc] initWithNorm:targSp andAngle:targAngle];
    
    Vec* deltaSp_vec = [targetSpeed_vec substractVector:initialSpeed_vec];
    
    float scalar = [deltaSp_vec dotProduct:initialSpeed_vec];
    
    if (scalar > 0) {
        [deltaSp_vec updateWithNorm:MIN(3, deltaSp_vec.norm)*0.1 andAngle:deltaSp_vec.angle];
    }else{
        [deltaSp_vec updateWithNorm:MIN(6, deltaSp_vec.norm)*0.1 andAngle:deltaSp_vec.angle];
    }
    
    Vec* newSpeed_vec =[deltaSp_vec addVector:initialSpeed_vec];
    
    return  newSpeed_vec;
}

-(CLLocation*) newDroneStateFromState:(CLLocation*) droneLoc targetSpeed:(float) targSp targetAngle:(float) targAngle targetAltitude:(float) targAlt{
    // state should be first initialized to : initial position , sp = 0, targang = 0
    
    Vec* newSpeed_Vec = [self newDroneSpeedFromSpeed:droneLoc targetSpeed:targSp targetAngle:targAngle];
//    float sp = bindBetween(newSpeed_Vec.norm, 0, 17);
    float sp = newSpeed_Vec.norm;
    
    [newSpeed_Vec updateWithNorm:sp andAngle:newSpeed_Vec.angle];
    
    
    
    // ALTITUDE
    float currentAltitude = droneLoc.altitude;
    float diffAlt = targAlt - currentAltitude;
    diffAlt = bindBetween(diffAlt, -0.5,0.5);
    float nextAltitudeForSimulatedDrone = currentAltitude + diffAlt;
    
    
    NSDate* date = [[NSDate alloc]init];
    CLLocationCoordinate2D newCoord = [[Calc Instance] predictedGPSPositionFromCurrentPosition:droneLoc.coordinate andCourse:droneLoc.course andSpeed:droneLoc.speed during:0.1];
    CLLocation* newLoc = [[CLLocation alloc] initWithCoordinate:newCoord altitude:nextAltitudeForSimulatedDrone horizontalAccuracy:0 verticalAccuracy:0 course:newSpeed_Vec.angle speed:newSpeed_Vec.norm timestamp:date];
    
    
    return newLoc;
}

#pragma mark - time estimation

-(float) timeForDroneToReachLoc:(CLLocation*) targetLoc andTargetSpeed:(float) targSpeed{
    
    CLLocation* droneLoc = self.droneLoc;
    Vec* droneSpeed = [[Vec alloc] initWithNorm:droneLoc.speed andAngle:droneLoc.course];
    float dist = [[Calc Instance] distanceFromCoords2D:droneLoc.coordinate toCoords2D:targetLoc.coordinate];
    float heading = [[Calc Instance] headingTo:targetLoc.coordinate fromPosition:droneLoc.coordinate];
    Vec* droneToLoc = [[Vec alloc] initWithNorm:dist andAngle:heading];
    
    Vec* droneToLocUnity = [droneToLoc unityVector];
    
    float droneSpeedInLocDir = [droneToLocUnity dotProduct:droneSpeed];
    
    return [self timeForDrone_linear:droneSpeedInLocDir toReachLocAtDist:dist withSpAtTarg:targSpeed];
}

-(float) timeForDrone_linear:(float) droneSpeed toReachLocAtDist:(float) dist withSpAtTarg:(float) speedAtTarget{
    
    // dist should be positive because its along with dronetoLoc vec
    // pour simplifier speedAtTarget >= 0
    
    float timeToTarget = 0;
    
    if (droneSpeed >= 0) {
        
        droneSpeed = bindBetween(droneSpeed, 0, 16);
        float distTo16mps = 75.8 - 1.63*expf(0.24*droneSpeed);
        float distFreinageFrom16mps = (16-speedAtTarget)*1.2356; //
        
        if (dist > distTo16mps + distFreinageFrom16mps) {
            float distAt16 = dist - distTo16mps - distFreinageFrom16mps;
            timeToTarget = distAt16/16 + 0.36*(16-droneSpeed) + 0.17*fabsf(16-speedAtTarget);
            
            //            NSLog(@"timeToTarg , %0.2f, dist , %0.1f ,droneSp , %0.2f",timeToTarget,dist,droneSpeed);
            
        }
        else{
            if (speedAtTarget == 0) {
                
                float maxSpeed = 0;
                if (dist >= 10) {
                    maxSpeed = 5.06*logf(dist)-7.1;
                }
                else{
                    maxSpeed = 0.455*dist;
                }
                
                maxSpeed = bindBetween(maxSpeed, 0, 16);
                // maxSpeed to reach before starting braking
                
                if (droneSpeed < maxSpeed) {
                    // temps accélération
                    float Tacc = 0.36*(maxSpeed-droneSpeed);
                    float Tdec = 0.17*maxSpeed;
                    
                    timeToTarget = Tacc + Tdec;
                }
                else{
                    timeToTarget = dist/((droneSpeed+speedAtTarget)/2);
                }
            }
            else{
                timeToTarget = dist/((droneSpeed+speedAtTarget)/2);
            }
            
        }
        
        
    }
    else{
        // freinage
        float timeToBrake = -0.17*droneSpeed;
        float distAfterBraking = -1.2356*droneSpeed;
        timeToTarget = timeToBrake + [self timeForDrone_linear:0 toReachLocAtDist:dist+distAfterBraking withSpAtTarg:speedAtTarget];
    }
    
    return timeToTarget;
}

@end
