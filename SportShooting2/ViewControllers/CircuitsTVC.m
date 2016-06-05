//
//  CircuitsTVC.m
//  SportShooting
//
//  Created by Othman Sbai on 5/23/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

/*
 --> add swipeable cells to edit or delete track ..
*/
#import "CircuitsTVC.h"

#import "CircuitMenuTVC.h"
#import "MapVC.h"
@interface CircuitsTVC ()

@end

@implementation CircuitsTVC


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // load all circuits available
    
    allCircuits = [self loadExistingCircuitsNames_coder];
    
    MenuRevealController = self.revealViewController;
    MainRevealController = MenuRevealController.revealViewController;

}

-(void) updateCircuitsList{
    allCircuits = [self loadExistingCircuitsNames_coder];
    [self.tableView reloadData];
}

-(NSMutableArray*) loadExistingCircuitsNames_coder{
    NSMutableArray* arrayOfCircuitsNames = [[NSMutableArray alloc] init];
    
    NSArray *keys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
    
    for(NSString* key in keys){
        if ([key hasSuffix:@"_c"]) {
            NSArray* arrayFromCircuitPath = [key componentsSeparatedByString:@"_"];
            NSString* circuitN = arrayFromCircuitPath[0];
            [arrayOfCircuitsNames addObject:circuitN];
            NSLog(@"%@",circuitN);
            
        }
        
    }
    return arrayOfCircuitsNames;
}

-(void) removeCircuitAtIndexPath:(NSIndexPath*) indexPath{
    
    NSInteger index = indexPath.row;
    
    NSString* circuitName = allCircuits[index];
    
    [[circuitManager Instance] removeCircuitNamed:circuitName];
    
    [allCircuits removeObjectAtIndex:index];
    
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return allCircuits.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CellIdentifier = @"circuitListCell";
    
    MGSwipeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    UILabel* textLabel = [[cell.contentView subviews] objectAtIndex:0];
    
    [textLabel setText:[allCircuits objectAtIndex:indexPath.row]];
    
    return cell;
    

}

-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell tappedButtonAtIndex:(NSInteger) index direction:(MGSwipeDirection)direction fromExpansion:(BOOL) fromExpansion
{
    NSString* circuitName = [self txtOfCell:cell];
    
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    
    if (direction == MGSwipeDirectionRightToLeft) {
        
        if (index == 0) { // delete
            [self removeCircuitAtIndexPath:indexPath];
    
        }
        else if (index == 1){ // edit
            circuitManager* cm = [circuitManager Instance];
            
            loadedCircuit = [cm loadCircuitNamed_coder:circuitName];
            
            if (!loadedCircuit || !loadedCircuit.locations || loadedCircuit.locations.count == 0) {
                NSString* shouldBeDeleted = [NSString stringWithFormat:@"%@ (should be deleted)",circuitName];
                [allCircuits replaceObjectAtIndex:indexPath.row withObject:shouldBeDeleted];
                [self.tableView reloadData];

            }
            else{
                MKMapView* mapView = [[Menu instance] getMap];
                // mapview set region
                [self map:mapView showCircuit:loadedCircuit];
                
                // open define new track with the input fields

                circuitDefinitionTVC* cdef = [[[Menu instance] getStoryboard] instantiateViewControllerWithIdentifier:@"CircDefMenu"];
    
                
                cdef.loadedCircuit = loadedCircuit;
                [cdef.txtFieldCircuitName setText:loadedCircuit.circuitName];
                [cdef.txtFieldRTH_Alt setText:[NSString stringWithFormat:@"%0.1f",loadedCircuit.RTH_altitude]];
                [cdef.txtFieldCircuitLength setText:[NSString stringWithFormat:@"%0.1f",loadedCircuit.length]];
                
                

                [[self navigationController] pushViewController:cdef animated:YES];
                
            }
        }
    }
    
    
    return YES;
}

-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction fromPoint:(CGPoint) point{
    
    if (direction == MGSwipeDirectionRightToLeft) {
    
        return YES;
    }
    else {
        
        return NO;
    }
}
-(NSArray*) swipeTableCell:(MGSwipeTableCell*) cell swipeButtonsForDirection:(MGSwipeDirection)direction
             swipeSettings:(MGSwipeSettings*) swipeSettings expansionSettings:(MGSwipeExpansionSettings*) expansionSettings;
{
    if (direction == MGSwipeDirectionRightToLeft) {

        return [self createRightButtons:2];
    }
    else {

        return nil;
    }
}

-(NSArray *) createRightButtons: (int) number
{
    NSMutableArray * result = [NSMutableArray array];
    NSString* titles[2] = {@"Delete", @"Edit"};
    
    UIColor* yellowColor = [UIColor colorWithHue:0.125 saturation:0.93 brightness:0.95 alpha:1.0];
    UIColor * colors[2] = {[UIColor redColor], yellowColor};
    for (int i = 0; i < 2; ++i)
    {
        MGSwipeButton * button = [MGSwipeButton buttonWithTitle:titles[i] backgroundColor:colors[i] callback:^BOOL(MGSwipeTableCell * sender){
            
            BOOL autoHide = i != 0;
            return autoHide; //Don't autohide in delete button to improve delete expansion animation
        }];

        [result addObject:button];
    }
    return result;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    // load concerned circuit and show it
    
    MGSwipeTableCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSString* circuitName = [self txtOfCell:cell];
    
    MapVC* mapVC = [[Menu instance] getMapVC];
    MKMapView* mapView = [[Menu instance] getMap];
    
    circuitManager* cm = [circuitManager Instance];
    
    if (!mapVC.circuit || !mapVC.circuit.circuitName || ![mapVC.circuit.circuitName isEqualToString:circuitName]) {
        NSLog(@"trying to load , '%@'",circuitName);
        mapVC.circuit = [cm loadCircuitNamed_coder:circuitName];
    }
    
    if (!mapVC.circuit || !mapVC.circuit.locations || !mapVC.circuit.locations.count) {
        NSLog(@"empty circuit loaded");
        return;
    }
    
    [self map:mapView showCircuit:mapVC.circuit];
    
    [[[Menu instance] getNavC] popViewControllerAnimated:YES];
    [[[Menu instance] getMainRevealVC] setFrontViewPosition:FrontViewPositionRight animated:YES];
    
}

-(NSString*) txtOfCell:(MGSwipeTableCell*) cell{
    if (cell.contentView.subviews.count) {
        UILabel* label = cell.contentView.subviews[0]; // the label containing the text
        return label.text;
    }
    return nil;
}

-(void) map:(MKMapView*)mapView showCircuit:(Circuit*) circuit{
    [mapView setRegion:[circuit region]];
    [[Calc Instance] map:mapView removePolylineNamed:@"circuitPolyline"];
    [[Calc Instance] map:mapView removePinsNamed:@"panLoc"];
    [[Calc Instance] map:mapView drawCircuitPolyline:circuit.locations withTitle:@"circuitPolyline" andColor:@"RGB 212 175 55"];
}

@end
