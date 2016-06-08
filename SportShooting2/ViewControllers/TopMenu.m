//
//  TopMenu.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/6/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "TopMenu.h"

#import "POP.h"

@implementation TopMenu

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    
    CGRect screenFrame = [[UIScreen mainScreen]bounds];
    
    self.frame = CGRectMake(0  , 0,screenFrame.size.width, screenFrame.size.height/10);
    self.alpha = 0.95;
    self.layer.cornerRadius = 3.0;
    
    UIImageView* backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"topmenuBackground.png"]];
    backgroundImage.frame = self.bounds;
    
    [self addSubview:backgroundImage];
    [self sendSubviewToBack:backgroundImage];
    
    self.clipsToBounds =  YES;
    appD = [[Menu instance] getAppDelegate];
    mapVC = [[Menu instance] getMapVC];
    
    Menu* menu = [Menu instance];
    menu.topMenu = self;
    
    [_batteryLabel setText:@"N/A"];
    [_gpsLabel setText:@"N/A"];

    return self;
}

-(void) showOn:(UIView*) superview{
    BOOL alreadyExists = NO;
    
    for (UIView* subview in [superview subviews]) {
        if ([subview isKindOfClass:[self class]]) {
            alreadyExists = YES;
        }
    }
    if (!alreadyExists) {
        [superview addSubview:self];
    }
    CGRect screenFrame = [[UIScreen mainScreen]bounds];
    CGRect frame = CGRectMake(0  , 0,screenFrame.size.width, screenFrame.size.height/10);
    
    CGRect modifiedFrame = CGRectMake(frame.origin.x, frame.origin.y-frame.size.height, frame.size.width, frame.size.height);
    self.frame = modifiedFrame;
    
    POPBasicAnimation* y_animation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    y_animation.toValue = @(frame.size.height/2);
    y_animation.duration = 1.5;
    [y_animation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        
    }];
    [self.layer pop_addAnimation:y_animation forKey:@"y_animation"];
}

-(void) hideFrom:(UIView*) superview{
    BOOL exists = NO;
    
    for (UIView* subview in [superview subviews]) {
        if ([subview isKindOfClass:[self class]]) {
            exists = YES;
        }
    }
    if (!exists) {
        // doesnt exist on superview /... already hidden
    }
    else{
        CGRect screenFrame = [[UIScreen mainScreen]bounds];
        CGRect frame = CGRectMake(0  , 0,screenFrame.size.width, screenFrame.size.height/10);
        
        POPBasicAnimation* y_animation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionY];
        y_animation.toValue = @(-frame.size.height/2);
        y_animation.duration = 1.5;
        [y_animation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
            
        }];
        [self.layer pop_addAnimation:y_animation forKey:@"y_animation"];
    }
}

- (IBAction)onMenuButtonClicked:(id)sender {
    [[[Menu instance]getMainRevealVC] setFrontViewPosition:FrontViewPositionRightMost animated:YES];
}

-(void) updateGPSLabel:(int) satelliteCount{
    if (appD.isConnectedToDrone) {
        [_gpsLabel setText:[NSString stringWithFormat:@"%d",satelliteCount]];
    }
    else{
        [_gpsLabel setText:@"N/A"];
    }
}

-(void) updateBatteryLabelWithBatteryState:(DJIBatteryState*) batteryState{
    [_batteryLabel setText:[NSString stringWithFormat:@"%ld%%",(long)batteryState.batteryEnergyRemainingPercent]];
}
-(void) updateBatteryLabel{
    DJIBattery* battery = [ComponentHelper fetchBattery];
    
    if (!battery) {
        [_batteryLabel setText:@"N/A"];
    }else{
        [_batteryLabel setText:[NSString stringWithFormat:@"%ld%%",(long)appD.batteryState.batteryEnergyRemainingPercent]];
    }
}

-(void) setStatusLabelText:(NSString*) textStatus{
    [_statusLabel setText:textStatus];
}


-(void)showTakeOffButton{
    
    takeOffButtonFrame = mapVC.takeOffButton.frame;
    CGRect modifiedFrame = takeOffButtonFrame;
    
    modifiedFrame.origin.x = -200;
    mapVC.takeOffButton.frame = modifiedFrame;
    [mapVC.takeOffButton setHidden:NO];
    [mapVC.takeOffButton setAlpha:1.0];
    
    POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    positionAnimation.toValue = @(takeOffButtonFrame.origin.x + takeOffButtonFrame.size.width/2);
    positionAnimation.springBounciness = 20;
    
    [mapVC.takeOffButton.layer pop_addAnimation:positionAnimation forKey:@"takeOffButtonEntrance"];
}

-(void) hideTakeOffButton{

    CGRect initialRect = mapVC.takeOffButton.frame;
    
    POPBasicAnimation *opacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    opacityAnimation.toValue = @(0);
    
    POPBasicAnimation *X_Animation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    X_Animation.toValue = @(0);
    [opacityAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        [mapVC.takeOffButton setHidden:YES];
        mapVC.takeOffButton.frame = initialRect;
    }];
    
    [mapVC.takeOffButton.layer pop_addAnimation:X_Animation forKey:@"X_Animation"];
    [mapVC.takeOffButton.layer pop_addAnimation:opacityAnimation forKey:@"takeOffButtonDismissingOpacity"];
    

    
}
























@end
