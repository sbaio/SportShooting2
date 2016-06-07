//
//  Calc.m
//  SportShooting2
//
//  Created by Othman Sbai on 5/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "Calc.h"
#define sign(a) ( ( (a) < 0 )  ?  -1   : ( (a) > 0 ) )
#define bindBetween(a,b,c) ((a > c) ? c: ((a<b)? b:a))
#define DEGREE(x) ((x)*180.0/M_PI)
#define RADIAN(x) ((x)*M_PI/180.0)

@implementation Calc

+(Calc *) Instance{
    static Calc * calc;
    
    @synchronized (self) {
        if (!calc) {
            calc = [[Calc alloc] init];
        }
    }
    
    return calc;
}

-(float) distanceFromCoords2D: (CLLocationCoordinate2D) origin toCoords2D: (CLLocationCoordinate2D) dest{
    CLLocation * originLocation = [[CLLocation alloc] initWithLatitude:origin.latitude longitude:origin.longitude];
    CLLocation * destLocation = [[CLLocation alloc] initWithLatitude:dest.latitude longitude:dest.longitude];
    
    return [originLocation distanceFromLocation:destLocation];
}

-(double) headingTo: (CLLocationCoordinate2D ) destination fromPosition:(CLLocationCoordinate2D ) origin{
    
    double destLat = destination.latitude* M_PI / 180.0;
    double destLong = destination.longitude* M_PI / 180.0;
    double originLat = origin.latitude* M_PI / 180.0;//self.droneLocation.latitude;
    double originLong = origin.longitude* M_PI / 180.0;//self.droneLocation.longitude;
    
    
    double bearing = atan2(sin(destLong-originLong)*cos(destLat), cos(originLat)*sin(destLat)-sin(originLat)*cos(destLat)*cos(destLong-originLong));
    
    double bearingDeg = bearing*180.0/M_PI;
    
    return bearingDeg;
}//returns angle in deg from north to destination positive for east negative for west

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

-(float) closestDiffAngle:(float) gimbalOrDest toAngle:(float) droneOrOrigin{
    //from drone to gimbal
    
    if (fabs(gimbalOrDest)>180) {
        DVLog(@"enter angle between -180 and 180");
    }
    if (fabs(droneOrOrigin)>180) {
        DVLog(@"enter angle between -180 and 180");
    }
    
    if (fabs(gimbalOrDest-droneOrOrigin)<180) {
        return gimbalOrDest-droneOrOrigin;
    }
    else
    {
        if (gimbalOrDest<0) {
            return 360+gimbalOrDest-droneOrOrigin;
        }
        else
            return -360+gimbalOrDest-droneOrOrigin;
    }
}

-(float) angle180Of330Angle:(float) angle330{
    
    float angle180;
    if (angle330 <= 180 && angle330>= -180) {
        angle180 = angle330;
    }
    else if (angle330 > 180 && angle330 < 360)
    {
        angle180 = -360+angle330;
    }
    else if( angle330<-180 && angle330>-360)
    {
        angle180 = 360+angle330;
    }
    else
        NSLog(@"angle330 not in range -330 .. 330,  %0.3f",angle330);
    
    return angle180;
}

-(float) angle330OfAngle:(float) angle withZone:(int) zone{
    float angle330;
    
    if (zone == 1) {
        if (angle<-30 && angle>-180) {
            angle330 = 360+angle;//see review
            return angle330;
        }
        else
            return 361;
        //DVLog(@"angle not possible for zone 1");
    }
    else if(zone ==-1)
    {
        if (angle>30 && angle<180)
        {
            angle330 = -360+angle;
            return angle330;
        }
        else
            return -361;
        //DVLog(@"angle not possible for zone -1");
    }
    else if(zone==0)
    {
        if (angle <= 180 && angle >= -180) {
            angle330 = angle;
            return angle330;
        }
        else
            return 362;
        //DVLog(@"angle not possible for zone 0");
    }
    else
    {
        //DVLog(@"invalid zone");
        return 365;
    }
    
    //return angle330;
}

-(float) CWDiffAngleFromAngle:(float) startAngle ToAngle:(float) destAngle{
    if (destAngle >= startAngle) {
        return destAngle - startAngle;
    }
    else{
        return 360+destAngle-startAngle;
    }
}


