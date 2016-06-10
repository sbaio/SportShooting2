//
//  alertsView.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "alertsView.h"
#import "POP.h"

@implementation alertsView

-(void) showTakeOffAlert{
    
    if (!_takeOffAlertView) {
        _takeOffAlertView = [[[NSBundle mainBundle] loadNibNamed:@"takeOffAlertView" owner:self options:nil] firstObject];
    }
    
    [self setFrame:self.superview.bounds];
    [mapVC.view addSubview:self];
    
    CGPoint center = self.center;
    CGSize size = CGSizeMake(self.frame.size.width*0.4, self.frame.size.height*0.7);
    
    [_takeOffAlertView setFrame:CGRectMake(center.x-size.width/2, center.y - size.height/2 , size.width, size.height)];
    
    [self.superview bringSubviewToFront:self];
    
    [self addSubview:_takeOffAlertView];
    
    POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    positionAnimation.velocity = @2000;
    positionAnimation.springBounciness = 20;
    [positionAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
        
    }];
    
    POPBasicAnimation* cornerAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerCornerRadius];
    cornerAnimation.fromValue = @0;
    cornerAnimation.toValue = @7.5;
    cornerAnimation.duration = 1.0f;
    
    [_takeOffAlertView.layer pop_addAnimation:cornerAnimation forKey:@"cornerAnimation"];
    [_takeOffAlertView.layer pop_addAnimation:positionAnimation forKey:@"positionAnimation"];
    
}

-(void) hideAlertView{
    [self.superview sendSubviewToBack:self];
}

-(void) didTapOnAlertView:(UITapGestureRecognizer*) sender{
    CGPoint tapPoint = [sender locationInView:sender.view];
    CGRect currentAlertRect = _takeOffAlertView.frame;
    if (!CGRectContainsPoint(currentAlertRect, tapPoint)) {
//        NSLog(@"dismiss");
        [self.superview sendSubviewToBack:self];
    }
    else{
        NSLog(@"not dismiss");
    }
}


-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    
    mapVC = [[Menu instance] getMapVC];
    dismissTapGRAlertView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnAlertView:)];
    
    [self addGestureRecognizer:dismissTapGRAlertView];
    return self;
}



@end
