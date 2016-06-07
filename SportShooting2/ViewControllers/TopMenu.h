//
//  TopMenu.h
//  SportShooting2
//
//  Created by Othman Sbai on 6/6/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DJISDK/DJISDK.h>
#import "AppDelegate.h"
#import "Menu.h"
#import "ComponentHelper.h"

@class AppDelegate;

@interface TopMenu : UIView
{
    __weak AppDelegate* appD;
    __weak DJIFlightControllerCurrentState* FCcurrentState;
}

-(void) showOn:(UIView*) superview;
-(void) hideFrom:(UIView*) superview;

-(void) updateBatteryLabel;
-(void) updateBatteryLabelWithBatteryState:(DJIBatteryState*) batteryState;
-(void) updateGPSLabel:(int) satelliteCount;

@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *gpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryLabel;

@end
