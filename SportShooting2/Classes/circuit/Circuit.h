//
//  Circuit.h
//  SportShooting2
//
//  Created by Othman Sbai on 5/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface Circuit : NSObject{
    
}
@property NSMutableArray* locations; // need to be set
@property float circuitLength;
@property NSString* circuitName; // need to be set
@property NSMutableArray* interDistance;
@property NSMutableArray* interIndexesDistance;
@property NSMutableArray* interAngle;
@property NSMutableArray* diffAngle;
@property NSMutableArray* Loc0_Loci_Vecs;
@property (nonatomic) MKCoordinateRegion region;
@property float RTH_altitude; // need to be set

// NFZ regions
// type of obstacles

// interesting locs

//-(Circuit*) initWithLocations:(NSMutableArray*) circLocs;
//-(Circuit*) initWithLocations:(NSMutableArray*) circLocs andName:(NSString*) circuitName;
-(id) initWithLocations:(NSMutableArray*) circLocs andName:(NSString*) circuitName calc:(BOOL) calc;
-(Circuit*) initWithCircuitNamed:(NSString*) circuitName;


-(float) length;
-(MKCoordinateRegion) region;
-(CLLocation*) locationAtIndex:(int) index;
-(float) distanceOnCircuitfromIndex:(int) startIndex toIndex:(int) endIndex;

-(void) update;


@end