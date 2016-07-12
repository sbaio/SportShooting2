//
//  alertsView.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "alertsView.h"
#import "POP.h"
#import "alert.h"

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
    [frontVC.view addSubview:self];
    
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
    
    if ([[[Menu instance] getFrontVC] isShowingCircuitList]) {
        [[[Menu instance] getFrontVC].circuitsList hideCircuitList:YES];
    }
    
    [self updateSwitchStack];
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
    
    [frontVC.autopilot takeOffWithCompletion:^(NSError * _Nullable error){
        if (error) {
            [self shakeTakeoffAlertViewWithComp:^(BOOL finished) {
            }];
        }
        else{
            [self dismissTakeOffAlertY];
        }
    }];
}
- (IBAction)didClickOnCancelButton:(id)sender {
    [self dismissTakeoffAlertFade];
}


-(void) updateSwitchStack{
    if ([[Menu instance] getAppDelegate].isRCSwitch_F) {
        // good
        [switchStack setHidden:YES];
        [confirmTakeoffButton setEnabled:YES];
    }
    else{
        // show switch alert
        [switchStack setHidden:NO];
        [confirmTakeoffButton setEnabled:NO];
    }
}


-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    
    frontVC = [[Menu instance] getFrontVC];
    dismissTapGRAlertView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnAlertView:)];
    
    [self addGestureRecognizer:dismissTapGRAlertView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(RCSwitchStateChanged:) name:@"RCSwitchStateChanged" object:nil];
    
    return self;
}


-(BOOL) isShowingAnAlert{
    NSArray* arrayOfSiblings = self.superview.subviews;
    int alertIndex = (int)[arrayOfSiblings indexOfObject:self];
    int mainContentViewIndex = (int)[arrayOfSiblings indexOfObject:[[Menu instance] getFrontVC].contentView];
    
    
    if (alertIndex < mainContentViewIndex) {
        return NO;
    }
    else{
        return YES;
    }
}

-(void) RCSwitchStateChanged:(NSNotification*) notif{
    [self updateSwitchStack];
}





@end
