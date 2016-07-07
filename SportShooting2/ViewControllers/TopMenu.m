//
//  TopMenu.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/6/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "TopMenu.h"

#import "POP.h"
@interface TopMenu ()
{
    NSArray* arrayOfNotifsNames;
}
@end

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
    frontVC = [[Menu instance] getFrontVC];
    
    Menu* menu = [Menu instance];
    menu.topMenu = self;

    arrayOfNotifsNames = [NSArray arrayWithObjects:@"RCFeedStarted",@"RCFeedStopped",@"FCFeedStarted",@"FCFeedStopped", nil];
    
    for (NSString* notifName in arrayOfNotifsNames) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:notifName object:nil];
    }
    
    
    return self;
}



-(void) showOn:(UIView*) superview{
    
    [self updateBatteryLabel];
    [self updateGPSLabel:0];
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
    if (appD.isReceivingFlightControllerStatus) {
        [_gpsLabel setText:[NSString stringWithFormat:@"%d",satelliteCount]];
    }
    else{
        [_gpsLabel setText:@"N/A"];
    }
}

-(void) updateBatteryLabelWithBatteryState:(DJIBatteryState*) batteryState{
    if (batteryState) {
        [_batteryLabel setText:[NSString stringWithFormat:@"%ld%%",(long)batteryState.batteryEnergyRemainingPercent]];
    }else{
        [_batteryLabel setText:@"N/A"];
    }
    
}
-(void) updateBatteryLabel{
    DJIBattery* battery = [ComponentHelper fetchBattery];
    
    if (!battery) {
        [_batteryLabel setText:@"N/A"];
    }else{
        [_batteryLabel setText:[NSString stringWithFormat:@"%ld%%",(long)appD.batteryState.batteryEnergyRemainingPercent]];
    }
}

-(void) updateDistDroneCarLabelWith:(CLLocation*) carLoc andDroneLoc:(CLLocation*) droneLoc{
    if (!carLoc || !droneLoc) {
        [_distDroneCarLabel setText:@"N/A"];
    }
    float dist = [[Calc Instance] distanceFromCoords2D:carLoc.coordinate toCoords2D:droneLoc.coordinate];
    if (dist < 100) {
        [_distDroneCarLabel setText:[NSString stringWithFormat:@"%0.1fm",dist]];
    }
    else{
        [_distDroneCarLabel setText:[NSString stringWithFormat:@"%0.0fm",dist]];
    }
}

-(void) updateDistDroneCarLabel{
    
}
-(void) setStatusLabelText:(NSString*) textStatus{
    [_statusLabel setText:textStatus];
}


-(void)showTakeOffButton{
    
    takeOffButtonFrame = frontVC.takeOffButton.frame;
    CGRect modifiedFrame = takeOffButtonFrame;
    
    modifiedFrame.origin.x = -200;
    frontVC.takeOffButton.frame = modifiedFrame;
    [frontVC.takeOffButton setHidden:NO];
    [frontVC.takeOffButton setAlpha:1.0];
    
    POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    positionAnimation.toValue = @(takeOffButtonFrame.origin.x + takeOffButtonFrame.size.width/2);
    positionAnimation.springBounciness = 10;
    
    [frontVC.takeOffButton.layer pop_addAnimation:positionAnimation forKey:@"takeOffButtonEntrance"];
}

-(void) hideTakeOffButton{

    CGRect initialRect = frontVC.takeOffButton.frame;
    
    POPBasicAnimation *opacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    opacityAnimation.toValue = @(0);
    
    POPBasicAnimation *X_Animation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    X_Animation.toValue = @(0);
    [opacityAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        [frontVC.takeOffButton setHidden:YES];
        frontVC.takeOffButton.frame = initialRect;
    }];
    
    [frontVC.takeOffButton.layer pop_addAnimation:X_Animation forKey:@"X_Animation"];
    [frontVC.takeOffButton.layer pop_addAnimation:opacityAnimation forKey:@"takeOffButtonDismissingOpacity"];
    

    
}


-(void)showLandButton{
    
    landButtonFrame = frontVC.landButton.frame;
    CGRect modifiedFrame = landButtonFrame;
    
    modifiedFrame.origin.x = -100;
    frontVC.landButton.frame = modifiedFrame;
    [frontVC.landButton setHidden:NO];
    [frontVC.landButton setAlpha:1.0];
    
    POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    positionAnimation.toValue = @(landButtonFrame.origin.x + landButtonFrame.size.width/2);
    positionAnimation.springBounciness = 20;
    
    [frontVC.landButton.layer pop_addAnimation:positionAnimation forKey:@"takeOffButtonEntrance"];
}

-(void) hideLandButton{
    
    CGRect initialRect = frontVC.landButton.frame;
    
    POPBasicAnimation *opacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    opacityAnimation.toValue = @(0);
    
    POPBasicAnimation *X_Animation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    X_Animation.toValue = @(0);
    [opacityAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        [frontVC.landButton setHidden:YES];
        frontVC.landButton.frame = initialRect;
    }];
    
    [frontVC.landButton.layer pop_addAnimation:X_Animation forKey:@"X_Animation"];
    [frontVC.landButton.layer pop_addAnimation:opacityAnimation forKey:@"landButtonDismissingOpacity"];
    
    
    
}



-(void) handleNotification:(NSNotification*) notification{
    BOOL respond = NO;
    for (NSString* notifName  in arrayOfNotifsNames) {
        if ([notifName isEqualToString:notification.name]) {
            respond = YES;
//            DVLog(@"responding to %@",notification.name);
        }
    }
    
    if (respond) {
        if ([notification.name isEqualToString:@"FCFeedStopped"]) {
            // update battery label
            [self updateBatteryLabelWithBatteryState:nil];
            [self updateGPSLabel:0];
            [self hideLandButton];
            [self hideTakeOffButton];
            [self setStatusLabelText:@"Disconnected"];
        }
        if ([notification.name isEqualToString:@"FCFeedStarted"]) {
            [self setStatusLabelText:@"Connected"];
            [self showTakeOffButton];
            [self showLandButton];
        }
        if ([notification.name isEqualToString:@"RCFeedStopped"]) {
            // update RC signal strength label
        }
    }
}


@end
