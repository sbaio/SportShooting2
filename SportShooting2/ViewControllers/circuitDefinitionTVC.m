//
//  circuitDefinitionTVC.m
//  SportShooting
//
//  Created by Othman Sbai on 5/25/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "circuitDefinitionTVC.h"
#import "MapVC.h"

#import "CircuitsTVC.h"

@interface circuitDefinitionTVC ()
{
    NSMutableArray* cellIDs;
}
@end

@implementation circuitDefinitionTVC
@synthesize txtFieldCircuitName,txtFieldRTH_Alt,txtFieldCircuitLength;

-(id) initWithCircuit:(Circuit*) circuit{
    self = [super init];
    
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
//    NSArray* methodsA = @[@"Name:",@"RTH altitude:",@"Define NFZ",@"Redefine locations",@"Circuit length: "];
 
//    methods = [methodsA mutableCopy];
    methods =[[NSMutableArray alloc] initWithObjects:@"Name ",@"Length",@"RTH altitude",@"Redefine locs", nil];
    cellIDs = [[NSMutableArray alloc] initWithObjects:@"circ_def_Name",@"circ_def_length",@"circ_def_RTH",@"circ_def_redefine_Locs", nil];
    
    MenuRevealController = self.revealViewController;
    MainRevealController = MenuRevealController.revealViewController;
    

//    [self setTextFiledForRTH_Alt];

    
    if (!_loadedCircuit) {
        _loadedCircuit = [[Circuit alloc] init];
    }
    

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
    return methods.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = [cellIDs objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UILabel* textLabel = [[cell.contentView subviews] objectAtIndex:0];
    [textLabel setText:[methods objectAtIndex:indexPath.row]];
    
    switch (indexPath.row) {
            case 0:
        {
            txtFieldCircuitName = [[cell.contentView subviews] objectAtIndex:1];
            txtFieldCircuitName.delegate = self;
            if (_loadedCircuit.circuitName) {
                [txtFieldCircuitName setText:_loadedCircuit.circuitName];
            }
            break;
        }
            case 1:
        {
            txtFieldCircuitLength = [[cell.contentView subviews] objectAtIndex:1];
            txtFieldCircuitLength.delegate = self;
            if (_loadedCircuit.locations) {
                [txtFieldCircuitLength setText:[NSString stringWithFormat:@"%0.1fm",[_loadedCircuit length]]];
            }
            break;
        }
            case 2:
        {
            txtFieldRTH_Alt = [[cell.contentView subviews] objectAtIndex:1];
            txtFieldRTH_Alt.delegate = self;
            if (_loadedCircuit.RTH_altitude) {
                [txtFieldRTH_Alt setText:[NSString stringWithFormat:@"%0.1fm",_loadedCircuit.RTH_altitude]];
            }
        }
            
        default:
            break;
    }
    
    
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    
    
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textFieldloc{
    [textFieldloc resignFirstResponder];
    NSString* string = textFieldloc.text;
    
    if (textFieldloc == txtFieldRTH_Alt) {
        if (!_loadedCircuit) {
            _loadedCircuit = [[Circuit alloc]init];
        }
        _loadedCircuit.RTH_altitude = [string floatValue];
        
        [txtFieldRTH_Alt setText:[NSString stringWithFormat:@"%0.1fm",_loadedCircuit.RTH_altitude]];
        
        if(_loadedCircuit.circuitName){
            [[circuitManager Instance] saveCircuit:_loadedCircuit];
        }
        else{
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES];
            });
        }
    }
    
    else if (textFieldloc == txtFieldCircuitName){
        _loadedCircuit.circuitName = string;
        
        if (!_loadedCircuit.locations) {
            // launch pan circuit to get _loadedCircuit.locations
            [self startPan];
        }
        else{
            [[circuitManager Instance] saveCircuit:_loadedCircuit];
            
            UINavigationController* navC = (UINavigationController*) MenuRevealController.frontViewController;
            CircuitsTVC* circuitListTVC = (CircuitsTVC*)navC.viewControllers[1];
            CircuitMenuTVC* circuitMenuTVC = (CircuitMenuTVC*)navC.viewControllers[0];
            [circuitMenuTVC updateCircuitList];
            [circuitListTVC.tableView reloadData];
    
            
        }
        
    }
    
    
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if (textField == txtFieldCircuitLength) {
        return NO;
    }
    return YES;
}

-(void) startPan{
   [MainRevealController setFrontViewPosition:FrontViewPositionLeftSide animated:YES];
    MapVC* mapVC = [[Menu instance] getMapVC];
    
    [mapVC disableMainMenuPan];
    [mapVC.mapView disableMapViewScroll];
    
    mapVC.isPathDrawingEnabled = YES;
    
    DVLog(@"please define circuit through swiping on the screen");
}



@end
