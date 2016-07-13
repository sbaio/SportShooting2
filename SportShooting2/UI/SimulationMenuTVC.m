//
//  SimulationMenuTVC.m
//  SportShooting2
//
//  Created by Renault on 7/13/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#define DV_FLOATING_WINDOW_ENABLE 1

#import "SimulationMenuTVC.h"
#import "UIColor+CustomColors.h"
#import <DJISDK/DJISDK.h>
#import "ComponentHelper.h"
#import "DVFloatingWindow.h"
#import "Menu.h"


@interface SimulationMenuTVC ()

@end

@implementation SimulationMenuTVC
{
    NSMutableArray* items;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    items = [@[@"SimulateDrone",@"SimulateCar"] mutableCopy];
    
    _simulateCar = YES;
    _simulateDrone = YES;
    
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

    return items.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = [items objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UIView *bgColorView = [[UIView alloc] initWithFrame:cell.bounds];
    bgColorView.backgroundColor = [UIColor customGrayForCellSelection];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    [cell setSelectedBackgroundView:bgColorView];
    
    UILabel* label = [cell.contentView.subviews objectAtIndex:0];
    label.textColor = [UIColor colorWithHue:0.67 saturation:0 brightness:0.86 alpha:1];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateCarText];
        [self updateDroneText];
    });
    
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.row) {
        case 0:
        {
            DJIFlightController* fc = [ComponentHelper fetchFlightController];
            
            if (!fc) {
                _simulateDrone = YES;
                [self updateDroneText];
                DVLog(@"no fc simulate");
            }
            else{
                
                if (fc.simulator.isSimulatorStarted) {
                    DVLog(@"simulator was started - stop simulator");
                    _simulateDrone = NO;
                    [self updateDroneText];
                    [[[Menu instance] getFrontVC] stopSimulatorWithCompletion:^(NSError * _Nullable error) {
                        _simulateDrone = NO;
                        [self updateDroneText];
                    }];
                }
                else{
                    DVLog(@"simulator was stopped - start simulator");
                    _simulateDrone = NO;
                    [self updateDroneText];
                    [[[Menu instance] getFrontVC] startSimulatorAtLoc:[[Menu instance] getFrontVC].phoneLocation WithCompletion:^(NSError * _Nullable error) {
                        _simulateDrone = YES;
                        [self updateDroneText];
                    }];
                }
            
            }
            
            break;
        }
        case 1:
        {
            if (_simulateCar) {
                DVLog(@"switch to simulate car: no");
                _simulateCar = NO;
                [self updateCarText];
            }
            else{
                DVLog(@"switch to simulate car: yes");
                _simulateCar = YES;
                [self updateCarText];
            }
            break;
            
        }
        default:
            break;
    }
    
}

-(void) updateDroneText{
    DJIFlightController* fc = [ComponentHelper fetchFlightController];
    UILabel* dronelabel = [self boolLabelAtIndex:0];
    if (fc) {
        if (fc.simulator.isSimulatorStarted) {
            
            [dronelabel setText:@"YES"];
            _simulateDrone = YES;
        }
        else{
            _simulateDrone = NO;
            [dronelabel setText:@"NO"];
        }
    }
    else{
        [dronelabel setText:@"YES"];
    }
    
    [self boolLabelAtIndex:0];
}
-(void) updateCarText{
    UILabel* carLabel = [self boolLabelAtIndex:1];
    if (_simulateCar) {
        [carLabel setText:@"YES"];
    }
    else{
        [carLabel setText:@"NO"];
    }
}

-(UILabel*) boolLabelAtIndex:(int) index{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UILabel* label = [cell.contentView.subviews objectAtIndex:1];
    
    
    return label;
}




@end
