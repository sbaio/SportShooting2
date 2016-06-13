//
//  MapVC.m
//  SportShooting
//
//  Created by Othman Sbai on 5/22/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

// problem when glview doesnt update when stream ended .. need to ask for adjustSize

#define WeakRef(__obj) __weak typeof(self) __obj = self
#define WeakReturn(__obj) if(__obj ==nil)return;

#import "MapVC.h"
#import "GeneralMenuVC.h"
#import "circuitDefinitionTVC.h"


#import "PresentingAnimationController.h"
#import "DismissingAnimationController.h"

#import "UIImage+animatedGIF.h"
#import "UIColor+CustomColors.h"

@import Photos;

@interface MapVC ()

@end

@implementation MapVC
@synthesize mapView,isPathDrawingEnabled;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadNibs];
    [self initUI];
    
    
    mainRevealVC = [[Menu instance] getMainRevealVC];
    menuRevealVC = [[Menu instance] getMenuRevealVC];
    
    [self initMapView];
    [self initVideoPreviewerView];
    
    [self showTopMenu]; // and bottom
    appD = [[Menu instance] getAppDelegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGoButton:) name:@"startedDriving" object:nil];
    
}

-(void) loadNibs{
    [[[NSBundle mainBundle] loadNibNamed:@"TopMenu" owner:self options:nil] firstObject];
    
    [[[NSBundle mainBundle] loadNibNamed:@"BottomStatusBar" owner:self options:nil] firstObject];

    [[NSBundle mainBundle] loadNibNamed:@"circuitsListFW" owner:self options:nil];
    
   
}
-(void) initUI{
    [_GoButton.layer setCornerRadius:8];
    [_GoButton setHidden:YES];
}

-(void) showTopMenu{
    
    [_topMenu showOn:self.view];
    
    
    [_bottomStatusBar showOn:self.view];

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - mapView

-(void) startUpdatingLoc{
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
    }
    
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
}

-(void) initMapView{
    
    mapView.mapVC = self;
    

   swipeGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeOnScreen:)];
    
    [self.view addGestureRecognizer:swipeGR];


    mapView.tapGRMapVideoSwitching = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchMapAndVideoViews:)];
    [mapView addGestureRecognizer:mapView.tapGRMapVideoSwitching];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    _phoneLocation = _locationManager.location;
    
    if(_phoneLocation.coordinate.longitude && _phoneLocation.coordinate.latitude){
        if ([[Calc Instance] distanceFromCoords2D:mapView.region.center toCoords2D:_phoneLocation.coordinate] > 10000) {
            [mapView setRegion:MKCoordinateRegionMake(_phoneLocation.coordinate, MKCoordinateSpanMake(0.03, 0.03)) animated:YES];
        }
        
    }
    else{
        _phoneLocation = nil;
    }
    
    _autopilot.userLocation = _phoneLocation;
    
}

#pragma mark - video previewer view

-(void) initVideoPreviewerView{

    [[VideoPreviewer instance] setDecoderDataSource:kDJIDecoderDataSoureInspire]; // hardware decode
    
    [[VideoPreviewer instance] setView:videoPreviewerView];
    
    [VideoPreviewer instance].tapGRSwitching = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(switchMapAndVideoViews:)];

    [[VideoPreviewer instance] start];
    
    freqCutterCameraFeed = 0;
}

-(void) enlargeVideo_MakeMapSmall_updateConstraints{
    // remove video constraints from superview constraints .. this will keep video aspect
    [_contentView removeConstraints:[NSArray arrayWithObjects:mapSmallHeight,mapSmallX,mapSmallY,mapLargeHeight,mapLargeX,mapLargeY, nil]];
    [_contentView removeConstraints:[NSArray arrayWithObjects:videoLargeHeight,videoLargeX,videoLargeY,videoSmallHeight,videoSmallX,videoSmallY, nil]];
    
    [_contentView addConstraints:[NSArray arrayWithObjects:mapSmallHeight,mapSmallX,mapSmallY, nil]];
    [_contentView addConstraints:[NSArray arrayWithObjects:videoLargeHeight,videoLargeX,videoLargeY, nil]];
    
}

-(void) enlargeMap_MakeVideoSmall_updateConstraints{
    
    [_contentView removeConstraints:[NSArray arrayWithObjects:mapSmallHeight,mapSmallX,mapSmallY,mapLargeHeight,mapLargeX,mapLargeY, nil]];
    [_contentView removeConstraints:[NSArray arrayWithObjects:videoLargeHeight,videoLargeX,videoLargeY,videoSmallHeight,videoSmallX,videoSmallY, nil]];
    
    [_contentView addConstraints:[NSArray arrayWithObjects:mapLargeHeight,mapLargeX,mapLargeY, nil]];
    [_contentView addConstraints:[NSArray arrayWithObjects:videoSmallHeight,videoSmallX,videoSmallY, nil]];
}