-(float) CCWDiffAngleFromAngle:(float) startAngle ToAngle:(float) destAngle{
    if (destAngle <= startAngle) {
        return startAngle-destAngle;
    }
    else{
        return 360-destAngle+startAngle;
    }//Output always positif, the orientation should be included in the sign
}
-(BOOL) isAngle:(float) angle1 toTheRightOfAngle:(float) angle2{
    float a = [self CWDiffAngleFromAngle:angle2 ToAngle:angle1];
    float b = [self CCWDiffAngleFromAngle:angle2 ToAngle:angle1];
    if (a <= b) {
        return  YES;
    }
    else return  NO;
}

-(BOOL) angle:(float)angle1 isBetween:(float) angle2 andAngle:(float) angle3{
    
    if ([self isAngle:angle3 toTheRightOfAngle:angle2]) {
        if ([self isAngle:angle1 toTheRightOfAngle:angle2]) {
            float angle2_angle3_CW = [self CWDiffAngleFromAngle:angle2 ToAngle:angle3];
            float angle2_angle1_CW = [self CWDiffAngleFromAngle:angle2 ToAngle:angle1];
            if (angle2_angle1_CW < angle2_angle3_CW) {
                return YES;
            }
        }
    }else{
        if (![self isAngle:angle1 toTheRightOfAngle:angle2]) {
            float angle2_angle3_CCW = [self CCWDiffAngleFromAngle:angle2 ToAngle:angle3];
            float angle2_angle1_CCW = [self CCWDiffAngleFromAngle:angle2 ToAngle:angle1];
            if (angle2_angle1_CCW < angle2_angle3_CCW) {
                return YES;
            }
        }
    }
    return NO;
}

-(float) angleAtPercentage:(float) perc fromAngle:(float) startAngle toAngle:(float) destAngle{
    float diffAngle = [self closestDiffAngle:destAngle toAngle:startAngle];
    
    perc = bindBetween(perc, 0, 1);
    
    float angle = [self angle180Of330Angle:startAngle+perc*diffAngle];
    
    return angle;
}

-(float) avgAngleOfArray:(NSMutableArray*) arrayOfAngles{
    
    float avg = 0;
    
    NSNumber* num0 = arrayOfAngles[0];
    float ang = [num0 floatValue];
    ang = bindBetween(ang, -179.99, 179.99);
    avg = ang;
    //    NSLog(@"0 , %0.3f",ang);
    for (int i = 1; i < arrayOfAngles.count; i++) {
        NSNumber* numi = arrayOfAngles[i];
        float angle = [numi floatValue];
        angle = bindBetween(angle, -179.99, 179.99);
        //        NSLog(@"%d , %0.3f",i,[numi floatValue]);
        avg = [self angleAtPercentage:1.0/(1+i) fromAngle:avg  toAngle:angle];
        //        NSLog(@"aavg ,%0.3f, perc , %0.3f",avg,1.0/(1+i));
    }
    //    NSLog(@"avg , %0.3f",avg);
    
    return avg;
}
-(float) averageOfArray:(NSMutableArray*) array{
    float avg = 0;
    for (NSNumber* num in array) {
        avg += [num floatValue];
    }
    avg/=(float)array.count;
    
    return avg;
}

-(float) filterVar:(float) var inArray:(NSMutableArray*) arrayOfVar angles:(BOOL) isVarAngle withNum:(int) num{ // mobile average
    
    if (!arrayOfVar) {
        arrayOfVar = [[NSMutableArray alloc] init];
    }
    if (arrayOfVar.count < num) {
        
        NSNumber* newVar = [NSNumber numberWithFloat:var];
        [arrayOfVar addObject:newVar];
        
    }else{
        [arrayOfVar removeObjectAtIndex:0];
        NSNumber* newVar = [NSNumber numberWithFloat:var];
        [arrayOfVar addObject:newVar];
    }
    
    if (!isVarAngle) {
        return [self averageOfArray:arrayOfVar];
    }
    else{
        return [self avgAngleOfArray:arrayOfVar];
    }
}

