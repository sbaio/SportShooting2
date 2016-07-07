//
//  FrontVC.m
//  SportShooting
//
//  Created by Othman Sbai on 5/22/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

// move to new SDK
// try the active track mission
// try the follow me mission with a bike


#define WeakRef(__obj) __weak typeof(self) __obj = self
#define WeakReturn(__obj) if(__obj ==nil)return;
#define sign(a) ( ( (a) < 0 )  ?  -1   : ( (a) > 0 ) )
#define bindBetween(a,b,c) ((a > c) ? c: ((a<b)? b:a))
#define DEGREE(x) ((x)*180.0/M_PI)
#define RADIAN(x) ((x)*M_PI/180.0)

#import "FrontVC.h"
#import "GeneralMenuVC.h"
#import "alert.h"

#import "UIImage+animatedGIF.h"
#import "UIColor+CustomColors.h"


@interface FrontVC ()

@end

@implementation FrontVC
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
    
    _autopilot = [[Autopilot alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGoButton:) name:@"startedDriving" object:nil];
    
    //[self initFilter];
    
}


-(void) loadNibs{
    [[[NSBundle mainBundle] loadNibNamed:@"TopMenu" owner:self options:nil] firstObject];
    
    [[[NSBundle mainBundle] loadNibNamed:@"BottomStatusBar" owner:self options:nil] firstObject];

    [[NSBundle mainBundle] loadNibNamed:@"circuitsListFW" owner:self options:nil];
    
   
}
-(void) initUI{
    [_GoButton.layer setCornerRadius:8];
    [_GoButton setHidden:YES];
    [_StopButton.layer setCornerRadius:8];
    [_StopButton setHidden:YES];
    
    [_simulatedCarSpeedSlider setHidden:YES];
    
    yellowColorString = @"RGB 212 175 55";
    redColorString = @"RGB 222 22 22";
}

/*-(void) initFilter{
    f = alloc_filter(2, 1);
    
    /* The train state is a 2d vector containing position and velocity.
     Velocity is measured in position units per timestep units.
    set_matrix(f.state_transition,
               1.0, 1.0,
               0.0, 1.0);
    
     We only observe position
    set_matrix(f.observation_model, 1.0, 0.0);
    
     The covariance matrices are blind guesses
    set_identity_matrix(f.process_noise_covariance);
    scale_matrix(f.process_noise_covariance, 100000);
    
    
    //R is The measurement noise covariance
    set_identity_matrix(f.observation_noise_covariance);
    scale_matrix(f.observation_noise_covariance, 0.3);
    
     Our knowledge of the start position is incorrect and unconfident
    double deviation = 1000.0;
    set_matrix(f.state_estimate, 10 * deviation);
    set_identity_matrix(f.estimate_covariance);
    scale_matrix(f.estimate_covariance, deviation * deviation);
    
//     Test with time steps of the position gradually increasing
//    for (int i = 0; i < 100; ++i) {
//        set_matrix(f.observation, (double) 2*i);
//        update(f);
//        printf("------------------------\n");
//        printf("estimated position: %f\n", f.state_estimate.data[0][0]);
//        printf("estimated velocity: %f\n", f.state_estimate.data[1][0]);
//
//    }
    
    

    
    
//    free_filter(f);
}*/

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
    
    [self startPredictingCarLoc];
}

-(void) startPredictingCarLoc{
    realPhoneCoordinates = [[NSMutableArray alloc] init];
    predictedGPSLocations = [[NSMutableArray alloc] init];
    
    float freqPrediction = 10;
    realCarPredictionTimer = [NSTimer scheduledTimerWithTimeInterval:1/freqPrediction target:self selector:@selector(predictCarLoc) userInfo:nil repeats:YES];
}

