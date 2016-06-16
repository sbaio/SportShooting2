//
//  MapView.m
//  SportShooting
//
//  Created by Othman Sbai on 6/4/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#define RADIAN(x) ((x)*M_PI/180.0)
#define bindBetween(a,b,c) ((a > c) ? c: ((a<b)? b:a))
#define MERCATOR_RADIUS 85445659.44705395
#define MAX_GOOGLE_LEVELS 20

#import "MapView.h"
#import "UIColor+CustomColors.h"



@interface MapView (){

}

@end
@implementation MapView


- (void)commonInit
{
    [self setMapViewMaskImage:YES];
    self.delegate = self;
    
    button = [[UIButton alloc] initWithFrame:CGRectMake(45, 85, 600, 60)];
    button.restorationIdentifier = @"clickToSelectTrackButton";
    button.alpha = 0.8;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [button addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
    
    selecTrackIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"clickToSelectTrack.png"]];
    selecTrackIV.frame = self.bounds;
    selecTrackIV.restorationIdentifier = @"selectTrack";
    selecTrackIV.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    selecTrackIV.backgroundColor = [[UIColor customYellowColor] colorWithAlphaComponent:0.1];
    
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[UIColor colorWithHue:0.125 saturation:0.93 brightness:0.95 alpha:0.5] CGColor];
    self.layer.cornerRadius = 2;
    
    
}



-(void) updateMaskImageAndButton{
    BOOL show = (!_mapVC.circuit && ![[[[UIApplication sharedApplication]keyWindow] subviews] containsObject:_mapVC.circuitsList]);
    
    if (show) {
        [self setMapViewMaskImage:YES];
    }
    else{
        [self setMapViewMaskImage:NO];
    }
}

-(void) tap:(id)sender{
    // did click on mapview button
    [_mapVC.circuitsList openCircuitListWithCompletion:^(BOOL finished) {
        
    }];
}
-(void) setMapViewMaskImage:(BOOL) set {
    
    BOOL containsImageView = NO;
    BOOL containsButton = NO;
    for (UIView* subview in [self subviews]) {
        if ([[subview restorationIdentifier] isEqualToString:@"selectTrack"]) {
            containsImageView = YES;
        }
        if([[subview restorationIdentifier] isEqualToString:@"clickToSelectTrackButton"]) {
            containsButton = YES;
        }
    }
    
    if (set) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!containsImageView) {
                selecTrackIV.frame = self.bounds;
                [self addSubview:selecTrackIV];
            }
            if (!containsButton && self.bounds.size.width == [[UIScreen mainScreen]bounds].size.width) {
                [self addSubview:button];
            }
            
            [UIView animateWithDuration:0.5 animations:^{
                self.alpha = 1.0;
            }];
        });
        
    }
    else{
        
        if (containsImageView) {
            [selecTrackIV removeFromSuperview];
        }
        if (containsButton) {
            [button removeFromSuperview];
        }
    }
    
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( self )
    {
        [self commonInit];
    }
    return self;
}

