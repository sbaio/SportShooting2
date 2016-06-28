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
#import "UIColor+CustomColors.h"

@interface GeneralMenuVC ()

@end

@implementation GeneralMenuVC{
    
    NSInteger _previouslySelectedRow;
    NSMutableArray* rowsArray;
    UILabel* carLabel;
    UILabel* droneLabel;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    rowsArray = [@[@"Track",@"Video",@"Drone",@"Car"] mutableCopy];
    

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:@"FCFeedStarted" object:nil];
    
}

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

    
    UIView *bgColorView = [[UIView alloc] initWithFrame:cell.bounds];
    bgColorView.backgroundColor = [UIColor customGrayForCellSelection];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    [cell setSelectedBackgroundView:bgColorView];
    
    UILabel* textLabel = [cell.contentView.subviews objectAtIndex:0];
    if ([textLabel.text containsString:@"Car"]) {
        carLabel = textLabel;
        _carSwitch = [cell.contentView.subviews objectAtIndex:1];
        if ([_carSwitch isOn]) {
            [carLabel setText:@"Car sim"];
        }
        else{
            [carLabel setText:@"Car"];
        }
    }
    if ([textLabel.text containsString:@"Drone"]) {
        droneLabel = textLabel;
        _droneSwitch = [cell.contentView.subviews objectAtIndex:2];
        if ([_droneSwitch isOn]) {
            [droneLabel setText:@"Drone sim"];
        }
        else{
            [droneLabel setText:@"Drone"];
        }
    }
    
    
    textLabel.textColor = [UIColor colorWithHue:0.67 saturation:0 brightness:0.86 alpha:1];
    return cell;
}

- (IBAction)onCarSwitchChanged:(id)sender {
    
    if (sender == _carSwitch) {
        if ([sender isOn]) {
            [carLabel setText:@"Car sim"];
        }
        else{
            [carLabel setText:@"Car"];
        }
    }
    else if(sender == _droneSwitch) {
        
        BOOL simulateWithDJI = YES;
    
        if (simulateWithDJI) {
            DJIFlightController* fc = [ComponentHelper fetchFlightController];
            if (fc && fc.simulator) {
                if ([sender isOn]) {
                    if (!fc.simulator.isSimulatorStarted) {
                        [[[Menu instance] getMapVC] startSimulatorAtLoc:[[Menu instance] getMapVC].phoneLocation WithCompletion:^(NSError * _Nullable error) {
                            [self updateDroneSwitchAndLabel];
                        }];
                    }
                }
                else{
                    if (fc.simulator.isSimulatorStarted) {
                        [[[Menu instance] getMapVC] stopSimulatorWithCompletion:^(NSError * _Nullable error) {
                            [self updateDroneSwitchAndLabel];
                        }];
                    }
                }
            }
            
        }
        else{
            if ([sender isOn]) {
                [droneLabel setText:@"Drone sim"];
            }
            else{
                [droneLabel setText:@"Drone"];
            }
        }
        
    }
}

-(void) updateDroneSwitchAndLabel{
    DJIFlightController* fc = [ComponentHelper fetchFlightController];
    if (fc) {
        if (fc.simulator.isSimulatorStarted) {
            [_droneSwitch setOn:YES];
            [droneLabel setText:@"Drone sim"];
        }
        else{
            [_droneSwitch setOn:NO];
            [droneLabel setText:@"Drone"];
        }
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


-(void) handleNotification:(NSNotification*) notification{
    if ([notification.name isEqualToString:@"FCFeedStarted"]) {
        [self updateDroneSwitchAndLabel];
    }
}


@end
