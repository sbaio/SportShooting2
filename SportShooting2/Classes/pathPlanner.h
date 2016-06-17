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

@class MapView;

typedef struct{
    BOOL isInit;     
    BOOL isRunning;
    
    BOOL carIsComing;
    BOOL carLeft;
    
    
    BOOL isDroneCloseToItsIndex;
    BOOL isDroneCloseToCar;
    
    BOOL isDroneShortcutting;
} pathPlannerStatus;

@interface pathPlanner : NSObject
{
    __weak MapView* mapView;
    __weak MapVC* mapVC;
    
    NSString* redColorString;
    NSString* yellowColorString;
    
    CLLocation* carLocation;
    Circuit* circuit;
    
    Drone* _drone;
    
    // dates
    NSDate* lastCarIsComingNotifDate;
}

@property int carIndexOnCircuit;

@property Drone* predictedDrone;

@property pathPlannerStatus status;

-(void) follow:(CLLocation*) carLoc onCircuit:(Circuit*) circ drone:(Drone*) drone;
-(void) follow2:(CLLocation*) carLoc onCircuit:(Circuit*) circ drone:(Drone*) drone;


@end
