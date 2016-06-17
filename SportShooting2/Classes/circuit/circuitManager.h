//
//  circuitManager.h
//  SportShooting2
//
//  Created by Othman Sbai on 5/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVFloatingWindow.h"
#import "Circuit.h"
#import "Calc.h"
#import "Menu.h"

@interface circuitManager : NSObject
{
    Circuit* simulationCircuit;
    NSTimer * carSimulationTimer;
    int carPrevIndex;
    CLLocation* carSimulatedLocation;
    float cumulatedDist;
    
    int carIndexOnSimpleCircuit;
    float carSpeed; // calculated with avgDist / timerInterval
}

@property float simulatedCarSpeed;

+(id) Instance;

-(NSMutableArray*) loadCircuitNamed:(NSString*)circuitName;


-(Circuit*) loadCircuit:(NSString*) circuitName;
-(Circuit*) circuitWithLocations:(NSMutableArray*) locations andName:(NSString*) circuitName;
-(MKCoordinateRegion) circuitRegionFromLocations:(NSMutableArray*) locs;

-(BOOL) saveCircuitFrom:(NSMutableArray*) circuit toPathName:(NSString*) circuitName;


-(NSMutableArray*) halfCircuitOf:(NSMutableArray*) originalCircuit;
-(NSMutableArray*) circuitOfMiddlePointsFrom:(NSMutableArray*) originalCircuit;
-(void) concatenateOrderedCircuits:(NSArray*) arrayOfCircuitsNames intoCircuit:(NSString*) circuitName;

-(NSMutableArray*) repairCircuit:(NSMutableArray*) locations;

-(NSMutableArray*) removeSameLocsFromCircuit:(NSMutableArray*) circuit;



-(void) saveCircuit:(Circuit*) circuit;
-(Circuit*) loadCircuitNamed_coder:(NSString*) circuitName;
-(void) removeCircuitNamed:(NSString*) circuitName;

// CAR SIMULATION
-(void) simulateCarOnCircuit:(Circuit*) circuit;

-(void) pauseCarMovement;
-(void) resumeCarMovement;
@end
