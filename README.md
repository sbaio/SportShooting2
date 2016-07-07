# SportShooting2

SportShooting2 is an app that is designed for tracking autonomously a car in a raceTrack with a drone, and delivering a video footage of the race and the tracking thanks to to the onboard 4K camera held through a gimbal.

The drone should be following the car whenever the car is at his reach, and keep up with the car's high speed. Otherwise, a shortcutting phase is started so as to be ahead. This implies that the app knows beforehand the layout of the circuit (racetrack). A circuit list is then loaded and the user can select the circuit he prefers to perform.

The car is identified through the user's phone GPS information. The app is running on this phone and receiving the drone state updates through the drone's remote controller. Other updates are being received through the RC: (battery state, gimbal state, flight controller state, video stream, remote controller hardware state...)



