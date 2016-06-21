//
//  circuitsListFW.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/6/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#define DV_FLOATING_WINDOW_ENABLE 1

#import "circuitsListFW.h"
#import "DVFLoatingWindow.h"



@implementation circuitsListFW

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    
    CGRect screenFrame = [[UIScreen mainScreen]bounds];
    
    self.frame = CGRectMake(self.superview.center.x, self.superview.center.y,screenFrame.size.width/3, 0.5*screenFrame.size.height);
    self.alpha = 0.95;
    self.layer.cornerRadius = 5.0;

    
    self.clipsToBounds = YES;
    self.alpha = 0;
    allCircuits = [self loadExistingCircuitsNames_coder];
    
    selectedRow = -1;
    selectRow = -1;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(panCircuitEnded:) name:@"panCircuitEnded" object:nil];
    
    showSwipeAnimation = YES;
    isInit = NO;
    return self;
}


-(void) initWithDefaultsProperties{
    
    CGRect screenFrame = [[UIScreen mainScreen]bounds];
    
    self.frame = CGRectMake(self.superview.center.x, self.superview.center.y,screenFrame.size.width/3, 0.5*screenFrame.size.height);

    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.alpha = 0.7;
    
    defineTableView = [[UITableView alloc] initWithFrame:_tableView.frame];
    defineTableView.dataSource = self;
    
    UIPanGestureRecognizer *topPanGR = [[UIPanGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(topBorderPanGesture:)];
    [_titleLabel addGestureRecognizer:topPanGR];
    
    
    
    [_closeBut addTarget:self action:@selector(onCloseButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    _closeBut.isAdd = NO;
    
    [_addBut addTarget:self action:@selector(onAddButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    _addBut.isAdd = YES;
    
    isInit = YES;
    
}

-(void) layoutSubviews{
    [super layoutSubviews];

    if (!_closeBut.resized) {
        [_closeBut resize];
    }
    if (!_addBut.resized) {
        [_addBut resize];
    }
  
}

-(void) onCloseButtonClicked:(id) sender{
    [self hideCircuitList:YES];
}

-(void) onAddButtonClicked:(id) sender{
    
    if (_addBut.status ==  2) {

        [self openDefineTableViewForCircuit:nil];
    }
    else if (_addBut.status == 3){

        [self closeDefineTableView];
    }

    
}

-(void) openDefineTableViewForCircuit:(Circuit*) circuit{
    
    if (!circuit) {
        newCirc = YES;
        newCircuit = [[Circuit alloc] init];
        isDefiningNewCircuit = YES;
    }
    else{
        newCircuit = loadedCircuit;
        newCirc = NO;
        isDefiningNewCircuit = NO;
    }
    
    [defineTableView reloadData];
    
    [defineTableView setFrame:_tableView.frame];
    
    POPBasicAnimation* entranceAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    
    if (_addBut.status ==  2) {
        
        entranceAnimation.fromValue = @(_tableView.center.x+_tableView.frame.size.width);
        entranceAnimation.toValue = @(_tableView.center.x);
        entranceAnimation.duration = 1;
        
        [self addSubview:defineTableView];
        [defineTableView.layer pop_addAnimation:entranceAnimation forKey:@"entranceAlpha"];
        [_addBut animateToMinusWithCompletion:^(BOOL finished) {
            
        }];
    }
}
-(void) closeDefineTableView{
    POPBasicAnimation* closeAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    
    if (_addBut.status == 3){
        isDefiningNewCircuit = NO;
        closeAnimation.toValue = @(_tableView.center.x + _tableView.frame.size.width);
        closeAnimation.duration = 0.5;
        [closeAnimation setCompletionBlock:^(POPAnimation * anim, BOOL finished) {
            [defineTableView removeFromSuperview];
        }];
        [defineTableView.layer pop_addAnimation:closeAnimation forKey:@"closeAlpha"];
        
        
        [_addBut animateToAddWithCompletion:^(BOOL finished) {
            
        }];
        allCircuits = [self loadExistingCircuitsNames_coder];
        [_tableView reloadData];
    }
}

-(void) openCircuitListWithCompletion:(void (^)(BOOL finished))callback{
    if (!isInit) {
        [self initWithDefaultsProperties];
    }
    [self closeDefineTableView];
    
    MapView* mapView = (MapView*)[[Menu instance] getMap];
    [mapView setMapViewMaskImage:NO];
    
    [[[UIApplication sharedApplication]keyWindow] addSubview:self];
    
    POPSpringAnimation *positionAnimationY = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    
    positionAnimationY.fromValue = @(0.5*self.superview.center.y + self.superview.frame.size.height/10);
    positionAnimationY.toValue = @(0.5*self.superview.center.y + self.superview.frame.size.height/10);
    positionAnimationY.springBounciness = 25;
    [positionAnimationY setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        
    }];
    POPSpringAnimation *positionAnimationX = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    
    positionAnimationX.fromValue = @(-self.superview.center.x*0.4);
    positionAnimationX.toValue = @(self.superview.center.x*0.4);
    positionAnimationX.springBounciness = 15;
    [positionAnimationX setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        [_closeBut animateToCloseWithCompletion:^(BOOL finished) {
            
        }];
        
        if ([self.subviews containsObject:defineTableView]) {
            [_addBut animateToMinusWithCompletion:^(BOOL finished) {
                
            }];
        }
        else{
            [_addBut animateToAddWithCompletion:^(BOOL finished) {
                
            }];
        }
        
        if (showSwipeAnimation) {
            MGSwipeTableCell* firstCell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            
            showSwipeAnimation = NO;
            
            
            
            [firstCell showSwipe:MGSwipeDirectionLeftToRight animated:YES completion:^(BOOL finished) {
                
            }];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [firstCell hideSwipeAnimated:YES completion:^(BOOL finished) {
                    
                }];
            });
            
        }
        
        callback(finished);
        
    }];
    
    
    POPBasicAnimation *fadeAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    fadeAnimation.duration = 1.0;
    fadeAnimation.toValue = @1;
    
    [self.layer pop_addAnimation:positionAnimationY forKey:@"positionAnimationY"];
    [self.layer pop_addAnimation:positionAnimationX forKey:@"positionAnimationX"];
    [self.layer pop_addAnimation:fadeAnimation forKey:@"fadeAnimation"];
}


#pragma mark -  UITableView  dataSource

// CIRCUIT LIST

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section{
    if (tableView == _tableView) {
        return allCircuits.count;
    }
    else if(tableView == defineTableView){
        return 3;
    }
    else{
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *parts = [[NSBundle mainBundle] loadNibNamed:@"cells" owner:nil options:nil];
    
    if (tableView == _tableView) {
        
        MGSwipeTableCell *cell = [parts objectAtIndex:0];
        
//        NSLog(@"cell for row ------>  %d <-------",(int)indexPath.row);
        cell.delegate = self;
        UILabel* textLabel = [self labelOfCell:cell];
        [textLabel setText:[allCircuits objectAtIndex:indexPath.row]];
        
        [self setButtonForCell:cell AtIndexPath:indexPath];
        
        return cell;
    }
    else if (tableView == defineTableView){
//        NSLog(@"cell for row ------>define  %d <-------",(int)indexPath.row);
        int row = (int)indexPath.row;
        
        UITableViewCell* cell = [parts objectAtIndex:(row+1)];
        
        switch (row) {
            case 0:
            {
                txtFieldCircuitName = [self textFieldOfCell:cell];
                txtFieldCircuitName.delegate = self;
                if (newCircuit.circuitName) {
                    [txtFieldCircuitName setText:newCircuit.circuitName];
                }
            }
                break;
            case 1:
            {
                txtFieldCircuitLength = [self textFieldOfCell:cell];
                txtFieldCircuitLength.delegate = self;
                
                if (newCircuit.locations) {
                    [txtFieldCircuitLength setText:[NSString stringWithFormat:@"%0.1fm",[newCircuit length]]];
                }
            }
                break;
            case 2:
            {
                txtFieldRTH_Alt = [self textFieldOfCell:cell];
                txtFieldRTH_Alt.delegate = self;
                if (newCircuit.RTH_altitude) {
                    [txtFieldRTH_Alt setText:[NSString stringWithFormat:@"%0.1fm",newCircuit.RTH_altitude]];
                }
            }
                break;
                
            default:
                break;
        }
        
        return cell;
    }
    else{
        return [[UITableViewCell alloc] init];
    }
    
}

-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction fromPoint:(CGPoint) point{
    
    if (direction == MGSwipeDirectionRightToLeft) {
        
        return NO;
    }
    else {
//        [_tableView selectRowAtIndexPath:[_tableView indexPathForCell:cell] animated:YES scrollPosition:UITableViewScrollPositionNone];
        return YES;
    }
}
-(NSArray*) swipeTableCell:(MGSwipeTableCell*) cell swipeButtonsForDirection:(MGSwipeDirection)direction
             swipeSettings:(MGSwipeSettings*) swipeSettings expansionSettings:(MGSwipeExpansionSettings*) expansionSettings;
{
    if (direction != MGSwipeDirectionRightToLeft) {
        
        return [self createLeftButtons:2];
    }
    else {
        
        return nil;
    }
}

-(NSArray *) createLeftButtons: (int) number
{
    NSMutableArray * result = [NSMutableArray array];
    NSString* titles[2] = {@"Delete", @"Edit"};
    
    UIColor* yellowColor = [UIColor colorWithHue:0.125 saturation:0.93 brightness:0.95 alpha:1.0];
    UIColor * colors[2] = {[UIColor redColor], yellowColor};
    for (int i = 0; i < 2; ++i)
    {
        MGSwipeButton * button = [MGSwipeButton buttonWithTitle:titles[i] backgroundColor:colors[i] callback:^BOOL(MGSwipeTableCell * sender){
            
            BOOL autoHide = i != 0;
            return autoHide; //Don't autohide in delete button to improve delete expansion animation
        }];
        
        [result addObject:button];
    }
    return result;
}

-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell tappedButtonAtIndex:(NSInteger) index direction:(MGSwipeDirection)direction fromExpansion:(BOOL) fromExpansion{
    circuitManager* cm = [circuitManager Instance];
    
    if (index == 0) {
        [cm removeCircuitNamed:[self txtOfCell:cell]];
        allCircuits = [self loadExistingCircuitsNames_coder];
        [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[_tableView indexPathForCell:cell]]  withRowAnimation:UITableViewRowAnimationFade];
        selectRow = -1;
        
        [_tableView reloadData];
        
    }
    else if(index == 1 ){
        [self tableView:_tableView didDeselectRowAtIndexPath:[_tableView indexPathForSelectedRow]];
        [self tableView:_tableView didSelectRowAtIndexPath:[_tableView indexPathForCell:cell]];
        [self openDefineTableViewForCircuit:loadedCircuit];
    }
    return NO;
}

// DEFINE TABLE VIEW
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if (textField == txtFieldCircuitLength) {
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textFieldloc{
    [textFieldloc resignFirstResponder];
    
    NSString* string = textFieldloc.text;
    
    if (textFieldloc == txtFieldRTH_Alt){
        if (!loadedCircuit) {
            loadedCircuit = [[Circuit alloc]init];
        }
        loadedCircuit.RTH_altitude = [string floatValue];
        
        [txtFieldRTH_Alt setText:[NSString stringWithFormat:@"%0.1fm",loadedCircuit.RTH_altitude]];
        
        if(loadedCircuit.circuitName){
            [[circuitManager Instance] saveCircuit:loadedCircuit];
        }
        else{
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES];
            });
        }
    }
    
    else if (textFieldloc == txtFieldCircuitName){
        if (!newCircuit) {
            newCircuit = [[Circuit alloc] init];
        }
        if (isDefiningNewCircuit) {
            
            newCircuit.circuitName = string;
            if (!newCircuit.locations) {
                [self startPan];
            }
            else{
                [[circuitManager Instance] saveCircuit:newCircuit];
            }
            
        }
        else{
            
            newCircuit.circuitName = string;
        }
//        if (!loadedCircuit) {
//            loadedCircuit = [[Circuit alloc]init];
//        }
//        loadedCircuit.circuitName = string;
//        
//        if (!loadedCircuit.locations) {
//            // launch pan circuit to get
//            isDefiningNewCircuit = YES;
//            [self startPan];
//        }
//        else{
//            [[circuitManager Instance] saveCircuit:loadedCircuit];
//            
//            
//        }
    }
    
    return NO;
}

