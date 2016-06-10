//
//  MapVC.h
//  SportShooting
//
//  Created by Othman Sbai on 5/22/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#define DV_FLOATING_WINDOW_ENABLE 1

#import <UIKit/UIKit.h>
#import <CoreLocation/CLLocation.h>
#import <MapKit/MapKit.h>

#import <DJISDK/DJISDK.h>
#import "SWRevealViewController.h"
#import "Drone.h"
#import "Autopilot.h"
#import "Calc.h"
#import "Circuit.h"
#import "circuitManager.h"

#import "Menu.h"

#import "VideoPreviewer.h"
#import "MapView.h"

#import "AppDelegate.h"
#import "CircuitsTVC.h"
#import "circuitsListFW.h"
#import "TopMenu.h"
#import "BottomStatusBar.h"

#import "POP.h"

@class MapView;
@class Drone;
@class circuitsListFW;
@class TopMenu;
@class BottomStatusBar;

@interface MapVC : UIViewController<DJIFlightControllerDelegate,MKMapViewDelegate,CLLocationManagerDelegate,UIViewControllerTransitioningDelegate>
{
    __weak SWRevealViewController* mainRevealVC;
    __weak SWRevealViewController* menuRevealVC;
    
    
    Drone* realDrone;
    
    UIPanGestureRecognizer * swipeGR;
    NSMutableArray* swipedCircuit;
    

    CGRect smallSize;
    
    
    CLLocation * phoneLocation;
    CircuitsTVC* circuitListTVC;
    
    UITapGestureRecognizer* mapVCTapGR;
    
    __weak IBOutlet UIView *videoPreviewerView;
    

    // Mapview
    __weak IBOutlet NSLayoutConstraint *mapViewAspectRatio;
    // small layout
    __weak IBOutlet NSLayoutConstraint *mapSmallHeight;
    __weak IBOutlet NSLayoutConstraint *mapSmallX;
    __weak IBOutlet NSLayoutConstraint *mapSmallY;
    
    // large layout
    __weak IBOutlet NSLayoutConstraint *mapLargeHeight;
    __weak IBOutlet NSLayoutConstraint *mapLargeX;
    __weak IBOutlet NSLayoutConstraint *mapLargeY;
    
    // VideoPreviewerView
    
    __weak IBOutlet NSLayoutConstraint *videoViewAspectRatio;
    //small layout
    __weak IBOutlet NSLayoutConstraint *videoSmallHeight;
    __weak IBOutlet NSLayoutConstraint *videoSmallX;
    __weak IBOutlet NSLayoutConstraint *videoSmallY;
    // large layout
    __weak IBOutlet NSLayoutConstraint *videoLargeHeight;
    __weak IBOutlet NSLayoutConstraint *videoLargeX;
    __weak IBOutlet NSLayoutConstraint *videoLargeY;
    
    
    
    NSDate* lastFCUpdateDate;
    int freqCutterCameraFeed;
}
@property (weak, nonatomic) IBOutlet MapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *scrollButton;
@property (strong,nonatomic) Circuit* circuit;
//@property (strong,nonatomic)  /// reference circuit
@property(nonatomic, strong) CLLocationManager* locationManager;
@property (weak, nonatomic) IBOutlet UIButton *recButton;
@property (weak, nonatomic) IBOutlet UILabel *recordingTimeLabel;
@property (weak, nonatomic) IBOutlet circuitsListFW *circuitsList;
@property (strong, nonatomic) IBOutlet TopMenu *topMenu;

@property (strong, nonatomic) IBOutlet BottomStatusBar *bottomStatusBar;
@property (strong, nonatomic) IBOutlet UIView *takeOffAlertView;

@property (weak, nonatomic) IBOutlet UIButton *takeOffButton;
@property (weak, nonatomic) IBOutlet UIButton *landButton;


@property(nonatomic,strong) DJIFlightControllerCurrentState* FCcurrentState;
@property(nonatomic,strong) Autopilot* autopilot;
@property(nonatomic,strong) DJICamera* camera;

@property BOOL isPathDrawingEnabled;


-(void) enableMainMenuPan;
-(void) disableMainMenuPan;

-(void) startUpdatingLoc;
-(void) showCircuitListView;
@end
