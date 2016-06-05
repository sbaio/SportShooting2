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


@interface GeneralMenuVC : UITableViewController <MGSwipeTableCellDelegate>
{
    
}

@property (strong, nonatomic) IBOutlet UISwitch* realDroneSwitch; // set manually by  usert to set either real drone or simulated drone .. to simulate the race ..
@property BOOL isDroneConnected;
@property BOOL realDrone;
@property BOOL isCameraConnected;
@property BOOL isDroneRecordingVideo;


-(void) mapWentRightMost;
-(void) mapWentRight;
@end