#pragma mark - delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == _tableView) {
        // load concerned circuit and show it
        MGSwipeTableCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        NSString* circuitName = [self txtOfCell:cell];
        
        MapVC* mapVC = [[Menu instance] getMapVC];
        MapView* mapView = [[Menu instance] getMapView];
        
        circuitManager* cm = [circuitManager Instance];
        
        if (!mapVC.circuit || !mapVC.circuit.circuitName || ![mapVC.circuit.circuitName isEqualToString:circuitName]) {
            loadedCircuit = [cm loadCircuitNamed_coder:circuitName];
        }
        
        if (!loadedCircuit || !loadedCircuit.locations || !loadedCircuit.locations.count) {
            NSLog(@"empty circuit loaded");
            return;
        }
        
        [[Calc Instance] map:mapView showCircuit:loadedCircuit];
        
        if (mapVC.phoneLocation) {
            float dist = 1000000;
            int i = 0;
            for (CLLocation* loci in loadedCircuit.locations) {
                float disti = [[Calc Instance] distanceFromCoords2D:loci.coordinate toCoords2D:mapVC.phoneLocation.coordinate];
                if (dist > disti) {
                    dist = disti;
                    i = (int)[loadedCircuit.locations indexOfObject:loci];
                }
            }
            NSLog(@"closest distance circuit to user , %0.3f",dist);
        }
        
        selectRow = (int)indexPath.row;
        [self setButtonForCell:[tableView cellForRowAtIndexPath:indexPath] AtIndexPath:indexPath];
    }
    else if (tableView == defineTableView){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    
}
-(void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectRow = -1;
    [self setButtonForCell:[tableView cellForRowAtIndexPath:indexPath] AtIndexPath:indexPath];
}

