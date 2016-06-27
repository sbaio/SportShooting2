//
//  pathPlanner.h
//  SportShooting2
//
//  Created by Othman Sbai on 6/16/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Circuit.h"
#import "Drone.h"
#import "MapView.h"
#import "Aircraft_Camera_Car_Annotation.h"

@class MapView;
@class Circuit;
@class Drone;


typedef struct{
    BOOL isInit;     
    BOOL isRunning;
    
    BOOL carStopped;
    BOOL carIsComing;
    BOOL carLeft;
    BOOL catchingCar;
    
    // drone
    BOOL isDroneCloseToItsIndex;
    BOOL isDroneCloseToCar;
    
    BOOL isDroneShortcutting;
    BOOL isDroneCloseTracking;
    
    
} pathPlannerStatus;

@interface pathPlanner : NSObject <DJIMissionManagerDelegate>
{
    __weak MapView* mapView;
    __weak MapVC* mapVC;
    
    NSString* redColorString;
    NSString* yellowColorString;
    
    CLLocation* carLocation;
    Circuit* circuit;
    
    Drone* _drone;
    
    // dates
    NSDate* lastFollowDate;
    NSDate* lastCarIsComingNotifDate;
    NSDate* lastCarHasLeftNotifDate;
    NSDate* lastCatchingCarNotifDate;
    
    Vec* orthoSpeed_Vec;
    Vec* radialSpeed_Vec;
    
    Aircraft_Camera_Car_Annotation* radialVec_Anno;
    Aircraft_Camera_Car_Annotation* orthoVec_Anno;
    
    // PID dist control
    float previousError;
    float derivativeError;
    float integralError;
    
    
    // PID droneDistIndex
    float integralDistError;
    
    float integralDistErrorSensCircuit;
    
}


@property int carIndexOnCircuit;

@property Drone* predictedDrone;

@property pathPlannerStatus status;

@property float Kp;
@property float Ki;
@property float Kd;

@property CLLocation* targetLocationFollow;

-(void) follow:(CLLocation*) carLoc onCircuit:(Circuit*) circ drone:(Drone*) drone;
-(void) follow2:(CLLocation*) carLoc onCircuit:(Circuit*) circ drone:(Drone*) drone;


@end