-(void) predictCarLoc{
     _isRealCar = ![[[Menu instance] getGeneralMenu].carSwitch isOn];
    
    if (!_phoneLocation) {
        return;
    }
    else if(!_isRealCar){
        return;
    }
    else{
        // here we are receiving location updates
        CLLocation* predictedCarLoc = [[CLLocation alloc] init];
        
        if (!predictedGPSLocations.count) {
            if (_phoneLocation.speed >= 0) {
                [realPhoneCoordinates addObject:_phoneLocation];
                [predictedGPSLocations addObject:_phoneLocation];
                
                countPrediction = 0;
                NSLog(@"first location speed >= 0, count %lu",predictedGPSLocations.count);
            }
            // go to display otherwise return
            else{
                NSLog(@"waiting for first location with speed >= 0");
                [self carAtLocation:_phoneLocation];
                return;
            }
        }
        else{
            CLLocation * lastPhoneLocation = [realPhoneCoordinates lastObject];
            if ([_phoneLocation.timestamp isEqualToDate:lastPhoneLocation.timestamp]) {
                // MAKE A PREDICTION
                countPrediction ++;
                
                if (lastPhoneLocation.speed > 0) {
                    //                NSLog(@"speed %0.3f, ",lastPhoneLocation.speed);
                    CLLocationCoordinate2D predictedLocation2D;
                    
                    if (lastPhoneLocation.course >= 0 && lastPhoneLocation.course <= 180) {
                        predictedLocation2D = [[Calc Instance] predictedGPSPositionFromCurrentPosition:lastPhoneLocation.coordinate andCourse:lastPhoneLocation.course andSpeed:lastPhoneLocation.speed during:0.1*(countPrediction+1)];
                    }
                    else if(lastPhoneLocation.course > 180){
                        predictedLocation2D = [[Calc Instance] predictedGPSPositionFromCurrentPosition:lastPhoneLocation.coordinate andCourse:(-360 + lastPhoneLocation.course) andSpeed:lastPhoneLocation.speed during:0.1*(countPrediction+1)];
                    }
                    
                    NSDate* now = [[NSDate alloc] init];
                    predictedCarLoc = [[CLLocation alloc] initWithCoordinate:predictedLocation2D altitude:lastPhoneLocation.altitude horizontalAccuracy:lastPhoneLocation.horizontalAccuracy verticalAccuracy:lastPhoneLocation.verticalAccuracy course:lastPhoneLocation.course speed:lastPhoneLocation.speed timestamp:now];
                    
                    [predictedGPSLocations addObject:predictedCarLoc];
                }
                else if (lastPhoneLocation.speed == 0){
                    [predictedGPSLocations addObject:lastPhoneLocation];
                    //                NSLog(@"sameLocation speed == 0");
                }
                else{
                    NSLog(@"lastPhone location has a negative Speed");
                }
            }
            else{
                //  NEW LOCATION UPDATE ADD IT
                
                [realPhoneCoordinates addObject:_phoneLocation];
                [predictedGPSLocations addObject:_phoneLocation];
                countPrediction = 0;
            }
            
        }
        
        if (predictedGPSLocations.count) {
            CLLocation* lastPrediction = [predictedGPSLocations lastObject];
            
            [mapView movePinNamed:@"prediction" toCoord:lastPrediction andColor:@"RGB 82 179 28"];
            
            [self carAtLocation:lastPrediction];
            if (realPhoneCoordinates.count == 6) {
                [realPhoneCoordinates removeObjectAtIndex:0];
            }
            if (predictedGPSLocations.count == 21) {
                [predictedGPSLocations removeObjectAtIndex:0];
            }
            
            for (CLLocation* loci in predictedGPSLocations) {
                [mapView movePinNamed:[NSString stringWithFormat:@"predicted %d",(int)[predictedGPSLocations indexOfObject:loci]] toCoord:loci andColor:@"RGB 35 250 239"];
            }
            
        }
    }
}
-(void) initMapView{
    
    mapView.frontVC = self;
    

   swipeGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeOnScreen:)];
    
    [self.view addGestureRecognizer:swipeGR];


    mapView.tapGRMapVideoSwitching = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchMapAndVideoViews:)];
    [mapView addGestureRecognizer:mapView.tapGRMapVideoSwitching];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    _phoneLocation = _locationManager.location;
    
    if(_phoneLocation.speed >= 0){
        if ([[Calc Instance] distanceFromCoords2D:mapView.region.center toCoords2D:_phoneLocation.coordinate] > 10000) {
            [mapView setRegion:MKCoordinateRegionMake(_phoneLocation.coordinate, MKCoordinateSpanMake(0.03, 0.03)) animated:YES];
        }
//        if (_isRealCar) {
//            [self carAtLocation:_phoneLocation];
//        }
        
        
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
        [_circuitsList openCircuitListWithCompletion:^(BOOL finished) {
            
        }];
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
    [_bottomStatusBar updateWith:state andPhoneLocation:_phoneLocation];
    if (!_realDrone) {
        _realDrone = [[Drone alloc] initWithLocation:[[Calc Instance] locationWithCoordinates:state.aircraftLocation]];
        _realDrone.realDrone = YES;
    }
    else{
        [_realDrone updateDroneStateWithFlightControllerState:state];
    }
    
    _autopilot.realDrone = _realDrone;
    
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
    
    if ( ![pathPlanningTimer isValid]) {
        [mapView updateDroneAnnotation:_realDrone];
        [mapView updateGimbalAnnoOfDrone:_realDrone];
        [_topMenu updateDistDroneCarLabelWith:_phoneLocation andDroneLoc:_realDrone.droneLoc];
    }

}
#pragma mark - gimbal state callback

