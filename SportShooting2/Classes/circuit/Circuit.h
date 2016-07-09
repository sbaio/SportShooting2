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
#import "MapView.h"

@class MapView;

@interface Circuit : NSObject{
    
}
@property NSMutableArray* locations; // need to be set
@property float circuitLength;
@property NSString* circuitName; // need to be set
@property NSMutableArray* interDistance; // distance between a loc i and the loc i+1
@property NSMutableArray* interIndexesDistance; // 2D array of distance between  loc i and a loc j
@property NSMutableArray* interAngle; // angle of circuit at loc i .. should be smooth and averaged
@property NSMutableArray* courbures;
@property NSMutableArray* turnLocs; // locations of circuit where courbure is high and
@property NSMutableArray* turnCenters;
@property NSMutableArray* Loc0_Loci_Vecs;
@property (nonatomic) MKCoordinateRegion region;
@property float RTH_altitude; // need to be set by user
@property __weak MapView* mapView;



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