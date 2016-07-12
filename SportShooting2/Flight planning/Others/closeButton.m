//
//  closeButton.m
//  Popping
//
//  Created by André Schneider on 12.05.14.
//  Copyright (c) 2014 André Schneider. All rights reserved.
//

#import "closeButton.h"
#import "POP.h"

@interface closeButton()
@property(nonatomic) CALayer *topLayer;
@property(nonatomic) CALayer *middleLayer;
@property(nonatomic) CALayer *bottomLayer;
@property(nonatomic) BOOL showAdd;
@property(nonatomic) BOOL showingAdd;


- (void)touchUpInsideHandler:(closeButton *)sender;
- (void)animateToMenu;
- (void)removeAllAnimations;
@end

@implementation closeButton

+ (instancetype)button
{
    return [self buttonWithOrigin:CGPointZero];
}

+ (instancetype)buttonWithOrigin:(CGPoint)origin
{
    return [[self alloc] initWithFrame:CGRectMake(origin.x,
                                                  origin.y,
                                                  24,
                                                  17)];
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self setup2];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup2];
    }
    return self;
}

#pragma mark - Instance methods

- (void)tintColorDidChange
{
    CGColorRef color = [self.tintColor CGColor];
    self.topLayer.backgroundColor = [[UIColor redColor]CGColor];
    self.middleLayer.backgroundColor = color;
    self.bottomLayer.backgroundColor = [[UIColor greenColor]CGColor];//color;
}

#pragma mark - Private Instance methods

- (void)animateToMenu
{
    [self removeAllAnimations];

    CGFloat height = CGRectGetHeight(self.topLayer.bounds);

    POPBasicAnimation *fadeAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    fadeAnimation.duration = 1.0;
    fadeAnimation.toValue = @0;

    POPBasicAnimation *positionTopAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPosition];
    positionTopAnimation.duration = 0.3;
    positionTopAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.bounds),
                                                                         roundf(CGRectGetMinY(self.bounds)+(height/2)))];

    POPBasicAnimation *positionBottomAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPosition];
    positionTopAnimation.duration = 0.3;
    positionBottomAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.bounds),
                                                                            roundf(CGRectGetMaxY(self.bounds)-(height/2)))];

    POPSpringAnimation *transformTopAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
    transformTopAnimation.toValue = @(0);
    transformTopAnimation.springBounciness = 20.f;
    transformTopAnimation.springSpeed = 20;
    transformTopAnimation.dynamicsTension = 1000;

    POPSpringAnimation *transformBottomAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
    transformBottomAnimation.toValue = @(0);
    transformBottomAnimation.springBounciness = 20.0f;
    transformBottomAnimation.springSpeed = 20;
    transformBottomAnimation.dynamicsTension = 1000;

    [self.topLayer pop_addAnimation:positionTopAnimation forKey:@"positionTopAnimation"];
    [self.topLayer pop_addAnimation:transformTopAnimation forKey:@"rotateTopAnimation"];
    [self.middleLayer pop_addAnimation:fadeAnimation forKey:@"fadeAnimation"];
    [self.bottomLayer pop_addAnimation:positionBottomAnimation forKey:@"positionBottomAnimation"];
    [self.bottomLayer pop_addAnimation:transformBottomAnimation forKey:@"rotateBottomAnimation"];
    
}

-(void) animateToMinusWithCompletion_part:(void(^)(BOOL finished))callback{
    
    [self removeAllAnimations];
    
    POPSpringAnimation *transformTopAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
    transformTopAnimation.toValue = @(0);
    transformTopAnimation.springBounciness = 20.f;
    transformTopAnimation.springSpeed = 20;
    transformTopAnimation.dynamicsTension = 1000;
    
    POPSpringAnimation *transformBottomAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
    transformBottomAnimation.toValue = @(0);
    transformBottomAnimation.springBounciness = 20.0f;
    transformBottomAnimation.springSpeed = 20;
    transformBottomAnimation.dynamicsTension = 1000;
    [transformTopAnimation setCompletionBlock:^(POPAnimation* anim, BOOL finished){
        _status = 3;
        callback(finished);
        NSLog(@"finished minus");
    }];
    [self.topLayer pop_addAnimation:transformTopAnimation forKey:@"rotateTopAnimation"];
    
    [self.bottomLayer pop_addAnimation:transformBottomAnimation forKey:@"rotateBottomAnimation"];
    
    
}