-(CLLocationCoordinate2D) predictedGPSPositionFromCurrentPosition:(CLLocationCoordinate2D) currentCoord andCourse:(double) course andSpeed:(double) speed during:(double) dt{
    
    //verify inputs -----  http://www.movable-type.co.uk/scripts/latlong.html
    // course [-180, 180] in degree
    double currentLat = RADIAN(currentCoord.latitude);
    double currentLongi = RADIAN(currentCoord.longitude);
    
    double distance = speed*dt;
    double earthRadius = 6378100;
    double rapport = distance/earthRadius;
    
    double nextLatitude = asin(sin(currentLat)*cos(rapport)+ cos(currentLat)*sin(rapport)*cos(RADIAN(course)));
    double nextLongitude = currentLongi + atan2(sin(RADIAN(course))*sin(rapport)*cos(currentLat),cos(rapport)-sin(currentLat)*sin(nextLatitude));
    //DVLog(@"currentLat %0.3f, currentLongi %0.3f, distance %0.3f, nextLat %0.3f, netLong %0.3f",currentLat,currentLongi, distance, nextLatitude,nextLongitude);
    
    return CLLocationCoordinate2DMake(DEGREE(nextLatitude) ,DEGREE(nextLongitude) );
}

-(NSString*) pathForFileNamedInSearchPathDirectoriesInDomains:(NSString*) fileName{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString * docsDirectory = paths[0];
    
    NSString * filePath = [docsDirectory stringByAppendingPathComponent:fileName];
    
    return filePath;
}

-(void) removeFileNamed:(NSString*) fileName{
    NSString* filePath = [self pathForFileNamedInSearchPathDirectoriesInDomains:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError* error;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (success) {
            DVLog(@"file %@ removed successfully",fileName);
        }
        else{
            DVLog(@"problem removing file %@",fileName);
        }
    }
    else{
        DVLog(@"file %@ inexistant",fileName);
    }
}

-(NSMutableArray*) loadCircuitNamed:(NSString*)circuitName{ // return nil if nothing found
    NSMutableArray* circuit = nil;
    
    NSString * filePath = [self pathForFileNamedInSearchPathDirectoriesInDomains:circuitName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        circuit = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        DVLog(@"loaded the circuit '%@'",circuitName);
        if (!circuit.count) {
            DVLog(@"empty circuit");
            return nil;
        }
    }
    else {
        DVLog(@"circuit %@ not found",circuitName);
        
        return nil;
    }
    
    return circuit;
}

-(CLLocationCoordinate2D) pointBetweenStartPoint:(CLLocationCoordinate2D) point1 andPoint:(CLLocationCoordinate2D) point2 atRatio:(float) ratio{
    float heading = [self headingTo:point2 fromPosition:point1];
    float dist = [self distanceFromCoords2D:point1 toCoords2D:point2];
    
    CLLocationCoordinate2D newPoint = [self predictedGPSPositionFromCurrentPosition:point1 andCourse:heading andSpeed:dist during:ratio];
    
    return newPoint;
}

-(CLLocation*) locationWithCoordinates:(CLLocationCoordinate2D) coord{
    CLLocation* loc = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    return  loc;
}

-(CLLocation*) locationFrom:(CLLocation*) startLoc atDistance:(float) distance atBearing:(float) bearing{
    CLLocation* loc = [self locationWithCoordinates:[self predictedGPSPositionFromCurrentPosition:startLoc.coordinate andCourse:bearing andSpeed:distance during:1]];
    return loc;
}

-(UIColor*) colorFromString:(NSString*) colorString{
    UIColor *color;
    if ([colorString containsString:@"RGB"]) {
        NSArray* array = [colorString componentsSeparatedByString:@" "];
        if([array[0] isEqualToString:@"RGB"] && array.count == 4){
            
            float R = [array[1] floatValue];
            float G = [array[2] floatValue];
            float B = [array[3] floatValue];
            color = [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:1];
        }
    }else{
        color = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:100.0/255.0 alpha:1];
    }
    return color;
}

-(void) map:(MKMapView*) mapView CenterViewOn:(CLLocationCoordinate2D) locationCoord{
    if(CLLocationCoordinate2DIsValid(locationCoord))
    {
        if (!locationCoord.longitude && !locationCoord.latitude) {
            DVLog(@"Center view: wrong coord, should try when got really valid ones");
            return;
        }
        MKCoordinateRegion region= MKCoordinateRegionMake(locationCoord, MKCoordinateSpanMake(0.003,0.003));
        [mapView setRegion:region animated:YES];
    }
    
}

