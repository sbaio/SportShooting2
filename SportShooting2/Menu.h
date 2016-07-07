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

#import "FrontVC.h"
#import "AppDelegate.h"
#import "VideoPreviewer.h"
#import "TopMenu.h"
#import "MapView.h"

@class FrontVC;
@class GeneralMenuVC;
@class AppDelegate;
@class CircuitsTVC;
@class MapView;


@interface Menu : NSObject
{
    NSMutableArray* arrayOfNavC;
}

@property (nonatomic,strong) TopMenu* topMenu;


+(id) instance;



-(UIStoryboard*) getStoryboard;
-(UITableViewController*) getProtoTVC;
-(SWRevealViewController*) getMainRevealVC;
-(SWRevealViewController*) getMenuRevealVC;

-(GeneralMenuVC*) getGeneralMenu;

-(FrontVC*) getFrontVC;
-(AppDelegate*) getAppDelegate;

-(MKMapView*) getMap;
-(MapView*) getMapView;

-(UINavigationController*) getNavC;


-(void) setSubmenu:(int) submenuIndex;

-(TopMenu*) getTopMenu;


@end
