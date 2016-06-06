//
//  circuitsListFW.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/6/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "circuitsListFW.h"
#import "DVFLoatingWindow.h"

@implementation circuitsListFW

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    
    CGRect screenFrame = [[UIScreen mainScreen]bounds];
    
    self.frame = CGRectMake(0, 0,0.35*screenFrame.size.width, 0.6*screenFrame.size.height);
    self.alpha = 0.95;
    self.layer.cornerRadius = 5.0;

    
    self.clipsToBounds = YES;
    
    allCircuits = [self loadExistingCircuitsNames_coder];
    
    return self;
}


-(void) initWithDefaultsProperties{
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    UIPanGestureRecognizer *topPanGR = [[UIPanGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(topBorderPanGesture:)];
    [_titleLabel addGestureRecognizer:topPanGR];
    
}


#pragma mark -  UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section{
    return allCircuits.count;;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    BOOL isSelected = ([tableView indexPathForSelectedRow] == indexPath);
    
    NSString *CellIdentifier = @"swipeableCellTrackSelection";

    CircuitsTVC* tvc = [[Menu instance] getCircuitsMenu];
    
    MGSwipeTableCell *cell = [tvc.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
//    UIButton* selectionButton = cell.contentView.subviews[1];
//
//    
//    if (!isSelected) {
//        [selectionButton setHidden:YES];
//    }
    
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
        NSLog(@"trying to load , '%@'",circuitName);
        mapVC.circuit = [cm loadCircuitNamed_coder:circuitName];
    }
    
    if (!mapVC.circuit || !mapVC.circuit.locations || !mapVC.circuit.locations.count) {
        NSLog(@"empty circuit loaded");
        return;
    }
    
    [[Calc Instance] map:mapView showCircuit:mapVC.circuit];

    
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
}

- (IBAction)onAddButtonClicked:(id)sender {
    NSLog(@"addButton");
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
    NSLog(@"%ld",[_tableView indexPathForSelectedRow].row);
}

-(void) showCircuitList:(BOOL)animated{
    MKMapView* mapView = [[Menu instance] getMap];
    
    for (UIView* subview in [mapView subviews]) {
        if([subview.restorationIdentifier isEqualToString:@"selectTrack"]){
            [subview removeFromSuperview];
        }
    }
    
    [[[UIApplication sharedApplication]keyWindow] addSubview:self];
    CGSize frameSize = self.frame.size;
    
    POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    positionAnimation.toValue = @(self.center.y/5 + frameSize.height/2);
    positionAnimation.springBounciness = 10;
    [positionAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        
    }];
    POPSpringAnimation *positionAnimationX = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    positionAnimationX.toValue = @(frameSize.width/2);
    positionAnimationX.springBounciness = 10;
    [positionAnimationX setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        
    }];
    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.springBounciness = 20;
    scaleAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(0.5, 1)];
    
    
    
    [self.layer pop_addAnimation:positionAnimation forKey:@"positionAnimation"];
    [self.layer pop_addAnimation:positionAnimationX forKey:@"positionAnimationX"];
//    [self.layer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
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