-(void) setButtonForCell:(MGSwipeTableCell*) cell AtIndexPath:(NSIndexPath*) indexPath {
    
    UIButton* selectButton = [self buttonOfCell:cell];
    [selectButton addTarget:self action:@selector(didSelectCircuitAtSelectedRow:) forControlEvents:UIControlEventTouchUpInside];
    int row = (int)indexPath.row;
    
//    if (!loadedCircuit) {
//        selectedRow = -1;
//    }
//    else{
//        if ([loadedCircuit.circuitName isEqualToString:[self txtOfCell:cell]]) {
//            [selectButton setTitle:@"selected" forState:UIControlStateNormal];
//            [selectButton setHidden:NO];
//        }
//    }
//    if ([_tableView indexPathForSelectedRow] == [_tableView indexPathForCell:cell] ) {
//        [selectButton setTitle:@"select" forState:UIControlStateNormal];
//        [selectButton setHidden:NO];
//    }
//    else{
//        [selectButton setHidden:YES];
//    }
    if (row == selectedRow) {
        [selectButton setTitle:@"selected" forState:UIControlStateNormal];
        [selectButton setHidden:NO];
    }
    else if (row == selectRow){
        [selectButton setTitle:@"select" forState:UIControlStateNormal];
        [selectButton setHidden:NO];
    }
    else{
        [selectButton setHidden:YES];
    }
}

