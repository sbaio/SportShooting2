//
//  CircuitMenuTVC.h
//  SportShooting
//
//  Created by Othman Sbai on 5/23/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapVC.h"
#import "Circuit.h"
#import "circuitManager.h"

@interface CircuitMenuTVC : UITableViewController
{
    Circuit* loadedCircuit;
}

@property Circuit* loadedCircuit;

-(void) updateCircuitList;
@end
