# SportShooting2

SportShooting2 is an app that is designed for tracking autonomously a car in a raceTrack with a drone, and delivering a video footage of the race and the tracking thanks to to the onboard 4K camera held through a gimbal.

The drone should be following the car whenever the car is at his reach, and keep up with the car's high speed. Otherwise, a shortcutting phase is started so as to be ahead. This implies that the app knows beforehand the layout of the circuit (racetrack). A circuit list is then loaded and the user can select the circuit he prefers to perform.

The car is identified through the user's phone GPS information. The app is running on this phone and receiving the drone state updates through the drone's remote controller. Other updates are being received through the RC: (battery state, gimbal state, flight controller state, video stream, remote controller hardware state...)

The UI of the app is inspired by DJI Go app, where the picture in picture lets the user have an eye on both the video stream and the updtaed map info. Also many labels facilitate monitoring the state of the flight ( drone horizontal and vertical speed, altitude, distance from RC, status of following mission: close tracking or shortcutting).

The app is also mainly inspired from the DJI Demo app where the use of the SDK is explained.

# About the SDK

The last SDK available as of July 7th contains very interesting APIs that weren't in the previous SDK.

In DJI SDK tutorials you will find how to make the SDK work in a xcode project, there are 3 libraries one should not forget to link with: libz.tbd, libstdc++.6.0.9.tbd and libiconv.tbd

In order to start receiving drone updates, we need to register the app with a key provided by DJI on the Developer center website.
- Another interesting point about the new SDK, new possibility of Simulator is possible. DJISimulator is a class created by DJI to make simulations easy. This makes having access to drone dynamics easier than having to go out and fly. When we start the simulator, the real drone turns to simulation mode and in responds to all the commands send to it in simulation.. for example when the command of takeoff is sent, we see the altitude going up in the flightController callback without the motors rotating.

# Concerning the video

The main callback is received in the function camera: didReceiveVideoData: where buffers are received at about 100Hz and added to videoPreviewer's queue. In the videoPreviewer execution loop "startRun", the frames are extracted and sent to the glView property of VideoPreviewer in order to be displayed.

In glView one can manipulate the frame obtained after the YUV conversion to RGB, either for obtaining less resolution or for distorting the image for virtual reality headsets etc..

The camera callback is received in AppDelegate.

# Concerning Drone state updates

We receive the most important information about the drone in the callback flightController:didUpdateSystemState: in FrontVC. There we update drone GPS position, aircraft speed, GPS signal strength, drone yaw.

# Classes :

-The circuit class :
  * The notion of distanceOnCircuit :
      
  * oihv
 
The circuit class is composed of different properties which are useful for the pathplanning and which we don't need to calculate each time, such as: (locations, length, distanceOnCircuit between two different locations from the circuit, the angle of the circuit at each location, the curvature).


# Before starting the follow mission

Before starting the following loop (calculate target position, send control commands to reach it) we need to setup the inputs for this loop. The circuit is set when the user clicks select. 



# Workflow of the app: normal use

After opening the app, it will start trying to connect to the drone. We should first choose the circuit we plan to drive and being filmed on. After selecting the circuit, we can click on takeoff button and confirm to start the takeoff mission, which is a normal takeoff plus a go up to 10 m.

The takeoff mission requires the user to switch the RC's hardware stick to F mode in order to be able to send automatic flight commands such as go up to 10m.

Once the takeoff mission has finished, we start the follow me mission, running the pathplanning loop.

# Things tried - random ideas

- The follow me functionality in the SDK (DJIFollowMeMission) is working perfectly but not adapted to the very dynamic SportShooting use case. The maximum speed is limited to 10m/s and the turns are thus very smooth.
- The DJICustomMission is a good and easy way of organising a scenario of takeoff, start record, goto a certain location. That's how the takeoff is done when the user confirm his intention to takeoff. The drone takes off to 1.2m and then goes up to 10m.


# Diffiulties encontered
- When using the app, the phone needs to be plugged to the drone's RC, this makes it difficult to have the logs a developer has on the console. Also many errors cause the app to crash without indicating the cause. DJI worked on this issue by created a classe DJIRemoteLogger and a mode for debugging using a bridge app.

The bridge app solution works as follows: The phone running the app is connected to the mac. To get the drone updates without being linked to the RC, we use another device running the bridge app and that communicates with the phone running the SportShooting2 app. This way we can debug our code being connected wirelessly to the drone's RC.

# Still to do


# Libraries Used

For this app, we use different libraries for different purposes. 

- SWRevealVC class is used to make easy the revealable menu as facebook friend list style. 
- DVFloatingWindow is used to have logs directly on the window of the iphone.
- Pop library from facebook for easy animations
- ffmpeg library is given by DJI Demo app project, it is used for decoding the video buffers coming from the camera and extracting a frame. (See VideoPreviewer class, videoFrameExtractor and MovieGlView classes)
- DJI framework 
