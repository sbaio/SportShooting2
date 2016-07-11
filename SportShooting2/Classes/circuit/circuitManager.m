//
//  circuitManager.m
//  SportShooting2
//
//  Created by Othman Sbai on 5/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "circuitManager.h"
#import <CoreLocation/CLLocation.h>


@implementation circuitManager


+(circuitManager *) Instance{
    static circuitManager * cm;
    
    @synchronized (self) {
        if (!cm) {
            cm = [[circuitManager alloc] init];
        }
    }
    return cm;
}
-(id) init{
    self = [super init];
    _simulatedCarSpeed = 0;
    return self;
}

-(Circuit*) loadCircuit:(NSString*) circuitName{
    
    NSMutableArray* locations = [self loadCircuitNamed:circuitName];
    
    return [self circuitWithLocations:locations andName:circuitName];
    
}

-(Circuit*) circuitWithLocations:(NSMutableArray*) locations andName:(NSString*) circuitName{
    
    Circuit* circuit = [[Circuit alloc] init];
    
    if (!locations) {
        NSLog(@"empty circuit");
        return nil;
    }
    
    circuit.locations = [self removeSameLocsFromCircuit:locations];
    
    circuit.interDistance = [self calculateInterDistancesOfCircuit:circuit.locations];
    circuit.interAngle = [self calculateSensCircuitAnglesOfCircuit:circuit.locations];
    
    circuit.circuitLength = [self lengthOfCircuit:circuit];
    circuit.circuitName = circuitName;
    
    circuit.interIndexesDistance = [self calculateInterIndexesDistances2:circuit];
    circuit.region = [self circuitRegionFromLocations:circuit.locations];
    
    
    NSLog(@"circuit %@ length , %0.3f, count , %d",circuit.circuitName,circuit.circuitLength,(int)circuit.locations.count);
    
    return circuit;
}

-(Circuit*) circuitWithLocations:(NSMutableArray*) locations{
    Circuit* circuit = [[Circuit alloc] init];
    
    if (!locations) {
        NSLog(@"empty circuit");
        return nil;
    }
    
    circuit.locations = [self removeSameLocsFromCircuit:locations];
    
    circuit.interDistance = [self calculateInterDistancesOfCircuit:circuit.locations];
    circuit.interAngle = [self calculateSensCircuitAnglesOfCircuit:circuit.locations];
    
    circuit.circuitLength = [self lengthOfCircuit:circuit];
    circuit.circuitName = @"";
    
    circuit.interIndexesDistance = [self calculateInterIndexesDistances2:circuit];
    circuit.region = [self circuitRegionFromLocations:circuit.locations];
    
    
    NSLog(@"circuit %@ length , %0.3f, count , %d",circuit.circuitName,circuit.circuitLength,(int)circuit.locations.count);
    
    return circuit;
}


//////

