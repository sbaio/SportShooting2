//
//  AppDelegate.h
//  SportShooting2
//
//  Created by Othman Sbai on 6/4/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#define DV_FLOATING_WINDOW_ENABLE 1

#import <UIKit/UIKit.h>
#import <DJISDK/DJISDK.h>
#import "SWRevealViewController.h"
#import "ComponentHelper.h"
#import "DVFloatingWindow.h"

#import "MapVC.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate,DJISDKManagerDelegate,SWRevealViewControllerDelegate>
{
    int attemptsToRegister;
    BOOL registered;
    SWRevealViewController *menuRevealController;
    SWRevealViewController *mainRevealController;
}
@property (strong, nonatomic) UIWindow *window;
@property(nonatomic,weak) DJIAircraft* realDrone;


@end

