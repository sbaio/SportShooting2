//
//  Aircraft_Camera_Car_AnnoView.m
//  SportShooting
//
//  Created by Othman Sbai on 11/20/15.
//  Copyright © 2015 Renault Silicon Valley. All rights reserved.
//

#import "Aircraft_Camera_Car_AnnoView.h"
#import "Aircraft_Camera_Car_Annotation.h"

@implementation Aircraft_Camera_Car_AnnoView



- (instancetype)initWithAnnotation:(Aircraft_Camera_Car_Annotation *)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.enabled = NO;
        self.draggable = NO;
        
        if (annotation.type==0) {
            self.image = [UIImage imageNamed:@"aircraft.png"];
            self.typeView = 0;
            annotation.identifier = @"aircraft";
        }
        else if(annotation.type==1)
        {
            self.typeView = 1;
            self.image = [UIImage imageNamed:@"car.png"];
            annotation.identifier = @"car";
        }
        else if(annotation.type==2)
        {
            self.typeView = 2;
            self.image = [UIImage imageNamed:@"cameraAnnView.png"];
            annotation.identifier = @"camera";
        }
        else if(annotation.type==3)
        {
            self.typeView = 3;
            self.image = [UIImage imageNamed:@"home.png"];
            annotation.identifier = @"home";
        }
        else if(annotation.type==4)
        {
            self.typeView = 4;
//            self.image = [UIImage imageNamed:@"flagDrone.png"]; //
//            self.image = [UIImage imageNamed:@"targetDronePosition.png"];//
//            self.image = [UIImage imageNamed:@"droneTargetLocation.png"];
            self.image = [UIImage imageNamed:@"droneTargetLocation50.png"];
            annotation.identifier = @"droneTarget";
        }
        else if(annotation.type==5)
        {
            self.typeView = 5;
            self.image = [UIImage imageNamed:@"flagCamera.png"];
            annotation.identifier = @"cameraTarget";
        }
        else if(annotation.type==6)
        {
            self.typeView = 6;
            self.image = [UIImage imageNamed:@"Me.png"];//bleu
            annotation.identifier = @"Me";
        }
        else if(annotation.type==7)
        {
            self.typeView = 7;
            self.image = [UIImage imageNamed:@"MeGPS.png"];//rouge
            annotation.identifier = @"MeGPS";
        }
        else if (annotation.type == 8)
        {
            self.typeView = 8;
            self.image = [UIImage imageNamed:@"mvtVector.png"];
            annotation.identifier = @"mvtVector";
        }
        else if (annotation.type == 9)
        {
            self.typeView = 8;
            self.image = [UIImage imageNamed:@"mvtVector_blue.png"];
            annotation.identifier = @"mvtVector";
        }
    }
    
    return self;
}


-(void) updateHeading:(float)heading
{
    self.transform = CGAffineTransformIdentity;
    self.transform = CGAffineTransformMakeRotation(heading);
}
-(void) updateScale:(float) scale{ 
    self.transform = CGAffineTransformMakeScale(1, scale);
}
-(void) updateHeading:(float)heading andScale:(float) scale{
    self.transform = CGAffineTransformIdentity;
    self.transform = CGAffineTransformMakeScale(scale,scale);
    self.transform = CGAffineTransformRotate(self.transform,heading);
}

@end
