//
//  BottomStatusBar.h
//  SportShooting2
//
//  Created by Othman Sbai on 6/7/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DJISDK/DJISDK.h>
#import "AppDelegate.h"
#import "Menu.h"
#import "ComponentHelper.h"
#import "Calc.h"

@interface BottomStatusBar : UIView


-(void) showOn:(UIView*) superview;
-(void) hideFrom:(UIView*) superview;


-(void) updateAltitudeLabelWithAltitude:(float) altitude;
-(void) updateDistanceToRCLabelWithDistance:(float) distance;
-(void) updateHorizontalSpeedWithHorizontalSpeed:(float) hSp;
-(void) updateVerticalSpeedWithHorizontalSpeed:(float) vSp;

-(void) update;

-(void) updateWith:(DJIFlightControllerCurrentState*)state andPhoneLocation:(CLLocation*) phoneLoc;

@property (weak, nonatomic) IBOutlet UILabel *horizontalSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *verticalSpeedLabel;

@property (weak, nonatomic) IBOutlet UILabel *altitudeLabel;

@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;






@end
