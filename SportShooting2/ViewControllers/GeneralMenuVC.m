//
//  GeneralMenuVC.m
//  SportShooting
//
//  Created by Othman Sbai on 5/22/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "GeneralMenuVC.h"
#import "DVFloatingWindow.h"

#import "MapVC.h"
#import "Menu.h"


@interface GeneralMenuVC ()

@end

@implementation GeneralMenuVC{
    
    NSInteger _previouslySelectedRow;
    NSMutableArray* rowsArray;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    rowsArray = [@[@"Track",@"Video",@"Drone",@"Car"] mutableCopy];
    

//    _realDrone = NO;
//    _isDroneRecordingVideo = NO;
}
//

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    _previouslySelectedRow = -1;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return rowsArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = [rowsArray objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    return cell;
}

-(void) onSwitchChanged:(id) sender{
    
    if (_realDrone) {
        DVLog(@"real drone");
    }
    else{
        DVLog(@"simulated drone");
    }
}

-(void) mapWentRightMost{
    
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:_previouslySelectedRow inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
}

-(void) mapWentRight{
    [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:_previouslySelectedRow inSection:0] animated:YES];
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSInteger row = indexPath.row;
    
    switch (row) {
        case 0:
        {
            [[Menu instance] setSubmenu:0];
            break;
        }
            
        case 1:
        {
            [[Menu instance] setSubmenu:1];
            break;
        }
        default:
            break;
    }
    if ([[Menu instance] getMainRevealVC].frontViewPosition != FrontViewPositionRightMost) {
        [[[Menu instance] getMainRevealVC] setFrontViewPosition:FrontViewPositionRightMost animated:YES];
    }
    
    _previouslySelectedRow = indexPath.row;
    
}



@end