-(void) animateToMinusWithCompletion:(void (^)(BOOL))callback{
    
    if (_status == 1 || _status == 2 ) {
        [self animateToMinusWithCompletion_part:^(BOOL finished) {
            callback(finished);
        }];
    }
    else if(_status == 0){
        [self animateToCloseWithCompletion_part:^(BOOL finished) {
            [self animateToMinusWithCompletion_part:^(BOOL finished) {
                callback(finished);
            }];
            
        }];
    }
    
}

-(void) animateToAddWithCompletion_part:(void(^)(BOOL finished))callback{
    
    [self removeAllAnimations];
    
    POPSpringAnimation *transformTopAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
    transformTopAnimation.toValue = @(0);
    transformTopAnimation.springBounciness = 20.f;
    transformTopAnimation.springSpeed = 20;
    transformTopAnimation.dynamicsTension = 1000;
    
    POPSpringAnimation *transformBottomAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
    transformBottomAnimation.toValue = @(-M_PI_2);
    transformBottomAnimation.springBounciness = 20.0f;
    transformBottomAnimation.springSpeed = 20;
    transformBottomAnimation.dynamicsTension = 1000;
    [transformTopAnimation setCompletionBlock:^(POPAnimation* anim, BOOL finished){
        _status = 2;
        callback(finished);
        
    }];
    [self.topLayer pop_addAnimation:transformTopAnimation forKey:@"rotateTopAnimation"];
    
    [self.bottomLayer pop_addAnimation:transformBottomAnimation forKey:@"rotateBottomAnimation"];
    
    
}

-(void) animateToAddWithCompletion:(void (^)(BOOL))callback{
    if (_status == 0) {
        
        [self animateToCloseWithCompletion:^(BOOL finished) {
            
            [self animateToAddWithCompletion_part:^(BOOL finished) {
                callback(finished);
            }];
        }];
    }
    else if (_status == 1 || _status == 3){
        [self animateToAddWithCompletion_part:^(BOOL finished) {
            callback(finished);
        }];
    }
}


-(void) animateToCloseWithCompletion_part:(void(^)(BOOL finished))callback{

    [self removeAllAnimations];
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    POPBasicAnimation *fadeAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    fadeAnimation.toValue = @0;
    fadeAnimation.duration = 0.3;
    
    POPBasicAnimation *positionTopAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPosition];
    positionTopAnimation.toValue = [NSValue valueWithCGPoint:center];
    positionTopAnimation.duration = 0.3;
    
    POPBasicAnimation *positionBottomAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPosition];
    positionBottomAnimation.toValue = [NSValue valueWithCGPoint:center];
    positionTopAnimation.duration = 0.3;
    
    POPSpringAnimation *transformTopAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
    transformTopAnimation.toValue = @(M_PI_4);
    transformTopAnimation.springBounciness = 20.f;
    transformTopAnimation.springSpeed = 20;
    transformTopAnimation.dynamicsTension = 1000;
    [transformTopAnimation setCompletionBlock:^(POPAnimation * anim, BOOL fin) {
        
        callback(fin);
    }];
    
    
    POPSpringAnimation *transformBottomAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
    transformBottomAnimation.toValue = @(-M_PI_4);
    transformBottomAnimation.springBounciness = 20.0f;
    transformBottomAnimation.springSpeed = 20;
    transformBottomAnimation.dynamicsTension = 1000;
    
    [self.topLayer pop_addAnimation:positionTopAnimation forKey:@"positionTopAnimation"];
    [self.topLayer pop_addAnimation:transformTopAnimation forKey:@"rotateTopAnimation"];
    [self.middleLayer pop_addAnimation:fadeAnimation forKey:@"fadeAnimation"];
    [self.bottomLayer pop_addAnimation:positionBottomAnimation forKey:@"positionBottomAnimation"];
    [self.bottomLayer pop_addAnimation:transformBottomAnimation forKey:@"rotateBottomAnimation"];
    
}