-(MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation{
    
    if ([annotation isKindOfClass:[Aircraft_Camera_Car_Annotation class]]) {
        Aircraft_Camera_Car_Annotation *anno = annotation;
        return anno.annotationView;
    }
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        
        MKPinAnnotationView *pinView = (MKPinAnnotationView *)[map dequeueReusableAnnotationViewWithIdentifier:@"pinView"];
        if (!pinView) {
            
        }
        if ([annotation.subtitle containsString:@"RGB"]) { //@"RGB"
            NSArray* array = [annotation.subtitle componentsSeparatedByString:@" "];
            if([array[0] isEqualToString:@"RGB"] && array.count == 4){
                
                float R = [array[1] floatValue];
                float G = [array[2] floatValue];
                float B = [array[3] floatValue];
                UIColor *color = [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:1];
                pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pinView"];
                pinView.pinTintColor = color;
                pinView.animatesDrop = FALSE;
                pinView.canShowCallout = YES;
                
                return pinView;
            }
            else{
                DVLog(@"didn't get the color");
            }
            
        }
        if ([annotation.title  isEqual: @"circuitReplayAnnotation1"]) {
            UIColor *color = [UIColor colorWithRed:0.0/255.0 green:180.0/255.0 blue:0/255.0 alpha:1];
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pinView"];
            pinView.pinTintColor = color;
            pinView.animatesDrop = FALSE;
            pinView.canShowCallout = YES;
            return pinView;
        }
        else if ([annotation.title  isEqual: @"circuitReplayAnnotation2"]){
            UIColor *color = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:180.0/255.0 alpha:1];
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pinView"];
            pinView.pinTintColor = color;
            pinView.animatesDrop = FALSE;
            pinView.canShowCallout = YES;
            return pinView;
        }
        else{
            UIColor *color = [UIColor colorWithRed:22.0/255.0 green:208.0/255.0 blue:215.0/255.0 alpha:1];
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pinView"];
            pinView.pinTintColor = color;
            pinView.animatesDrop = FALSE;
            pinView.canShowCallout = YES;
        }
    }
    
    return nil;
}
-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *route = overlay;
        MKPolylineRenderer *routeRenderer = [[MKPolylineRenderer alloc] initWithPolyline:route];
        
        if ([route.title isEqualToString:@"limit"]) {
            if ([route.subtitle containsString:@"RGB"]) {
                NSArray* array = [route.subtitle componentsSeparatedByString:@" "];
                if([array[0] isEqualToString:@"RGB"] && array.count == 4){
                    
                    float R = [array[1] floatValue];
                    float G = [array[2] floatValue];
                    float B = [array[3] floatValue];
                    UIColor *color = [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:1];
                    routeRenderer.strokeColor = color;
                }
            }
        }else if ([route.subtitle containsString:@"RGB"]){
            NSArray* array = [route.subtitle componentsSeparatedByString:@" "];
            if([array[0] isEqualToString:@"RGB"] && array.count == 4){
                
                float R = [array[1] floatValue];
                float G = [array[2] floatValue];
                float B = [array[3] floatValue];
                UIColor *color = [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:1];
                routeRenderer.strokeColor = color;
            }
        }
        else{
            routeRenderer.strokeColor = [UIColor blueColor];
        }
        routeRenderer.lineWidth = 1.0;
        return routeRenderer;
    }
    else if ([overlay isKindOfClass:[MKCircle class]])
    {
        MKCircle* circle = (MKCircle*) overlay;
        MKCircleRenderer* aRenderer = [[MKCircleRenderer alloc] initWithCircle:(MKCircle *)overlay];
        
        aRenderer.fillColor = [[[Calc Instance] colorFromString:circle.subtitle] colorWithAlphaComponent:0.2];
        aRenderer.strokeColor = [[[Calc Instance] colorFromString:circle.subtitle] colorWithAlphaComponent:0.7];
        aRenderer.lineWidth = 3;
        return aRenderer;
    }
    else return nil;
}
- (double)getZoomLevel
{
    CLLocationDegrees longitudeDelta = self.region.span.longitudeDelta;
    CGFloat mapWidthInPixels = self.bounds.size.width;
    double zoomScale = longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * mapWidthInPixels);
    double zoomer = MAX_GOOGLE_LEVELS - log2( zoomScale );
    if ( zoomer < 0 ) zoomer = 0;
    //  zoomer = round(zoomer);
    return zoomer;
}

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
   
}
-(void) disableMapViewScroll{
    [self setScrollEnabled:NO];
    [_mapVC.scrollButton setImage:[UIImage imageNamed:@"pan_50.png"] forState:UIControlStateNormal];
}

-(void) enableMapViewScroll{
    [self setScrollEnabled:YES];
    [_mapVC.scrollButton setImage:[UIImage imageNamed:@"pan_yellow.png"] forState:UIControlStateNormal];
}



#pragma mark - annotations

-(void) updateCarLocation:(CLLocation*) carLoc{
    if (!carAnnotation) {
        carAnnotation = [[Aircraft_Camera_Car_Annotation alloc] initWithCoordiante:carLoc.coordinate andType:1];
    }
    else{
        
        [carAnnotation setCoordinate:carLoc.coordinate];
        float carHeading = (carLoc.course < 180) ? carLoc.course : carLoc.course-360;
        [carAnnotation updateHeading:RADIAN(carHeading)];
    }
    [self addAnnotation:carAnnotation];
}

