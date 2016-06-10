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


- (void)setup;
-(void) animateToAdd;
-(void) animateToClose;
@end
