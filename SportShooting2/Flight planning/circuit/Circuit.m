//
//  Circuit.m
//  SportShooting2
//
//  Created by Othman Sbai on 5/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//
#define sign(a) ( ( (a) < 0 )  ?  -1   : ( (a) > 0 ) )

#import "Circuit.h"
#import <CoreLocation/CLLocation.h>
#import "Calc.h"
#import "Vec.h"

#import "KalmanFilter1D.h"

@implementation Circuit
@synthesize region,circuitLength;
// saving a circuit
-(id) initWithLocations:(NSMutableArray*) circLocs andName:(NSString*) circuitName calc:(BOOL) calc{
    
    self.locations = circLocs;
    
    self.interDistance = [self calculateInterDistancesOfCircuit:self.locations];
    self.circuitLength = [self length];
    self.circuitName = circuitName;
    
    // NOT HERE
    if (calc) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.interAngle = [self calculateSensCircuitAnglesOfCircuit:self.locations];
//            [self calculateCourbureCircuit:self.locations];
            self.interIndexesDistance = [[Calc Instance] loadArrayNamed:[NSString stringWithFormat:@"distances%@",self.circuitName]];
            if (!self.interIndexesDistance) {
                // THIS Operation takes around 5 seconds depending on the circuit size
                self.interIndexesDistance = [self calculateInterIndexesDistances:self.locations];
                NSString* st = [NSString stringWithFormat:@"distances%@",self.circuitName];
                [self saveArrayFrom:self.interIndexesDistance toPathName:st];
            }
            self.Loc0_Loci_Vecs = [[NSMutableArray alloc] init];
            for (int i = 0; i<self.locations.count; i++) {
                CLLocation* loci = self.locations[i];
                CLLocation* loc0 = self.locations[0];
                
                float distLociToLoc0 = [[Calc Instance] distanceFromCoords2D:loc0.coordinate toCoords2D:loci.coordinate];
                float headingLoc0ToLoci = [[Calc Instance] headingTo:loci.coordinate fromPosition:loc0.coordinate];
                
                NSLog(@"%0.3f  , %0.3f ",distLociToLoc0,headingLoc0ToLoci);
                Vec* Loc0ToLoci_Vec = [[Vec alloc] initWithNorm:distLociToLoc0 andAngle:headingLoc0ToLoci];
                [self.Loc0_Loci_Vecs addObject:Loc0ToLoci_Vec];
            }
        });
        
    }
    
    
    NSLog(@"circuit %@ length , %0.3f, count , %d ",self.circuitName,self.circuitLength,(int)self.locations.count);
    
    return self;
}

// loading a circuit
-(Circuit*) initWithCircuitNamed:(NSString*) circuitName{
    
    NSString * filePath = [[Calc Instance] pathForFileNamedInSearchPathDirectoriesInDomains:circuitName];
    
    NSMutableArray* circuit = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        circuit = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        DVLog(@"loaded the circuit '%@'",circuitName);
        if (!circuit.count) {
            return nil;
        }
    }
    else {
        DVLog(@"circuit %@ not found",circuitName);
        return nil;
    }
    
    
    return [self initWithLocations:circuit andName:circuitName calc:NO];
}