-(NSMutableArray*) calculateInterDistancesOfCircuit:(NSMutableArray*) circuit{
    NSMutableArray* interDistArray = [[NSMutableArray alloc] init];
    
    for(int i = 0;i<circuit.count;i++){
        
        CLLocation* loci = circuit[i];
        CLLocation* locip = circuit[(i+1)%circuit.count];
        
        NSNumber* dist = [NSNumber numberWithFloat:[[Calc Instance] distanceFromCoords2D:loci.coordinate toCoords2D:locip.coordinate]];
        [interDistArray addObject:dist];
        //                NSLog(@"index , %d, dist , %0.3f",i,[dist floatValue]);
    }
    
    return interDistArray;
}
-(NSMutableArray*) calculateSensCircuitAnglesOfCircuit:(NSMutableArray*) circuit{
    
    NSMutableArray* returnArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < circuit.count; i++) {
        NSMutableArray* array = [[NSMutableArray alloc] init];
        
        for (int j =-7; j<7; j++) {
            CLLocation* loci = circuit[(i+j+circuit.count)%circuit.count];
            CLLocation* locip = circuit[(i+j+1+circuit.count)%circuit.count];
            float dist = [[Calc Instance] distanceFromCoords2D:loci.coordinate toCoords2D:locip.coordinate];
            
            int k = 0;
            while (!dist) {
                k++;
                locip = circuit[(i+j+1+k+circuit.count)%circuit.count];
                dist = [[Calc Instance] distanceFromCoords2D:loci.coordinate toCoords2D:locip.coordinate];
            }
            float heading = [[Calc Instance] headingTo:locip.coordinate fromPosition:loci.coordinate];
            if (i< 2) {
                //                                NSLog(@"i = %d ,j = %d , %0.3f ",i,j,heading);
            }
            
            
            [array addObject:[NSNumber numberWithFloat:heading]];
        }
        float angle = [[Calc Instance] avgAngleOfArray:array];
        //                NSLog(@"index, %d, angle , %0.3f",i,angle);
        [returnArray addObject:[NSNumber numberWithFloat:angle]];
    }
    
    
    // FILTER 7 angles
    NSMutableArray* avgedInterAngle = [[NSMutableArray alloc] init];
    
    NSMutableArray* sevenFloats = [[NSMutableArray alloc] init];
    
    for (int i = 0; i<circuit.count; i++) {
        float anglei = [returnArray[i] floatValue];
        
        float newAvgedAngle = [[Calc Instance] filterVar:anglei inArray:sevenFloats angles:YES withNum:7];
        
        [avgedInterAngle addObject:[NSNumber numberWithFloat:newAvgedAngle]];
    }
    
    return avgedInterAngle;
}
-(float) lengthOfCircuit:(Circuit*) circuit{
    float length = 0;
    
    for (NSNumber* num in circuit.interDistance) {
        length += [num floatValue];
    }
    
    return length;
}

-(NSMutableArray*) calculateInterIndexesDistances:(Circuit*) circuit{
    
    NSMutableArray* returnArray = [[NSMutableArray alloc] init];
    
    for (CLLocation* loci in circuit.locations) {
        NSMutableArray* startIndexArray = [[NSMutableArray alloc] init];
        for (CLLocation* locj in circuit.locations) {
            int indexi = (int)[circuit.locations indexOfObject:loci];
            int indexj = (int)[circuit.locations indexOfObject:locj];
            
            float dist_i_j = [[Calc Instance] distanceOnCircuit_interDistances:circuit fromIndex:indexi toIndex:indexj];
            if (dist_i_j > circuit.circuitLength/2) {
                dist_i_j -= circuit.circuitLength;
            }
            [startIndexArray addObject:[NSNumber numberWithFloat:dist_i_j]];
        }
        [returnArray addObject:startIndexArray];
        
    }
    return  returnArray;
}
-(NSMutableArray*) calculateInterIndexesDistances2:(Circuit*) circuit{
    
    NSMutableArray* returnArray = [[NSMutableArray alloc] init];
    // initialisation
    for (int i = 0; i <circuit.locations.count; i++) {
        NSMutableArray* startIndexArray = [[NSMutableArray alloc] init];
        for (int j=0; j<circuit.locations.count; j++) {
            [startIndexArray addObject:[NSNumber numberWithFloat:0]];
        }
        [returnArray addObject:startIndexArray];
    }
    
    for (int i = 0 ; i<circuit.locations.count; i++) {
        
        for (int j = 0; j<circuit.locations.count; j++) {
            // here we calculate from j to j+i
            float value_j_jpi = 0;
            if (i == 0) {
                value_j_jpi = 0;
            }
            else if (i == 1) {
                value_j_jpi = [circuit.interDistance[j] floatValue];
            }
            else{
                int k = (j+1)%circuit.locations.count;
                int l = (j+i)%circuit.locations.count;
                NSMutableArray* start_j = [returnArray objectAtIndex:j];
                float j_k = [[start_j objectAtIndex:k] floatValue];
                NSMutableArray* start_k = [returnArray objectAtIndex:k];
                float k_jpi = [[start_k objectAtIndex:l] floatValue];
                
                value_j_jpi = j_k + k_jpi;
                
                if (value_j_jpi > circuit.circuitLength/2) {
                    value_j_jpi -= circuit.circuitLength;
                }
            }
            NSMutableArray* startIndex_j = [returnArray objectAtIndex:j];
            [startIndex_j replaceObjectAtIndex:(j+i)%circuit.locations.count withObject:[NSNumber numberWithFloat:value_j_jpi]];
        }
    }
    return  returnArray;
}

