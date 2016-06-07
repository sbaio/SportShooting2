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

#import <PermissionScope/PermissionScope-Swift.h>

#import "VideoPreviewer/VideoPreviewer.h"
#import "MapVC.h"
#import "circuitsListFW.h"
#import "MapView.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate,DJISDKManagerDelegate,SWRevealViewControllerDelegate,DJIBatteryDelegate,DJIRemoteControllerDelegate,DJICameraDelegate>
{
    int attemptsToRegister;
    BOOL registered;
    SWRevealViewController *menuRevealController;
    SWRevealViewController *mainRevealController;
    
    
//    BOOL isConnectedToDrone;
    BOOL isReceivingDroneStateUpdates;
    BOOL isReceivingVideoData;
    BOOL isReceivingRCUpdates;
//    BOOL isLocationsServicesEnabled;
    
    int testC;
    
    NSDate* lastCameraUpdateDate;
    
}
@property (strong, nonatomic) UIWindow *window;
@property(nonatomic,weak) DJIAircraft* realDrone;
@property(nonatomic,strong) PermissionScope * locationPermission;
@property BOOL isConnectedToDrone;
@property BOOL isLocationsServicesEnabled;
@property(nonatomic,strong) DJIBatteryState* batteryState;

-(void) promptForLocationServices;


@end

