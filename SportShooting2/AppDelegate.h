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

#import "VideoPreviewer/VideoPreviewer.h"
#import "FrontVC.h"
#import "MapView.h"

@class FrontVC;

@interface AppDelegate : UIResponder <UIApplicationDelegate,DJISDKManagerDelegate,SWRevealViewControllerDelegate,DJIBatteryDelegate,DJIRemoteControllerDelegate,DJICameraDelegate,CLLocationManagerDelegate>
{
    int attemptsToRegister;
    BOOL registered;
    SWRevealViewController *menuRevealController;
    SWRevealViewController *mainRevealController;
    
    BOOL isReceivingDroneStateUpdates;

    
    int freqCutterCameraVideoCallback;
    NSDate* lastCameraUpdateDate;
    NSDate* lastRCUpdateDate;
    
    CLLocationManager* locManager;
    
    __weak FrontVC* frontVC;
    
    DJIRCHardwareFlightModeSwitchState prevSwitchState;
    
}
@property (strong, nonatomic) UIWindow *window;
@property(nonatomic,weak) DJIAircraft* realDrone;
@property BOOL isReceivingVideoData;
@property BOOL isReceivingRCUpdates;
@property BOOL isReceivingFlightControllerStatus;
@property BOOL isDroneRecording;

@property BOOL isRCSwitch_F;

@property BOOL isLocationsServicesEnabled;
@property(nonatomic,strong) DJIBatteryState* batteryState;

-(void) promptForLocationServices;


@end

