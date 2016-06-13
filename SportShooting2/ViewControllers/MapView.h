//
//  MapView.h
//  SportShooting
//
//  Created by Othman Sbai on 6/4/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "Menu.h"
#import "MapVC.h"
#import "Aircraft_Camera_Car_Annotation.h"
#import "Drone.h"

@class MapVC;
@class Drone;

@interface MapView : MKMapView <MKMapViewDelegate>
{
    UIButton* button;
    UIImageView* selecTrackIV;
    
    
    Aircraft_Camera_Car_Annotation* carAnnotation;
    Aircraft_Camera_Car_Annotation* droneAnno;
    Aircraft_Camera_Car_Annotation* droneSpeed_vecAnno;
    
}
@property (weak) MapVC* mapVC;

@property (nonatomic,strong) UITapGestureRecognizer* tapGRMapVideoSwitching;



-(void) disableMapViewScroll;
-(void) enableMapViewScroll;

-(void) setMapViewMaskImage:(BOOL) set;
//-(void) didEnlargeMapView;
-(void) updateMaskImageAndButton;

-(void) updateCarLocation:(CLLocation*) carLoc;
-(void) updateDroneAnnotation:(Drone*) drone;

@end