-(void) gimbalController:(DJIGimbal *)controller didUpdateGimbalState:(DJIGimbalState *)gimbalState{
    // 10 Hz Freq
    // update zone of gimbal
    [_autopilot updateZoneOfGimbalForDrone:_realDrone withGimbalState:gimbalState];
    
    if (controller) {
        _autopilot.gimbal = controller;
    }
    
    controller.completionTimeForControlAngleAction = 0.7;
    //UI Update with the flight controller callback
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
            [mapView removePinsNamed:@"panLoc"];
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
            
            
            [mapView removePinsNamed:@"panLoc"];
            

            [[Calc Instance] map:mapView drawCircuitPolyline:swipedCircuit withTitle:@"poly" andColor:@"RGB 212 175 55"];
            
            isPathDrawingEnabled = NO;
            [self enableMainMenuPan];
            
            NSDictionary *aDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:swipedCircuit,@"locations", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"panCircuitEnded" object:nil userInfo:aDictionary];
            return;
        }
    }
    else if (_autopilot){
        if (pan.state == UIGestureRecognizerStateChanged) {
            CGPoint point = [pan locationInView:mapView];
            CLLocationCoordinate2D newCoord =[mapView convertPoint:point toCoordinateFromView:mapView];
            _autopilot.followLoc = [[Calc Instance] locationWithCoordinates:newCoord];
            
        }
    }
    else{
        if ([pathPlanningTimer isValid]) {
            return;
        }
        // with the pan button we will control the location of simulated drone ..
    
        else if(pan.state == UIGestureRecognizerStateChanged){
            CGPoint point = [pan locationInView:mapView];
            CLLocationCoordinate2D newCoord =[mapView convertPoint:point toCoordinateFromView:mapView];
//            CLLocation* newLoc = [[Calc Instance] locationWithCoordinates:newCoord];
            CLLocation* newLoc = [[CLLocation alloc] initWithCoordinate:newCoord altitude:_simulatedDrone.droneLoc.altitude horizontalAccuracy:_simulatedDrone.droneLoc.horizontalAccuracy verticalAccuracy:_simulatedDrone.droneLoc.verticalAccuracy course:_simulatedDrone.droneLoc.course speed:_simulatedDrone.droneLoc.speed timestamp:[[NSDate alloc]init]];
            _simulatedDrone.droneLoc = newLoc;
            [mapView updateDroneAnnotation:_simulatedDrone];
            
           
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
                ShowResult(@"Start record error %@", error.localizedDescription);
            }
        }];
    }else{
        ShowResult(@"start record: No Camera");
    }
}
-(void) stopRecord{
    __weak DJICamera* camera = [ComponentHelper fetchCamera];
    if (camera) {
        [camera stopRecordVideoWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                ShowResult(@"Stop record error %@", error.localizedDescription);
            }
        }];
    }else{
        ShowResult(@"stop record: No camera");
    }
}

