//
//  alertsView.h
//  SportShooting2
//
//  Created by Othman Sbai on 6/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Menu.h"
#import "MapVC.h"


@interface alertsView : UIView
{
    __weak MapVC* mapVC;
    UITapGestureRecognizer* dismissTapGRAlertView;
    
//    UIView* takeOffAlertView;
}

@property (strong, nonatomic) IBOutlet UIView *takeOffAlertView;
@property (weak, nonatomic) IBOutlet UIImageView *switchGIF;


-(void) showTakeOffAlert;

@end
