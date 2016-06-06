//
//  Menu.h
//  SportShooting
//
//  Created by Othman Sbai on 5/28/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SWRevealViewController.h"
#import "GeneralMenuVC.h"
#import "CircuitMenuTVC.h"
#import "CircuitsTVC.h"

#import "MapVC.h"
#import "AppDelegate.h"
#import "VideoPreviewer.h"

@class MapVC;
@class GeneralMenuVC;
@class AppDelegate;

@interface Menu : NSObject
{
    NSMutableArray* arrayOfNavC;
}


+(id) instance;


-(UIStoryboard*) getStoryboard;
-(SWRevealViewController*) getMainRevealVC;
-(SWRevealViewController*) getMenuRevealVC;

-(GeneralMenuVC*) getGeneralMenu;

-(MapVC*) getMapVC;
-(AppDelegate*) getAppDelegate;

-(MKMapView*) getMap;

-(UINavigationController*) getNavC;


-(void) setSubmenu:(int) submenuIndex;


@end