- (IBAction)didClickOnRecButton:(id)sender {
    
    if (!appD.isDroneRecording) {
        [self startRecord];
    }
    else{
        [self stopRecord];
    }
    
}

- (IBAction)didClickOnStartDrivingButton:(id)sender {
//        [_autopilot startFollowMissionWithCompletion:^(NSError *error) {
    
    //    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startedDriving" object:nil];
}


#pragma mark - simulator setup
-(void) startSimulatorAtLoc:(CLLocation*) startLoc WithCompletion:(void(^)(NSError * _Nullable error))callback{
    DJIFlightController* fc = [ComponentHelper fetchFlightController];
    if (fc && fc.simulator) {
        
        if (!fc.simulator.isSimulatorStarted) {
            [fc.simulator startSimulatorWithLocation:startLoc.coordinate updateFrequency:10 GPSSatellitesNumber:17 withCompletion:^(NSError * _Nullable error) {
                callback(error);
                if (error) {
                    ShowResult(@"Start simulator error:%@", error.description);
                } else {
                    ShowResult(@"Start simulator succeeded.");
                    [fc takeoffWithCompletion:^(NSError * _Nullable error) {
                        
                    }];
                }
            }];
        }
        
        _djiSimulatedDrone = [[Drone alloc] init];
        _djiSimulatedDrone.realDrone = NO;
        
        [fc.simulator setDelegate:self];
    }
}

-(void) stopSimulatorWithCompletion:(void(^)(NSError * _Nullable error))callback{
    DJIFlightController* fc = [ComponentHelper fetchFlightController];
    if (fc && fc.simulator) {
        
        if (fc.simulator.isSimulatorStarted) {
            [fc.simulator stopSimulatorWithCompletion:^(NSError * _Nullable error) {
                callback(error);
                if (error) {
                    ShowResult(@"Stop simulator error:%@", error.description);
                } else {
                    ShowResult(@"Stop simulator succeeded.");
                    DJIGimbal* gimbal = [ComponentHelper fetchGimbal];
                    [gimbal resetGimbalWithCompletion:^(NSError * _Nullable error) {
                        if (error) {
                            ShowResult(@"error reset gimbal , %@",error.localizedDescription);
                        }
                    }];
                }
            }];
        }
        else{
            DVLog(@"simulator is not started");
        }
        
        [fc.simulator setDelegate:nil];
    }
}
// check the simulator state in the same callback also as the real drone
-(void)simulator:(DJISimulator *)simulator updateSimulatorState:(DJISimulatorState *)state {
    // We still receive simulator info in the same callback as the real drone callback : filghtController didReceiveStateUpdates...

//    set_identity_matrix(f.process_noise_covariance);
//    scale_matrix(f.process_noise_covariance,powf(10, [_KpSlider value]));
    
//    set_identity_matrix(f.observation_noise_covariance);
//    scale_matrix(f.observation_noise_covariance, [_KdSlider value]);
    
//    set_matrix(f.observation,(double)state.positionX);
//    update(f);

    
//    DVLog(@"x , %0.3f , est , %0.3f,gain , %0.3f , estVel , %0.3f  , velo ,%0.3f  ,prc, %0.3f , obs ,%0.3f",state.positionX,f.state_estimate.data[0][0],f.optimal_gain.data[0][0],f.state_estimate.data[1][0],_FCcurrentState.velocityX/10,f.process_noise_covariance.data[0][0],f.observation_noise_covariance.data[0][0]);
}



#pragma mark - handle UI
-(void) didTapOnFrontVC:(UITapGestureRecognizer*) tapGR{
    NSLog(@"tap on FrontVC , %@",NSStringFromCGPoint([tapGR locationInView:self.view]));
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
        [_simulatedCarSpeedSlider setHidden:NO];
        
        
    }
    else{
        [_GoButton setHidden:YES];
        [_simulatedCarSpeedSlider setHidden:YES];
    }
}

