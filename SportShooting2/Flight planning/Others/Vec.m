//
//  Vec.m
//  SportShooting
//
//  Created by Othman Sbai on 12/11/15.
//  Copyright © 2015 Renault Silicon Valley. All rights reserved.
//

#define sign(a) ( ( (a) < 0 )  ?  -1   : ( (a) > 0 ) )

#define DEGREE(x) ((x)*180.0/M_PI)
#define RADIAN(x) ((x)*M_PI/180.0)

#define bindBetween(a,b,c) ((a > c) ? c: ((a<b)? b:a))

#import "Vec.h"
#import "DVFloatingWindow.h"
#import "Calc.h"

@implementation Vec


-(id) initWithNorm:(float) norm andAngle:(float) angle
{
    Vec *vec = [[Vec alloc] init];
    if (norm >=0) {
        vec.norm = norm;
        vec.angle = angle; //from north in deg
    }
    else if (norm < 0){
        vec.norm = fabsf(norm);
        vec.angle = [self angle180Of330Angle:angle+180];
    }
    
    vec.N = norm*cos(angle*M_PI/180.0);
    vec.E = norm*sin(angle*M_PI/180.0);
    
    return vec;
}

-(id) initWithNorthComponent:(float) vec_N andEastComponent:(float) vec_E
{
    Vec *vec = [[Vec alloc] init];
    
    vec.N = vec_N;
    vec.E = vec_E;
    vec.norm = sqrt(vec_N*vec_N+vec_E*vec_E);
    vec.angle = [self angleFromNorthOfVectorWithNorthComponent:vec_N EastComponent:vec_E]; //from north in deg
    
    return vec;
}

-(id) vectorFrom:(CLLocationCoordinate2D) coord1 toCoord:(CLLocationCoordinate2D) coord2{
    float dist = [[Calc Instance] distanceFromCoords2D:coord1 toCoords2D:coord2];
    float heading = [[Calc Instance] headingTo:coord2 fromPosition:coord1];
    Vec* new = [[Vec alloc] initWithNorm:dist andAngle:heading];
    return new;
}

-(void) updateWithNorthComponent:(float) vec_N andEastComponent:(float) vec_E{

    self.N = vec_N;
    self.E = vec_E;
    self.norm = sqrt(vec_N*vec_N+vec_E*vec_E);
    self.angle = [self angleFromNorthOfVectorWithNorthComponent:vec_N EastComponent:vec_E];
}

-(void) updateWithNorm:(float) norm andAngle:(float) angle{
    angle = bindBetween(angle, -180, 180);
    self.N = norm*cos(angle*M_PI/180.0);;
    self.E = norm*sin(angle*M_PI/180.0);
    self.norm = fabsf(norm);
    self.angle = angle;
}

-(float) dotProduct:(Vec *) vec2
{
    return self.N*vec2.N+self.E*vec2.E;
}
-(float) dotProductWithNormalEastToVector:(Vec *) vec2
{
    Vec * normalVec =[[Vec alloc] initWithNorm:vec2.norm andAngle:[self angle180Of330Angle:(vec2.angle+90)]];
    return self.N*normalVec.N+self.E*normalVec.E;
}

-(Vec *) addVector:(Vec *)vec2 //vec2 should be updated
{
    Vec * result = [[Vec alloc] init];
    float NorthComp = self.N + vec2.N;
    float EastComp = self.E + vec2.E;
    
    [result updateWithNorthComponent:NorthComp andEastComponent:EastComp];
    
    return  result;
}

-(Vec *) substractVector:(Vec *)vec2 //vec2 should be updated
{
    Vec * result = [[Vec alloc] init];
    float NorthComp = self.N - vec2.N;
    float EastComp = self.E - vec2.E;
    
    [result updateWithNorthComponent:NorthComp andEastComponent:EastComp];
    
    return  result;
}

-(Vec *) multiplyByScalar:(float) scalar
{
    Vec * result = [[Vec alloc] init];
    float NorthComp = self.N * scalar;
    float EastComp = self.E * scalar;
    
    [result updateWithNorthComponent:NorthComp andEastComponent:EastComp];
    
    return  result;
}

-(Vec *) rotateByAngle:(float) angle
{
    Vec * result = [[Vec alloc] init];
    float newAngle = [self angle180Of330Angle:(angle+self.angle)];
    [result updateWithNorm:self.norm andAngle:newAngle];
    
    return  result;
}
-(Vec*) unityVector
{
    Vec * result = [[Vec alloc] init];
    
    [result updateWithNorm:1 andAngle:self.angle];
    
    return  result;
}

-(float) angleFromNorthOfVectorWithNorthComponent:(float) vec_N EastComponent:(float) vec_E
{
    // returns the angle in degree
    float vec_Angle;
    
    if (!vec_N) {
        return sign(vec_E)*90;
    }
    if (vec_N > 0) {
        vec_Angle = atan(vec_E/vec_N);
    }
    else
    {
        if (vec_E > 0) {
            vec_Angle= M_PI + atan(vec_E/vec_N);
        }
        else{
            vec_Angle= -M_PI + atan(vec_E/vec_N);
        }
    }
    
    return vec_Angle*180.0/M_PI;
}

-(float) angle{
    return [self angleFromNorthOfVectorWithNorthComponent:self.N EastComponent:self.E];
}

-(float) norm{
    return  sqrt(self.N*self.N+self.E*self.E);
}

-(float) angle180Of330Angle:(float) angle330{
    
    float angle180;
    if (angle330 <= 180 && angle330>= -180) {
        angle180 = angle330;
    }
    else if (angle330 > 180 && angle330 <= 360)
    {
        angle180 = -360+angle330;
    }
    else if( angle330<-180 && angle330>=-360)
    {
        angle180 = 360+angle330;
    }
    else
        NSLog(@"angle330 not in range -360.. 360, %0.3f",angle330);
    
    return angle180;
}



@end
