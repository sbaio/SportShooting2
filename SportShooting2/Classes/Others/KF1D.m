//
//  KF1D.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/20/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "KF1D.h"

@implementation KF1D

-(id) init{
    self = [super init];
    
    memset(&_state, 0, sizeof(KF_state));
    [self setMeasurementMatrix];
    [self setTransitionMatrix];
    
    [self setInitialState:0 V:0];
    
    
    return self;
}

-(void) setInitialState:(float) x V:(float) V{
    _state.x_est[0] = x;
    _state.x_est[1] = V;
}

-(void) setCovQ:(float) Q R:(float) R{
    R_cov = R;
    Q_cov[0] = Q;
    Q_cov[1] = 0;
    Q_cov[2] = 0;
    Q_cov[3] = Q;
}

-(void) setTransitionMatrix{
    F[0] = 1;
    F[1] = 1;
    F[2] = 0;
    F[3] = 1;
    
    F_transp[0] = 1;
    F_transp[1] = 0;
    F_transp[2] = 1;
    F_transp[3] = 1;
}
-(void) setMeasurementMatrix{
    H[0] = 1;
    H[1] = 0;
}


-(void) predictNextState{
   
//    float x_prd[2];
    float a[4];
    float a21;
    
    float S;
    
    // I-1. State prediction : form previous state, make a guess
    for (int k = 0; k< 2; k++) {
        x_prd[k] = 0;
        for (int r2 = 0; r2 < 2; r2++) {
            x_prd[k] +=  F[k + 2*r2]*_state.x_est[r2]; // x$(k +1|k )= F(k ) x$(k| k)
        }
        
        
        // II-1.a State prediction cov P(k+1/k) = F(k)P(k/k) stored in
        
        for (int r2 = 0; r2 < 2; r2++) {
            a[k+2*r2] = 0;
            for (int i0 = 0; i0 < 2; i0++) {
                a[k+2*r2] += F[k+2*i0]*_state.p_est[i0+2*r2];
            }
        }
    }
    
    // II-1.b State prediciton covariance : P(k+1/k) = F(k)P(k/k)F(k)' + Q(k)
    for (int r2 = 0; r2 < 2; r2 ++) {
        for (int i0 = 0; i0 < 2; i0++) {
            a21 = 0;
            for (int r1 = 0; r1 < 2; r1 ++) {
                a21 += a[r2 +2*r1]*F_transp[r1+2*i0];
            }
            p_pred[r2+2*i0] = a21 + Q_cov[r2+2*i0];
        }
    }
    
    // II-2.a Calcul de S(k+1) : P(k+1)H(k+1)'
    for (int i0 = 0; i0 < 2; i0++) {
        klm_gain[i0] = 0.0;
        for (int r1 = 0; r1 < 2; r1++) {
            klm_gain[i0] += H[r1] * p_pred[i0 + 2*r1];
        }
    }
    
    // 2 eme étape ---->  S(k+1) = H(k+1)P(k+1)H(k+1)' +R(k+1)
    a21 = 0;
    for (int i =0; i<2; i++) {
        a21 += klm_gain[i]*H[i];
    }
    S = a21 + R_cov;
    
    // II-3. gain calculation
    for (int i = 0; i<2; i++) {
        klm_gain[i] = 0;
        for (int j = 0; j<2; j++) {
            klm_gain[i] += H[i]*p_pred[i+2*j];
            klm_gain[i] /=S;
        }
    }
    
}

-(void) estimateWithMeasurement:(float) meas{
    [self predictNextState];
    float residu = 0;
    float meas_pred = 0;
    float a[4];
    
    for (int i = 0; i<2; i++) {
        meas_pred += H[i]*x_prd[i];
    }
    
    residu = meas - meas_pred;
    
    for (int i = 0; i<2; i++) {
        _state.x_est[i] = x_prd[i] + klm_gain[i]*residu;
    }
    
    
    // update state covariance
    for (int i = 0; i< 2; i++) {
        for (int j = 0; j<2 ; j++) {
            a[i+2*j] = klm_gain[i]*H[j];
        }
    }
    for (int i =0; i<2; i++) {
        for (int j = 0; j<2; j++) {
            
            float c = 0;
            for (int k =0; k<2 ; k++) {
                c += a[i+2*k]*p_pred[k+2*j];
            }
            _state.p_est[i+2*j] = p_pred[i+2*j]-c;
        }
    }
    
    
    _state.filtered = _state.x_est[0];
}

@end