- (IBAction)didClickOnGoButton:(id)sender {
    // when detected driving .. popup to ask if drone should start following/ moving
    [self startMissionWithCompletion:^(BOOL started) {
        if (started) {
            [self hideGoButtonWithCompletion:^{
                [self showStopButtonWithCompletion:^{
                    
                }];
            }];
        }
    }];
    
    
}
- (IBAction)didClickOnStopButton:(id)sender {
    [self pauseMission];
    [self hideStopButtonWithCompletion:^{
        [self showResumeGoHomeStackWithCompletion:^{
            
        }];
    }];
    
}
- (IBAction)didClickOnResumeButton:(id)sender {
    [self resumeMission];
    [self hideResumeGoHomeStackWithCompletion:^{
       [self showStopButtonWithCompletion:^{
           
       }];
    }];
}
- (IBAction)didClickOnGoHomeButton:(id)sender {
    
}


-(void) hideGoButtonWithCompletion:(void (^)()) callback{
    if (_GoButton.alpha == 0.0 || [_GoButton isHidden]) {
        [_GoButton setHidden:YES];
        [_GoButton setAlpha:0];
        callback();
        NSLog(@"go button already hidden");
        return;
    }
    POPBasicAnimation* opacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    
    opacityAnimation.fromValue = @(1.0);
    opacityAnimation.toValue = @(0);
    [opacityAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
        [_GoButton setHidden:YES];
        callback();
    }];
    [_GoButton.layer pop_addAnimation:opacityAnimation forKey:@"opacityAnimation"];
}
-(void) showGoButtonWithCompletion:(void (^)()) callback{
    if (_GoButton.alpha == 1.0 && ![_GoButton isHidden]) {
        callback();
        [_StopButton setHidden:YES];
        [_StopButton setAlpha:0];
        [_resumeGoHomeStack setHidden:YES];
        [_resumeGoHomeStack setAlpha:YES];
        return;
    }
    POPBasicAnimation* opacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    [_GoButton setHidden:NO];
    opacityAnimation.fromValue = @(0.0);
    opacityAnimation.toValue = @(1.0);
    [opacityAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
        
        callback();
    }];
    [_GoButton.layer pop_addAnimation:opacityAnimation forKey:@"opacityAnimation"];
}

-(void) hideStopButtonWithCompletion:(void (^)() )callback{
    if (_StopButton.alpha == 0.0 || [_StopButton isHidden]) {
        [_StopButton setHidden:YES];
        [_StopButton setAlpha:0];
        callback();
        return;
    }
    POPBasicAnimation* opacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    
    opacityAnimation.fromValue = @(1.0);
    opacityAnimation.toValue = @(0);
    [opacityAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
        [_StopButton setHidden:YES];
        callback();
    }];
    [_StopButton.layer pop_addAnimation:opacityAnimation forKey:@"opacityAnimation"];
}
-(void) showStopButtonWithCompletion:(void (^)()) callback{
    if (_StopButton.alpha == 1.0 && ![_StopButton isHidden]) {
        callback();
        return;
    }
    POPBasicAnimation* opacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    [_StopButton setHidden:NO];
    opacityAnimation.fromValue = @(0.0);
    opacityAnimation.toValue = @(1.0);
    [opacityAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
        
        callback();
    }];
    [_StopButton.layer pop_addAnimation:opacityAnimation forKey:@"opacityAnimation"];
}

-(void) hideResumeGoHomeStackWithCompletion:(void (^)() )callback{
    if (_resumeGoHomeStack.alpha == 0.0 || [_resumeGoHomeStack isHidden]) {
        [_resumeGoHomeStack setHidden:YES];
        [_resumeGoHomeStack setAlpha:0];
        callback();
        return;
    }
    POPBasicAnimation* opacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    
    opacityAnimation.fromValue = @(1.0);
    opacityAnimation.toValue = @(0);
    [opacityAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
        [_resumeGoHomeStack setHidden:YES];
        callback();
    }];
    [_resumeGoHomeStack.layer pop_addAnimation:opacityAnimation forKey:@"opacityAnimation"];
}
-(void) showResumeGoHomeStackWithCompletion:(void (^)()) callback{
    if (_resumeGoHomeStack.alpha == 1.0 && ![_resumeGoHomeStack isHidden]) {
        callback();
        return;
    }
    POPBasicAnimation* opacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    [_resumeGoHomeStack setHidden:NO];
    opacityAnimation.fromValue = @(0.0);
    opacityAnimation.toValue = @(1.0);
    [opacityAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
        
        callback();
    }];
    [_resumeGoHomeStack.layer pop_addAnimation:opacityAnimation forKey:@"opacityAnimation"];
}


