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
#import "MapView.h"

@class MapVC;

@interface AppDelegate : UIResponder <UIApplicationDelegate,DJISDKManagerDelegate,SWRevealViewControllerDelegate,DJIBatteryDelegate,DJIRemoteControllerDelegate,DJICameraDelegate>
{
    int attemptsToRegister;
    BOOL registered;
    SWRevealViewController *menuRevealController;
    SWRevealViewController *mainRevealController;
    
    BOOL isReceivingDroneStateUpdates;

    
    int freqCutterCameraVideoCallback;
    NSDate* lastCameraUpdateDate;
    NSDate* lastRCUpdateDate;
    
    __weak MapVC* mapVC;
    
}
@property (strong, nonatomic) UIWindow *window;
@property(nonatomic,weak) DJIAircraft* realDrone;
@property(nonatomic,strong) PermissionScope * locationPermission;

@property BOOL isReceivingVideoData;
@property BOOL isReceivingRCUpdates;
@property BOOL isReceivingFlightControllerStatus;
@property BOOL isDroneRecording;

@property BOOL isLocationsServicesEnabled;
@property(nonatomic,strong) DJIBatteryState* batteryState;

-(void) promptForLocationServices;


@end