-(void) map:(MKMapView*) mapView drawCircuitPolyline:(NSMutableArray *) circuitCoords{
    
    NSUInteger circuitSize = circuitCoords.count;
    CLLocationCoordinate2D coordinates [circuitSize];
    
    for (NSInteger index = 0; index < circuitSize; index++) {
        CLLocation *location = [circuitCoords objectAtIndex:index];
        CLLocationCoordinate2D coordinate = location.coordinate;
        coordinates[index] = coordinate;
    }
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:circuitSize];
    polyLine.title = @"limit";
    [mapView addOverlay:polyLine];

}

-(void) map:(MKMapView*) mapView drawCircuitPolyline:(NSMutableArray *) circuitCoords withTitle:(NSString*) title andColor:(NSString*) colorString{
    NSUInteger circuitSize = circuitCoords.count;
    CLLocationCoordinate2D coordinates [circuitSize];
    
    for (NSInteger index = 0; index < circuitSize; index++) {
        CLLocation *location = [circuitCoords objectAtIndex:index];
        CLLocationCoordinate2D coordinate = location.coordinate;
        coordinates[index] = coordinate;
    }
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:circuitSize];
    polyLine.title = title;
    polyLine.subtitle = colorString;
    
    [mapView addOverlay:polyLine];
    
}

-(void) map:(MKMapView *)mapView removePolylineNamed:(NSString*) polylineName{
    
    NSMutableArray *allOverlays = [[NSMutableArray alloc] initWithArray:[mapView overlays]];
    
    for( id <MKOverlay> overlay in allOverlays)
    {
        if ([overlay isKindOfClass:[MKPolyline class]]) {
            MKPolyline* polyline = (MKPolyline*) overlay;
            if ([polyline.title isEqualToString:polylineName]) {
                [mapView removeOverlay:polyline];
            }
        }
    }

    
}

-(void) map:(MKMapView*) mapView drawCircuitPins:(NSMutableArray *) circuitCoords{
    
    NSMutableArray * circuitAnnotations = [[NSMutableArray alloc] init];
    
    NSUInteger circuitSize = circuitCoords.count;
    
    for (NSInteger index = 0; index < circuitSize; index++) {
        CLLocation *location = [circuitCoords objectAtIndex:index];
        CLLocationCoordinate2D coordinate = location.coordinate;
        
        MKPointAnnotation * annotation = [[MKPointAnnotation alloc] init];
        annotation.title = [NSString stringWithFormat:@"circuit coord %lu ", circuitCoords.count];
        annotation.coordinate = coordinate;
        
        [circuitAnnotations addObject:annotation];
    }
    
    [mapView addAnnotations:circuitAnnotations];
}

-(void) map:(MKMapView*) mapView drawCircuitPins:(NSMutableArray *) circuitCoords withColor:(NSString*) colorString{
    for (CLLocation* loci in circuitCoords) {
        [self map:mapView addPin:loci andTitle:@"circuitDrawing" andColor:colorString];
    }
}

-(void) map:(MKMapView*) mapView addPin:(CLLocation*) location andTitle:(NSString*) title andColor:(NSString*) colorString{
    MKPointAnnotation * annotation = [[MKPointAnnotation alloc] init];
    annotation.title = title;
    annotation.subtitle = colorString;
    annotation.coordinate = location.coordinate;
    
    [mapView addAnnotation:annotation];
}

-(void) map:(MKMapView*) mapView CenterViewOnCar:(CLLocation*) carLoc andDrone:(CLLocation*) droneLoc{
    
    float dist_Drone_Car = [self distanceFromCoords2D:carLoc.coordinate toCoords2D:droneLoc.coordinate];
    float angle = [self headingTo:carLoc.coordinate fromPosition:droneLoc.coordinate];
    
    CLLocationCoordinate2D middlePoint = [self predictedGPSPositionFromCurrentPosition:droneLoc.coordinate andCourse:angle andSpeed:dist_Drone_Car during:0.5];
    
    if(CLLocationCoordinate2DIsValid(middlePoint))
    {
        if (!middlePoint.longitude && !middlePoint.latitude) {
            DVLog(@"Center view: wrong coord, should try when got really valid ones");
            return;
        }
        
        float northDist = fabs(dist_Drone_Car*cos(RADIAN(angle)))*7/3;
        float eastDist = fabs(dist_Drone_Car*sin(RADIAN(angle)))*7/3;
        
        northDist = bindBetween(northDist, 100, 10000);
        eastDist = bindBetween(eastDist, 100, 10000);
        
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(middlePoint, northDist, eastDist);
        
        
        [mapView setRegion:region animated:YES];
    }
    
}

