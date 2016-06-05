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
@synthesize mapView;
-(void) initWithDrone:(DJIAircraft*) realDrone{
    DVLog(@"setting real drone as drone");
    
}
-(id) initWithLocation:(CLLocation*) loc{
    
    self = [super init];
    
    self.droneLoc = loc;
    self.droneYaw = 0;
    
    self.droneAnno = [[Aircraft_Camera_Car_Annotation alloc] initWithCoordiante:loc.coordinate andType:0];
    self.droneSpeedVec_Anno = [[Aircraft_Camera_Car_Annotation alloc] initWithCoordiante:loc.coordinate andType:9];
    
    MapVC* mapVC = [[Menu instance] getMapVC];
    
    mapView = mapVC.mapView;
    
    [mapView addAnnotation:self.droneAnno];
    [mapView addAnnotation:self.droneSpeedVec_Anno];
    
    return self;
}

-(void) updateDroneStateWithLoc:(CLLocation*) droneLoc andYaw:(float) yaw{
    self.droneLoc = droneLoc;
    self.droneYaw = yaw;
    // droneAnno
    [self.droneAnno setCoordinate:droneLoc.coordinate];
    [self.droneAnno.annotationView updateHeading:RADIAN(yaw)];
    // droneSpeedAnno
    [self.droneSpeedVec_Anno setCoordinate:droneLoc.coordinate];
    [self.droneSpeedVec_Anno.annotationView updateHeading:RADIAN(droneLoc.course) andScale:droneLoc.speed/17.0];
}

