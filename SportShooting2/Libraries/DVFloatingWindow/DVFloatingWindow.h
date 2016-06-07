//
//  DVFloatingWindow.h
//  DVFloatingWindow
//
//  Created by Dmitry Vorobyov on 7/26/13.
//  Copyright (c) 2013 Dmitry Vorobyov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DVDefinitions.h"
#import "DVLoggerConfiguration.h"
#import "DVMacros.h"

@interface DVFloatingWindow : UIView

+ (DVFloatingWindow *)sharedInstance;

@end


@interface DVFloatingWindow(Window)

/**
 * Show the window if it's hidden.
 *
 * Corresponding macro - DVWindowShow()
 */
- (void)windowShow;

-(void) log:(NSString*) log;
/**
 * Hide the window if it's visible.
 *
 * Corresponding macro - DVWindowHide()
 */
- (void)windowHide;

/**
 * Set tap gesture recognizer as an activation gesture. From now on, when tapped with
 * touchesNumber, the window will show/hide automatically.
 * 
 * Rewrite activation gesture that has been set before.
 *
 * Corresponding macro - DVWindowActivationTap(touchesNumber)
 */
- (void)windowActivationTapWithTouchesNumber:(NSUInteger)touchesNumber;

/**
 * Set long press gesture recognizer as an activation gesture. From now on, long pressed 
 * with touchesNumber and at least minimumPressDuration, the window will show/hide
 * automatically.
 * 
 * Rewrite activation gesture that has been set before.
 *
 * Corresponding macro - DVWindowActivationLongPress(touchesNumber, minimumPressDuration)
 */
- (void)windowActivationLongPressWithTouchesNumber:(NSUInteger)touchesNumber
                              minimumPressDuration:(CFTimeInterval)minimumPressDuration;

@end


@interface DVFloatingWindow(Tabs)

/**
 * Switch to previous or next tabs. This action is similar to pressing previous/next
 * buttons manually.
 *
 * Corresponding macros - DVTabPrevious(), DVTabNext()
 */
- (void)tabShowPrevious;
- (void)tabShowNext;

/**
 * Switch to tab with particular logger (if such exist)
 *
 * Corresponding macro - DVTabSwitchToLogger(loggerKey)
 */
- (void)tabSwitchToLogger:(NSString *)loggerKey;

/**
 * Switch to buttons tab
 *
 * Corresponding macro - DVTabSwitchToButtonsTab()
 */
- (void)tabSwitchToButtonsTab;

@end


@interface DVFloatingWindow(Logger)

/**
 * Create logger with NSString as a key (identifier). Only after logger was created it can
 * be configured, cleared, removed or receive a sent log.
 *
 * Corresponding macro - DVLoggerCreate(loggerKey)
 */
- (void)loggerCreate:(NSString *)loggerKey;

/**
 * Remove all logs that from logger.
 *
 * If logger doesn't exist nothing happens.
 *
 * Corresponding macro - DVLoggerClear(loggerKey)
 */
- (void)loggerClear:(NSString *)loggerKey;

/**
 * Remove logger. After removing, all other methods with a same logger key will do nothing.
 *
 * If logger doesn't exist nothing happens.
 *
 * Corresponding macro - DVLoggerRemove(loggerKey)
 */
- (void)loggerRemove:(NSString *)loggerKey;

/**
 * Add string with format to logger. The appearance depends on a logger configuration.
 *
 * If logger doesn't exist nothing happens.
 *
 * Corresponding macro -              DVLoggerLog(loggerKey, format, ...)
 * Also this method has short macro - DVLLog(loggerKey, format, ...)
 */
- (void)loggerLogToLogger:(NSString *)loggerKey
                      log:(NSString *)format,...;

@end


@interface DVFloatingWindow(Buttons)

/**
 * Add a button with handler to buttons tab. When the button is pressed, handler is called
 * (if exists).
 *
 * Corresponding macro - DVButtonAdd(
 *                                      NSString *title,
 *                                      DVFloatingWindowButtonHandler handler
 *                                  )
 */
- (void)buttonAddWithTitle:(NSString *)title
                   handler:(DVFloatingWindowButtonHandler)handler;

@end


