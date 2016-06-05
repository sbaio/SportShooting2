//
//  DVFloatingWindow.m
//  DVFloatingWindow
//
//  Created by Dmitry Vorobyov on 7/26/13.
//  Copyright (c) 2013 Dmitry Vorobyov. All rights reserved.
//

#import "DVFloatingWindow.h"
#import "DVLogger.h"
#import "DVButtonObject.h"
#import "DVEmailManager.h"

#define BORDER_SIZE 2
#define TOP_BORDER_HEIGHT 30
#define BOTTOM_CORNER_SIZE 30
#define MOVEMENT_BUTTON_WIDTH 30
#define MENU_BUTTON_WIDTH 60
#define AUTOSCROLL_BUTTON_WIDTH 60

#define MIN_ORIGIN_Y 20
//#define MIN_ORIGIN_X 500
#define MIN_VISIBLE_SIZE 30
#define MIN_WIDTH 100
#define MIN_HEIGHT 50

typedef enum
{
    TableViewStateMenuButtons,
    TableViewStateMenuLogs,
    TableViewStateButtons,
    TableViewStateLogs
} TableViewState;

@interface DVFloatingWindow() <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UILabel *topTitleLabel;
@property (strong, nonatomic) UIView *bottomCorner;
@property (strong, nonatomic) UIButton *previousButton;
@property (strong, nonatomic) UIButton *nextButton;
@property (strong, nonatomic) UIButton *menuButton;
@property (strong, nonatomic) UIButton *autoscrollButton;

@property (strong, nonatomic) NSMutableArray *menuArray;
@property (strong, nonatomic) NSMutableArray *arrayWithButtons;
@property (strong, nonatomic) NSMutableDictionary *dictWithLoggers;

@property (assign, nonatomic) TableViewState tableViewState;
@property (strong, nonatomic) NSString *visibleLoggerKey;

@property (strong, nonatomic) UIGestureRecognizer *activateRecognizer;

@property (strong, nonatomic) DVEmailManager *emailManager;


// properties from h file
@property (assign, nonatomic) CGRect configFrame;
@property (strong, nonatomic) UIColor *configBackroundColor;
@property (strong, nonatomic) UIColor *configTopBGColor;
@property (strong, nonatomic) UIColor *configTopMenuBGColor;
@property (strong, nonatomic) UIColor *configTopFontColor;
@property (strong, nonatomic) UIColor *configRightCornerColor;
@property (strong, nonatomic) NSString *configEmailSubject;
@property (strong, nonatomic) NSArray *configEmailToRecipients;
@property (strong, nonatomic) NSArray *configEmailCcRecipients;
@property (strong, nonatomic) NSArray *configEmailBccRecipients;
@property (strong, nonatomic) NSString *configEmailMessageBody;
@property (assign, nonatomic) BOOL configEmailIsMessageBodyHTML;

@end


@implementation DVFloatingWindow

#pragma mark -  Lifecycle

- (id)initWithFrame:(CGRect)frame
{
    return nil;
}

- (id)initPrivate
{
    if (self = [super initWithFrame:CGRectZero]) {
        [self performBlockOnMainThread:^{
            [self createSubviews];

            self.configFrame = CGRectMake(400, 50, 250, 100);
            self.configBackroundColor = [UIColor lightGrayColor];
            self.configTopBGColor = [UIColor colorWithHue:0.125 saturation:0.93 brightness:0.95 alpha:1.0];
            self.configTopMenuBGColor = [UIColor lightGrayColor];
            self.configTopTextColor = [UIColor blackColor];
            self.configRightCornerColor = [UIColor colorWithHue:0.125 saturation:0.89 brightness:0.95 alpha:1.0];

            self.clipsToBounds = YES;
        }];

        self.arrayWithButtons = [NSMutableArray new];
        self.dictWithLoggers = [NSMutableDictionary new];
    }

    return self;
}

