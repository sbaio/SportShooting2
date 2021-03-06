//
//  GeneralMenuVC.h
//  SportShooting
//
//  Created by Othman Sbai on 5/22/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"
#import "AircraftMenuTVC.h"
#import "CircuitMenuTVC.h"
#import <DJISDK/DJISDK.h>
#import "ComponentHelper.h"
#import "MGSwipeTableCell.h"
#import "ComponentHelper.h"


@interface GeneralMenuVC : UITableViewController <MGSwipeTableCellDelegate>
{
    
    
}

@property BOOL realDrone;
@property BOOL isCameraConnected;
@property UISwitch* carSwitch;
@property UISwitch* droneSwitch;

-(void) mapWentRightMost;
-(void) mapWentRight;

-(void) updateDroneSwitchAndLabel;
@end