-(MKCoordinateRegion) circuitRegionFromLocations:(NSMutableArray*) locs{
    CLLocation* loc0 = locs[0];
    CLLocationCoordinate2D eastCoord = loc0.coordinate;
    CLLocationCoordinate2D westCoord = loc0.coordinate;
    CLLocationCoordinate2D northCoord = loc0.coordinate;
    CLLocationCoordinate2D southCoord = loc0.coordinate;
    
    for (int i = 1; i<locs.count; i++) {
        CLLocation* loci = locs[i];
        CLLocationCoordinate2D coordi = loci.coordinate;
        
        if ([[Calc Instance] isCoord:coordi toEastOfCoord:eastCoord]) {
            eastCoord = coordi;
        }
        else if (![[Calc Instance] isCoord:coordi toEastOfCoord:westCoord]){
            westCoord = coordi;
        }
        
        if ([[Calc Instance] isCoord:coordi toTheNorthOfCoord:northCoord]) {
            northCoord = coordi;
        }
        else if (![[Calc Instance] isCoord:coordi toTheNorthOfCoord:southCoord]){
            southCoord = coordi;
        }
    }
    float eastDist = [[Calc Instance] distanceFromCoords2D:eastCoord toCoords2D:westCoord];
    float northDist = [[Calc Instance] distanceFromCoords2D:southCoord toCoords2D:northCoord];
    
    CLLocationCoordinate2D midEastWest = [[Calc Instance] pointBetweenStartPoint:westCoord andPoint:eastCoord atRatio:0.5];
    CLLocationCoordinate2D midSouthNorth = [[Calc Instance] pointBetweenStartPoint:southCoord andPoint:northCoord atRatio:0.5];
    
    CLLocationCoordinate2D regionCenter = CLLocationCoordinate2DMake(midSouthNorth.latitude,midEastWest.longitude);
    
    return MKCoordinateRegionMakeWithDistance(regionCenter, eastDist, northDist);
    
}


-(BOOL) saveCircuitFrom:(NSMutableArray*) circuit toPathName:(NSString*) circuitName{
    
    NSString* filePath = [[Calc Instance] pathForFileNamedInSearchPathDirectoriesInDomains:circuitName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
    }
    DVLog(@"saving circuit %@, count : %d",circuitName,circuit.count);
    return [NSKeyedArchiver archiveRootObject:circuit toFile:filePath];
}

-(void) concatenateOrderedCircuits:(NSArray*) arrayOfCircuitsNames intoCircuit:(NSString*) circuitName{
    NSMutableArray* totalCircuit = [[NSMutableArray alloc] init];
    
    for (NSString* circuitNameInArray in arrayOfCircuitsNames) {
        NSMutableArray* currentCircuit = [[Calc Instance] loadCircuitNamed:circuitNameInArray];
        if (currentCircuit) {
            for (CLLocation* loc in currentCircuit) {
                [totalCircuit addObject:loc];
            }
        }
        else{
            NSLog(@"empty circuit %@",circuitNameInArray);
        }
        
    }
    [self saveCircuitFrom:totalCircuit toPathName:circuitName];
}

-(NSMutableArray*) halfCircuitOf:(NSMutableArray*) originalCircuit{
    NSMutableArray* newCirc = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < originalCircuit.count; i+=2) {
        [newCirc addObject:originalCircuit[i]];
    }
    
    return newCirc;
}

-(NSMutableArray*) circuitOfMiddlePointsFrom:(NSMutableArray*) originalCircuit{
    
    // if circuit is not "closed" the last point is wrong ...
    if (!originalCircuit) {
        DVLog(@"empty circuit");
        return nil;
    }
    
    NSMutableArray* newCircuit = [[NSMutableArray alloc] init];
    
    for (CLLocation* loci in originalCircuit) {
        [newCircuit addObject:loci];
        NSUInteger indexi = [originalCircuit indexOfObject:loci];
        CLLocation* locip1 = originalCircuit[(indexi+1)%originalCircuit.count];
        
        CLLocationCoordinate2D coord = [[Calc Instance] pointBetweenStartPoint:loci.coordinate andPoint:locip1.coordinate atRatio:0.5];
        CLLocation* middleLoc = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
        
        [newCircuit addObject:middleLoc];
    }
    
    return newCircuit;
}

