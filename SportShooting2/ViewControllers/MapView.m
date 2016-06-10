//
//  MapView.m
//  SportShooting
//
//  Created by Othman Sbai on 6/4/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

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
    [_mapVC showCircuitListView];
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


-(void) disableMapViewScroll{
    [self setScrollEnabled:NO];
    [_mapVC.scrollButton setImage:[UIImage imageNamed:@"pan_50.png"] forState:UIControlStateNormal];
}

-(void) enableMapViewScroll{
    [self setScrollEnabled:YES];
    [_mapVC.scrollButton setImage:[UIImage imageNamed:@"pan_yellow.png"] forState:UIControlStateNormal];
}
@end
