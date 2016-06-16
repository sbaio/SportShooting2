//
//  Aircraft_Camera_Car_Annotation.m
//  SportShooting
//
//  Created by Othman Sbai on 11/20/15.
//  Copyright © 2015 Renault Silicon Valley. All rights reserved.
//

#import "Aircraft_Camera_Car_Annotation.h"

@implementation Aircraft_Camera_Car_Annotation

-(id) initWithCoordiante:(CLLocationCoordinate2D)coordinate andType:(NSInteger)type
{
    self = [super init];
    if (self) {
        _coordinate = coordinate;
        _type = type;
        
    }
    _annotationView =[[Aircraft_Camera_Car_AnnoView alloc] initWithAnnotation:self reuseIdentifier:_identifier];
    
    return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    _coordinate = newCoordinate;
}

-(void) updateHeading:(float)heading
{
    if (self.annotationView) {
        [self.annotationView updateHeading:heading];
    }
   // NSLog(@"updateHeading");
}

-(void) updateScale:(float)scale{
    if (self.annotationView) {
        [self.annotationView updateScale:scale];
    }
}
-(void) updateHeading:(float)heading andScale:(float) scale{
    if (self.annotationView) {
        [self.annotationView updateHeading:heading andScale:scale];
    }
}
@end


