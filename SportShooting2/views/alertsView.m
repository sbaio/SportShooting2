//
//  alertsView.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "alertsView.h"
#import "POP.h"

#import "UIImage+animatedGIF.h"

@implementation alertsView


-(void) didTapOnAlertView:(UITapGestureRecognizer*) sender{

    CGPoint tapPoint = [sender locationInView:sender.view];
    CGRect currentAlertRect = _takeOffAlertView.frame;
    if (!CGRectContainsPoint(currentAlertRect, tapPoint)) {

        [self dismissTakeoffAlertFade];
    }
    else{
        
    }
}

// takeoff
-(void) showTakeOffAlert{
    
    if (!_takeOffAlertView) {
        _takeOffAlertView = [[[NSBundle mainBundle] loadNibNamed:@"AlertViews" owner:self options:nil] firstObject];
        
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"SwitchRC" withExtension:@"gif"];
        UIImage* mygif = [UIImage animatedImageWithAnimatedGIFURL:url];
        
        [_switchGIF setImage:mygif];
        _switchGIF.layer.cornerRadius = 8;
        
        _takeOffAlertView.clipsToBounds = YES;
    }
    [_takeOffAlertView.layer pop_removeAllAnimations];
    
    [self setFrame:self.superview.bounds];
    [mapVC.view addSubview:self];
    
    CGPoint center = self.center;
    CGSize size = CGSizeMake(self.frame.size.width*0.6, self.frame.size.height*0.75);
    
    [_takeOffAlertView setFrame:CGRectMake(center.x-size.width/2, center.y - size.height/2 , size.width, size.height)];
    
    [self.superview bringSubviewToFront:self];
    
    if (![self.subviews containsObject:_takeOffAlertView]) {
        [self addSubview:_takeOffAlertView];
    }
    
    self.userInteractionEnabled = YES;
    self.alpha = 1.0;
    
    POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    positionAnimation.velocity = @2000;
    positionAnimation.springBounciness = 20;
    [positionAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
        
    }];
    
    POPSpringAnimation *positionAnimationY = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    positionAnimationY.toValue = @(center.y);
    positionAnimationY.springBounciness = 20;
    [positionAnimationY setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
        
    }];
    
    POPBasicAnimation* cornerAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerCornerRadius];
    cornerAnimation.fromValue = @0;
    cornerAnimation.toValue = @7.5;
    cornerAnimation.duration = 1.0f;
    
    [_takeOffAlertView.layer pop_addAnimation:cornerAnimation forKey:@"cornerAnimation"];
    [_takeOffAlertView.layer pop_addAnimation:positionAnimation forKey:@"positionAnimation"];
    [_takeOffAlertView.layer pop_addAnimation:positionAnimationY forKey:@"positionAnimationY"];
    
    if ([[[Menu instance] getMapVC] isShowingCircuitList]) {
        [[[Menu instance] getMapVC].circuitsList hideCircuitList:YES];
    }
    
}

-(void) dismissTakeOffAlertY{
    POPBasicAnimation* dismissY =[POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    dismissY.toValue = @(-0);
    dismissY.duration = 1.0;
    
    [_takeOffAlertView.layer pop_addAnimation:dismissY forKey:@"dismissFly"];
    
    POPBasicAnimation* opacityAnimSelf = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    
    opacityAnimSelf.toValue = @(0);
    opacityAnimSelf.duration = 0.5;
    [opacityAnimSelf setCompletionBlock:^(POPAnimation * animation, BOOL finished) {
        [self.superview sendSubviewToBack:self];
    }];
    [self.layer pop_addAnimation:opacityAnimSelf forKey:@"opacity"];
}
-(void) dismissTakeoffAlertFade{
    POPBasicAnimation* opacityAnimSelf = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    
    opacityAnimSelf.toValue = @(0);
    opacityAnimSelf.duration = 0.5;
    [opacityAnimSelf setCompletionBlock:^(POPAnimation * animation, BOOL finished) {
        
        [self.superview sendSubviewToBack:self];
    }];
    [self.layer pop_addAnimation:opacityAnimSelf forKey:@"opacity"];
}

-(void) shakeTakeoffAlertViewWithComp:(void (^)(BOOL finished))callback{
    
    POPSpringAnimation *shakeAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    shakeAnimation.velocity = @2000;
    shakeAnimation.springBounciness = 20;
    [shakeAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
        callback(finished);
    }];
    [_takeOffAlertView pop_addAnimation:shakeAnimation forKey:@"shakeAnimation"];
}

- (IBAction)didClickOnTakeOffButton:(id)sender {
    
    DJIFlightController* fc = [ComponentHelper fetchFlightController];
    if (fc && [[Menu instance] getAppDelegate].isReceivingFlightControllerStatus) {
        DVLog(@"taking off");
        [fc takeoffWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                DVLog(@"takeOff error : %@",error.localizedDescription);
                
            }
        }];
    }
    else{
        DVLog(@"Flight controller not found");
        [self shakeTakeoffAlertViewWithComp:^(BOOL finished) {
            [self dismissTakeoffAlertFade];
            [mapVC switchToVideo];
        }];
    }
}
- (IBAction)didClickOnCancelButton:(id)sender {
    [self dismissTakeoffAlertFade];
}


// land



-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    
    mapVC = [[Menu instance] getMapVC];
    dismissTapGRAlertView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnAlertView:)];
    
    [self addGestureRecognizer:dismissTapGRAlertView];
    return self;
}

-(BOOL) isShowingAnAlert{
    NSArray* arrayOfSiblings = self.superview.subviews;
    int alertIndex = (int)[arrayOfSiblings indexOfObject:self];
    int mainContentViewIndex = (int)[arrayOfSiblings indexOfObject:[[Menu instance] getMapVC].contentView];
    
    
    if (alertIndex < mainContentViewIndex) {
        return NO;
    }
    else{
        return YES;
    }
}


@end
