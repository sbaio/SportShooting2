//
//  Autopilot.h
//  SportShooting2
//
//  Created by Othman Sbai on 1/25/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJISDK.h>
//#import "Tracker.h"
#import "ComponentHelper.h"
#import "Vec.h"
#import "Drone.h"

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

@protocol AutopilotDelegate <NSObject>

@optional
-(void) notifyMissionVC:(int) intToDo;
-(void) autopilotDidSendFlightCommands:(DJIVirtualStickFlightControlData) flightCtrlData;
@end
typedef struct{
    BOOL isSendingFlightControlData:1;
    BOOL isRunning:1;
    BOOL isPause:1;
    
    BOOL isF_Mode:1; // try to get this sync with the callback from the RC
    BOOL isPGPS_Mode:1; //-----> changed by self.flightModeSwitch
    
    BOOL isFlying:1; // ON when takeOff is successfull --> available in state.isFlying
    BOOL isTakingOff;
    
} AutopilotStatus;

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

@interface Autopilot : NSObject //<GimbalTracking>
{
    //NSThread * _missionFlightThread;
    //dispatch_queue_t _dispatchFlightControlQueue;
    

    BOOL startMission; // start calculating path, and recording

    CLLocationCoordinate2D takeOffPosition;
    NSTimer * takeOffCheckTimer;

    
    NSTimer * timerSendCtrlData;
    
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

    //test & debug
    int count1;
    int count2;
}

@property (weak) id<AutopilotDelegate> delegate;
@property (nonatomic,strong) Drone* realDrone;
@property(assign,readonly) AutopilotStatus autopilotStatus;
@property(nonatomic) DJIRCHardwareFlightModeSwitch flightModeSwitch;
@property(readonly) UISegmentedControl * statusSegmented;
@property(nonatomic,strong) DJIFlightController * flightController;
//@property(weak) Tracker* tracker;
@property(nonatomic,strong) DJIFlightControllerCurrentState* FCcurrentState;
@property(nonatomic) DJIRCGPSData RCgpsData;
@property(nonatomic) CLLocation * userLocation;// phoneLocation --> set in location manager callback
@property(nonatomic,strong) DJIGimbal * gimbal;
@property(strong,nonatomic) NSTimer* gimbalSpeedTimer;
@property(strong,nonatomic) NSTimer* gimbalAngleTimer;

@property (nonatomic, strong) CLLocation * targetCameraHeadingLocation;
@property (nonatomic, strong) CLLocation * targetdroneGPSLocation;

@property  BOOL avoidObstacles;
@property  int droneYawMode;
@property  int gimbalYawMode;
@property BOOL isDroneGoingToNFZ;
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
-(void) goTo:(CLLocation*) location withAcc:(float) acc;
-(void) makeCircleAround:(CLLocationCoordinate2D) center atDistance:(float) radius andSpeed:(float) speed atAltitude:(float) altitude;

-(void) onMissionTimerTickedSendFlighControlData;
-(void) sendFlightCtrlCommands:(struct PitchRoll) pitchAndRoll withAltitude:(struct Altitude) altitude andYaw:(struct Yaw) yaw;

-(float) targetSpeedForDistance:(float) distance;


-(void) gimbalGoToAbsolutePitch2:(float) targetPitch andYaw:(float) targetYaw;
-(void) adjustGimbalAttitudeTo_new16:(CLLocationCoordinate2D)targetBearingCoordForGimbal;

// new
-(void) goWithSpeed:(float)speed atBearing:(float)bearing atAltitude:(float) altitude andYaw:(float) yaw;
@end
