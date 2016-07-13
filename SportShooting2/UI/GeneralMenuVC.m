//
//  GeneralMenuVC.m
//  SportShooting
//
//  Created by Othman Sbai on 5/22/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "GeneralMenuVC.h"
#import "DVFloatingWindow.h"

#import "FrontVC.h"
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
    
    rowsArray = [@[@"Track",@"Video",@"Simulation"] mutableCopy];

    
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
    
    UILabel* label = nil;
    
    for (UIView* subview in cell.contentView.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            label = (UILabel*)subview;
        }
    }
    label.textColor = [UIColor colorWithHue:0.67 saturation:0 brightness:0.86 alpha:1];
    
    return cell;
}

-(void) mapWentRightMost{
    
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:_previouslySelectedRow inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
}

-(void) mapWentRight{
    [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:_previouslySelectedRow inSection:0] animated:YES];
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSInteger row = indexPath.row;
    
    switch (row) {
        case 0:
        {
            [[Menu instance] setSubmenu:0]; // track menu
            break;
        }
            
        case 1:
        {
            [[Menu instance] setSubmenu:1]; // video menu
            break;
        }
        case 2:
        {
            [[Menu instance] setSubmenu:2]; // simulation menu
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