-(void) startMissionWithCompletion:(void (^)(BOOL started)) callback{
    
    _simulateWithDJISimulator = ([ComponentHelper fetchFlightController]);
    
    if (_simulateWithDJISimulator) {
        _isRealDrone = YES;
    }
    else{
        _isRealDrone = ![[[Menu instance] getGeneralMenu].droneSwitch isOn];
    }
    
    _isRealCar = ![[[Menu instance] getGeneralMenu].carSwitch isOn];

    
    if (!_circuit || !_circuit.locations.count) {
        NSLog(@"no circuit");
        callback(NO);
        return;
    }
    
    // ***********  CAR ***********
    if (!_isRealCar) {
        // start simulation --> callback --> carLocation contains current car location
        [[circuitManager Instance]simulateCarOnCircuit:_circuit];
    }
    // ***********  Drone ***********
    if (!_isRealDrone) {
        
        CLLocation* droneSimulatedLoc = [[CLLocation alloc] initWithCoordinate:[_circuit.locations[0] coordinate] altitude:10 horizontalAccuracy:1 verticalAccuracy:1 course:0 speed:0 timestamp:[[NSDate alloc]init]];
        
        _simulatedDrone = [[Drone alloc] initWithLocation:droneSimulatedLoc];
        _simulatedDrone.realDrone = NO;
    }
    else{
        if (!appD.isReceivingFlightControllerStatus) {
            DVLog(@"No drone connected");
        }
        
        if (_simulateWithDJISimulator) {
            DJIFlightController* fc = [ComponentHelper fetchFlightController];
            if (fc.simulator.isSimulatorStarted) {
                [self stopSimulatorWithCompletion:^(NSError * _Nullable error) {
                    [self startSimulatorAtLoc:_circuit.locations[0] WithCompletion:^(NSError * _Nullable error) {
                        
                    }];
                }];
            }
        }
        
        // here we are supposed to have info in _realDrone
    }
    
    // ********** PATH PLANNING TIMER *********
    _planner = [[pathPlanner alloc] init];
    if(pathPlanningTimer){
        [pathPlanningTimer invalidate];
        pathPlanningTimer = nil;
    }
    
    pathPlanningTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onPathPlanningTimerTicked) userInfo:nil repeats:YES];
    
    callback(YES);
    
    pathPlanningTimer.tolerance = 0.01;
    
    startMissionDate = [[NSDate alloc] init]; // initialisation de la date reference de start mission
    countFollow = 0;
    refDate = [[NSDate alloc] init];
}

-(void) pauseMission{
    if ([pathPlanningTimer isValid]) {
        [pathPlanningTimer invalidate];
    }
    [[circuitManager Instance] pauseCarMovement];
}
-(void) resumeMission{
     pathPlanningTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onPathPlanningTimerTicked) userInfo:nil repeats:YES];
    [[circuitManager Instance] resumeCarMovement];
}

- (IBAction)simulatedCarSpeedSliderDidChangeValue:(id)sender {
    if (sender == _simulatedCarSpeedSlider) {
        [[circuitManager Instance] setSimulatedCarSpeed:[_simulatedCarSpeedSlider value]];
    }
}
- (IBAction)onSliderDidChange:(id)sender {
 
    if (sender == _KiSlider) {
        [_KiLabel setText:[NSString stringWithFormat:@"i:%0.2f",[_KiSlider value]]];
        _planner.Ki = [_KiSlider value];
    }
    if (sender == _KpSlider) {
        [_KpLabel setText:[NSString stringWithFormat:@"p:%0.2f",[_KpSlider value]]];
        _planner.Kp = [_KpSlider value];
    }
    if (sender == _KdSlider) {
        [_KdLabel setText:[NSString stringWithFormat:@"d:%0.2f",[_KdSlider value]]];
        _planner.Kd = [_KdSlider value];
    }
}


