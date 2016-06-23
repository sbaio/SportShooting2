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
@class Circuit;

@interface MapView : MKMapView <MKMapViewDelegate>
{
    UIButton* button;
    UIImageView* selecTrackIV;
    
    
    Aircraft_Camera_Car_Annotation* carAnnotation;
//    Aircraft_Camera_Car_Annotation* droneAnno;
//    Aircraft_Camera_Car_Annotation* droneSpeed_vecAnno;
    
}
@property (weak) MapVC* mapVC;

@property (nonatomic,strong) UITapGestureRecognizer* tapGRMapVideoSwitching;



-(void) disableMapViewScroll;
-(void) enableMapViewScroll;

-(void) setMapViewMaskImage:(BOOL) set;
//-(void) didEnlargeMapView;
-(void) updateMaskImageAndButton;

// annotations
-(void) updateCarLocation:(CLLocation*) carLoc;
-(void) updateDroneAnnotation:(Drone*) drone;
-(void) updateDroneSensCircuit_PerpAnnotations:(Drone*) drone;
-(void) updateDrone:(Drone*) drone Vec_Anno_WithTargetSpeed:(float) targSp AndTargetHeading:(float) targHeading;
-(void) updateGimbalAnnoOfDrone:(Drone*) drone;


// mapview methods
-(void) addPin:(CLLocation*) location andTitle:(NSString*) title andColor:(NSString*) colorString;
-(void) removePinsNamed:(NSString*) pinName;
-(void) showCircuit:(Circuit*) circuit;

-(void) CenterViewOn:(CLLocationCoordinate2D) locationCoord;
-(void) CenterViewOnCar:(CLLocation*) carLoc andDrone:(CLLocation*) droneLoc;

-(void) movePinNamed:(NSString*) name toCoord:(CLLocation*) newLoc andColor:(NSString*) colorString;

@end
