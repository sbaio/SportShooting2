//
//  pathPlanner.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/16/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//
#define bindBetween(a,b,c) ((a > c) ? c: ((a<b)? b:a))
#define sign(a) ( ( (a) < 0 )  ?  -1   : ( (a) > 0 ) )
#define DV_FLOATING_WINDOW_ENABLE 1

#import "pathPlanner.h"

@implementation pathPlanner

-(id) init{
    self = [super init];
    
    mapView = [[Menu instance] getMapView];
    mapVC = [[Menu instance] getMapVC];
    
    yellowColorString = @"RGB 212 175 55";
    redColorString = @"RGB 222 22 22";
    
    return self;
}


#pragma mark - method 1 of path planning

-(void) follow:(CLLocation*) carLoc onCircuit:(Circuit*) circ drone:(Drone*) drone{

    carLocation = carLoc;
    circuit = circ;
    _drone = drone;
    
    [self updatePredictedDrone:_drone];
    
    _carIndexOnCircuit = [self carIndexOnCircuit:circ forCarLoc:carLoc];
    
    [_drone calculateDroneInfoOnCircuit:circ forCarLocation:carLoc carIndex:_carIndexOnCircuit calcIndex:YES];
    
    [mapView movePinNamed:@"droneIndexLoc" toCoord:_drone.droneIndexLocation andColor:@"RGB 0 255 0"];

    _predictedDrone.droneIndexOnCircuit = _drone.droneIndexOnCircuit;
    _predictedDrone.droneIndexLocation = _drone.droneIndexLocation;
    _predictedDrone.distanceOnCircuitToCar = _drone.distanceOnCircuitToCar;
    
    [_predictedDrone calculateDroneInfoOnCircuit:circ forCarLocation:carLoc carIndex:_carIndexOnCircuit calcIndex:NO];
    
    [mapView updateDroneSensCircuit_PerpAnnotations:_predictedDrone];
    
    [self setCloseTrackingOrShortcutting:carLoc drone:_drone onCircuit:circ];
    
    if (_drone.isCloseTracking) {
        [self performCloseTracking];
    }
    else{
        [self performShortcutting];
    }
}

-(void) updatePredictedDrone:(Drone*) drone{
    CLLocationCoordinate2D predictCoord = [[Calc Instance] predictedGPSPositionFromCurrentPosition:drone.droneLoc.coordinate andCourse:drone.droneLoc.course andSpeed:drone.droneLoc.speed during:1.5];
    
    CLLocation* dronePredictedLocation = [[CLLocation alloc] initWithCoordinate:predictCoord altitude:drone.droneLoc.altitude horizontalAccuracy:0 verticalAccuracy:0 course:drone.droneLoc.course speed:drone.droneLoc.speed timestamp:drone.droneLoc.timestamp];
    
    if (!_predictedDrone) {
        _predictedDrone = [[Drone alloc] initWithLocation:dronePredictedLocation];
    }
    else{
        [_predictedDrone updateDroneStateWithLoc:dronePredictedLocation andYaw:dronePredictedLocation.course];
    }
    
    [mapView movePinNamed:@"dronePredictedLoc" toCoord:dronePredictedLocation andColor:@"RGB 129 22 89"];
}



