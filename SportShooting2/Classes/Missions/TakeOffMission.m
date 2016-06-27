//
//  TakeOffMission.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/24/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "TakeOffMission.h"

@interface TakeOffMission()
{
    NSMutableArray* takeOffMissionSteps;
    NSArray* takeOffstepNames;
}
@end

@implementation TakeOffMission

-(instancetype)init {
    
    takeOffMissionSteps = [[NSMutableArray alloc] init];
    takeOffstepNames = [NSArray arrayWithObjects:@"Taking off",@"going Up to 11m", nil];
    
    DJIMissionStep* takeoffStep = [[DJITakeoffStep alloc] init];
    [takeOffMissionSteps addObject:takeoffStep];
    
    DJIMissionStep* goUpStep = [[DJIGoToStep alloc] initWithAltitude:11];
    [takeOffMissionSteps addObject:goUpStep];
    
    self = [super initWithSteps:takeOffMissionSteps];
    
    return self;
}

// should set the delegate when the takeoff is launched

-(void) startWithCompletion:(void(^)(NSError * _Nullable error))callback{
    [[DJIMissionManager sharedInstance] setDelegate:self];
    
    [[DJIMissionManager sharedInstance] prepareMission:self withProgress:^(float progress) {
        
    } withCompletion:^(NSError * _Nullable error) {
        if (error) {
            ShowResult(@"ERROR while preparing takeOff mission: %@", error.localizedDescription);

            callback(error);
        }
        else {
            [[DJIMissionManager sharedInstance] startMissionExecutionWithCompletion:^(NSError * _Nullable error) {
                callback(error);
                if (error) {
                    ShowResult(@"ERROR while starting takeoff mission %@", error.localizedDescription);
                }
                else{
                    [self takeoffMissionDidStart];
                }
            }];
            
        }
    }];
}

-(void) takeoffMissionDidStart{
    
}


@end
