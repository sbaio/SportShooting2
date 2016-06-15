//
//  CircuitMenuTVC.m
//  SportShooting
//
//  Created by Othman Sbai on 5/23/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "CircuitMenuTVC.h"
#import "CircuitsTVC.h"
#import "circuitDefinitionTVC.h"
#import "SWRevealViewController.h"
#import "UIColor+CustomColors.h"
#import "Menu.h"


@interface CircuitMenuTVC ()

@end

@implementation CircuitMenuTVC
{
    NSMutableArray* items;
}
@synthesize loadedCircuit;

- (void)viewDidLoad {
    [super viewDidLoad];

    items = [@[@"Select track", @"Define new track",@"Record: blank lap",@"play"] mutableCopy];
    loadedCircuit = [[Circuit alloc] init];
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
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.row) {
        case 0:
        {// select circuti .. open
            [[[Menu instance] getMainRevealVC] setFrontViewPosition:FrontViewPositionLeft animated:YES];
            [[[Menu instance] getMapVC] showCircuitListView];
            break;
        }
        case 1:
        {// push circuit definition vc
            circuitDefinitionTVC* circDefTVC = [[[Menu instance] getStoryboard] instantiateViewControllerWithIdentifier:@"CircDefMenu"];
            [self.navigationController pushViewController:circDefTVC animated:YES];
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


-(void) updateCircuitList{
    NSArray* arrayOfControllers = self.navigationController.viewControllers;
    for (UIViewController* vc in arrayOfControllers) {
        if ([vc isKindOfClass:[CircuitsTVC class]]) {
            NSLog(@"found !");
        }
    }
}


@end
