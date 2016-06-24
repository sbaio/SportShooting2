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


@interface alertsView : UIView <DJIMissionManagerDelegate>
{
    __weak MapVC* mapVC;
    UITapGestureRecognizer* dismissTapGRAlertView;
    
    __weak IBOutlet UIStackView *switchStack;
    __weak IBOutlet UIButton *confirmTakeoffButton;
    
    BOOL takeOffSucceded;
    NSArray* stepsNames;
    
}

@property (strong, nonatomic) IBOutlet UIView *takeOffAlertView;
@property (weak, nonatomic) IBOutlet UIImageView *switchGIF;

@property(nonatomic, strong) NSMutableArray* takeOffMissionSteps;
@property DJICustomMission* takeOffMission;

-(void) showTakeOffAlert;


-(BOOL) isShowingAnAlert;
@end
