//
//  Circuit.m
//  SportShooting2
//
//  Created by Othman Sbai on 5/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

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
    
    if (calc) {
        self.interAngle = [self calculateSensCircuitAnglesOfCircuit:self.locations];
        [self calculateCourbureCircuit:self.locations];
        self.interIndexesDistance = [[Calc Instance] loadArrayNamed:[NSString stringWithFormat:@"distances%@",self.circuitName]];
        if (!self.interIndexesDistance) {
            self.interIndexesDistance = [self calculateInterIndexesDistances:self.locations];
            NSString* st = [NSString stringWithFormat:@"distances%@",self.circuitName];
            [self saveArrayFrom:self.interIndexesDistance toPathName:st];
        }
        self.distLociTo_Vec = [[NSMutableArray alloc] init];
        for (int i = 0; i<circLocs.count; i++) {
            CLLocation* loci = circLocs[i];
            CLLocation* droneLoc = circLocs[0];
            float distLociDrone = [[Calc Instance] distanceFromCoords2D:droneLoc.coordinate toCoords2D:loci.coordinate];
            float headingDroneToLoci = [[Calc Instance] headingTo:loci.coordinate fromPosition:droneLoc.coordinate];
            
            Vec* droneToLoci_Vec = [[Vec alloc] initWithNorm:distLociDrone andAngle:headingDroneToLoci];
            [self.distLociTo_Vec addObject:droneToLoci_Vec];
        }
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
    
    
    return [self initWithLocations:circuit andName:circuitName];
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

-(NSMutableArray*) calculateCourbureCircuit:(NSMutableArray*) circuit{
    // start from interAngle and interDistance
    KalmanFilter1D* KF = [[KalmanFilter1D alloc] init];
    [KF setQ:50 andR:1000000];
    
    
    NSMutableArray* courbure = [[NSMutableArray alloc] init];

    NSLog(@"calculate courbure");
    for (int i = 0; i<self.locations.count; i++) {

        float anglei = [self.interAngle[(i)%circuit.count] floatValue];
        float angleip1 = [self.interAngle[(i+1)%circuit.count] floatValue];
        
        float diffi_ip1 = [[Calc Instance] closestDiffAngle:angleip1 toAngle:anglei];// TO BE FILTERED
        
        [KF filter:diffi_ip1];
        
        float filtered = KF.state.y[0];
        
//        NSLog(@"dist , %0.3f , angle , %0.3f,filtered, %0.3f,couriip1 , %0.3f",[self.interDistance[i] floatValue],[self.interAngle[i] floatValue],filtered,diffi_ip1);
        
        [courbure addObject:[NSNumber numberWithFloat:filtered]];
    }
    return courbure;
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
