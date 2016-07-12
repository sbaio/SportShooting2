//
//  KF1D.h
//  SportShooting2
//
//  Created by Othman Sbai on 6/20/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct{
    float x_est[2];
    float p_est[2];
    
    float filtered;
    
} KF_state;

@interface KF1D : NSObject
{
    float F[4];
    float F_transp[4];
    
    float H[2];
    
    float P[4];
    float klm_gain[2];

    
    float Q_cov[4];
    float R_cov;
    
    float x_prd[2];
    float p_pred[4];
    
}

@property KF_state state;

-(void) setCovQ:(float) Q R:(float) R;
-(void) estimateWithMeasurement:(float) meas;

@end
