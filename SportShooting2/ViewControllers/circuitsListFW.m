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
    
    return self;
}


-(void) initWithDefaultsProperties{
    
    CGRect screenFrame = [[UIScreen mainScreen]bounds];
    
    self.frame = CGRectMake(self.superview.center.x, self.superview.center.y,screenFrame.size.width/3, 0.5*screenFrame.size.height);
    NSLog(@"%@,%@", NSStringFromCGRect(self.frame),NSStringFromCGRect(_titleLabel.frame));

    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.alpha = 0.7;
    
    UIPanGestureRecognizer *topPanGR = [[UIPanGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(topBorderPanGesture:)];
    [_titleLabel addGestureRecognizer:topPanGR];
    
    
    
    [_closeBut addTarget:self action:@selector(onCloseButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_closeBut animateToClose];
    
    
    [_addBut addTarget:self action:@selector(onAddButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_addBut addTarget:self action:@selector(onAddButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    
}

-(void) layoutSubviews{
    [super layoutSubviews];

    [_closeBut setup];
    [_addBut setup];
  
}

-(void) onCloseButtonClicked:(id) sender{
    [self hideCircuitList:YES];
    
}

-(void) onAddButtonClicked:(id) sender{
    DVLog(@"add but ");
}


#pragma mark -  UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section{
    return allCircuits.count;;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *CellIdentifier = @"swipeableCellTrackSelection";

    CircuitsTVC* tvc = [[Menu instance] getCircuitsMenu];
    
    MGSwipeTableCell *cell = [tvc.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    [tableView setBackgroundColor:cell.contentView.backgroundColor];
    
    cell.delegate = self;
    UILabel* textLabel = [[cell.contentView subviews] objectAtIndex:0];
    
    [textLabel setText:[allCircuits objectAtIndex:indexPath.row]];
    
    return cell;
}

-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction fromPoint:(CGPoint) point{
    
    if (direction == MGSwipeDirectionRightToLeft) {
        
        return NO;
    }
    else {
        
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


#pragma mark - delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // load concerned circuit and show it
    MGSwipeTableCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSString* circuitName = [self txtOfCell:cell];
    
    MapVC* mapVC = [[Menu instance] getMapVC];
    MKMapView* mapView = [[Menu instance] getMap];
    
    circuitManager* cm = [circuitManager Instance];
    
    if (!mapVC.circuit || !mapVC.circuit.circuitName || ![mapVC.circuit.circuitName isEqualToString:circuitName]) {
        loadedCircuit = [cm loadCircuitNamed_coder:circuitName];
    }
    
    if (!loadedCircuit || !loadedCircuit.locations || !loadedCircuit.locations.count) {
        NSLog(@"empty circuit loaded");
        return;
    }
    
    [[Calc Instance] map:mapView showCircuit:loadedCircuit];

    
    [self hideOrshowButtonAtIndexPath:indexPath hide:NO];
    
}
-(void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self hideOrshowButtonAtIndexPath:indexPath hide:YES];
}

-(void) hideOrshowButtonAtIndexPath:(NSIndexPath*) indexPath hide:(BOOL) hide{
    MGSwipeTableCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    float alph = 1;
    float duration = 0.5;
    
    if (hide) {
        duration = 0.1;
        alph = 0;
        
    }
    UIButton* selectButton = cell.contentView.subviews[1];
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
    NSLog(@"selected circuit , %d",(int)[_tableView indexPathForSelectedRow].row);
    MapVC* mapVC = [[Menu instance] getMapVC];
    if (loadedCircuit) {
        mapVC.circuit = loadedCircuit;
        NSLog(@"setting mapVC circuit: \"%@\"",loadedCircuit.circuitName);
        
        // inform that this circuit "circuitName" is selected
        MGSwipeTableCell* cell = [_tableView cellForRowAtIndexPath:[_tableView indexPathForSelectedRow]];
        UIButton* button = cell.contentView.subviews[1];
        [button setTitle:@"selected" forState:UIControlStateNormal];
        
        for (MGSwipeTableCell* celli in [_tableView visibleCells]) {
            if (celli != cell ) {
                UIButton* buttoni = celli.contentView.subviews[1];

                [buttoni setHidden:YES];
                [buttoni setTitle:@"select" forState:UIControlStateNormal];
            }
        }
    }
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

    NSLog(@"herer");
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
        [_closeBut animateToClose];
        [_addBut animateToAdd];
    }];

    
    POPBasicAnimation *fadeAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    fadeAnimation.duration = 1.0;
    fadeAnimation.toValue = @1;
    
    [self.layer pop_addAnimation:positionAnimation forKey:@"positionAnimation"];
    [self.layer pop_addAnimation:positionAnimationX forKey:@"positionAnimationX"];
    [self.layer pop_addAnimation:fadeAnimation forKey:@"fadeAnimation"];
}













#pragma mark -  Supporting methods

- (void)performBlockOnMainThread:(void (^)())block
{
    if (block) {
        if ([NSThread isMainThread]) {
            block();
        }
        else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                block();
            });
        }
    }
}

-(NSMutableArray*) loadExistingCircuitsNames_coder{
    NSMutableArray* arrayOfCircuitsNames = [[NSMutableArray alloc] init];
    
    NSArray *keys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
    
    for(NSString* key in keys){
        if ([key hasSuffix:@"_c"]) {
            NSArray* arrayFromCircuitPath = [key componentsSeparatedByString:@"_"];
            NSString* circuitN = arrayFromCircuitPath[0];
            [arrayOfCircuitsNames addObject:circuitN];
            NSLog(@"%@",circuitN);
            
        }
        
    }
    return arrayOfCircuitsNames;
}

-(NSString*) txtOfCell:(MGSwipeTableCell*) cell{
    if (cell.contentView.subviews.count) {
        UILabel* label = cell.contentView.subviews[0]; // the label containing the text
        return label.text;
    }
    return nil;
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
@end
