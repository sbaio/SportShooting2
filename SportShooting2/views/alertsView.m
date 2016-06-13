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

-(void) showTakeOffAlert{
    [_takeOffAlertView.layer pop_removeAllAnimations];
    
    if (!_takeOffAlertView) {
        _takeOffAlertView = [[[NSBundle mainBundle] loadNibNamed:@"takeOffAlertView" owner:self options:nil] firstObject];
        
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"SwitchRC" withExtension:@"gif"];
        UIImage* mygif = [UIImage animatedImageWithAnimatedGIFURL:url];
        
        [_switchGIF setImage:mygif];
        _switchGIF.layer.cornerRadius = 8;
        
        _takeOffAlertView.clipsToBounds = YES;
    }
    
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
    
}

-(void) didTapOnAlertView:(UITapGestureRecognizer*) sender{
    CGPoint tapPoint = [sender locationInView:sender.view];
    CGRect currentAlertRect = _takeOffAlertView.frame;
    if (!CGRectContainsPoint(currentAlertRect, tapPoint)) {

        [self hideAlertView];
    }
    else{
        
    }
}

- (IBAction)didClickOnTakeOffButton:(id)sender {
    self.userInteractionEnabled = NO;
    
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
    }
    
    NSLog(@"takeOff with completion");
    
    POPBasicAnimation* dismissY =[POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    dismissY.toValue = @(-0);
    dismissY.duration = 1.0;
    
    [_takeOffAlertView.layer pop_addAnimation:dismissY forKey:@"dismissFly"];
    
    POPBasicAnimation* opacityAnimSelf = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    
    opacityAnimSelf.toValue = @(0);
    opacityAnimSelf.duration = 0.5;
    [opacityAnimSelf setCompletionBlock:^(POPAnimation * animation, BOOL finished) {
        NSLog(@"finished");
        [self.superview sendSubviewToBack:self];
    }];
    [self.layer pop_addAnimation:opacityAnimSelf forKey:@"opacity"];
}

- (IBAction)didClickOnCancelButton:(id)sender {
    [self hideAlertView];
    
}

-(void) hideAlertView{
    POPBasicAnimation* opacityAnimSelf = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    
    opacityAnimSelf.toValue = @(0);
    opacityAnimSelf.duration = 0.5;
    [opacityAnimSelf setCompletionBlock:^(POPAnimation * animation, BOOL finished) {
        NSLog(@"finished");
        [self.superview sendSubviewToBack:self];
    }];
    [self.layer pop_addAnimation:opacityAnimSelf forKey:@"opacity"];
}


-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    
    mapVC = [[Menu instance] getMapVC];
    dismissTapGRAlertView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnAlertView:)];
    
    [self addGestureRecognizer:dismissTapGRAlertView];
    return self;
}



@end