-(void) switchToVideo{
    BOOL isVideoMain = (videoPreviewerView.frame.size.width == [[UIScreen mainScreen]bounds].size.width);
    if (isVideoMain) {
        return;
    }
    void (^completionWhenFinishedShowingVideo)(BOOL) = ^(BOOL finished)
    {
        [mapView updateMaskImageAndButton];
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            
            mapView.alpha = 1.0;
        } completion:nil];
        
    };
    if (CGRectIsEmpty(smallSize)) {
        smallSize = videoPreviewerView.frame;
    }
    
    [mapView setMapViewMaskImage:NO];
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        mapView.alpha = 0.5;//1
        [mapView setFrame:smallSize];
        
    } completion:completionWhenFinishedShowingVideo];
    [self enlargeVideo_MakeMapSmall_updateConstraints];
    [_contentView sendSubviewToBack:videoPreviewerView];
    [mapView enableMapViewScroll];
    
    [videoPreviewerView setFrame:[[UIScreen mainScreen] bounds]];
    [[VideoPreviewer instance].glView adjustSize];
    
    [mapView addGestureRecognizer:mapView.tapGRMapVideoSwitching];
    [[VideoPreviewer instance].glView addGestureRecognizer:[VideoPreviewer instance].tapGROnLargeView];
    [[VideoPreviewer instance].glView removeGestureRecognizer:[VideoPreviewer instance].tapGRSwitching];
}
-(void) switchToMap{
    BOOL isMapMain = (mapView.frame.size.width == [[UIScreen mainScreen]bounds].size.width);
    if (isMapMain) {
        return;
    }
    void (^completionWhenFinishedShowingMap)(BOOL) = ^(BOOL finished)
    {
        [_contentView sendSubviewToBack:mapView];
        [mapView updateMaskImageAndButton];
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            videoPreviewerView.alpha = 1.0;
            mapView.alpha = 1.0;
        } completion:nil];
    };
    // enlarge map
    if (CGRectIsEmpty(smallSize)) {
        smallSize = mapView.frame;
    }
    [mapView setMapViewMaskImage:NO];
    
    [UIView animateWithDuration:0.9 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        videoPreviewerView.alpha = 0.8;
        
        mapView.alpha = 0.8;//1
        [mapView setFrame:[[UIScreen mainScreen] bounds]];
        
    } completion:completionWhenFinishedShowingMap];
    
    [self enlargeMap_MakeVideoSmall_updateConstraints];
    [videoPreviewerView setFrame:smallSize];
    [[VideoPreviewer instance].glView adjustSize];
    [mapView enableMapViewScroll];
    
    [mapView removeGestureRecognizer:mapView.tapGRMapVideoSwitching];
    [[VideoPreviewer instance].glView removeGestureRecognizer:[VideoPreviewer instance].tapGROnLargeView];
    [[VideoPreviewer instance].glView addGestureRecognizer:[VideoPreviewer instance].tapGRSwitching];
    
    // circuit selection part
    if (!self.circuit) {
        [self showCircuitListView];
    }
}
-(void)switchMapAndVideoViews:(UITapGestureRecognizer*) tap{
    
    BOOL isVideoMain = (videoPreviewerView.frame.size.width == [[UIScreen mainScreen]bounds].size.width);
    
    if (isVideoMain) {
        [self switchToMap];
    
        
    }
    else{
        [self switchToVideo];
    }
}
#pragma mark - drone state callback

- (void)flightController:(DJIFlightController *)fc didUpdateSystemState:(DJIFlightControllerCurrentState *)state{

    _FCcurrentState = state;
    _autopilot.FCcurrentState = state;
    
    [[[Menu instance] getTopMenu] updateGPSLabel:state.satelliteCount];
    if (!realDrone) {
        realDrone = [[Drone alloc] initWithLocation:[[Calc Instance] locationWithCoordinates:state.aircraftLocation]];
    }
    else{

        [realDrone updateDroneStateWithFlightControllerState:state];
    }
    
    lastFCUpdateDate = [[NSDate alloc] init];
    if (!appD.isReceivingFlightControllerStatus) {
        [appD setIsReceivingFlightControllerStatus:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FCFeedStarted" object:self];
    }
    [appD setIsReceivingFlightControllerStatus:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (lastFCUpdateDate) {
            float timeSinceLastUpdate = -[lastFCUpdateDate timeIntervalSinceNow];
            
            if (timeSinceLastUpdate > 0.7) {
                [appD setIsReceivingFlightControllerStatus:NO];
                DVLog(@"FC feed stopped");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"FCFeedStopped" object:self];
                // Notification
                lastFCUpdateDate = nil;
                return;
            }
        }
    });
