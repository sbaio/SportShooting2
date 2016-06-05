//
//  AircraftMenuTVC.m
//  SportShooting
//
//  Created by Othman Sbai on 5/23/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "AircraftMenuTVC.h"

@interface AircraftMenuTVC ()

@end

@implementation AircraftMenuTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
     self.clearsSelectionOnViewWillAppear = NO;
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
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
    return 4;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    self.tableView.frame = CGRectMake(0, 0,navC.mainReveal.rearViewRevealOverdraw, self.tableView.frame.size.height);
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
   
    NSString *text = nil;
    switch ( indexPath.row )
    {
        case 0:
        {
            text = @"Aircraft";
            break;
        }
        case 1:{
            text = @"Gimbal"; break;
        }
        case 2:{
            text = @"Remote Controller"; break;
        }
        case 3:{
            text = @"Camera";
            UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"camera_25_red.png"]];
            DJICamera* camera = [ComponentHelper fetchCamera];
            
            if (camera) {
                _isCameraConnected = YES;
                imageView.image =[UIImage imageNamed:@"camera_25_green.png"];
            }
            else{
                _isCameraConnected = NO;
            }
            CGRect cellFrame = cell.frame;
            float h = 0.6*cellFrame.size.height;
            float w = h;
            float x = 175;
            float y = (cellFrame.size.height - h)/2;
            
            imageView.frame = CGRectMake(x, y, w,h);

            [cell.contentView addSubview:imageView];
            
            break;
        }
        case 4:{
                text = @"star"; break;
        }
        case 5:{
                text = @"More"; break;
        }
    }
    
    
 
 cell.textLabel.text = text;
 cell.textLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
 cell.backgroundColor = self.tableView.backgroundColor;
 
    // background during selection
    UIView * selectedBackgroundView = [[UIView alloc] init];
    [selectedBackgroundView setBackgroundColor:[UIColor colorWithHue:0.125 saturation:0.93 brightness:0.95 alpha:1.0]];
    [cell setSelectedBackgroundView:selectedBackgroundView];
 
 return cell;
}





#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
}



@end