-(void) hideOrshowButtonAtIndexPath:(NSIndexPath*) indexPath hide:(BOOL) hide{
    MGSwipeTableCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    float alph = 1;
    float duration = 0.5;
    
    if (hide) {
        duration = 0.1;
        alph = 0;
        
    }
    UIButton* selectButton = [self buttonOfCell:cell];
    if (hide && [selectButton.titleLabel.text isEqualToString:@"selected"]) {
        return;
    }
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        selectButton.alpha = alph;
        [selectButton setHidden:hide];
    }completion:^(BOOL finished){
        if (!hide) {
            [selectButton addTarget:self action:@selector(didSelectCircuitAtSelectedRow:) forControlEvents:UIControlEventTouchUpInside];
        }
    }];
}


- (void) didSelectCircuitAtSelectedRow:(id) sender{
    
    MapVC* mapVC = [[Menu instance] getMapVC];
    if (loadedCircuit) {
        
        loadedCircuit.mapView = [[Menu instance] getMapView];
        
        [loadedCircuit update];
        
        mapVC.circuit = loadedCircuit;
        
        NSLog(@"setting mapVC circuit: \"%@\"",loadedCircuit.circuitName);
        
        // inform that this circuit "circuitName" is selected
        MGSwipeTableCell* cell = [_tableView cellForRowAtIndexPath:[_tableView indexPathForSelectedRow]];
        UIButton* button = [self buttonOfCell:cell];
        [button setTitle:@"selected" forState:UIControlStateNormal];
        
        for (MGSwipeTableCell* celli in [_tableView visibleCells]) {
            if (celli != cell ) {
                UIButton* buttoni = [self buttonOfCell:celli];

                [buttoni setHidden:YES];
                [buttoni setTitle:@"select" forState:UIControlStateNormal];
            }
        }
    }
    selectedRow = (int) [_tableView indexPathForSelectedRow].row;
}


- (void)topBorderPanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:_titleLabel];
    [recognizer setTranslation:CGPointZero inView:_titleLabel];
    
    CGRect frame = self.frame;
    frame.origin.x += translation.x;
    frame.origin.y += translation.y;
    
    self.frame = frame;
    NSLog(@"here");
}

#pragma mark - animations
-(void) hideCircuitList:(BOOL)animated{

    POPBasicAnimation *opacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    opacityAnimation.toValue = @(0.0);
    
    POPBasicAnimation *offscreenAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    offscreenAnimation.toValue = @(5*self.superview.center.x);
    offscreenAnimation.duration = 0.5;
    [offscreenAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
         [self removeFromSuperview];
        MapView* map = (MapView*)[[Menu instance] getMap];
        [map updateMaskImageAndButton];
    }];
    
    [self.layer pop_addAnimation:offscreenAnimation forKey:@"offscreenAnimation"];
    
    
}

