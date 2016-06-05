//
//  CircuitsTVC.h
//  SportShooting
//
//  Created by Othman Sbai on 5/23/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "circuitManager.h"
#import "Circuit.h"
#import "SWRevealViewController.h"
#import "circuitDefinitionTVC.h"

#import "MGSwipeButton.h"
#import "MGSwipeTableCell.h"

#import "CircuitMenuTVC.h"
#import "Menu.h"

@interface CircuitsTVC : UITableViewController <MGSwipeTableCellDelegate>
{
    NSMutableArray* allCircuits;
    SWRevealViewController* MainRevealController;
    SWRevealViewController* MenuRevealController;
    
    Circuit* loadedCircuit;
}

-(void) updateCircuitsList;
@end
