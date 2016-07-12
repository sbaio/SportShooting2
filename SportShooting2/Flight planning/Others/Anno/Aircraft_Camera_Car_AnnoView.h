//
//  Aircraft_Camera_Car_AnnoView.h
//  SportShooting
//
//  Created by Othman Sbai on 11/20/15.
//  Copyright © 2015 Renault Silicon Valley. All rights reserved.
//

#import <MapKit/MapKit.h>


@interface Aircraft_Camera_Car_AnnoView : MKAnnotationView

@property(nonatomic) NSInteger typeView;

-(void) updateHeading:(float)heading;
-(void) updateScale:(float) scale;
-(void) updateHeading:(float)heading andScale:(float) scale;

@end