+ (DVFloatingWindow *)sharedInstance
{
    static DVFloatingWindow *window;

    @synchronized(self) {
        
        if (! window) {
            window = [[DVFloatingWindow alloc] initPrivate];
            [window loggerCreate:DV_FLOATING_WINDOW_DEFAULT_LOGGER_KEY];
            [window tabSwitchToLogger:DV_FLOATING_WINDOW_DEFAULT_LOGGER_KEY];
        }
        
            }

    
    return window;
}

#pragma mark -  Methods

- (void)setFrame:(CGRect)frame
{
    CGRect screenBounds = [UIScreen mainScreen].bounds;

    if (frame.size.width < MIN_WIDTH) {
        frame.size.width = MIN_WIDTH;
    }
    if (frame.size.height < MIN_HEIGHT) {
        frame.size.height = MIN_HEIGHT;
    }
    if (frame.origin.x + frame.size.width < MIN_VISIBLE_SIZE) {
        frame.origin.x = MIN_VISIBLE_SIZE - frame.size.width;
    }
    if (frame.origin.y < MIN_ORIGIN_Y) {
        frame.origin.y = MIN_ORIGIN_Y;
    }
    if (frame.origin.x > screenBounds.size.width - MIN_VISIBLE_SIZE) {
        frame.origin.x = screenBounds.size.width - MIN_VISIBLE_SIZE;
    }
    if (frame.origin.y > screenBounds.size.height - MIN_VISIBLE_SIZE) {
        frame.origin.y = screenBounds.size.height - MIN_VISIBLE_SIZE;
    }

    [self performBlockOnMainThread:^{
        [super setFrame:frame];

        CGRect theFrame = self.previousButton.frame;
        theFrame.origin.y = self.frame.size.height - theFrame.size.height - BORDER_SIZE;
        self.previousButton.frame = theFrame;

        theFrame = self.nextButton.frame;
        theFrame.origin.y = self.frame.size.height - theFrame.size.height - BORDER_SIZE;
        self.nextButton.frame = theFrame;

        theFrame = self.menuButton.frame;
        theFrame.origin.y = self.frame.size.height - theFrame.size.height - BORDER_SIZE;
        self.menuButton.frame = theFrame;

        theFrame = self.autoscrollButton.frame;
        theFrame.origin.y = self.frame.size.height - theFrame.size.height - BORDER_SIZE;
        self.autoscrollButton.frame = theFrame;

        theFrame = self.topTitleLabel.frame;
        theFrame.size.width = (self.frame.size.width - 2 * BORDER_SIZE);
        self.topTitleLabel.frame = theFrame;

        theFrame = self.bottomCorner.frame;
        theFrame.origin.x = self.frame.size.width - BOTTOM_CORNER_SIZE - BORDER_SIZE;
        theFrame.origin.y = self.frame.size.height - BOTTOM_CORNER_SIZE - BORDER_SIZE;
        self.bottomCorner.frame = theFrame;
    }];
}

- (void)menuButtonPressed
{
    // change to simple state
    if (self.tableViewState == TableViewStateMenuButtons) {
        self.tableViewState = TableViewStateButtons;

        [self.menuButton setTitle:@"Menu" forState:UIControlStateNormal];
        self.previousButton.enabled = self.nextButton.enabled = YES;

        [self deleteMenu];
    }
    else if (self.tableViewState == TableViewStateMenuLogs) {
        self.tableViewState = TableViewStateLogs;

        [self.menuButton setTitle:@"Menu" forState:UIControlStateNormal];
        self.previousButton.enabled = self.nextButton.enabled = YES;

        [self deleteMenu];
    }
    // change to menu state
    else if (self.tableViewState == TableViewStateButtons) {
        self.tableViewState = TableViewStateMenuButtons;

        [self.menuButton setTitle:@"Back" forState:UIControlStateNormal];
        self.previousButton.enabled = self.nextButton.enabled = NO;

        [self createMenuForButtons];
    }
    else if (self.tableViewState == TableViewStateLogs) {
        self.tableViewState = TableViewStateMenuLogs;

        [self.menuButton setTitle:@"Back" forState:UIControlStateNormal];
        self.previousButton.enabled = self.nextButton.enabled = NO;

        [self createMenuForLogs];
    }

    [self updateTopTitleLabelText];
    [self.tableView reloadData];
}