-(void) updateDroneAnnotation:(Drone*) drone{
    if (!drone.droneAnno) {
        drone.droneAnno = [[Aircraft_Camera_Car_Annotation alloc] initWithCoordiante:drone.droneLoc.coordinate andType:0];
    }
    else{
        [drone.droneAnno setCoordinate:drone.droneLoc.coordinate];
    }
         [drone.droneAnno.annotationView updateHeading:RADIAN(drone.droneYaw)];
    
    [self addAnnotation:drone.droneAnno];
    
    if (!drone.droneSpeed_vecAnno) {
        drone.droneSpeed_vecAnno = [[Aircraft_Camera_Car_Annotation alloc] initWithCoordiante:drone.droneLoc.coordinate andType:9];
        drone.droneSpeed_vecAnno.identifier = @"droneSpeed_vecAnno";
    }
    else{
        [drone.droneSpeed_vecAnno setCoordinate:drone.droneLoc.coordinate];
        [drone.droneSpeed_vecAnno.annotationView updateHeading:RADIAN(drone.droneLoc.course) andScale:drone.droneLoc.speed/17];
    }
    [self addAnnotation:drone.droneSpeed_vecAnno];
    for ( id <MKAnnotation> annotation in [self annotations]) {
        if ([annotation isKindOfClass:[Aircraft_Camera_Car_Annotation class]] && annotation!= drone.droneSpeed_vecAnno) {
            Aircraft_Camera_Car_Annotation* anno = (Aircraft_Camera_Car_Annotation*) annotation;
            if (anno.type == 9 && [anno.identifier isEqualToString:@"droneSpeed_vecAnno"]) {
                [self removeAnnotation:annotation];
            }
        }
    }
}

-(void) updateDroneSensCircuit_PerpAnnotations:(Drone*) drone{
    if (!drone.sensCircuit_Anno) {
        drone.sensCircuit_Anno = [[Aircraft_Camera_Car_Annotation alloc] initWithCoordiante:drone.droneIndexLocation.coordinate andType:9];
        drone.sensCircuit_Anno.identifier = @"sensCircuit_Anno";
        
    }
    else{
        [drone.sensCircuit_Anno setCoordinate:drone.droneIndexLocation.coordinate];
        [drone.sensCircuit_Anno updateHeading:RADIAN(drone.sensCircuit.angle) andScale:0.5];
    }
    [self addAnnotation:drone.sensCircuit_Anno];
    for ( id <MKAnnotation> annotation in [self annotations]) {
        if ([annotation isKindOfClass:[Aircraft_Camera_Car_Annotation class]] && annotation!= drone.sensCircuit_Anno) {
            Aircraft_Camera_Car_Annotation* anno = (Aircraft_Camera_Car_Annotation*) annotation;
            if (anno.type == 9 && [anno.identifier isEqualToString:@"sensCircuit_Anno"]) {
                [self removeAnnotation:annotation];
            }
        }
    }
    
    if (!drone.versCircuit_Anno) {
        drone.versCircuit_Anno = [[Aircraft_Camera_Car_Annotation alloc] initWithCoordiante:drone.droneIndexLocation.coordinate andType:8];
        drone.versCircuit_Anno.identifier = @"versCircuit_Anno";
    }
    else{
        [drone.versCircuit_Anno setCoordinate:drone.droneIndexLocation.coordinate];
        [drone.versCircuit_Anno updateHeading:RADIAN(drone.versCircuit.angle) andScale:0.5];
    }
    [self addAnnotation:drone.versCircuit_Anno];
    for ( id <MKAnnotation> annotation in [self annotations]) {
        if ([annotation isKindOfClass:[Aircraft_Camera_Car_Annotation class]] && annotation!= drone.versCircuit_Anno) {
            Aircraft_Camera_Car_Annotation* anno = (Aircraft_Camera_Car_Annotation*) annotation;
            if (anno.type == 8 && [anno.identifier isEqualToString:@"versCircuit_Anno"]) {
                [self removeAnnotation:annotation];
            }
        }
    }
}

-(void) updateDrone:(Drone*) drone Vec_Anno_WithTargetSpeed:(float) targSp AndTargetHeading:(float) targHeading{
    if (!drone.droneTargSpeed_vecAnno) {
        drone.droneTargSpeed_vecAnno = [[Aircraft_Camera_Car_Annotation alloc] initWithCoordiante:drone.droneLoc.coordinate andType:9];
        drone.droneTargSpeed_vecAnno.identifier = @"droneTargSpeed_vecAnno";
    }
    else{
        
        [drone.droneTargSpeed_vecAnno setCoordinate:drone.droneLoc.coordinate];
        [drone.droneTargSpeed_vecAnno.annotationView updateHeading:RADIAN(targHeading) andScale:targSp/17];
    }
    
    [self addAnnotation:drone.droneTargSpeed_vecAnno];
    for ( id <MKAnnotation> annotation in [self annotations]) {
        if ([annotation isKindOfClass:[Aircraft_Camera_Car_Annotation class]] && annotation!= drone.droneTargSpeed_vecAnno) {
            Aircraft_Camera_Car_Annotation* anno = (Aircraft_Camera_Car_Annotation*) annotation;
            if (anno.type == 9 && [anno.identifier isEqualToString:@"droneTargSpeed_vecAnno"]) {
                [self removeAnnotation:annotation];
            }
        }
    }
}


