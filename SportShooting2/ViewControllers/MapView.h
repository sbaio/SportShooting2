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

@class MapVC;

@interface MapView : MKMapView <MKMapViewDelegate>
{
    
}
@property (weak) MapVC* mapVC;

@property (nonatomic,strong) UITapGestureRecognizer* tapGRMapVideoSwitching;



-(void) disableMapViewScroll;
-(void) enableMapViewScroll;

-(void) setMapViewMaskImage:(BOOL) set;

@end
