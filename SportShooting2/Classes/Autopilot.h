//
//  Autopilot.h
//  SportShooting2
//
//  Created by Othman Sbai on 1/25/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJISDK.h>

#import "ComponentHelper.h"
#import "Vec.h"
#import "Drone.h"
#import "MapVC.h"
#import "mapView.h"

/* inputs of Autopilot are:
 
 --> flightController callbacks
 --> car gps position and course
 
 --> gimbal callback
 --> tracker output
 
 
 outputs of Autopilot are
 --> flightCommand to send to drone
 --> gimbal commands
 
 */

@class Drone;
@class MapVC;
@class MapView;

struct PitchRoll {
    float pitch;
    float roll;
    BOOL coordSystem; // YES Body coord, NO Earth Coord
    BOOL angleOrVelocity; // YES for angle, NO for velocity
};

struct Yaw {
    float yaw;
    BOOL palstance; // yes speed controlled, NO --> degree controlled
};

struct Altitude {
    float altitude;
    BOOL position; // YES (Default) position, NO--> speed
};

@interface Autopilot : NSObject <DJIMissionManagerDelegate>
{
    
    // drone
    float droneCurrentYawEarth;
    CLLocationCoordinate2D currentDroneCoordinate;
    
    // flight infos && parameters
    double distanceTotarget;
    
    float targetSpeed;
    Vec * targetSpeed_Vec; // in BC coord
    float targetPitchSpeed;
    float targetRollSpeed;
    
    float pitchSpeed;
    float rollSpeed;
    float radiusBrakingZone;
    
    float previousPitchCommande;
    float previousRollCommande;
    
    //gimbal
    
    float previousGDDiffAngle;
    float currentDiffAngle;
    
    float gimbalCurrentYawEarth;
    float gimbalCurrentBearingInDroneBC;
    
    int gimbalZone; //current gimbal zone
    float gimbalCurrent330Yaw;
    float gimbalTarget330Yaw;
    
    float gimbalTargetBearingInDroneBC; //target not current
    float gimbalTargetBearingEarth;
    
    NSMutableArray* arrayGimbalBearing;
    float avgGimbalBearing;
    
    float distanceToGimbalTarget;
    float gimbalPitchToTargetOnTheGround;
    
    float targetAngularSpeed;

    
    NSMutableArray* takeOffMissionSteps;
    NSArray* takeOffstepNames;
    
    DJIMission* currentMission;
    
    __weak MapVC* mapVC;
    __weak MapView* mapView;
    
    
}

@property float mXVelocity;
@property float mYVelocity;
@property float mYaw;
@property float mThrottle;

@property CLLocation* followLoc;
@property BOOL isVirtualStickModeEnabled;

@property DJICustomMission* takeOffMission;
@property CLLocation* takeOffLocation;
@property Drone* realDrone;

@property(nonatomic,strong) DJIFollowMeMission* followMeMission;

@property(nonatomic) DJIRCHardwareFlightModeSwitch flightModeSwitch;
@property(nonatomic,strong) DJIFlightController * flightController;

@property(nonatomic,strong) DJIFlightControllerCurrentState* FCcurrentState;

@property(nonatomic) CLLocation * userLocation;// phoneLocation --> set in location manager callback
@property(nonatomic,strong) DJIGimbal * gimbal;



@property (nonatomic, strong) CLLocation * targetCameraHeadingLocation;
@property (nonatomic, strong) CLLocation * targetdroneGPSLocation;

@property  BOOL avoidObstacles;
@property  int droneYawMode;
@property  int gimbalYawMode;

@property float gimbalCurrent330yaw;

-(void) enableVirtualStickControlMode;
-(void) disableVirtualStickControlMode;

//-(void) updateZoneOfGimbal;
-(void) updateZoneOfGimbalForDrone:(Drone*) drone withGimbalState:(DJIGimbalState*) gimbalState;

-(void) gimbalGoToAbsolutePitch:(float) targetPitch andRoll:(float) targetRoll andYaw:(float) target330Yaw;
-(void) gimbalMoveWithSpeed:(float) pitchSp andRoll:(float) rollSp andYaw:(float) yawSp;
-(void) gimbalMoveWithRelativeAngle:(float) pitchAngle andRoll:(float) rollAngle andYaw:(float) yawAngle withCompletionTime:(float) compTime;

-(void) adjustGimbalAttitudeTo:(CLLocationCoordinate2D) targetBearingCoordForGimbal;
-(void) adjustGimbalToLocation:(CLLocation*) location;
-(void) followLocation:(CLLocation *) location withDroneYawMode:(int) droneYawMode andTargetAltitude:(float) targetAltitude;

-(void) goWithSpeed:(float) speed atBearing:(float) bearing;
-(void) goUpWithSpeed_altitude:(float) speed;
-(void) goWithSpeed:(float)speed atBearing:(float)bearing andAcc:(float) acc;

-(void) sendFlightCtrlCommands:(struct PitchRoll) pitchAndRoll withAltitude:(struct Altitude) altitude andYaw:(struct Yaw) yaw;

-(float) targetSpeedForDistance:(float) distance;


-(void) gimbalGoToAbsolutePitch2:(float) targetPitch andYaw:(float) targetYaw;
-(void) adjustGimbalAttitudeTo_new16:(CLLocationCoordinate2D)targetBearingCoordForGimbal;

// new
-(void) goWithSpeed:(float)speed atBearing:(float)bearing atAltitude:(float) altitude andYaw:(float) yaw;

-(void) sendFlightCtrlCommands:(DJIVirtualStickFlightControlData) ctrlData;

-(void) takeOffWithCompletion:(void(^)(NSError * _Nullable error))callback;
-(void) startFollowMissionWithCompletion:(void (^)(NSError* error))callback;
@end