- (void)autoscrollButtonPressed
{
    self.autoscrollButton.selected = ! self.autoscrollButton.selected;
}

#pragma mark -  Methods window

- (void)windowShow
{
    @synchronized(self) {
        if (! [self isWindowVisible]) {

            [[[[[UIApplication sharedApplication] delegate] window] rootViewController].view addSubview:self];
            
            [self performBlockOnMainThread:^{

                //[self.tableView reloadData];
            }];
        }
    }
}

- (void)windowHide
{
    @synchronized(self) {
        [self performBlockOnMainThread:^{
            [self removeFromSuperview];
        }];
    }
}

- (void)windowActivationTapWithTouchesNumber:(NSUInteger)touchesNumber
{
    @synchronized(self) {
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(activateGesture:)];

        recognizer.numberOfTouchesRequired = touchesNumber;

        [self updateActivationGestureRecognizer:recognizer];
    }
}

- (void)windowActivationLongPressWithTouchesNumber:(NSUInteger)touchesNumber
                              minimumPressDuration:(CFTimeInterval)minimumPressDuration
{
    @synchronized(self) {
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self action:@selector(activateGesture:)];

        recognizer.numberOfTouchesRequired = touchesNumber;
        recognizer.minimumPressDuration = minimumPressDuration;

        [self updateActivationGestureRecognizer:recognizer];
    }
}

#pragma mark -  Methods tab

- (void)tabShowPrevious
{
    @synchronized(self) {
        [self tabShowNextOrPrevious:NO];
    }
}

- (void)tabShowNext
{
    @synchronized(self) {
        [self tabShowNextOrPrevious:YES];
    }
}

- (void)tabSwitchToLogger:(NSString *)loggerKey
{
    if (! [loggerKey isKindOfClass:[NSString class]] || ! self.dictWithLoggers[loggerKey]) {
        return;
    }

    @synchronized(self) {
        self.tableViewState = TableViewStateLogs;
        self.visibleLoggerKey = loggerKey;

        [self updateAll];
    }
}

- (void)tabSwitchToButtonsTab
{
    @synchronized(self) {
        if (self.arrayWithButtons.count) {
            self.tableViewState = TableViewStateButtons;
        }

        [self updateAll];
    }
}

#pragma mark -  Methods logger

- (void)loggerCreate:(NSString *)key
{
    if (! [key isKindOfClass:[NSString class]] || self.dictWithLoggers[key]) {
        return;
    }

    @synchronized(key) {
        self.dictWithLoggers[key] = [DVLogger loggerWithDefaultConfiguration];
        [self updateAll];
    }
}

- (void)loggerClear:(NSString *)key
{
    if (! [key isKindOfClass:[NSString class]] || ! self.dictWithLoggers[key]) {
        return;
    }

    @synchronized(key) {
        DVLogger *logger = self.dictWithLoggers[key];
        [logger removeAllLogs];

        if (self.tableViewState == TableViewStateLogs &&
            [key isEqualToString:self.visibleLoggerKey])
        {
            [self performBlockOnMainThread:^{
                [self.tableView reloadData];
            }];
        }
    }
}

- (void)loggerRemove:(NSString *)key
{
    if (! [key isKindOfClass:[NSString class]] || ! self.dictWithLoggers[key]) {
        return;
    }

    @synchronized(key) {
        if ([self isStateLogOrMenuLog] && [key isEqualToString:self.visibleLoggerKey]) {
            [self tabShowNext];
        }

        [self.dictWithLoggers removeObjectForKey:key];
        [self updateTopTitleLabelText];
    }
}