-(void) update{
    if (!self.circuitName) {
        NSLog(@"empty name");
        return;
    }
    if (!self.locations) {
        NSLog(@"empty locs");
        return;
    }
    if (self.RTH_altitude < 5) {
        NSLog(@"RTH altitude insufficient");
    }
    if (!self.interDistance) {
        self.interDistance = [self calculateInterDistancesOfCircuit:self.locations];
//        NSLog(@"%@",_interDistance);
    }
    
    self.circuitLength = [self length];
    
    if (!self.interAngle) {
        self.interAngle = [self calculateSensCircuitAnglesOfCircuit:self.locations];
    }
    
    if (!self.interIndexesDistance) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.interIndexesDistance = [self calculateInterIndexesDistances2];
            NSLog(@"finished");
            if (!self.courbures) {
                [self calculateCourbure];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_mapView removePinsNamed:@"turnLoc"];
                for (CLLocation* loci in self.turnLocs) {
                    NSUInteger indexInLocs = [self.turnLocs indexOfObject:loci];
                    CLLocation* centeri = [self.turnCenters objectAtIndex:indexInLocs];
//                    [_mapView addPin:centeri andTitle:@"turnLoc" andColor:@"RGB 255 0 0"];
                    NSUInteger index = (int)[self.locations indexOfObject:loci];
//                    NSLog(@"%d -> courb : %0.3f ",(int)index,[self.courbures[index]floatValue]);
                }
            });
            
        });
        
    }
    
    
    if (!self.Loc0_Loci_Vecs) {
        self.Loc0_Loci_Vecs = [[NSMutableArray alloc] init];
        for (int i = 0; i<self.locations.count; i++) {
            CLLocation* loci = self.locations[i];
            CLLocation* loc0 = self.locations[0];
            
            float distLoc0ToLoci = [[Calc Instance] distanceFromCoords2D:loc0.coordinate toCoords2D:loci.coordinate];
            float headingLoc0ToLoci = [[Calc Instance] headingTo:loci.coordinate fromPosition:loc0.coordinate];
            
//            NSLog(@"%0.3f  , %0.3f ",distLoc0ToLoci,headingLoc0ToLoci);
            Vec* Loc0ToLoci_Vec = [[Vec alloc] initWithNorm:distLoc0ToLoci andAngle:headingLoc0ToLoci];
            [self.Loc0_Loci_Vecs addObject:Loc0ToLoci_Vec];
        }
    }
}

// save circuit


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

            float heading = [[Calc Instance] headingTo:locip.coordinate fromPosition:loci.coordinate];

            
            [array addObject:[NSNumber numberWithFloat:heading]];
        }
        float angle = [[Calc Instance] avgAngleOfArray:array];

        [returnArray addObject:[NSNumber numberWithFloat:angle]];
    }
    
    // FILTER 7 angles
    NSMutableArray* avgedInterAngle = [[NSMutableArray alloc] init];
    
    NSMutableArray* sevenFloats = [[NSMutableArray alloc] init];
    
    for (int i = 0; i<returnArray.count; i++) {
        float anglei = [returnArray[i] floatValue];
        
        float newAvgedAngle = [[Calc Instance] filterVar:anglei inArray:sevenFloats angles:YES withNum:7];
        
        [avgedInterAngle addObject:[NSNumber numberWithFloat:newAvgedAngle]];
    }
    
    return avgedInterAngle;
}

-(void) calculateCourbure{
    KalmanFilter1D* KF = [[KalmanFilter1D alloc] init];
    [KF setQ:50 andR:1000000];
    
    
    NSMutableArray* courbure = [[NSMutableArray alloc] init];
    
    NSLog(@"calculate courbure");
    for (int i = 0; i<self.locations.count; i++) {
        
        float anglei = [self.interAngle[(i)%self.locations.count] floatValue];
        float angleip1 = [self.interAngle[(i+1)%self.locations.count] floatValue];
        
        float diffi_ip1 = [[Calc Instance] closestDiffAngle:angleip1 toAngle:anglei];// TO BE FILTERED
        
        float disti = [self.interDistance[i] floatValue];
        float courb = (diffi_ip1/disti);
        [KF filter:courb];
        
        float filtered = KF.state.y[0];
        
//        NSLog(@"dist , %0.3f , angle , %0.3f,filtered, %0.3f,couriip1 , %0.3f",disti,[self.interAngle[i] floatValue],filtered,courb);
        
        [courbure addObject:[NSNumber numberWithFloat:filtered]];
    }
    self.courbures = courbure;
    [self fetchTurnCenters];
}

