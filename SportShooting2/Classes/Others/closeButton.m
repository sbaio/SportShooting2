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
- (void)animateToClose;
-(void) animateToAdd;
- (void)setup;
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
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
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
    NSLog(@"showing menu");
}

-(void) animateToAdd{
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
    
    [self.topLayer pop_addAnimation:transformTopAnimation forKey:@"rotateTopAnimation"];
    
    [self.bottomLayer pop_addAnimation:transformBottomAnimation forKey:@"rotateBottomAnimation"];
    
    self.showAdd = NO;
    self.showingAdd = YES;
    NSLog(@"showing add");
}

- (void)animateToClose
{
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
    self.showAdd = YES;
    self.showingAdd = NO;
    NSLog(@"showing close");
}

- (void)touchUpInsideHandler:(closeButton *)sender
{
    if (self.showAdd) {
//        [self animateToMenu];
        [self animateToAdd];
    } else {
        [self animateToClose];
    }
//    self.showAdd = !self.showAdd;
}

- (void)setup
{
    CGFloat height = 2.f;
    
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat cornerRadius =  1.f;
    CGColorRef color = [self.tintColor CGColor];

    if (!self.topLayer) {
        self.topLayer = [CALayer layer];
    }
    if (!self.middleLayer) {
        self.middleLayer = [CALayer layer];
    }
    if (!self.bottomLayer) {
        self.bottomLayer = [CALayer layer];
    }
    
    self.topLayer.frame = CGRectMake(0, CGRectGetMinY(self.bounds), width, height);
    self.topLayer.cornerRadius = cornerRadius;
    self.topLayer.backgroundColor = color;

    self.middleLayer.frame = CGRectMake(0, CGRectGetMidY(self.bounds)-(height/2), width, height);
    self.middleLayer.cornerRadius = cornerRadius;
    self.middleLayer.backgroundColor = color;
    
    self.bottomLayer.frame = CGRectMake(0, CGRectGetMaxY(self.bounds)-height, width, height);
    self.bottomLayer.cornerRadius = cornerRadius;
    self.bottomLayer.backgroundColor = color;

    if (![[self.layer sublayers] containsObject:self.topLayer]) {
        [self.layer addSublayer:self.topLayer];
    }
    if (![[self.layer sublayers] containsObject:self.middleLayer]) {
//        [self.layer addSublayer:self.middleLayer];
    }
    if (![[self.layer sublayers] containsObject:self.bottomLayer]) {
        [self.layer addSublayer:self.bottomLayer];
    }
//    [self addTarget:self
//             action:@selector(touchUpInsideHandler:)
//   forControlEvents:UIControlEventTouchUpInside];
    
    [self animateToClose];
}

- (void)removeAllAnimations
{
    [self.topLayer pop_removeAllAnimations];
    [self.middleLayer pop_removeAllAnimations];
    [self.bottomLayer pop_removeAllAnimations];
}

@end