- (void)loggerLogToLogger:(NSString *)key
                      log:(NSString *)format,...
{
    if (! [format isKindOfClass:[NSString class]] ||
           ! [key isKindOfClass:[NSString class]] || 
           ! self.dictWithLoggers[key]) 
    {
        return;
    }

    @synchronized(key) {
        va_list argList;
        va_start (argList, format);
        NSString *log = [[NSString alloc] initWithFormat:format arguments:argList];
        va_end(argList);

        DVLogger *logger = self.dictWithLoggers[key];
        NSUInteger newIndex = [logger addLog:log];

        if ([self isWindowVisible] &&
            self.tableViewState == TableViewStateLogs &&
            [key isEqualToString:self.visibleLoggerKey])
        {
            [self performBlockOnMainThread:^{
                NSIndexPath *path = [NSIndexPath indexPathForRow:newIndex inSection:0];
                [self.tableView insertRowsAtIndexPaths:@[path]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];

                if (self.autoscrollButton.selected) {
                    UITableViewScrollPosition scrollPosition = (newIndex == 0) ?
                        UITableViewScrollPositionTop : UITableViewScrollPositionBottom;

                    [self.tableView scrollToRowAtIndexPath:path
                                          atScrollPosition:scrollPosition
                                                  animated:YES];
                }
                else {
                    [self.tableView flashScrollIndicators];
                }
            }];
        }
    }
}

#pragma mark -  Methods button

- (void)buttonAddWithTitle:(NSString *)title
                   handler:(DVFloatingWindowButtonHandler)handler
{
    @synchronized(self) {
        DVButtonObject *object = [DVButtonObject objectWithName:title handler:handler];

        [self.arrayWithButtons addObject:object];

        [self performBlockOnMainThread:^{
            [self.tableView reloadData];
        }];
    }
}

#pragma mark -  Methods configuration

- (void)setConfigFrame:(CGRect)configFrame
{
    [self performBlockOnMainThread:^{
        self.frame = configFrame;
        [self updateTableViewFrame];
    }];
}

- (CGRect)configFrame
{
    return self.frame;
}

- (void)setConfigBackroundColor:(UIColor *)color
{
    [self performBlockOnMainThread:^{
        self.backgroundColor = color;
    }];
}

- (UIColor *)configBackroundColor
{
    return self.backgroundColor;
}

- (void)setConfigTopBGColor:(UIColor *)color
{
    _configTopBGColor = color;

    if (! [self isStateMenu])
    {
        [self performBlockOnMainThread:^{
            self.topTitleLabel.backgroundColor = color;
        }];
    }
}

- (void)setConfigTopMenuBGColor:(UIColor *)color;
{
    _configTopMenuBGColor = color;

    if ([self isStateMenu])
    {
        [self performBlockOnMainThread:^{
            self.topTitleLabel.backgroundColor = color;
        }];
    }
}

- (void)setConfigTopTextColor:(UIColor *)color
{
    [self performBlockOnMainThread:^{
        self.topTitleLabel.textColor = color;
    }];
}

- (UIColor *)configTopTextColor
{
    return self.topTitleLabel.textColor;
}

- (void)setConfigRightCornerColor:(UIColor *)color
{
    [self performBlockOnMainThread:^{
        self.bottomCorner.backgroundColor = color;
    }];
}

- (UIColor *)configRightCornerColor
{
    return self.bottomCorner.backgroundColor;
}

- (void)configLogger:(NSString *)loggerKey latestMessageOnTop:(BOOL)latestMessageOnTop
{
    if (! [loggerKey isKindOfClass:[NSString class]] ||
        ! self.dictWithLoggers[loggerKey])
    {
        return;
    }

    @synchronized(loggerKey) {
        DVLogger *logger = self.dictWithLoggers[loggerKey];
        logger.configuration.latestMessageOnTop = latestMessageOnTop;

        if (self.tableViewState == TableViewStateLogs &&
                [loggerKey isEqualToString:self.visibleLoggerKey])
        {
            [self performBlockOnMainThread:^{
                [self.tableView reloadData];
            }];
        }
    }
}

