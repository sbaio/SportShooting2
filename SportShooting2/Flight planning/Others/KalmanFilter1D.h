//
//  KalmanFilter1D.h
//  SportShooting
//
//  Created by Othman Sbai on 5/18/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KalmanFilter1D : NSObject

typedef struct{
    float x_est[6];
    float p_est[36];
    double y[2];
    
    float Q;
    float R;
} KF_State;



@property KF_State state;


-(void) filter:(double) z1;
-(void) setQ:(float) Q andR:(float) R;
@end