@interface DVFloatingWindow(Config)

/**
 * This property is used to get or change window frame.
 *
 * !!! Please use this property instead of UIView `frame` property
 *
 * Corresponding macro - DVConfigFrameGet()
 *                       DVConfigFrameSet(frame)
 */
@property (assign, nonatomic) CGRect configFrame;

/**
 * Properties below are used to get or change window colors
 */

/**
 * Corresponding macro - DVConfigBackgroundColorGet()
 *                       DVConfigBackgroundColorSet(color)
 */
@property (strong, nonatomic) UIColor *configBackroundColor;

/**
 * Corresponding macro - DVConfigTopBGColorGet()
 *                       DVConfigTopBGColorSet(color)
 */
@property (strong, nonatomic) UIColor *configTopBGColor;

/**
 * Corresponding macro - DVConfigTopMenuBGColorGet()
 *                       DVConfigTopMenuBGColorSet(color)
 */
@property (strong, nonatomic) UIColor *configTopMenuBGColor;

/**
 * Corresponding macro - DVConfigTopTextColorGet()
 *                       DVConfigTopTextColorSet(color)
 */
@property (strong, nonatomic) UIColor *configTopTextColor;

/**
 * Corresponding macro - DVConfigRightCornerColorGet()
 *                       DVConfigRightCornerColorSet(color)
 */
@property (strong, nonatomic) UIColor *configRightCornerColor;


/**
 * Corresponding macro - DVConfigEmailSubjectGet()
 *                       DVConfigEmailSubjectSet(subject)
 */
@property (strong, nonatomic) NSString *configEmailSubject;

/**
 * Corresponding macro - DVConfigEmailToRecipientsGet()
 *                       DVConfigEmailToRecipientsSet(subject)
 */
@property (strong, nonatomic) NSArray *configEmailToRecipients;

/**
 * Corresponding macro - DVConfigEmailCcRecipientsGet()
 *                       DVConfigEmailCcRecipientsSet(subject)
 */
@property (strong, nonatomic) NSArray *configEmailCcRecipients;

/**
 * Corresponding macro - DVConfigEmailBccRecipientsGet()
 *                       DVConfigEmailBccRecipientsSet(subject)
 */
@property (strong, nonatomic) NSArray *configEmailBccRecipients;

/**
 * Corresponding macro - DVConfigEmailMessageBodyGet()
 *                       DVConfigEmailMessageBodySet(subject)
 */
@property (strong, nonatomic) NSString *configEmailMessageBody;

/**
 * Corresponding macro - DVConfigEmailIsMessageBodyHTMLGet()
 *                       DVConfigEmailIsMessageBodyHTMLSet(subject)
 */
@property (assign, nonatomic) BOOL configEmailIsMessageBodyHTML;


/**
 * If logger doesn't exist nothing happens.
 *
 * Corresponding macro -
 * DVConfigLoggerLatestMessageOnTop(NSString *loggerKey, BOOL latestMessageOnTop)
 */
- (void)configLogger:(NSString *)loggerKey latestMessageOnTop:(BOOL)latestMessageOnTop;

/**
 * If logger doesn't exist nothing happens.
 *
 * Corresponding macro - DVConfigLoggerFont(NSString *loggerKey, UIFont *font)
 */
- (void)configLogger:(NSString *)loggerKey font:(UIFont *)font;

- (BOOL)isWindowVisible;

#pragma mark -  Deprecated

/**
 * Method is deprecated, please use these methods instead:
 * configLogger:latestMessageOnTop:
 * configLogger:font:
 *
 *
 * Set configuration for logger.
 *
 * If logger doesn't exist nothing happens.
 *
 * Corresponding macro - DVLoggerSetConfiguration(
 *                                                   NSString *loggerKey,
 *                                                   BOOL latestMessageOnTop,
 *                                                   BOOL scrollToNewMessage,
 *                                                   UIFont *font
 *                                               )
 */
- (void)loggerSetConfigurationForLogger:(NSString *)loggerKey
                          configuration:(DVLoggerConfiguration *)configuration __attribute__((deprecated));

- (BOOL)sendLogsToEmailFromLoggersWithNames:(NSArray *)arrayWithLoggersNames;

@end
