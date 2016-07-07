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

# Concerning the video

The main callback is received in the function camera: didReceiveVideoData: where buffers are received at about 100Hz and added to videoPreviewer's queue. In the videoPreviewer execution loop "startRun", the frames are extracted and sent to the glView property of VideoPreviewer in order to be displayed.

In glView one can manipulate the frame obtained after the YUV conversion to RGB, either for obtaining less resolution or for distorting the image for virtual reality headsets etc..

The camera callback is received in AppDelegate.

# Concerning Drone state updates

We receive the most important information about the drone in the callback flightController:didUpdateSystemState: in FrontVC. There 

# Things tried - random ideas

- The follow me functionality in the SDK (DJIFollowMeMission) is working perfectly but not adapted to the very dynamic SportShooting use case. The maximum speed is limited to 10m/s and the turns are thus very smooth.
- The DJICustomMission is a good and easy way of organising a scenario of takeoff, start record, goto a certain location. That's how the takeoff is done when the user confirm his intention to takeoff. The drone takes off to 1.2m and then goes up to 10m.
