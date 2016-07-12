//
//  Vec.h
//  SportShooting
//
//  Created by Othman Sbai on 12/11/15.
//  Copyright © 2015 Renault Silicon Valley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface Vec : NSObject
{
    
}

@property (nonatomic) float norm; // module
@property (nonatomic) float angle;
@property (nonatomic) float N;
@property (nonatomic) float E;


-(id) initWithNorm:(float) norm andAngle:(float) angle;
-(id) initWithNorthComponent:(float) vec_N andEastComponent:(float) vec_E;
-(void) updateWithNorthComponent:(float) vec_N andEastComponent:(float) vec_E;
-(void) updateWithNorm:(float) norm andAngle:(float) angle;

-(float) angleFromNorthOfVectorWithNorthComponent:(float) vec_N EastComponent:(float) vec_E;

-(float) dotProductWithNormalEastToVector:(Vec *) vec2;
-(float) dotProduct:(Vec *) vec2;

-(Vec *) addVector:(Vec *)vec2 ;//vec2 should be updated
-(Vec *) substractVector:(Vec *)vec2;
-(Vec *) multiplyByScalar:(float) scalar;
-(Vec *) rotateByAngle:(float) angle;
-(Vec*) unityVector;

-(float) norm;
-(float) angle;

@end
