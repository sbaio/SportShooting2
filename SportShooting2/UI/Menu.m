//
//  Menu.m
//  SportShooting
//
//  Created by Othman Sbai on 5/28/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "Menu.h"

@implementation Menu


+(Menu*) instance{
    static Menu *menu;
    
    @synchronized(self) {
        
        if (! menu) {
            menu = [[Menu alloc] init];
        }
        
    }
    return menu;
}

-(UIStoryboard*) getStoryboard{
    UIStoryboard* mainStoryboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    return mainStoryboard;
}

-(SWRevealViewController*) getMainRevealVC{
//    NSLog(@"%@",(SWRevealViewController*)[[[[UIApplication sharedApplication] delegate] window] rootViewController]);
    return (SWRevealViewController*)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
}

-(SWRevealViewController*) getMenuRevealVC{
    SWRevealViewController* mainReveal = [self getMainRevealVC];
    return (SWRevealViewController*)mainReveal.rearViewController;
}

-(GeneralMenuVC*) getGeneralMenu{
    SWRevealViewController* menuReveal = [self getMenuRevealVC];
    return (GeneralMenuVC*)menuReveal.rearViewController;
}


-(UINavigationController*) getNavC{
    SWRevealViewController* menuReveal = [self getMenuRevealVC];
    UINavigationController* navC = (UINavigationController*)menuReveal.frontViewController;
    if (navC.viewControllers.count) {
//        UIViewController* sf = navC.viewControllers[0];
    }
    
    return navC;
}

-(FrontVC*) getFrontVC{
    FrontVC* frontVC = (FrontVC*)[self getMainRevealVC].frontViewController;
    return frontVC;
}

-(MapView*) getMapView{
    
    return [self getFrontVC].mapView;
}

-(MKMapView*) getMap{
    return [self getMapView];
}


-(UITableViewController*) getProtoTVC{
    return [[self getStoryboard] instantiateViewControllerWithIdentifier:@"Proto"];
}


-(void) setSubmenu:(int) submenuIndex{
    
    UINavigationController* navC = [self getNavC];
    
    BOOL new = YES;
    NSArray* menuItems = [NSArray arrayWithObjects:@"TrackMenu",@"VideoMenu",@"SimulationMenu", nil];
    
    if (navC.viewControllers.count == 1) {
        UIViewController* vc = navC.viewControllers[0];
        if ([vc.title isEqualToString:menuItems[submenuIndex]]) {
            new = NO;
        }
    }
    // find the view controllers
    
    
    
    
    NSArray* newArrayOfViewControllers = navC.viewControllers;
    
    switch (submenuIndex) {
        case 0: // circuit menu
        {
            if (new) {
                UITableViewController* circtuiMenu = [[self getStoryboard] instantiateViewControllerWithIdentifier:@"TrackMenu"];
                newArrayOfViewControllers = [NSArray arrayWithObject:circtuiMenu];
                [navC setViewControllers:newArrayOfViewControllers animated:NO];
            }
            
            break;
        }
        case 1: // video menu
        {
            if (new) {
                UITableViewController* videoMenu = [[self getStoryboard] instantiateViewControllerWithIdentifier:@"VideoMenu"];
                newArrayOfViewControllers = [NSArray arrayWithObject:videoMenu];
                [navC setViewControllers:newArrayOfViewControllers animated:NO];
            }
            
            break;
        }
        
        case 2:
        { // simulation menu
            if (!_simulationMenu) {
                _simulationMenu = [[self getStoryboard] instantiateViewControllerWithIdentifier:@"SimulationMenu"];
            }
            
                newArrayOfViewControllers = [NSArray arrayWithObject:_simulationMenu];
                [navC setViewControllers:newArrayOfViewControllers animated:NO];
            
        }
        default:
            break;
    }
    

    return;
}

-(AppDelegate*) getAppDelegate{
    AppDelegate* appD = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    return appD;
}

-(VideoPreviewer*) getVideoPreviewer{
    return [VideoPreviewer instance];
}

-(TopMenu*) getTopMenu{
    return _topMenu;
}

@end
