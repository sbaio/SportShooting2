//
//  KalmanFilter1D.m
//  SportShooting
//
//  Created by Othman Sbai on 5/18/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "KalmanFilter1D.h"

@implementation KalmanFilter1D


-(id) init{
    self = [super init];
    
    memset(&_state, 0, sizeof(KF_State));
    
    for (int i = 0; i < 6; i++) {
        _state.x_est[i] = 0.0;
    }
    
    
    
    /*  x_est=[x,y,Vx,Vy,Ax,Ay]' */
//    memset(&_state.p_est[0], 0, 36U * sizeof(double));
    
    return self;
}

-(void) setQ:(float) Q andR:(float) R{
    _state.R = R;
    _state.Q = Q;
}

-(void) filter:(double) z1{
    
    signed char Q[36];
    int r2;
    double a[36];
    int k;
    double x_prd[6];
    // b_a state transition matrix ? to transform x_est to new guess
    static const signed char b_a[36] = { 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0,
        1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1 };
    
    int i0;
    double p_prd[36];
    double a21;
    int r1;
    // b transposée de  b_a  ... transition state matrix F
    static const signed char b[36] = { 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1,
        0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1 };
    
    double klm_gain[12];
    
    // c_a is the measurement matrix (6x2) takes the state x$ and gives only (x,y) --> H
    static const signed char c_a[12] = { 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 };
    
    double S[4];
    // transposée de H .. de c_a (2x6)
    static const signed char b_b[12] = { 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0 };
    
    float R[4] = { _state.R , 0, 0, _state.R };
    // R is The measurement noise covariance
    
    double B[12];
    double a22;
    double Y[12];
    double b_z[2];
    
    /*  Initialize state transition matrix */
    /*      % [x ] */
    /*      % [y ] */
    /*      % [Vx] */
    /*      % [Vy] */
    /*      % [Ax] */
    /*      % [Ay] */
    /*  Initialize measurement matrix */
    for (r2 = 0; r2 < 36; r2++) {
        Q[r2] = 0;
    }
    
    for (k = 0; k < 6; k++) {
        // previous
        Q[k + 6 * k] = _state.Q;
        
        /*  Initial state conditions */
        /*  Predicted state and covariance */
        
        // --> State Prediction
        // from previous state.x_est we try to make a guess
        // x$(k +1|k )= F(k ) x$(k| k)
        
        x_prd[k] = 0.0;
        for (r2 = 0; r2 < 6; r2++) {
            x_prd[k] += (double)b_a[k + 6 * r2] * _state.x_est[r2];
        }
        
        // 1. State prediction covariance  P(k+1/k) = F(k)P(k/k)
        for (r2 = 0; r2 < 6; r2++) {
            a[k + 6 * r2] = 0.0;
            for (i0 = 0; i0 < 6; i0++) {
                a[k + 6 * r2] += (double)b_a[k + 6 * i0] * _state.p_est[i0 + 6 * r2];
            }
        }
    }
    
    // suite de State prediciton covariance : P(k+1/k) = F(k)P(k/k)F(k)' + Q(k)
    for (r2 = 0; r2 < 6; r2++) {
        for (i0 = 0; i0 < 6; i0++) {
            a21 = 0.0;
            for (r1 = 0; r1 < 6; r1++) {
                a21 += a[r2 + 6 * r1] * (double)b[r1 + 6 * i0]; // b transpose de F ?
            }
            
            p_prd[r2 + 6 * i0] = a21 + (double)Q[r2 + 6 * i0];
        }
    }
    
    /*  Estimation */
    
    // 2. Measurement prediction covariance ... calcul de S(k+1)
    // 1 ere étape de calcul intermédiaire P(k+1)H(k+1)'
    for (r2 = 0; r2 < 2; r2++) {
        for (i0 = 0; i0 < 6; i0++) {
            klm_gain[r2 + (i0 << 1)] = 0.0;
            for (r1 = 0; r1 < 6; r1++) {
                klm_gain[r2 + (i0 << 1)] += (double)c_a[r2 + (r1 << 1)] * p_prd[i0 + 6 *
                                                                                r1];
            }
        }
    }
    
    // 2 eme étape ---->  S(k+1) = H(k+1)P(k+1)H(k+1)' +R(k+1)
    for (r2 = 0; r2 < 2; r2++) {
        for (i0 = 0; i0 < 2; i0++) {
            a21 = 0.0;
            for (r1 = 0; r1 < 6; r1++) {
                a21 += klm_gain[r2 + (r1 << 1)] * (double)b_b[r1 + 6 * i0];
            }
            
            S[r2 + (i0 << 1)] = a21 + (double)R[r2 + (i0 << 1)];
        }
    }
    //filter gain calculation  B = P(k+1/k)H(k+1)'
    
    for (r2 = 0; r2 < 2; r2++) {
        for (i0 = 0; i0 < 6; i0++) {
            B[r2 + (i0 << 1)] = 0.0;
            for (r1 = 0; r1 < 6; r1++) {
                B[r2 + (i0 << 1)] += (double)c_a[r2 + (r1 << 1)] * p_prd[i0 + 6 * r1];
            }
        }
    }
    
    // inversion de la matrice S (2x2) --> calcul de S(k+1)^(-1)
    if (fabs(S[1]) > fabs(S[0])) {
        r1 = 1;
        r2 = 0;
    } else {
        r1 = 0;
        r2 = 1;
    }
    
    // inversion de S par methode du determinant
    a21 = S[r2] / S[r1];
    a22 = S[2 + r2] - a21 * S[2 + r1];
    for (k = 0; k < 6; k++) {
        Y[1 + (k << 1)] = (B[r2 + (k << 1)] - B[r1 + (k << 1)] * a21) / a22;
        Y[k << 1] = (B[r1 + (k << 1)] - Y[1 + (k << 1)] * S[2 + r1]) / S[r1];
    }
    
    for (r2 = 0; r2 < 2; r2++) {
        for (i0 = 0; i0 < 6; i0++) {
            klm_gain[i0 + 6 * r2] = Y[r2 + (i0 << 1)];
        }
    }
    
    /*  Estimated state and covariance */
    for (r2 = 0; r2 < 2; r2++) {
        a21 = 0.0;
        for (i0 = 0; i0 < 6; i0++) {
            a21 += (double)c_a[r2 + (i0 << 1)] * x_prd[i0];
        }
        
        b_z[r2] = z1 - a21;
    }
    
    for (r2 = 0; r2 < 6; r2++) {
        a21 = 0.0;
        for (i0 = 0; i0 < 2; i0++) {
            a21 += klm_gain[r2 + 6 * i0] * b_z[i0];
        }
        
        _state.x_est[r2] = x_prd[r2] + a21;
    }
    
    for (r2 = 0; r2 < 6; r2++) {
        for (i0 = 0; i0 < 6; i0++) {
            a[r2 + 6 * i0] = 0.0;
            for (r1 = 0; r1 < 2; r1++) {
                a[r2 + 6 * i0] += klm_gain[r2 + 6 * r1] * (double)c_a[r1 + (i0 << 1)];
            }
        }
    }
    // updated State Covariance
    for (r2 = 0; r2 < 6; r2++) {
        for (i0 = 0; i0 < 6; i0++) {
            a21 = 0.0;
            for (r1 = 0; r1 < 6; r1++) {
                a21 += a[r2 + 6 * r1] * p_prd[r1 + 6 * i0];
            }
            
            _state.p_est[r2 + 6 * i0] = p_prd[r2 + 6 * i0] - a21;
        }
    }
    
    /*  Compute the estimated measurements */
    for (r2 = 0; r2 < 2; r2++) {
        _state.y[r2] = 0.0;
        for (i0 = 0; i0 < 6; i0++) {
            _state.y[r2] += (double)c_a[r2 + (i0 << 1)] * _state.x_est[i0];
        }
    }
    
    /*  of the function */
}
@end
