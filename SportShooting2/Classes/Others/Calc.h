//
//  Calc.h
//  SportShooting2
//
//  Created by Othman Sbai on 5/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import <MapKit/MapKit.h>
#import "DVFloatingWindow.h"
#import "Circuit.h"

@interface Calc : NSObject

+ (Calc *) Instance;

-(float) distanceFromCoords2D: (CLLocationCoordinate2D) origin toCoords2D: (CLLocationCoordinate2D) dest;

-(double) headingTo: (CLLocationCoordinate2D ) destination fromPosition:(CLLocationCoordinate2D ) origin;

-(float) angleFromNorthOfVectorWithNorthComponent:(float) vec_N EastComponent:(float) vec_E;

-(float) averageOfArray:(NSMutableArray*) array;

-(float) avgAngleOfArray:(NSMutableArray*) arrayOfAngles;

-(float) closestDiffAngle:(float) gimbalOrDest toAngle:(float) droneOrOrigin;

-(float) angle180Of330Angle:(float) angle330;

-(float) angle330OfAngle:(float) angle withZone:(int) zone;

-(float) CWDiffAngleFromAngle:(float) startAngle ToAngle:(float) destAngle;

-(float) CCWDiffAngleFromAngle:(float) startAngle ToAngle:(float) destAngle;

-(BOOL) angle:(float)angle1 isBetween:(float) angle2 andAngle:(float) angle3;

-(BOOL) isAngle:(float) angle1 toTheRightOfAngle:(float) angle2;

-(float) angleAtPercentage:(float) perc fromAngle:(float) startAngle toAngle:(float) destAngle;

-(float) filterVar:(float) var inArray:(NSMutableArray*) arrayOfVar angles:(BOOL) isVarAngle withNum:(int) num;

-(CLLocationCoordinate2D) predictedGPSPositionFromCurrentPosition:(CLLocationCoordinate2D) currentCoord andCourse:(double) course andSpeed:(double) speed during:(double) dt;

-(NSString*) pathForFileNamedInSearchPathDirectoriesInDomains:(NSString*) fileName;

-(void) removeFileNamed:(NSString*) fileName;

-(CLLocationCoordinate2D) pointBetweenStartPoint:(CLLocationCoordinate2D) point1 andPoint:(CLLocationCoordinate2D) point2 atRatio:(float) ratio;

-(CLLocation*) locationWithCoordinates:(CLLocationCoordinate2D) coord;

-(CLLocation*) locationFrom:(CLLocation*) startLoc atDistance:(float) distance atBearing:(float) bearing;

// MAPVIEW
-(UIColor*) colorFromString:(NSString*) colorString;

-(void) map:(MKMapView*) mapView CenterViewOn:(CLLocationCoordinate2D) locationCoord;

-(void) map:(MKMapView*) mapView drawCircuitPolyline:(NSMutableArray *) circuitCoords;

-(void) map:(MKMapView*) mapView drawCircuitPolyline:(NSMutableArray *) circuitCoords withTitle:(NSString*) title andColor:(NSString*) colorString;

-(void) map:(MKMapView *)mapView removePolylineNamed:(NSString*) polylineName;

-(void) map:(MKMapView*) mapView drawCircuitPins:(NSMutableArray *) circuitCoords;

-(void) map:(MKMapView*) mapView addPin:(CLLocation*) location andTitle:(NSString*) title andColor:(NSString*) colorString;

-(void) map:(MKMapView*) mapView drawCircuitPins:(NSMutableArray *) circuitCoords withColor:(NSString*) colorString;

-(void) map:(MKMapView*) mapView CenterViewOnCar:(CLLocation*) carLoc andDrone:(CLLocation*) droneLoc;

-(void) map:(MKMapView*) mapView addRegion:(CLCircularRegion*) region andTitle:(NSString*) regionName andColor:(NSString*) colorString;

-(void) map:(MKMapView*) mapView removePinsNamed:(NSString*) pinName;

-(void) map:(MKMapView*) mapView addLocations:(NSMutableArray*) locations withName:(NSString*) pinName andColor:(NSString*) colorName;


// CIRCUIT

-(NSMutableArray*) loadCircuitNamed:(NSString*)circuitName;

-(NSMutableArray*) loadArrayNamed:(NSString*) arrayName;

-(float) distanceOnCircuit_interDistances:(Circuit*) circuit fromIndex:(int) startIndex toIndex:(int) endIndex;

-(BOOL) saveArrayFrom:(NSMutableArray*) array toPathName:(NSString*) arrayName;

-(BOOL) isCoord:(CLLocationCoordinate2D) coord1 toTheNorthOfCoord:(CLLocationCoordinate2D) coord2;

-(BOOL) isCoord:(CLLocationCoordinate2D) coord1 toEastOfCoord:(CLLocationCoordinate2D) coord2;
-(void) map:(MKMapView*)mapView showCircuit:(Circuit*) circuit;
@end