#pragma mark - methods

-(void) removePinsNamed:(NSString*) pinName{
//    NSMutableArray *allAnnotations = [[NSMutableArray alloc] initWithArray:];
    
    for( id <MKAnnotation> annotation in [self annotations])
    {
        
        if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
            MKPointAnnotation* pin = (MKPointAnnotation*) annotation;
            if ([pin.title isEqualToString:pinName]) {
                [self removeAnnotation:annotation];
            }
        }
    }
}

-(void) addPin:(CLLocation*) location andTitle:(NSString*) title andColor:(NSString*) colorString{
    MKPointAnnotation * annotation = [[MKPointAnnotation alloc] init];
    annotation.title = title;
    annotation.subtitle = colorString;
    annotation.coordinate = location.coordinate;
    
    [self addAnnotation:annotation];
}

-(void) movePinNamed:(NSString*) name toCoord:(CLLocation*) newLoc andColor:(NSString*) colorString{
    int count = 0;
    for( id <MKAnnotation> annotation in [self annotations])
    {
        if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
            MKPointAnnotation* pin = (MKPointAnnotation*) annotation;
            if ([pin.title isEqualToString:name]) {
                if (count) {
                    [self removeAnnotation:annotation];
                }
                else{
                    [pin setCoordinate:newLoc.coordinate];
                    count = 1;
                }
                
            }
        }
    }
    if (!count) {
        [self addPin:newLoc andTitle:name andColor:colorString];
    }
}

-(void) showCircuit:(Circuit*) circuit{
    [self setRegion:[circuit region]];
//    [self removePolylineNamed:@"circuitPolyline"];
    [self removePinsNamed:@"panLoc"];
//    [self drawCircuitPolyline:circuit.locations withTitle:@"circuitPolyline" andColor:@"RGB 212 175 55"];
}

-(void) CenterViewOn:(CLLocationCoordinate2D) locationCoord{
    if(CLLocationCoordinate2DIsValid(locationCoord))
    {
        if (!locationCoord.longitude && !locationCoord.latitude) {
            DVLog(@"Center view: wrong coord, should try when got really valid ones");
            return;
        }
        MKCoordinateRegion region= MKCoordinateRegionMake(locationCoord, MKCoordinateSpanMake(0.003,0.003));
        [self setRegion:region animated:YES];
    }
    
}

-(void) CenterViewOnCar:(CLLocation*) carLoc andDrone:(CLLocation*) droneLoc{
    
    if (!carLoc && !droneLoc) {
        return;
    }
    else if (droneLoc && !carLoc){
        [self CenterViewOn:droneLoc.coordinate];
    }
    else if(carLoc && !droneLoc){
        [self CenterViewOn:carLoc.coordinate];
    }
    else{
        float dist_Drone_Car = [[Calc Instance] distanceFromCoords2D:carLoc.coordinate toCoords2D:droneLoc.coordinate];
        float angle = [[Calc Instance] headingTo:carLoc.coordinate fromPosition:droneLoc.coordinate];
        
        CLLocationCoordinate2D middlePoint = [[Calc Instance] predictedGPSPositionFromCurrentPosition:droneLoc.coordinate andCourse:angle andSpeed:dist_Drone_Car during:0.5];
        
        if(CLLocationCoordinate2DIsValid(middlePoint))
        {
            if (!middlePoint.longitude && !middlePoint.latitude) {
                DVLog(@"Center view: wrong coord, should try when got really valid ones");
                return;
            }
            
            float northDist = fabs(dist_Drone_Car*cos(RADIAN(angle)))*7/3;
            float eastDist = fabs(dist_Drone_Car*sin(RADIAN(angle)))*7/3;
            
            northDist = bindBetween(northDist, 100, 10000);
            eastDist = bindBetween(eastDist, 100, 10000);
            
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(middlePoint, northDist, eastDist);
            
            
            [self setRegion:region animated:YES];
        }
    }
    
}
@end