- (void)configLogger:(NSString *)loggerKey font:(UIFont *)font
{
    if (! font ||
        ! [loggerKey isKindOfClass:[NSString class]] ||
        ! self.dictWithLoggers[loggerKey])
    {
        return;
    }

    @synchronized(loggerKey) {
        DVLogger *logger = self.dictWithLoggers[loggerKey];
        logger.configuration.font = font;

        if (self.tableViewState == TableViewStateLogs &&
                [loggerKey isEqualToString:self.visibleLoggerKey]) 
        {
            [self performBlockOnMainThread:^{
                [self.tableView reloadData];
            }];
        }
    }
}

#pragma mark -  Gestures

- (void)activateGesture:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }

    if ([self isWindowVisible]) {
        [self windowHide];
    }
    else {
        [self windowShow];
    }
}

- (void)topBorderPanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.topTitleLabel];
    [recognizer setTranslation:CGPointZero inView:self.topTitleLabel];

    CGRect frame = self.frame;
    frame.origin.x += translation.x;
    frame.origin.y += translation.y;

    self.frame = frame;
}

- (void)bottomCornerPanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.bottomCorner];
    [recognizer setTranslation:CGPointZero inView:self.bottomCorner];

    CGRect frame = self.frame;
    frame.size.width += translation.x;
    frame.size.height += translation.y;

    self.frame = frame;

    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self updateTableViewFrame];
    }
}

#pragma mark -  UITableView dataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self isStateMenu] ? @"DVButtonCell" : @"DVLoggerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];

        if ([self isStateMenu]) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else {
            cell.textLabel.numberOfLines = 0;
        }
    }

    if ([self isStateMenu]) {
        DVButtonObject *object = self.menuArray[indexPath.row];
        cell.textLabel.text = object.name;
    }
    else if (self.tableViewState == TableViewStateButtons) {
        DVButtonObject *object = self.arrayWithButtons[indexPath.row];
        cell.textLabel.text = object.name;
        cell.textLabel.font = [UIFont systemFontOfSize:13.0];
    }
    else if (self.tableViewState == TableViewStateLogs) {
        DVLogger *logger = self.dictWithLoggers[self.visibleLoggerKey];
        cell.textLabel.text = [logger logAtIndex:indexPath.row];
        cell.textLabel.font = logger.configuration.font;
    }

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if ([self isStateMenu]) {
        return self.menuArray.count;
    }
    else if (self.tableViewState == TableViewStateButtons) {
        return self.arrayWithButtons.count;
    }
    else if (self.tableViewState == TableViewStateLogs) {
        DVLogger *logger = self.dictWithLoggers[self.visibleLoggerKey];
        return logger.count;
    }

    return 0;
}

#pragma mark -  UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([self isStateMenu]) {
        if (indexPath.row >= self.menuArray.count) {
            return;
        }

        DVButtonObject *object = self.menuArray[indexPath.row];
        if (object.handler) {
            object.handler();
        }
    }
    else if (self.tableViewState == TableViewStateButtons) {
        if (indexPath.row >= self.arrayWithButtons.count) {
            return;
        }

        DVButtonObject *object = self.arrayWithButtons[indexPath.row];
        if (object.handler) {
            object.handler();
        }
    }
    else if (self.tableViewState == TableViewStateLogs) {
        DVLogger *logger = self.dictWithLoggers[self.visibleLoggerKey];

        if (indexPath.row >= logger.count) {
            return;
        }

        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [logger logAtIndex:indexPath.row];
    }
}

- (CGFloat)    tableView:(UITableView *)tableView
 heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.0;

    if ([self isStateMenu] || self.tableViewState == TableViewStateButtons) {
        height = 44.0;
    }
    else {
        DVLogger *logger = self.dictWithLoggers[self.visibleLoggerKey];
        NSString *text = [logger logAtIndex:indexPath.row];
        CGSize maximumLabelSize = CGSizeMake(310, CGFLOAT_MAX);
        //CGSize size = [text sizeWithFont:logger.configuration.font constrainedToSize:CGSizeMake(300.0, CGFLOAT_MAX)];
        CGRect size = [text boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:logger.configuration.font} context:nil];
        height = size.size.height + 2;
    }

    return height;
}