-(void) fetchTurnCenters{
    NSMutableArray* turnLocs = [[NSMutableArray alloc] init];
    
    
    
    NSArray* sortedLocsWithMaxCourb = [self.locations sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSNumber* num1 = self.courbures[[self.locations indexOfObject:obj1]];
        NSNumber* num2 = self.courbures[[self.locations indexOfObject:obj2]];
        
        float absCourb1 = fabsf([num1 floatValue]);
        float absCourb2 = fabsf([num2 floatValue]);
        
        if (absCourb1 < absCourb2) {
            return NSOrderedDescending;
        }
        else if (absCourb2 < absCourb1){
            return NSOrderedAscending;
        }
        else{
            return NSOrderedSame;
        }
    }];
    
    
    [turnLocs addObject:sortedLocsWithMaxCourb[0]];
    
    for (int i = 0; i<sortedLocsWithMaxCourb.count && turnLocs.count < 5; i++) {
        BOOL fitsInAGroup = NO;
        
        NSUInteger indexi = [self.locations indexOfObject:sortedLocsWithMaxCourb[i]];
        float courbure = [self.courbures[indexi] floatValue];

        NSMutableArray* starti = self.interIndexesDistance[indexi];
        
        for (int j = 0; j< turnLocs.count; j++) {
            NSUInteger indexj = [self.locations indexOfObject:turnLocs[j]];
            float dist = [[starti objectAtIndex:indexj] floatValue];

            if (fabsf(dist) < 80) {
                fitsInAGroup = YES;
            }
        }
        
        if (fabsf(courbure) < 2) {
            break;
        }
        if (!fitsInAGroup ) {
            [turnLocs addObject:sortedLocsWithMaxCourb[i]];
        }
        
    }
    
    NSMutableArray* centers = [[NSMutableArray alloc] init];
    
    for (CLLocation* turnLoci in turnLocs) {
        NSUInteger indexi = [self.locations indexOfObject:turnLoci];
        float courb = [[self.courbures objectAtIndex:indexi] floatValue];
        float angleSens = [self.interAngle[indexi] floatValue];
        
        Vec* angle90 = [[Vec alloc] initWithNorm:1 andAngle:[[Calc Instance] angle180Of330Angle:angleSens+sign(courb)*90]];
        
        CLLocation* locCenteri = [[Calc Instance] locationFrom:turnLoci atDistance:20 atBearing:angle90.angle];
        [centers addObject:locCenteri];
        
    }
    self.turnLocs = turnLocs;
    self.turnCenters = centers;
}


-(float) length{
   
    return [self lengthOfCircuit:self.locations];
        
    
}
-(MKCoordinateRegion) region{
    MKCoordinateRegion regionC = MKCoordinateRegionMake(CLLocationCoordinate2DMake(1, 1), MKCoordinateSpanMake(0.1, 0.1));
    if (!self.locations) {
        return regionC;
    }
    else{
        if (self.locations.count) {
            return [self circuitRegionFromLocations:self.locations];
        }
        else{
            return regionC;
        }
    }
}


-(float) lengthOfCircuit:(NSMutableArray*) circuit{
    float length = 0;
    if (self.locations) {
        if (!self.interDistance) {
            self.interDistance = [self calculateInterDistancesOfCircuit:self.locations];
        }
        for (NSNumber* num in self.interDistance) {
            length += [num floatValue];
        }
    }
    
    
    
    return length;
}




-(CLLocation*) locationAtIndex:(int) index{

    CLLocation* locindex = (CLLocation*)[self.locations objectAtIndex:(index%self.locations.count)];
    return locindex;
}