-(void) animateToCloseWithCompletion_part2:(void(^)(BOOL finished))callback{
    
    [self removeAllAnimations];
    
    POPSpringAnimation *transformTopAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
    transformTopAnimation.toValue = @(M_PI_4);
    transformTopAnimation.springBounciness = 20.f;
    transformTopAnimation.springSpeed = 20;
    transformTopAnimation.dynamicsTension = 1000;
    
    POPSpringAnimation *transformBottomAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
    transformBottomAnimation.toValue = @(-M_PI_4);
    transformBottomAnimation.springBounciness = 20.0f;
    transformBottomAnimation.springSpeed = 20;
    transformBottomAnimation.dynamicsTension = 1000;
    [transformTopAnimation setCompletionBlock:^(POPAnimation* anim, BOOL finished){
        _status = 1;
        callback(finished);
        NSLog(@"finished close");
    }];
    [self.topLayer pop_addAnimation:transformTopAnimation forKey:@"rotateTopAnimation"];
    
    [self.bottomLayer pop_addAnimation:transformBottomAnimation forKey:@"rotateBottomAnimation"];
    
}

- (void)animateToCloseWithCompletion:(void (^)(BOOL))callback
{
    if (_status == 0) {
        [self animateToCloseWithCompletion_part:^(BOOL finished) {
            _status = 1;
            callback(finished);
        }];
    }
    else if (_status == 2 || _status == 3){
        [self animateToCloseWithCompletion_part:^(BOOL finished) {
            _status = 1;
            callback(finished);
        }];
    }
    
}

- (void)touchUpInsideHandler:(closeButton *)sender
{
    return;
}

-(void) resize{
    CGFloat height = 2.f;
    CGFloat width = CGRectGetWidth(self.bounds);
    
    self.topLayer.frame = CGRectMake(0, CGRectGetMinY(self.bounds), width, height);
    self.middleLayer.frame = CGRectMake(0, CGRectGetMidY(self.bounds)-(height/2), width, height);
    self.bottomLayer.frame = CGRectMake(0, CGRectGetMaxY(self.bounds)-height, width, height);
    
    self.resized = YES;
}
-(void) setup2{
    CGFloat height = 2.f;
    
    CGFloat width = CGRectGetWidth(self.bounds);
    
    CGFloat cornerRadius =  1.f;
    CGColorRef color = [self.tintColor CGColor];
    self.topLayer = [CALayer layer];
    self.middleLayer = [CALayer layer];
    self.bottomLayer = [CALayer layer];
    
    self.topLayer.frame = CGRectMake(0, CGRectGetMinY(self.bounds), width, height);
    self.topLayer.cornerRadius = cornerRadius;
    self.topLayer.backgroundColor = color;
    
    self.middleLayer.frame = CGRectMake(0, CGRectGetMidY(self.bounds)-(height/2), width, height);
    self.middleLayer.cornerRadius = cornerRadius;
    self.middleLayer.backgroundColor = color;
    
    self.bottomLayer.frame = CGRectMake(0, CGRectGetMaxY(self.bounds)-height, width, height);
    self.bottomLayer.cornerRadius = cornerRadius;
    self.bottomLayer.backgroundColor = color;
    
    [self.layer addSublayer:self.topLayer];
    [self.layer addSublayer:self.middleLayer];
    [self.layer addSublayer:self.bottomLayer];
    
    _status = 0;
}



- (void)removeAllAnimations
{
    [self.topLayer pop_removeAllAnimations];
    [self.middleLayer pop_removeAllAnimations];
    [self.bottomLayer pop_removeAllAnimations];
}

@end
