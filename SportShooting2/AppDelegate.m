//
//  AppDelegate.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/4/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#define ENTER_DEBUG_MODE 0
#define ENABLE_REMOTE_LOGGER 0

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
@synthesize window = _window , isLocationsServicesEnabled,isConnectedToDrone;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    
    mainRevealController = (SWRevealViewController*)[mainStoryboard instantiateInitialViewController];
    [self.window setRootViewController:mainRevealController];
    
    MapVC* mapVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"mainFrontVC"];
    
    menuRevealController = (SWRevealViewController*)[mainStoryboard instantiateViewControllerWithIdentifier:@"mainBackVC"];
    [mainRevealController setFrontVC:mapVC rearVC:menuRevealController];
    
    UINavigationController* navC = [[UINavigationController alloc] init];
    
    UITableViewController* GeneralMenu = [mainStoryboard instantiateViewControllerWithIdentifier:@"generalMenuVC"];
    
    [menuRevealController setFrontVC:navC rearVC:GeneralMenu];
    
    [self setMainAndMenuRevealProperties];
    
    [[Menu instance] setSubmenu:0];
    
    
    isConnectedToDrone = NO;
    
    
    [self registerApp];
    [self initPermissionLocationWhileInUse];
    
    DVWindowShow();

    DVWindowActivationLongPress(1, 0.5);
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - App registration
-(void) sdkManagerDidRegisterAppWithError:(NSError *)error {
    
    if (error) { // try multiple times
        //DVLog(@"attempts to register 
        if (attemptsToRegister < 3 ) {
            sleep(2);
            attemptsToRegister ++;
            registered  = NO;
            [self registerApp];
        }
        else{
            DVLog(@"Registration error : %@",error.localizedDescription);
        }
        
    }
    else {
        DVLog(@"app registered");
        registered = YES;
#if ENTER_DEBUG_MODE
        [DJISDKManager enterDebugModeWithDebugId:@"192.168.168.79"];
#else
                DVLog(@"starting connection to product");
        [DJISDKManager startConnectionToProduct];
#endif
        
#if ENABLE_REMOTE_LOGGER
        [DJISDKManager enableRemoteLoggingWithDeviceID:@"Device ID" logServerURLString:@"Enter Remote Logger URL here"];
#endif
        
        if (attemptsToRegister) {
            DVLog(@"registered after %d attempts !",attemptsToRegister);
#if ENTER_DEBUG_MODE
            
            [DJISDKManager enterDebugModeWithDebugId:@"192.168.0.5"];
#else
            DVLog(@"starting connection to product");
            [DJISDKManager startConnectionToProduct];
#endif
        }
    }
    
}

-(void) sdkManagerProductDidChangeFrom:(DJIBaseProduct* _Nullable) oldProduct to:(DJIBaseProduct* _Nullable) newProduct{
    
    _realDrone = [ComponentHelper fetchAircraft];
    
    if (_realDrone) {
        DVLog(@"Agumon : I'm here");
        
//        //setting delegates

        DVLog(@"getmapVC , %@",[[Menu instance] getMapVC]);
        DJIFlightController* fc = [ComponentHelper fetchFlightController];
        fc.delegate = [[Menu instance] getMapVC];
//
        DJICamera* cam = (DJICamera*)[ComponentHelper fetchCamera];
        DVLog(@"%@",cam);
        cam.delegate = [[Menu instance] getMapVC];
        
        // post notification
        isConnectedToDrone = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"droneConnected" object:self];
        
        
    }else{
        DVLog(@"Agumon : not here");
        isConnectedToDrone = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"droneDisconnected" object:self];
    }
}

-(void) registerApp {
    
    attemptsToRegister = 0;
    registered = NO;
    
    NSString* appKey = @"c0c4b76bc9958412ef245778";
    
    [DJISDKManager registerApp:appKey withDelegate:self];
}


#pragma mark - SWReveal 

-(void) setMainAndMenuRevealProperties{
    // MENU
    
    float generalMenuWidth = 200; // = rearViewRevealWidth+ rearViewRevealOverdraw
    //    float subMenuWidth = 250;// _totalViewWidth - generalMenuWidth
    
    [menuRevealController _initDefaultProperties];
    menuRevealController.rearViewRevealWidth = generalMenuWidth;
    menuRevealController.rearViewRevealOverdraw = 0; // general menu width ...
    menuRevealController.bounceBackOnOverdraw = NO;
    menuRevealController.stableDragOnOverdraw = YES;
    menuRevealController.rearViewRevealDisplacement = 200; // !!!!!
    // modifications !!
    menuRevealController.isLeftViewAboveFront = YES;
    menuRevealController.isViewCropping = YES;
    menuRevealController.alwaysGoRightMost = YES; ///!!!!!
    menuRevealController.totalViewWidth = 467;
    menuRevealController.presentFrontViewHierarchically = NO;
    menuRevealController.delegate = self;
    [menuRevealController.frontViewController.view addGestureRecognizer:menuRevealController.panGestureRecognizer];
    [menuRevealController setFrontViewPosition:FrontViewPositionRightMost animated:NO];
    
    // MAIN
    [mainRevealController _initDefaultProperties];
    
    mainRevealController.rearViewRevealWidth = 200;
    mainRevealController.rearViewRevealOverdraw = 250;
    mainRevealController.bounceBackOnOverdraw = NO;
    mainRevealController.stableDragOnOverdraw = YES;
    mainRevealController.presentFrontViewHierarchically = NO;
    mainRevealController.frontViewShadowOpacity = 0.5;
    mainRevealController.delegate = self;
    
    [mainRevealController.frontViewController.view addGestureRecognizer:mainRevealController.panGestureRecognizer];
    //    [mainRevealController setFrontViewPosition:FrontViewPositionRight animated:NO];
}

-(void) initPermissionLocationWhileInUse{
    _locationPermission = [[PermissionScope alloc]init];
    [_locationPermission addPermission:[[LocationWhileInUsePermission alloc]init] message:@"We use this to track\r\nwhere you live"];
    
    if (_locationPermission.statusLocationInUse == PermissionStatusAuthorized) {
        isLocationsServicesEnabled = YES;
        
        [[[Menu instance] getMapVC] startUpdatingLoc];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"InUseLocEnabled" object:self];
    }
    else {
        isLocationsServicesEnabled = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"InUseLocNotEnabled" object:self];
    }
    
}

-(void) promptForLocationServices{ // in use
    
    [_locationPermission show:^(BOOL completed, NSArray *results) {
        NSLog(@"Changed: %@ - %@", @(completed), results);
        if (completed) {
            isLocationsServicesEnabled = YES;
            [[[Menu instance] getMapVC] startUpdatingLoc];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"InUseLocEnabled" object:self];
        }
        else{
            isLocationsServicesEnabled = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"InUseLocNotEnabled" object:self];
        }
    } cancelled:^(NSArray *x) {
        NSLog(@"cancelled");
        isLocationsServicesEnabled = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"InUseLocNotEnabled" object:self];
    }];
}

-(void) startLocationUpdates{
    
}





@end
