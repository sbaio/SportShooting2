//
//  closeButton.h
//  Popping
//
//  Created by André Schneider on 12.05.14.
//  Copyright (c) 2014 André Schneider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface closeButton : UIButton

+ (instancetype)button;
+ (instancetype)buttonWithOrigin:(CGPoint)origin;


-(void) animateToMinusWithCompletion:(void (^)(BOOL))callback;

-(void) animateToAddWithCompletion:(void(^)(BOOL finished))callback;

- (void)animateToCloseWithCompletion:(void (^)(BOOL))callback;

-(void) setup2;
-(void) resize;



@property(nonatomic) BOOL isAdd;
@property BOOL resized;
@property (nonatomic) int status; // 0 menu , 1 close , 2 add , 3 minus

@end
