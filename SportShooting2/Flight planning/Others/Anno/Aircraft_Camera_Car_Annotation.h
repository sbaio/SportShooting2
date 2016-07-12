//
//  Aircraft_Camera_Car_Annotation.h
//  SportShooting
//
//  Created by Othman Sbai on 11/20/15.
//  Copyright © 2015 Renault Silicon Valley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "Aircraft_Camera_Car_AnnoView.h"

@interface Aircraft_Camera_Car_Annotation : NSObject<MKAnnotation>



@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic,readonly) NSInteger type;
@property(nonatomic) NSString* identifier;
@property(nonatomic, strong) Aircraft_Camera_Car_AnnoView* annotationView;

-(id) initWithCoordiante:(CLLocationCoordinate2D)coordinate andType:(NSInteger) type;

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;

-(void) updateHeading:(float)heading;
-(void) updateScale:(float) scale;
-(void) updateHeading:(float)heading andScale:(float) scale;


@end