//    
//    if (state.isUltrasonicBeingUsed) {
//        [_bottomStatusBar updateAltitudeLabelWithAltitude:state.ultrasonicHeight];
//    }
//    else{
        [_bottomStatusBar updateWith:state andPhoneLocation:_phoneLocation];
//        [_bottomStatusBar updateDistanceToRCLabelWithDistance:-1];
//    }
    
}


-(void) enableMainMenuPan{
    [self.view addGestureRecognizer:mainRevealVC.panGestureRecognizer];
    [mapView setScrollEnabled:NO];
}
-(void) disableMainMenuPan{
    [self.view removeGestureRecognizer:mainRevealVC.panGestureRecognizer ];
    [mapView setScrollEnabled:YES];
    // will give scroll back to mapview, to pan on map disableScroll
}

- (IBAction)onScrollButtonClicked:(id)sender {
    
    if ([mapView isScrollEnabled]) {
        [mapView disableMapViewScroll];
    }
    else{
        [mapView enableMapViewScroll];
    }
}

-(void) didSwipeOnScreen:(UIPanGestureRecognizer*) pan{
    if (isPathDrawingEnabled) {
        if (pan.state == UIGestureRecognizerStateBegan){
            swipedCircuit = [[NSMutableArray alloc] init];
            
            // mapview to remove pins
            [[Calc Instance] map:mapView removePinsNamed:@"panLoc"];
            [[Calc Instance] map:mapView removePolylineNamed:@"poly"];
        }
        else if(pan.state == UIGestureRecognizerStateChanged){
            // get the coordinate
            CGPoint point = [pan locationInView:mapView];
            CLLocationCoordinate2D newCoord =[mapView convertPoint:point toCoordinateFromView:mapView];
            CLLocation* newLoc = [[Calc Instance] locationWithCoordinates:newCoord];
            [swipedCircuit addObject:newLoc];
            
            [[Calc Instance] map:mapView addPin:newLoc andTitle:@"panLoc" andColor:@"RGB 212 175 55"];
        }
        else if (pan.state == UIGestureRecognizerStateEnded){
            
            // traitement du circuit avant enregistrement
            circuitManager* cm = [circuitManager Instance];
            
            swipedCircuit = [cm removeSameLocsFromCircuit:swipedCircuit];
            
            swipedCircuit = [cm repairCircuit:swipedCircuit];
            
            
            [[Calc Instance] map:mapView removePinsNamed:@"panLoc"];
            

            [[Calc Instance] map:mapView drawCircuitPolyline:swipedCircuit withTitle:@"poly" andColor:@"RGB 212 175 55"];
            
            isPathDrawingEnabled = NO;
            [self enableMainMenuPan];
            
            NSDictionary *aDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:swipedCircuit,@"locations", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"panCircuitEnded" object:nil userInfo:aDictionary];
            return;
            
            UINavigationController* navC = (UINavigationController*)menuRevealVC.frontViewController;
            NSArray* arrayOfControllers = navC.viewControllers;
            
            circuitDefinitionTVC* tvc = (circuitDefinitionTVC*)arrayOfControllers[1];
            tvc.loadedCircuit.locations = swipedCircuit;
            
            
            if (tvc.loadedCircuit.circuitName) {
                [cm saveCircuit:tvc.loadedCircuit];
                DVLog(@"saving circuit %@ ,count ,%d",tvc.loadedCircuit.circuitName,(int)swipedCircuit.count);
            }
            
            [mainRevealVC setFrontViewPosition:FrontViewPositionRight];
            
            
            
            [tvc.tableView reloadData];
            
            
        }
    }
}



-(void) setCameraRecordMode{
    WeakRef(target);
    __weak DJICamera* camera = [ComponentHelper fetchCamera];
    [camera setCameraMode:DJICameraModeRecordVideo withCompletion:^(NSError * _Nullable error) {
        WeakReturn(target);
        if (error) {
            DVLog(@"ERROR: setCameraMode:withCompletion:. %@", error.description);
        }
        else {
            // Normally, once an operation is finished, the camera still needs some time to finish up
            // all the work. It is safe to delay the next operation after an operation is finished.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                WeakReturn(target);
                DVLog(@"Camera set to record mode");
            });
        }
    }];
}

-(void) startRecord{
    [self setCameraRecordMode];
    __weak DJICamera* camera = [ComponentHelper fetchCamera];
    if (camera) {
        [camera startRecordVideoWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                DVLog(@"ERROR: startRecordVideoWithCompletion:. %@", error.description);
            }
        }];
    }else{
        DVLog(@"start record: No Camera");
    }
}
-(void) stopRecord{
    __weak DJICamera* camera = [ComponentHelper fetchCamera];
    if (camera) {
        [camera stopRecordVideoWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                DVLog(@"ERROR: stopRecordVideoWithCompletion:. %@", error.description);
            }
        }];
    }else{
        DVLog(@"stop record: No camera");
    }
}