-(void) showCircuitList:(BOOL)animated{

    [self closeDefineTableView];
    MapView* mapView = (MapView*)[[Menu instance] getMap];
    [mapView setMapViewMaskImage:NO];
    
    [[[UIApplication sharedApplication]keyWindow] addSubview:self];
    
    POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];

    positionAnimation.toValue = @(0.5*self.superview.center.y + self.superview.frame.size.height/10);
    positionAnimation.springBounciness = 25;
    [positionAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        
    }];
    POPSpringAnimation *positionAnimationX = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];

    positionAnimationX.toValue = @(self.superview.center.x*0.4);
    positionAnimationX.springBounciness = 20;
    [positionAnimationX setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        [_closeBut animateToCloseWithCompletion:^(BOOL finished) {
            
        }];
        
        if ([self.subviews containsObject:defineTableView]) {
            [_addBut animateToMinusWithCompletion:^(BOOL finished) {
                
            }];
        }
        else{
            [_addBut animateToAddWithCompletion:^(BOOL finished) {
                
            }];
        }
        
        if (showSwipeAnimation) {
            MGSwipeTableCell* firstCell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            
            showSwipeAnimation = NO;

            
            
            [firstCell showSwipe:MGSwipeDirectionLeftToRight animated:YES completion:^(BOOL finished) {
                
            }];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [firstCell hideSwipeAnimated:YES completion:^(BOOL finished) {
                    
                }];
            });
            
        }
        
    }];

    
    POPBasicAnimation *fadeAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    fadeAnimation.duration = 1.0;
    fadeAnimation.toValue = @1;
    
    [self.layer pop_addAnimation:positionAnimation forKey:@"positionAnimation"];
    [self.layer pop_addAnimation:positionAnimationX forKey:@"positionAnimationX"];
    [self.layer pop_addAnimation:fadeAnimation forKey:@"fadeAnimation"];
}




-(void) startPan{
    [[[Menu instance] getMainRevealVC] setFrontViewPosition:FrontViewPositionLeftSide animated:YES];
    MapVC* mapVC = [[Menu instance] getMapVC];
    
    [mapVC disableMainMenuPan];
    [mapVC.mapView disableMapViewScroll];
    
    mapVC.isPathDrawingEnabled = YES;
    
    DVLog(@"please define circuit through swiping on the screen");
}


-(void) panCircuitEnded:(NSNotification*) notification{
    NSDictionary* dict = notification.userInfo;
    NSMutableArray* locations = [dict objectForKey:@"locations"];
    
    if (isDefiningNewCircuit) {
        newCircuit.locations = locations;
        [[circuitManager Instance] saveCircuit:newCircuit];
        [defineTableView reloadData];
        [_tableView reloadData];
    }
}


#pragma mark -  Supporting methods

-(NSMutableArray*) loadExistingCircuitsNames_coder{
    NSMutableArray* arrayOfCircuitsNames = [[NSMutableArray alloc] init];
    
    NSArray *keys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
    
    for(NSString* key in keys){
        if ([key hasSuffix:@"_c"]) {
            
            NSArray* arrayFromCircuitPath = [key componentsSeparatedByString:@"_"];
            NSString* circuitN = arrayFromCircuitPath[0];
            [arrayOfCircuitsNames addObject:circuitN];
        }
        
    }
    return arrayOfCircuitsNames;
}

-(NSString*) txtOfCell:(MGSwipeTableCell*) cell{
    return [self labelOfCell:cell].text;
}

-(UILabel*) labelOfCell:(MGSwipeTableCell*)cell{
    return cell.contentView.subviews[1];
}
-(UIButton*) buttonOfCell:(MGSwipeTableCell*)cell{
    return [cell.contentView.subviews objectAtIndex:0];
}
-(UITextField*) textFieldOfCell:(UITableViewCell*)cell{
    return [cell.contentView.subviews objectAtIndex:1];
}

-(void) removeCircuitAtIndexPath:(NSIndexPath*) indexPath{
    
    NSInteger index = indexPath.row;
    
    NSString* circuitName = allCircuits[index];
    
    [[circuitManager Instance] removeCircuitNamed:circuitName];
    
    [allCircuits removeObjectAtIndex:index];
    
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}

// add observer when menu opened .. mainReveal frontPosition != left
//--> dismiss this view

// rename circuit ...:/
@end
