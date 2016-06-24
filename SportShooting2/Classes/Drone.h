//
//  Drone.h
//  SportShooting2
//
//  Created by Othman Sbai on 5/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import "Aircraft_Camera_Car_Annotation.h"
#import "Circuit.h"
#import "Calc.h"
#import "SWRevealViewController.h"
#import "Menu.h"
#import <DJISDK/DJISDK.h>
#import "Vec.h"

@class Circuit;

@protocol droneDelegate <NSObject>

@optional

@end


@interface Drone : NSObject
{
    // drone yaw speed estimation
    float prevDroneYaw;
    NSMutableArray* arrayOfDroneYawDiff;
    NSMutableArray* arrayOfDroneYawSp;
    
    int freqCalcIndex;
}

//@property (weak, nonatomic) MKMapView* mapView;
@property CLLocation* droneLoc; // GPS pos , alt, velocity .. when realDrone updated in callback at init
@property int droneIndexOnCircuit;
@property CLLocation* droneIndexLocation;

@property float droneDistToItsIndex;

@property float droneYaw;
@property float droneYawSpeed;

// gimbal
@property float gimbalYawEarth;
@property float gimbalTargetYawEarth;
@property float gimbalCurrent330yaw;

@property float previousGDDiffAngle; 
@property float gimbalCurrentBearingInDroneBC;
@property int gimbalZone;


@property CLLocation* targetLocation;

@property Aircraft_Camera_Car_Annotation* droneAnno;
@property Aircraft_Camera_Car_Annotation* gimbalAnno;
@property Aircraft_Camera_Car_Annotation* droneSpeed_vecAnno;
@property Aircraft_Camera_Car_Annotation* droneTargSpeed_vecAnno;


@property Aircraft_Camera_Car_Annotation* sensCircuit_Anno;
@property Aircraft_Camera_Car_Annotation* versCircuit_Anno;
@property Aircraft_Camera_Car_Annotation* sensNextCenter_Anno;

@property float distanceToCar;
@property float bearingToCar;
@property float distanceOnCircuitToCar;

@property Vec* carSpeed_Vec;
@property Vec* droneSpeed_Vec;
@property Vec* droneCar_Vec;

@property Vec* drone_Loc0_Vec;

@property Vec* sensCircuit;
@property Vec* versCircuit;
@property Vec* sensNextCenter;

@property float targSp;
@property float targHeading;

@property float V_parralele;
@property float V_perp;

@property BOOL isCloseTracking;
@property BOOL realDrone;

@property NSMutableArray* arrayOfKeyLocations;

-(void) initWithDrone:(DJIAircraft*) realDrone;
-(id) initWithLocation:(CLLocation*) loc;
-(void) updateDroneStateWithLoc:(CLLocation*) droneLoc andYaw:(float) yaw;
//-(void) calculateDroneInfoOnCircuit:(Circuit*) circuit forCarLocation:(CLLocation*) carLoc carIndex:(int) carIndex;
-(void) calculateDroneInfoOnCircuit:(Circuit*) circuit forCarLocation:(CLLocation*) carLoc carIndex:(int) carIndex calcIndex:(BOOL) calc;
-(void) estimateDroneYawSpeed:(float) currentYaw;

-(void) updateDroneStateWithFlightControllerState:(DJIFlightControllerCurrentState*) state;

-(Drone*) newDroneStateFrom:(Drone*) currentDroneState withTargetSpeed:(float) targSp andTargetAngle:(float) targHeading andTargAltitude:(float) targAlt during:(float) dt;

-(float) timeForDroneToReachLoc:(CLLocation*) targetLoc andTargetSpeed:(float) targSpeed;

@end
