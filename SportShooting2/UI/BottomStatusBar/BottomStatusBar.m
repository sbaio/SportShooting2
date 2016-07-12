//
//  BottomStatusBar.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/7/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "BottomStatusBar.h"

#import "POP.h"

@implementation BottomStatusBar



-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    
    
    CGRect screenFrame = [[UIScreen mainScreen]bounds];
    float width = screenFrame.size.width;
    float height = screenFrame.size.height;

    self.frame = CGRectMake(0  , 0,11*width/20, height/13);
    self.alpha = 0.95;
    self.layer.cornerRadius = 3.0;
    
    UIImageView* backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BottomStatusBar.png"]];
    backgroundImage.frame = self.bounds;
    
    [self addSubview:backgroundImage];
    [self sendSubviewToBack:backgroundImage];
    
    self.clipsToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFCFeedStopped:) name:@"FCFeedStopped" object:nil];
    
    return self;
}


-(void) showOn:(UIView*) superview{
    [self update];
    
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
    float width = screenFrame.size.width;
    float height = screenFrame.size.height;

    self.frame = CGRectMake(0.37*width, 2*height, 11*width/20, height/13);
    
    POPBasicAnimation* y_animation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    y_animation.toValue = @(0.925*height);
    y_animation.duration = 1;
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

-(void) updateAltitudeLabelWithAltitude:(float) altitude{
    
    if (!altitude) {
        [_altitudeLabel setText:[NSString stringWithFormat:@"0 m"]];
    }
    else{
        [_altitudeLabel setText:[NSString stringWithFormat:@"%0.1f m",altitude]];
    }
}
-(void) updateDistanceToUserLabelWithDistance:(float) distance{
    if (!distance) {
        [_distanceLabel setText:[NSString stringWithFormat:@"0 m"]];
    }
    else{
        [_distanceLabel setText:[NSString stringWithFormat:@"%0.0f m",distance]];
    }
    
}
-(void) updateHorizontalSpeedWithHorizontalSpeed:(float) hSp{
    if (!hSp) {
        [_horizontalSpeedLabel setText:[NSString stringWithFormat:@"0 m/s"]];
    }
    else{
        [_horizontalSpeedLabel setText:[NSString stringWithFormat:@"%0.1f m/s",hSp]];
    }
}
-(void) updateVerticalSpeedWithHorizontalSpeed:(float) vSp{
    if (!vSp) {
        [_verticalSpeedLabel setText:[NSString stringWithFormat:@"0 m/s"]];
    }
    else{
        [_verticalSpeedLabel setText:[NSString stringWithFormat:@"%0.1f m/s",vSp]];
    }
}

-(void) updateWith:(DJIFlightControllerCurrentState*)state andPhoneLocation:(CLLocation*) phoneLoc{
    if (phoneLoc) { // if phoneLoc is valid
        [self updateDistanceToUserLabelWithDistance:[[Calc Instance] distanceFromCoords2D:phoneLoc.coordinate toCoords2D:state.aircraftLocation]];
    }
    [self updateAltitudeLabelWithAltitude:state.altitude];
    
    float horizontalSpe = sqrtf(state.velocityX*state.velocityX+state.velocityY*state.velocityY);
    [self updateHorizontalSpeedWithHorizontalSpeed:horizontalSpe];
    [self updateVerticalSpeedWithHorizontalSpeed:state.velocityZ];
}

-(void) setNA{
    [_verticalSpeedLabel setText:[NSString stringWithFormat:@"N/A"]];
    [_horizontalSpeedLabel setText:[NSString stringWithFormat:@"N/A"]];
    [_altitudeLabel setText:[NSString stringWithFormat:@"N/A"]];
    [_distanceLabel setText:[NSString stringWithFormat:@"N/A"]];
}
-(void) onFCFeedStopped:(NSNotification*) notif{
    [self setNA];
}

-(void) update{
    AppDelegate* appD = [[Menu instance] getAppDelegate];
    if (!appD.isReceivingFlightControllerStatus) {
        [self setNA];
    }
}

@end