-(void) calculateDroneIndexOnCircuit:(Circuit*) circuit forCarLocation:(CLLocation*) carLoc carIndex:(int) carIndex{
    
    NSMutableArray* distToDroneArray = [[NSMutableArray alloc]init];
    NSMutableArray* distOnCircToCar = [[NSMutableArray alloc] init];
    NSMutableArray* startIndexArray = circuit.interIndexesDistance[carIndex];
    
    for (CLLocation* loc in circuit.locations) {
        float distDr = [[Calc Instance] distanceFromCoords2D:self.droneLoc.coordinate toCoords2D:loc.coordinate];
        [distToDroneArray addObject:[NSNumber numberWithFloat:distDr]];
        
        
        float distCar = [[startIndexArray objectAtIndex:[circuit.locations indexOfObject:loc]] floatValue];
       
        [distOnCircToCar addObject:[NSNumber numberWithFloat:distCar]];
        
        //        NSLog(@"index , %d, distToDr , %0.3f, distOnCirCar , %0.3f",(int)[circuit indexOfObject:loc],distDr,distCar);
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
    
    for (int i = 0; i < 50; i++) {
        [indexes addObject:[NSNumber numberWithInt:(int)[circuit.locations indexOfObject:sortedWithDistanceToDrone[i]]]];
        [distances addObject:distToDroneArray[[circuit.locations indexOfObject:sortedWithDistanceToDrone[i]]]];
    }
    
    // RECUPERER les tetes de groupes
    NSMutableArray* teteDeGroupes = [[NSMutableArray alloc] init];
    
    [teteDeGroupes addObject:indexes[0]];
    for (int i = 0; i< indexes.count; i++) {
        BOOL fitsInAGroup = NO;
        
        int inde = [indexes[i] intValue];
        //        NSLog(@"%d",inde);
        
        for (int j=0; j< teteDeGroupes.count;j++) {
            int diff = abs(inde - [teteDeGroupes[j] intValue]);
            if (diff > circuit.locations.count/2) {
                diff -= circuit.locations.count;
            }

            if (abs(diff) < 50 ){
                fitsInAGroup = YES;
            }
        }
        if (!fitsInAGroup) {
            //            NSLog(@"new group found ,%d",inde);
            [teteDeGroupes addObject:indexes[i]];
        }
    }

    NSMutableArray* arrayOfKeyLocations = [[NSMutableArray alloc] init];
    
    for (int i =0; i< teteDeGroupes.count; i++) {
        int indexi = [teteDeGroupes[i] intValue];
        CLLocation* loci = circuit.locations[indexi];
        
        [arrayOfKeyLocations addObject:loci];
        
        //        [self addPin:loci andTitle:@"teteDeGroupe" andColor:@"RGB 215 175 55"];
    }
    
    // HERE we can run choice between these key locations !!!!
    
    
    if (teteDeGroupes.count ==1) {
        // droneIndex is no doubt this value ...
        int index = [teteDeGroupes[0] intValue];
        CLLocation* loci = circuit.locations[index];
        float distDrone = [[Calc Instance] distanceFromCoords2D:loci.coordinate toCoords2D:self.droneLoc.coordinate];
        
        self.droneIndexOnCircuit = index;
        self.droneDistToItsIndex = distDrone;
        self.distanceOnCircuitToCar = [[startIndexArray objectAtIndex:index] floatValue];
    }
    else{
        //        NSLog(@"should choose between %d",(int)teteDeGroupes.count);
        
        NSArray* sortedWithDistOnCircuit = [teteDeGroupes sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
            int index1 = [obj1 intValue];
            int index2 = [obj2 intValue];
            
            
            float dist1 = [[startIndexArray objectAtIndex:index1] floatValue];
            float dist2 = [[startIndexArray objectAtIndex:index2] floatValue];
            
            CLLocation* loc1 = circuit.locations[index1];
            CLLocation* loc2 = circuit.locations[index2];
            float distDrone1 = [[Calc Instance] distanceFromCoords2D:self.droneLoc.coordinate toCoords2D:loc1.coordinate];
            float distDrone2 = [[Calc Instance] distanceFromCoords2D:self.droneLoc.coordinate toCoords2D:loc2.coordinate];
            
            
            //            NSLog(@"dist1 , %0.3f , dist2 , %0.3f",dist1,dist2);
            if (self.isCloseTracking) {
                if (fabsf(dist1) < fabsf(dist2)) {
                    return NSOrderedAscending;
                }
                else if (fabsf(dist1) > fabsf(dist2)){
                    return NSOrderedDescending;
                }
                else{
                    return NSOrderedSame;
                }
            }
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
        self.droneDistToItsIndex = [distToDroneArray[index] floatValue];
        self.distanceOnCircuitToCar = [[startIndexArray objectAtIndex:index] floatValue];
    }
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
    
    double heading = RADIAN(state.attitude.yaw);
    
    if (!self.droneAnno) {
        self.droneAnno = [[Aircraft_Camera_Car_Annotation alloc] initWithCoordiante:state.aircraftLocation andType:0];
        [self.droneAnno.annotationView updateHeading:heading];
        [mapView addAnnotation:self.droneAnno];
    }
    else{
        if (![mapView.annotations containsObject:self.droneAnno]) {
            [mapView addAnnotation:self.droneAnno];
        }
        [self.droneAnno setCoordinate:state.aircraftLocation];
        [self.droneAnno.annotationView updateHeading:heading];
    }
    
    
    float scale = speed/17.0;
    if (!self.droneSpeedVec_Anno) {
        self.droneSpeedVec_Anno = [[Aircraft_Camera_Car_Annotation alloc] initWithCoordiante:state.aircraftLocation andType:9];
        [self.droneSpeedVec_Anno updateHeading:RADIAN(angle) andScale:scale];
        [mapView addAnnotation: self.droneSpeedVec_Anno];
    }
    else{
        if (![mapView.annotations containsObject:self.droneSpeedVec_Anno]) {
            [mapView addAnnotation:self.droneSpeedVec_Anno];
        }
        [self.droneSpeedVec_Anno setCoordinate:state.aircraftLocation];
        [self.droneSpeedVec_Anno updateHeading:RADIAN(angle) andScale:scale];
    }
    
}

@end