-(void) setCloseTrackingOrShortcutting:(CLLocation*) carLoc drone:(Drone*) drone onCircuit:(Circuit*) circ{
    
    float maxDistOnCircuitForCloseTracking = 9*40;
    float minDistOnCircuitForCloseTracking = -75;
    float droneSpeedSensCircuit = [drone.droneSpeed_Vec dotProduct:drone.sensCircuit];
    
    float diffSp = drone.carSpeed_Vec.norm - droneSpeedSensCircuit;
    
    
    if (drone.isCloseTracking) {
        [mapVC.topMenu setStatusLabelText:@"Close tracking"];
        // décider si on arrete le close tracking : voiture est partie/ index loin
        
        if (drone.distanceOnCircuitToCar > -75 && drone.distanceOnCircuitToCar < 35) {
            // en fct de la vitesse de la voiture dire si la voiture est partie...
            
            if (diffSp > 0.5*drone.distanceOnCircuitToCar +20) {
//                DVLog(@"Shortcutting: la voiture est partie");
                drone.isCloseTracking = NO;
            }
            else {
                
            }
        }
        
        if (drone.distanceOnCircuitToCar < minDistOnCircuitForCloseTracking -20) {
            
            drone.isCloseTracking = NO;
        }
        
    }
    else{
        [mapVC.topMenu setStatusLabelText:@"Shortcutting"];
        
        if (drone.carSpeed_Vec.norm < 2 && (drone.droneCar_Vec.norm < 20 || (drone.distanceOnCircuitToCar >- 50 && drone.distanceOnCircuitToCar < 50 && drone.droneDistToItsIndex < 20)) ) {
            
            drone.isCloseTracking = YES;
            
            //            arrayTargetBearingCloseTracking = nil;
            DVLog(@"voiture proche");
            return;
        }
        // décider si on peut reprendre la voiture
        if (drone.droneDistToItsIndex < 15) {
            
            if (drone.distanceOnCircuitToCar > minDistOnCircuitForCloseTracking && drone.distanceOnCircuitToCar < maxDistOnCircuitForCloseTracking) {
                if (diffSp < 0.5*drone.distanceOnCircuitToCar+10) {
                    DVLog(@"CloseTracking: peut suivre la voiture");
                    
                    drone.isCloseTracking = YES;
                    //                    arrayTargetBearingCloseTracking = nil;
                }
            }
        }
        else{
            // if have the right altitude then go
            
            // else just gain altitude
            
            
            // prendre de l'altitude et freiner ...
            //***********************************
            // SHORTCUT if have the right altitude
            //***********************************
            // else
            //***********************************
            //      isShortcutting = NO;
            //      isCloseTracking = NO;
        }
    }
}



-(void) performCloseTracking{
    
    // if drone should strictly follow the circuit locations then choose
    
    float targ_V_perp = _predictedDrone.droneDistToItsIndex/2;;
    
    targ_V_perp = bindBetween(targ_V_perp, 0, 16); // doit être continue
    
    float diffSp = _drone.carSpeed_Vec.norm - _drone.V_parralele;
    float totalDist = _drone.distanceOnCircuitToCar-20*(1+diffSp/10);
    
    float speedFromDist = -16*sign(totalDist)*(1-expf(-fabsf(totalDist)/25));
    float targ_V_Parallel = speedFromDist + _drone.carSpeed_Vec.norm;
    
    
    targ_V_Parallel = bindBetween(targ_V_Parallel, -sqrt(256-targ_V_perp*targ_V_perp), sqrt(256-targ_V_perp*targ_V_perp));
    
    
    Vec* V_parallele_Vec = [[Vec alloc] initWithNorm:targ_V_Parallel andAngle:_drone.sensCircuit.angle];
    Vec* V_Perp_Vec = [[Vec alloc] initWithNorm:targ_V_perp andAngle:_drone.versCircuit.angle];
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





#pragma mark - method 2 of path planning

-(void) follow2:(CLLocation*) carLoc onCircuit:(Circuit*) circ drone:(Drone*) drone{
    if (carLoc.speed == 0) {
        NSLog(@"car Stopped");
        _status.carIsComing = NO;
    }
    else{

        if (_drone.distanceOnCircuitToCar > 0 && _drone.distanceOnCircuitToCar/carLoc.speed < 15 && _drone.droneDistToItsIndex < 100) {
            lastCarIsComingNotifDate = [NSDate new];
            if (!_status.carIsComing) {
                DVLog(@"car is coming : YES");
                _status.carIsComing = YES;
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ((-[lastCarIsComingNotifDate timeIntervalSinceNow] >0.3) && _status.carIsComing) {
                    DVLog(@"car is coming : NO");
                    _status.carIsComing = NO;
                }
            });
        }
        
        if (1) {
            NSLog(@"distSur Circ , %0.3f",_drone.distanceOnCircuitToCar);
        }
    }
    
    
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
    [mapView movePinNamed:@"carIndex" toCoord:loc andColor:redColorString];
    
    return carIndex;
}
@end
