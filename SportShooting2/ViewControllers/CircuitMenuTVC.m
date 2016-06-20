//
//  CircuitMenuTVC.m
//  SportShooting
//
//  Created by Othman Sbai on 5/23/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "CircuitMenuTVC.h"
#import "UIColor+CustomColors.h"
#import "Menu.h"


@interface CircuitMenuTVC ()

@end

@implementation CircuitMenuTVC
{
    NSMutableArray* items;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    items = [@[@"Select track", @"Define new track",@"Record: blank lap",@"play"] mutableCopy];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.row) {
        case 0:
        {// select circuti .. open
            [[[Menu instance] getMainRevealVC] setFrontViewPosition:FrontViewPositionLeft animated:YES];
            [[[Menu instance] getMapVC].circuitsList openCircuitListWithCompletion:^(BOOL finished) {
                
            } ];
            break;
        }
        case 1:
        {// push circuit definition vc
            [[[Menu instance] getMainRevealVC] setFrontViewPosition:FrontViewPositionLeft animated:YES];
            [[[Menu instance] getMapVC].circuitsList openCircuitListWithCompletion:^(BOOL finished) {
                [[[Menu instance] getMapVC].circuitsList openDefineTableViewForCircuit:nil];
            }];
            
            break;

        }
        case 2:
        {

            break;
        }
        default:
            break;
    }
}





@end