// This method carAtLocation: manages the locations coming from the phone locationManager and the car simulation
-(void) carAtLocation:(CLLocation*) location{
    _isRealCar = ![[[Menu instance] getGeneralMenu].carSwitch isOn];
    if (_isRealCar) {
        
        if (location.speed < 0) {
            [_topMenu updateDistDroneCarLabelWith:nil andDroneLoc:nil];
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
    
    if (_drone.droneLoc) {
        [_topMenu updateDistDroneCarLabelWith:location andDroneLoc:_drone.droneLoc];
    }
}

-(void) onPathPlanningTimerTicked{
    _isRealCar = ![[[Menu instance] getGeneralMenu].carSwitch isOn];
    
    if (_simulateWithDJISimulator) {
        _isRealDrone = YES;
    }
    else{
        _isRealDrone = ![[[Menu instance] getGeneralMenu].droneSwitch isOn];
    }
    
    if (_simulateWithDJISimulator) {
        DJIFlightController* fc = [ComponentHelper fetchFlightController];
        
        if (fc.simulator.isSimulatorStarted) {
            _drone = _realDrone;
        }
        else{
            DVLog(@"problem here: start DJI simulator first, or switch simulator type");
        }
    }
    else{
        _drone = _simulatedDrone;
    }
    
    
    if (_isRealDrone) {
        _drone = _realDrone;
    }
    // here we have _drone , _carLocation , _circuit
    
    [_planner follow:_carLocation onCircuit:_circuit drone:_drone];
    
//    [_planner follow2:_carLocation onCircuit:_circuit drone:_drone];
    
    [mapView updateDroneAnnotation:_drone];
    [mapView updateDrone:_drone Vec_Anno_WithTargetSpeed:_drone.targSp AndTargetHeading:_drone.targHeading];
    

    if (!_isRealDrone) {// SIMULATED DRONE
        
        _simulatedDrone = [_simulatedDrone newDroneStateFrom:_simulatedDrone withTargetSpeed:_simulatedDrone.targSp andTargetAngle:_simulatedDrone.targHeading andTargAltitude:10 during:0.1];

        [_bottomStatusBar updateHorizontalSpeedWithHorizontalSpeed:_simulatedDrone.droneSpeed_Vec.norm];
    }
    else{ // REAL DRONE
         // ********* GIMBAL COMMAND **********
        if (!_simulateWithDJISimulator) {
            [self adjustGimbalToCarLocation:_carLocation andDrone:_drone];
        }
        
        
        [mapView updateGimbalAnnoOfDrone:_drone];
        

        [_autopilot goWithSpeed:_drone.targSp atBearing:_drone.targHeading atAltitude:10 andYaw:0];
    
        // ********* PATH PLANNING ************
    }
    
    // CALCULER LA FREQ D'exec
    countFollow ++;
    countFollow = countFollow%10;
    if (!countFollow) {
        NSTimeInterval time = -[refDate timeIntervalSinceNow];
        float freqRuntime = 10/time;
//        NSLog(@"freq , %0.3f",freqRuntime);
        refDate = [[NSDate alloc] init];
    }
}


-(void) adjustGimbalToCarLocation:(CLLocation*) carLoc andDrone:(Drone*) drone {
    DJIGimbal* gimbal = [ComponentHelper fetchGimbal];
    
    if (!gimbal) {
        return;
    }
    else{
        
        //******************** PITCH *******************
        float currentGimbalPitch = gimbal.attitudeInDegrees.pitch;
        
        float gimbalPitchToTargetOnTheGround = -atanf(_FCcurrentState.altitude/(drone.droneCar_Vec.norm))*180/M_PI;
        
        if (isnan(gimbalPitchToTargetOnTheGround)) {
            gimbalPitchToTargetOnTheGround = 90;
            DVLog(@"gimbal target pitch is nan");
        }
        
        float pitchError = gimbalPitchToTargetOnTheGround - currentGimbalPitch;
        float pitchSpeed = 120*sign(pitchError)*(1-expf(-fabsf(pitchError)/50));
        
        
        //********************* YAW ********************
//        float gimbalEarthYaw = gimbal.attitudeInDegrees.yaw;
        
        float gimbalTarget330Yaw = [self calculateGimbalTarget300YawFrom:carLoc drone:drone]; //we also have gimbalTargetYawEarth stored as a global variable
        
        float delta330 = gimbalTarget330Yaw - _drone.gimbalCurrent330yaw;//_autopilot.gimbalCurrent330yaw;
        
        float speed = 175*sign(delta330)*(1-expf(-fabsf(delta330)/(80)));
        //    float speed = 150*sign(delta330)*(1-expf(-fabsf(delta330)/(80)));
        speed = bindBetween(speed, -120, 120);
        
        // calcul de la vitesse radiale de la voiture % au drone
        float droneCarD = drone.droneCar_Vec.norm;
        if (droneCarD == 0) {
            droneCarD = 1;
        }
        float orthoRadialSpeed = DEGREE([drone.carSpeed_Vec dotProductWithNormalEastToVector:[drone.droneCar_Vec unityVector]]/droneCarD);
        
        orthoRadialSpeed = bindBetween(orthoRadialSpeed, -120, 120); // limits for orthoradial speed variation
        
        float totalYawSpeed = speed+orthoRadialSpeed;
        
        [_autopilot gimbalMoveWithSpeed:pitchSpeed andRoll:0 andYaw:totalYawSpeed];
    
//        float time = -[startMissionDate timeIntervalSinceNow];
        
        
        
//        DVLoggerLog(@"gimbalTracking", [NSString stringWithFormat:@"%0.3f,%0.3f ,%0.3f,%0.3f, %0.3f,%0.3f,,%0.3f,%0.3f,%0.3f",time,drone.gimbalYawEarth,drone.droneCar_Vec.angle,delta330,speed,orthoRadialSpeed,gimbalPitchToTargetOnTheGround,currentGimbalPitch,pitchSpeed]);
    }
    

}

-(float) calculateGimbalTarget300YawFrom:(CLLocation*) carLoc drone:(Drone*) drone{
    
    //calulate gimbal targetBearing in earth coordinate
    drone.gimbalTargetYawEarth = [[Calc Instance] headingTo:carLoc.coordinate fromPosition:drone.droneLoc.coordinate]; // theta target
    
    float predictedDroneYawEarth = [[Calc Instance] angle180Of330Angle:_FCcurrentState.attitude.yaw+_drone.droneYawSpeed*0.3];
    
    float gimbalTargetHeadingInDroneBC = [[Calc Instance] closestDiffAngle:drone.gimbalTargetYawEarth toAngle:predictedDroneYawEarth];
    
    float angle330_0 = bindBetween([[Calc Instance] angle330OfAngle:gimbalTargetHeadingInDroneBC withZone:0],-180,180);
    float angle330_1 = bindBetween([[Calc Instance] angle330OfAngle:gimbalTargetHeadingInDroneBC withZone:1],180,330);
    float angle330_m1 = bindBetween([[Calc Instance] angle330OfAngle:gimbalTargetHeadingInDroneBC withZone:-1],-330,-180);
    
    float diff0 = fabsf(angle330_0 - _autopilot.gimbalCurrent330yaw);
    float diff1 = fabsf(angle330_1 - _autopilot.gimbalCurrent330yaw);
    float diffm1 = fabsf(angle330_m1 - _autopilot.gimbalCurrent330yaw);
    
    float minDiff = MIN(MIN(diff0, diff1), diffm1);
    
    float gimbalTarget330Yaw = 0;
    
    if (minDiff == diffm1) {
        gimbalTarget330Yaw = angle330_m1;
    }
    else if (minDiff == diff1)
    {
        gimbalTarget330Yaw = angle330_1;
    }
    else
    {
        gimbalTarget330Yaw = angle330_0;
        
    }
    return gimbalTarget330Yaw;
}
/*
 Test reponse à l'accéleration a partir de stopped position
 */
@end