-(float) distanceOnCircuitfromIndex:(int) startIndex toIndex:(int) endIndex{
    
    NSMutableArray* startIndexArray = self.interIndexesDistance[startIndex%self.locations.count];
    float dist = [[startIndexArray objectAtIndex:endIndex%self.locations.count] floatValue];
    
    return dist;
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

-(float) distanceOnCircuit_interDistances:(NSMutableArray*) circuit fromIndex:(int) startIndex toIndex:(int) endIndex{
    float distance = 0;
    
    for (int i = 0; i<circuit.count ; i++) {
        if ((startIndex+i)%circuit.count == endIndex) {
            break;
        }
        
        float dist2 = [self.interDistance[(startIndex+i)%circuit.count] floatValue];
        
        distance+= dist2;
    }
    return distance;
}

-(NSMutableArray*) calculateInterIndexesDistances:(NSMutableArray*) circuit{
    
    NSMutableArray* returnArray = [[NSMutableArray alloc] init];
    
    for (CLLocation* loci in circuit) {
        NSMutableArray* startIndexArray = [[NSMutableArray alloc] init];
        for (CLLocation* locj in circuit) {
            int indexi = (int)[circuit indexOfObject:loci];
            int indexj = (int)[circuit indexOfObject:locj];
            
            float dist_i_j = [self distanceOnCircuit_interDistances:circuit fromIndex:indexi toIndex:indexj];
            if (dist_i_j > self.circuitLength/2) {
                dist_i_j -= self.circuitLength;
            }
            [startIndexArray addObject:[NSNumber numberWithFloat:dist_i_j]];
        }
        [returnArray addObject:startIndexArray];
        
    }
    return  returnArray;
}

-(NSMutableArray*) calculateInterIndexesDistances2{
    
    NSMutableArray* returnArray = [[NSMutableArray alloc] init];
    // initialisation
    for (int i = 0; i <self.locations.count; i++) {
        NSMutableArray* startIndexArray = [[NSMutableArray alloc] init];
        for (int j=0; j<self.locations.count; j++) {
            [startIndexArray addObject:[NSNumber numberWithFloat:0]];
        }
        [returnArray addObject:startIndexArray];
    }
    
    for (int i = 0 ; i<self.locations.count; i++) {
        
        for (int j = 0; j<self.locations.count; j++) {
            // here we calculate from j to j+i
            float value_j_jpi = 0;
            if (i == 0) {
                value_j_jpi = 0;
            }
            else if (i == 1) {
                value_j_jpi = [self.interDistance[j] floatValue];
            }
            else{
                int k = (j+1)%self.locations.count;
                int l = (j+i)%self.locations.count;
                NSMutableArray* start_j = [returnArray objectAtIndex:j];
                float j_k = [[start_j objectAtIndex:k] floatValue];
                NSMutableArray* start_k = [returnArray objectAtIndex:k];
                float k_jpi = [[start_k objectAtIndex:l] floatValue];
                
                value_j_jpi = j_k + k_jpi;
                
                if (value_j_jpi > self.circuitLength/2) {
                    value_j_jpi -= self.circuitLength;
                }
            }
            NSMutableArray* startIndex_j = [returnArray objectAtIndex:j];
            [startIndex_j replaceObjectAtIndex:(j+i)%self.locations.count withObject:[NSNumber numberWithFloat:value_j_jpi]];
        }
    }
    return  returnArray;
}


-(BOOL) saveArrayFrom:(NSMutableArray*) array toPathName:(NSString*) arrayName{
    NSString* filePath = [[Calc Instance] pathForFileNamedInSearchPathDirectoriesInDomains:arrayName];
    
    return [NSKeyedArchiver archiveRootObject:array toFile:filePath];
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_locations forKey:@"locations"];
    [coder encodeObject:_circuitName forKey:@"circuitName"];
    [coder encodeFloat:_RTH_altitude forKey:@"RTH_Alt"];
    NSLog(@"encode with coder");
}

-(void) decodeObjectForKey:(NSCoder*) coder{
    _locations = [coder decodeObjectForKey:@"locations"];
    _circuitName = [coder decodeObjectForKey:@"circuitName"];
    _RTH_altitude = [coder decodeFloatForKey:@"RTH_Alt"];
    NSLog(@"decode object for key");
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    
    NSMutableArray* locations = [decoder decodeObjectForKey:@"locations"];
    NSString* circuitName = [decoder decodeObjectForKey:@"circuitName"];
    float RTH_alt = [decoder decodeFloatForKey:@"RTH_Alt"];

    Circuit* circuit = [self initWithLocations:locations andName:circuitName calc:NO];
    circuit.RTH_altitude = RTH_alt;
    
    return circuit;
}


@end