#pragma mark -  Properties

- (DVEmailManager *)emailManager
{
    if (! _emailManager) {
        _emailManager = [DVEmailManager new];
    }

    return _emailManager;
}

- (NSString *)configEmailSubject
{
    if (! _configEmailSubject) {
        _configEmailSubject = @"Logs";
    }

    return _configEmailSubject;
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

- (void)createSubviews
{
    {
        CGRect frame = CGRectZero;
        frame.origin.x = BORDER_SIZE;
        frame.origin.y = BORDER_SIZE + TOP_BORDER_HEIGHT;

        self.tableView = [[UITableView alloc] initWithFrame:frame];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        [self addSubview:self.tableView];
    }

    {
        self.previousButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.previousButton setTitle:@"<" forState:UIControlStateNormal];
        [self.previousButton addTarget:self
                                action:@selector(tabShowPrevious)
                      forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.previousButton];

        CGRect frame = self.previousButton.frame;
        frame.origin.x = BORDER_SIZE;
        frame.size.width = MOVEMENT_BUTTON_WIDTH;
        frame.size.height = BOTTOM_CORNER_SIZE;
        self.previousButton.frame = frame;
    }

    {
        self.nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.nextButton setTitle:@">" forState:UIControlStateNormal];
        [self.nextButton addTarget:self
                            action:@selector(tabShowNext)
                  forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.nextButton];

        CGRect frame = self.nextButton.frame;
        frame.origin.x = BORDER_SIZE + MOVEMENT_BUTTON_WIDTH;
        frame.size.width = MOVEMENT_BUTTON_WIDTH;
        frame.size.height = BOTTOM_CORNER_SIZE;
        self.nextButton.frame = frame;
    }

    {
        CGRect frame = CGRectZero;
        frame.origin.x = 2 * (BORDER_SIZE + MOVEMENT_BUTTON_WIDTH);
        frame.size.width = MENU_BUTTON_WIDTH;
        frame.size.height = BOTTOM_CORNER_SIZE;


        self.menuButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.menuButton.frame = frame;
        [self.menuButton setTitle:@"Menu" forState:UIControlStateNormal];
        [self.menuButton addTarget:self
                            action:@selector(menuButtonPressed)
                  forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.menuButton];
    }

    {
        CGRect frame = CGRectZero;
        frame.origin.x = 2 * (BORDER_SIZE + MOVEMENT_BUTTON_WIDTH) + MENU_BUTTON_WIDTH;
        frame.size.width = AUTOSCROLL_BUTTON_WIDTH;
        frame.size.height = BOTTOM_CORNER_SIZE;


        self.autoscrollButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.autoscrollButton.selected = YES;
        self.autoscrollButton.frame = frame;
        self.autoscrollButton.titleLabel.font = [UIFont systemFontOfSize:9.0];
        [self.autoscrollButton setTitle:@"✗ autoscroll" forState:UIControlStateNormal];
        [self.autoscrollButton setTitle:@"✓ autoscroll" forState:UIControlStateSelected];
        [self.autoscrollButton addTarget:self
                            action:@selector(autoscrollButtonPressed)
                  forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.autoscrollButton];
    }

    {
        CGRect frame = CGRectZero;
        frame.origin.x = frame.origin.y = BORDER_SIZE;
        frame.size.height = TOP_BORDER_HEIGHT;

        self.topTitleLabel = [[UILabel alloc] initWithFrame:frame];
        self.topTitleLabel.userInteractionEnabled = YES;
        self.topTitleLabel.font = [UIFont systemFontOfSize:13.0];
        self.topTitleLabel.textAlignment = NSTextAlignmentCenter;
        self.topTitleLabel.text = @"<<Buttons>>";
        [self addSubview:self.topTitleLabel];

        UIPanGestureRecognizer *topPanGR = [[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(topBorderPanGesture:)];
        [self.topTitleLabel addGestureRecognizer:topPanGR];
    }

    {
        CGRect frame = CGRectZero;
        frame.size.width = frame.size.height = BOTTOM_CORNER_SIZE;

        self.bottomCorner = [[UIView alloc] initWithFrame:frame];
        [self addSubview:self.bottomCorner];

        UIPanGestureRecognizer *bottomPanGR = [[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(bottomCornerPanGesture:)];
        [self.bottomCorner addGestureRecognizer:bottomPanGR];
    }
}

- (void)createMenuForButtons
{
    self.menuArray = [NSMutableArray new];
}

- (void)createMenuForLogs
{
    self.menuArray = [NSMutableArray new];

    [self.menuArray addObject:[DVButtonObject objectWithName:@"Clear current log" handler:^{
        if (self.visibleLoggerKey) {
            [self loggerClear:self.visibleLoggerKey];
            [self menuButtonPressed];
        }
    }]];

    [self.menuArray addObject:[DVButtonObject objectWithName:@"Send log to email" handler:^{
        if (self.visibleLoggerKey) {
            NSArray *arrayWithLoggersNames = @[self.visibleLoggerKey];

            if ([self sendLogsToEmailFromLoggersWithNames:arrayWithLoggersNames]) {
                [self menuButtonPressed];
                //[self windowHide];
            }
        }
    }]];

    [self.menuArray addObject:[DVButtonObject objectWithName:@"Send all logs to email" handler:^{
        if ([self sendLogsToEmailFromLoggersWithNames:[self.dictWithLoggers allKeys]]) {
            [self menuButtonPressed];
            //[self windowHide];
        }
    }]];
//    [self.menuArray addObject:[DVButtonObject objectWithName:@"Save log To device" handler:^{
//        if (self.visibleLoggerKey) {
//            NSArray *arrayWithLoggersNames = @[self.visibleLoggerKey];
//            
////            if ([self saveLogsToIOSDevice:arrayWithLoggersNames]) {
////                [self menuButtonPressed];
////                //[self windowHide];
////            }
//        }
//    }]];
    
}

- (void)deleteMenu
{
    self.menuArray = nil;
}

- (void)updateTableViewFrame
{
    CGRect frame = self.tableView.frame;
    frame.origin.x = BORDER_SIZE;
    frame.origin.y = BORDER_SIZE + TOP_BORDER_HEIGHT;
    frame.size.width = self.frame.size.width - 2 * BORDER_SIZE;
    frame.size.height = self.frame.size.height - TOP_BORDER_HEIGHT -
        BOTTOM_CORNER_SIZE - 2 * BORDER_SIZE;

    [self performBlockOnMainThread:^{
        self.tableView.frame = frame;
    }];
}

- (void)updateActivationGestureRecognizer:(UIGestureRecognizer *)recognizer
{
    id delegate = [UIApplication sharedApplication].delegate;
    UIWindow *window = [delegate window];

    [self performBlockOnMainThread:^{
        if (self.activateRecognizer) {
            [window removeGestureRecognizer:self.activateRecognizer];
        }

        [window addGestureRecognizer:recognizer];
    }];
    self.activateRecognizer = recognizer;
}

- (NSArray *)sortedLoggersKeys
{
    return [[self.dictWithLoggers allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)updateAll
{
    [self performBlockOnMainThread:^{
        [self updateTopTitleLabelText];
        [self.tableView reloadData];
    }];
}

- (void)updateTopTitleLabelText
{
    [self performBlockOnMainThread:^{
        if ([self isStateMenu]) {
            self.topTitleLabel.text = @"<<Menu>>";
            self.topTitleLabel.backgroundColor = self.configTopMenuBGColor;
        }
        else if (self.tableViewState == TableViewStateButtons) {
            self.topTitleLabel.text = @"<<Buttons>>";
            self.topTitleLabel.backgroundColor = self.configTopBGColor;
        }
        else if (self.tableViewState == TableViewStateLogs) {
            self.topTitleLabel.text = [NSString stringWithFormat:@"%@", self.visibleLoggerKey];
            self.topTitleLabel.backgroundColor = self.configTopBGColor;
        }
    }];
}

- (void)tabShowNextOrPrevious:(BOOL)showNext
{
    if (! self.dictWithLoggers.count) {
        return;
    }

    @synchronized(self) {
        NSArray *keys = [self sortedLoggersKeys];

        if (self.tableViewState == TableViewStateButtons) {
            NSUInteger index = showNext ? 0 : keys.count-1;

            self.visibleLoggerKey = keys[index];
            self.tableViewState = TableViewStateLogs;
        }
        else if (self.tableViewState == TableViewStateLogs) {
            NSInteger index = [keys indexOfObject:self.visibleLoggerKey];
            index += showNext ? 1 : -1;

            if (index >= 0 && index < keys.count) {
                self.visibleLoggerKey = keys[index];
            }
            else {
                if (self.arrayWithButtons.count) {
                    self.tableViewState = TableViewStateButtons;
                }
                else {
                    index = (index < 0) ? keys.count-1 : 0;
                    self.visibleLoggerKey = keys[index];
                }
            }
        }
    }

    [self updateAll];
}

- (BOOL)isStateButtonsOrMenuButtons
{
    return self.tableViewState == TableViewStateButtons ||
           self.tableViewState == TableViewStateMenuButtons;
}

- (BOOL)isStateLogOrMenuLog
{
    return self.tableViewState == TableViewStateLogs ||
           self.tableViewState == TableViewStateMenuLogs;
}

- (BOOL)isStateMenu
{
    return self.tableViewState == TableViewStateMenuButtons ||
           self.tableViewState == TableViewStateMenuLogs;
}

- (BOOL)isWindowVisible
{
    return self.superview != nil;
}
//- (BOOL)saveLogsToIOSDevice:(NSArray *)arrayWithLoggersNames
//{
//    NSMutableDictionary *loggers = [NSMutableDictionary new];
//    
//    for (NSString *loggerKey in arrayWithLoggersNames) {
//        DVLogger *l = self.dictWithLoggers[loggerKey];
//        
//        if (l) {
//            loggers[loggerKey] = l;
//        }
//    }
//    
//    if (loggers.count) {
//         NSLog(@"lbddv");
//        return [self.emailManager saveLogsToIOSDevice:loggers];
//        
//        
//    }
//    else {
//        return NO;
//    }
//    
//   
//}


- (BOOL)sendLogsToEmailFromLoggersWithNames:(NSArray *)arrayWithLoggersNames
{
    NSMutableDictionary *loggers = [NSMutableDictionary new];

    for (NSString *loggerKey in arrayWithLoggersNames) {
        DVLogger *l = self.dictWithLoggers[loggerKey];

        if (l) {
            loggers[loggerKey] = l;// creation du dictionnaire à envoyer en parcourant la liste de nom de loggers
        }
    }

    if (loggers.count) {
        //[self ]
        return [self.emailManager sendLogsToEmailFromLoggers:loggers        //dictionnaire
                                                     subject:self.configEmailSubject
                                                toRecipients:self.configEmailToRecipients
                                                ccRecipients:self.configEmailCcRecipients
                                               bccRecipients:self.configEmailBccRecipients
                                                 messageBody:self.configEmailMessageBody
                                           isMessageBodyHTML:self.configEmailIsMessageBodyHTML];
        
        
    }
    else {
        return NO;
    }
}

#pragma mark -  Deprecated

- (void)loggerSetConfigurationForLogger:(NSString *)key
                          configuration:(DVLoggerConfiguration *)configuration
{
    [self configLogger:key latestMessageOnTop:configuration.latestMessageOnTop];
    [self configLogger:key font:configuration.font];
}

@end
