//
//  MapView.m
//  SportShooting
//
//  Created by Othman Sbai on 6/4/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "MapView.h"

@interface MapView (){
    UIImageView* layerImage;
}

@end
@implementation MapView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)commonInit
{
    layerImage = [[UIImageView alloc] initWithFrame:self.bounds];
    layerImage.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    layerImage.backgroundColor = [UIColor redColor];
    layerImage.alpha = 0.5;
    
    [self addSubview:layerImage];
    
    self.delegate = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setRegion:MKCoordinateRegionMake(self.userLocation.coordinate, MKCoordinateSpanMake(0.01, 0.01)) animated:YES];
    });
    
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