-(void) map:(MKMapView*) mapView addRegion:(CLCircularRegion*) region andTitle:(NSString*) regionName andColor:(NSString*) colorString{
    MKCircle* circle = [MKCircle circleWithCenterCoordinate:region.center radius:region.radius];
    [circle setTitle:regionName];
    [circle setSubtitle:colorString];
    [mapView addOverlay:circle];
}


-(NSMutableArray*) loadArrayNamed:(NSString*) arrayName{
    NSMutableArray* array = nil;
    
    NSString * filePath = [self pathForFileNamedInSearchPathDirectoriesInDomains:arrayName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        array = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        DVLog(@"loaded the array '%@'",arrayName);
        if (!array.count) {
            return nil;
        }
    }
    else {
        DVLog(@"array %@ not found",arrayName);
        return nil;
    }
    return array;
}


-(float) distanceOnCircuit_interDistances:(Circuit*) circuit fromIndex:(int) startIndex toIndex:(int) endIndex{
    float distance = 0;
    
    for (int i = 0; i<circuit.locations.count ; i++) {
        if ((startIndex+i)%circuit.locations.count == endIndex) {
            break;
        }
        
        float dist2 = [circuit.interDistance[(startIndex+i)%circuit.locations.count] floatValue];
        
        distance+= dist2;
    }
    return distance;
}

-(BOOL) saveArrayFrom:(NSMutableArray*) array toPathName:(NSString*) arrayName{
    NSString* filePath = [self pathForFileNamedInSearchPathDirectoriesInDomains:arrayName];
    
    return [NSKeyedArchiver archiveRootObject:array toFile:filePath];
}

-(BOOL) isCoord:(CLLocationCoordinate2D) coord1 toEastOfCoord:(CLLocationCoordinate2D) coord2{
    float angle = [self headingTo:coord1 fromPosition:coord2];
    if (angle > 0) {
        return YES;
    }else{
        return NO;
    }
}
-(BOOL) isCoord:(CLLocationCoordinate2D) coord1 toTheNorthOfCoord:(CLLocationCoordinate2D) coord2{
    float angle = [self headingTo:coord1 fromPosition:coord2];
    
    if (fabsf(angle) < 90) {
        return YES;
    }
    else{
        return NO;
    }
}

-(void) map:(MKMapView*) mapView removePinsNamed:(NSString*) pinName{
    NSMutableArray *allAnnotations = [[NSMutableArray alloc] initWithArray:[mapView annotations]];
    
    for( id <MKAnnotation> annotation in allAnnotations)
    {
        
        if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
            MKPointAnnotation* pin = (MKPointAnnotation*) annotation;
            if ([pin.title isEqualToString:pinName]) {
                [mapView removeAnnotation:annotation];
            }
        }
    }
}

-(void) map:(MKMapView*) mapView addLocations:(NSMutableArray*) locations withName:(NSString*) pinName andColor:(NSString*) colorName{
    for (CLLocation* loc in locations) {
        [self map:mapView addPin:loc andTitle:pinName andColor:colorName];
    }
}

-(void) map:(MKMapView*)mapView showCircuit:(Circuit*) circuit{
    [mapView setRegion:[circuit region]];
    [[Calc Instance] map:mapView removePolylineNamed:@"circuitPolyline"];
    [[Calc Instance] map:mapView removePinsNamed:@"panLoc"];
    [[Calc Instance] map:mapView drawCircuitPolyline:circuit.locations withTitle:@"circuitPolyline" andColor:@"RGB 212 175 55"];
}

-(void) log:(NSString*) log{
    [[DVFloatingWindow sharedInstance] loggerLogToLogger:@"Default" log:log];
}
@end
