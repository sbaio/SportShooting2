//
//  circuitDefinitionTVC.h
//  SportShooting
//
//  Created by Othman Sbai on 5/25/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"
#import "Circuit.h"
#import "circuitManager.h"
#import "MGSwipeTableCell.h"

@interface circuitDefinitionTVC : UITableViewController<UITextFieldDelegate,MGSwipeTableCellDelegate>
{
    NSMutableArray* methods;
    SWRevealViewController* MenuRevealController;
    SWRevealViewController* MainRevealController;
    
//    UITextField *txtFieldCircuitLength;
    
    
}

//@property (weak, nonatomic) IBOutlet UITextField *txtFieldCircuitName;
@property UITextField *txtFieldCircuitName;
//@property (weak, nonatomic) IBOutlet UITextField *txtFieldRTH_Alt;

@property UITextField *txtFieldRTH_Alt;
//@property (weak, nonatomic) IBOutlet UITextField *txtFieldCircuitLength;

@property UITextField *txtFieldCircuitLength;

@property Circuit* loadedCircuit;

-(id) initWithCircuit:(Circuit*) circuit;
@end
