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

#import "closeButton.h"


@interface circuitsListFW : UIView <UITableViewDataSource, UITableViewDelegate,MGSwipeTableCellDelegate,UITextFieldDelegate>
{
    NSMutableArray* allCircuits;
    Circuit* loadedCircuit;
    int selectedRow;
    int selectRow;
    
    UITableView* defineTableView;
    
    UITextField* txtFieldCircuitName;
    UITextField *txtFieldRTH_Alt;
    UITextField *txtFieldCircuitLength;
}
-(void) showCircuitList:(BOOL)animated;

-(void) hideCircuitList:(BOOL)animated;

-(void) initWithDefaultsProperties;



@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet closeButton *closeBut;
@property (weak, nonatomic) IBOutlet closeButton *addBut;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *addButton;

@end