- (IBAction)didClickOnRecButton:(id)sender {
//    AppDelegate* appD = [[Menu instance] getAppDelegate];
//    
//    if (!appD.isDroneRecording) {
//        [self startRecord];
//    }
//    else{
//        [self stopRecord];
//    }

//    [_alertsView showTakeOffAlert];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startedDriving" object:nil];
}


-(void) showCircuitListView{
    
    [_circuitsList initWithDefaultsProperties];
    
    mapVCTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnMapVC:)];
    
    [self.view addGestureRecognizer:mapVCTapGR];
    
    [_circuitsList showCircuitList:YES];
}

-(void) didTapOnMapVC:(UITapGestureRecognizer*) tapGR{
    NSLog(@"tap on mapVC , %@",NSStringFromCGPoint([tapGR locationInView:self.view]));
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [[PresentingAnimationController alloc] init];
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[DismissingAnimationController alloc] init];
}

- (IBAction)onTakeOffButtonClicked:(id)sender {
    [_alertsView showTakeOffAlert];
}
- (IBAction)onLandButtonClicked:(id)sender {
    DJIFlightController* fc = [ComponentHelper fetchFlightController];
    // set landing icon to gif
    if (fc) {
        DVLog(@"landing");
        [fc autoLandingWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                DVLog(@"landing error : %@",error.localizedDescription);
                // set landing icon to fix image
            }
            else{
                DVLog(@"landing succeded");
            }
        }];
        return;
    }
    else{
        DVLog(@"Flight controller not found");
        return;
    }
}

-(BOOL) isShowingCircuitList{

    if ([[[UIApplication sharedApplication]keyWindow].subviews containsObject:_circuitsList]) {
        return YES;
    }
    else{
        return NO;
    }
    
}

-(void) handleGoButton:(NSNotification*) notif{
    if ([_GoButton isHidden]) {
        [_GoButton setHidden:NO];
    }
    else{
        [_GoButton setHidden:YES];
        
    }
}
- (IBAction)didClickOnGoButton:(id)sender {
    // when detected driving .. popup to ask if drone should start following/ moving
    [self startMission];
}


-(void) startMission{
    _isRealDrone = NO;
    _isRealCar = NO;
    
    if (!_circuit) {
        NSLog(@"no circuit");
        return;
    }
    
    // ***********  CAR ***********
    if (!_isRealCar) {
        // start simulation --> callback --> carLocation contains current car location
        [[circuitManager Instance]simulateCarOnCircuit:_circuit];
    }
    // ***********  Drone ***********
    if (!_isRealDrone) {
        
        CLLocation* simulatedDroneStartLocation = _circuit.locations[0];
        droneSimulatedLoc = [[CLLocation alloc] initWithCoordinate:simulatedDroneStartLocation.coordinate altitude:10 horizontalAccuracy:1 verticalAccuracy:1 course:0 speed:0 timestamp:[[NSDate alloc]init]];
        
        _simulatedDrone = [[Drone alloc] initWithLocation:droneSimulatedLoc];
    }
    
    // ********** PATH PLANNING TIMER *********
    if(pathPlanningTimer){
        [pathPlanningTimer invalidate];
        pathPlanningTimer = nil;
    }
    
    pathPlanningTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onPathPlanningTimerTicked) userInfo:nil repeats:YES];
    
    pathPlanningTimer.tolerance = 0.01;
    
    startMissionDate = [[NSDate alloc] init]; // initialisation de la date reference de start mission
    countFollow = 0;
    refDate = [[NSDate alloc] init];
}


-(void) carAtLocation:(CLLocation*) location{
    
    if (_isRealCar) {
        if (location.speed < 0) {
            NSLog(@"location with negative speed");
            _carLocation = nil;
            return;
        }
        else{
            _carLocation = location;
            // display the speed !!!
        }
    }
    else{
        _carLocation = location;
    }
    [mapView updateCarLocation:_carLocation];
    
}

-(void) onPathPlanningTimerTicked{
    _isRealDrone = NO;
    _isRealCar = NO;
    
    if (!_isRealDrone) {// SIMULATED DRONE
        if (_circuit.locations.count) {
            
            _simulatedDrone = [_simulatedDrone newDroneStateFrom:_simulatedDrone withTargetSpeed:10 andTargetAngle:0 andTargAltitude:10 during:0.1];
            [mapView updateDroneAnnotation:_simulatedDrone];
            
            if (commandByTargetLocation) {
                // MOVE SIMULATED DRONE WITH TARGET LOCATION
                
            }
            else{
                
            }
        }
        else{
            NSLog(@"simple circuit not loaded yet");
            return;
        }
    }
    else{ // REAL DRONE
         // ********* GIMBAL COMMAND **********
        
        
        // ********* PATH PLANNING ************
    }
}


@end