-(NSMutableArray*) repairCircuit:(NSMutableArray*) locations{
    // doesn't modify input locations 
    NSMutableArray* newCircuit = [[NSMutableArray alloc] initWithArray:locations copyItems:YES];
  
    
    for (int i = 0; i<newCircuit.count; i++) {
        CLLocation* loci = newCircuit[i];
        CLLocation* locip1 = newCircuit[(i+1)%newCircuit.count];
        
        float dist = [[Calc Instance] distanceFromCoords2D:loci.coordinate toCoords2D:locip1.coordinate];
        if (dist > 10) {
            float heading = [[Calc Instance] headingTo:locip1.coordinate fromPosition:loci.coordinate];
            
            CLLocation* newLoc = [[Calc Instance] locationFrom:loci atDistance:5 atBearing:heading];
            [newCircuit insertObject:newLoc atIndex:(i+1)];
            
        }
    }
    
    
    
    return newCircuit;
}



-(NSMutableArray*) removeSameLocsFromCircuit:(NSMutableArray*) circuit{
    NSMutableArray* returnArray = [[NSMutableArray alloc] init];
    
    NSMutableArray* interDistArr = [[NSMutableArray alloc] init];
    
    for (int i = 0; i<circuit.count; i++) {
        CLLocation* loci = circuit[i];
        CLLocation* locip = circuit[(i+1)%circuit.count];
        
        float dist = [[Calc Instance] distanceFromCoords2D:locip.coordinate toCoords2D:loci.coordinate];
        [interDistArr addObject:[NSNumber numberWithFloat:dist]];
    }
    
    // put start loc
    CLLocation* loc = circuit[0];
    [returnArray addObject:loc];
    
    for (int i = 1; i<circuit.count; i++) {
        CLLocation* loci = circuit[i];
        float distToPrev = [interDistArr[(i+circuit.count-1)%circuit.count] floatValue];
        
        if (distToPrev) {
            [returnArray addObject:loci];
        }
    }
    
    NSLog(@"circuit without doublons count, %lu",returnArray.count);
    
    return returnArray;
}

-(BOOL) isCircuitExisting:(NSString*) circuitName{
    
    return YES;
}

-(NSMutableArray*) loadCircuitNamed:(NSString*)circuitName{ // return nil if nothing found
    NSMutableArray* circuit = nil;
    NSString* circuitName_c = [NSString stringWithFormat:@"%@_c",circuitName];
    
    NSString * filePath = [[Calc Instance] pathForFileNamedInSearchPathDirectoriesInDomains:circuitName_c];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        circuit = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        DVLog(@"loaded the circuit '%@'",circuitName);
        if (!circuit.count) {
            DVLog(@"empty circuit");
            return nil;
        }
    }
    else {
        DVLog(@"circuit %@ not found",circuitName);
        
        return nil;
    }
    
    return circuit;
}

-(BOOL) remove:(CLLocation*) locaToRemove FromCircuit:(Circuit*) circuit {
    
    BOOL contains = NO;
    
    CLLocation* locInCircuit = [[CLLocation alloc] init];
    
    for (CLLocation* loc in circuit.locations) {
        if ([[Calc Instance] distanceFromCoords2D:loc.coordinate toCoords2D:locaToRemove.coordinate]< 0.5) {
            contains = YES;
            locInCircuit = loc;
            break;
        }
    }
    if (contains) {
        [circuit.locations removeObject:locInCircuit];
        //        DVLog(@"removed selected locations from circuit");
        [self saveCircuitFrom:circuit.locations toPathName:circuit.circuitName];
//        [self removePinsNamed:@"circuitDrawing"];
//        NSMutableArray* newCircuit = [[Calc Instance] loadCircuitNamed:circuit.circuitName];
//        [[Calc Instance] map:mapView drawCircuitPins:newCircuit withColor:@"RGB 255 255 255"];
        return YES;
    }
    else{
        //        DVLog(@"circuit does not contain location");
        return NO;
    }
}

