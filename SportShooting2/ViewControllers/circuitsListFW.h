//
//  circuitsListFW.h
//  SportShooting2
//
//  Created by Othman Sbai on 6/6/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "POP.h"

#import "MGSwipeButton.h"
#import "MGSwipeTableCell.h"

#import "CircuitsTVC.h"
#import "Menu.h"
#import "MapView.h"


@interface circuitsListFW : UIView <UITableViewDataSource, UITableViewDelegate,MGSwipeTableCellDelegate>
{
    NSMutableArray* allCircuits;
    Circuit* loadedCircuit;
    
}
-(void) showCircuitList:(BOOL)animated;

-(void) hideCircuitList:(BOOL)animated;

-(void) initWithDefaultsProperties;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *addButton;

@end