-(void) saveCircuit:(Circuit*) circuit{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:circuit];
    if (!circuit.circuitName) {
        NSLog(@"empty name");
    }

    [[NSUserDefaults standardUserDefaults] setObject:data forKey:[NSString stringWithFormat:@"%@_c",circuit.circuitName]];
    NSLog(@"save circuit %@, %d",circuit.circuitName,(int)circuit.locations.count);
    
}
-(Circuit*) loadCircuitNamed_coder:(NSString*) circuitName{
    
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_c",circuitName]];
    Circuit* circuit = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return circuit;
}
-(void) removeCircuitNamed:(NSString*) circuitName{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults removeObjectForKey:[NSString stringWithFormat:@"%@_c",circuitName]];
}




#pragma mark - car simulation 

-(void) simulateCarOnCircuit:(Circuit*) circuit{
    if ([carSimulationTimer isValid]) {
        [carSimulationTimer invalidate];
    }
    
    carPrevIndex = 0; // for simulation purpose ...
    carIndexOnSimpleCircuit = 0;
    carSimulatedLocation = circuit.locations[carIndexOnSimpleCircuit%circuit.locations.count];
    
    simulationCircuit = circuit;
    
    cumulatedDist = 0;
    
    carSimulationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(moveCarOnCircuit:) userInfo:nil repeats:YES];
}

-(void) moveCarOnCircuit:(NSTimer*)timer{
    if ([[Menu instance]getFrontVC].isRealCar) {
        return;
    }
    // input slider ...
    carSpeed = _simulatedCarSpeed;//[virtualCarSpeedSlider value];
    
    carSimulatedLocation = [self moveSimulatedCarFrom:carSimulatedLocation byDistance:carSpeed*0.1 onCircuit:simulationCircuit];
    
    NSMutableArray* angleArray = simulationCircuit.interAngle;
    float course_heading = [angleArray[carPrevIndex] floatValue];
   
    
    carSimulatedLocation = [[CLLocation alloc]initWithCoordinate:carSimulatedLocation.coordinate altitude:0 horizontalAccuracy:1 verticalAccuracy:1 course:course_heading speed:carSpeed timestamp:[[NSDate alloc] init]];
    if (![[Menu instance]getFrontVC].isRealCar) {
        [[[Menu instance]getFrontVC] carAtLocation:carSimulatedLocation];
    }
    
}

-(void) pauseCarMovement{
    if ([carSimulationTimer isValid]) {
        [carSimulationTimer invalidate];
    }
}
-(void) resumeCarMovement{
    carSimulationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(moveCarOnCircuit:) userInfo:nil repeats:YES];
}

-(CLLocation*) moveSimulatedCarFrom:(CLLocation*) carLoc byDistance:(float) distance onCircuit:(Circuit*) circuit{
    
    CLLocation* nextLoc  = [[CLLocation alloc] init];
    
    // prevCarIndex here stored
    CLLocation* locip1 = circuit.locations[(carPrevIndex+1)%circuit.locations.count];
    
    
    float distToLocip1 = [[Calc Instance] distanceFromCoords2D:carLoc.coordinate toCoords2D:locip1.coordinate];
    
    
    if (distToLocip1 > distance) {
        
        float heading = [[Calc Instance] headingTo:locip1.coordinate fromPosition:carLoc.coordinate];
        
        nextLoc = [[Calc Instance] locationFrom:carLoc atDistance:distance atBearing:heading];
        
        // going to next index prevCarIndex +1
    }
    else{
        float distanceToDo = distance;
        
        for (int i = 0; i< 2*circuit.locations.count; i++) {
            CLLocation* locip1 = circuit.locations[(carPrevIndex+i+1)%circuit.locations.count];
            CLLocation* locip2 = circuit.locations[(carPrevIndex+i+2)%circuit.locations.count];
            
            float dist_ip1_ip2 = [circuit.interDistance[(carPrevIndex+i+1)%circuit.locations.count] floatValue];
            
            if (distanceToDo > dist_ip1_ip2) {
                
                distanceToDo -= dist_ip1_ip2;
                continue;
            }
            else{
                float course = [[Calc Instance] headingTo:locip2.coordinate fromPosition:locip1.coordinate];
                
                
                nextLoc = [[Calc Instance] locationFrom:locip1 atDistance:distanceToDo atBearing:course];
                // going between index prevCarIndex+1 and prevCarIndex+2
                
                carPrevIndex = (int)(carPrevIndex+i+1)%circuit.locations.count;
                
                break;
            }
        }
        
    }
    return nextLoc;
}


@end
