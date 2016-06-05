//
//  DVEmailManager.m
//  DVFloatingWindow
//
//  Created by Dmitry Vorobyov on 10/22/13.
//  Copyright (c) 2013 Dmitry Vorobyov. All rights reserved.
//

#import <MessageUI/MessageUI.h>

#import "DVEmailManager.h"
#import "DVLogger.h"
#import "DVFloatingWindow.h"

@interface DVEmailManager() <MFMailComposeViewControllerDelegate>

@end

@implementation DVEmailManager


#pragma mark -  Methods
- (BOOL)saveLogsToIOSDevice:(NSDictionary *)dictWithLoggers//save to txt file
{
    // Get path to documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    // Path to save dictionary
    NSString *dictPath = [[paths objectAtIndex:0]
                stringByAppendingPathComponent:@"dict.out"];
    
    // Write dictionary
    [dictWithLoggers writeToFile:dictPath atomically:YES];
    
    
    NSLog(@"ok");
    return YES;
}

- (BOOL)sendLogsToEmailFromLoggers:(NSDictionary *)dictWithLoggers
                           subject:(NSString *)subject
                      toRecipients:(NSArray *)toRecipients
                      ccRecipients:(NSArray *)ccRecipients
                     bccRecipients:(NSArray *)bccRecipients
                       messageBody:(NSString *)messageBody
                 isMessageBodyHTML:(BOOL)isMessageBodyHTML;
{
    if ([MFMailComposeViewController canSendMail]) {
        
        //DVWindowShow();

        MFMailComposeViewController *mailVC = [MFMailComposeViewController new];
        mailVC.mailComposeDelegate = self;

        [mailVC setSubject:subject];
        [mailVC setToRecipients:toRecipients];
        [mailVC setCcRecipients:ccRecipients];
        [mailVC setBccRecipients:bccRecipients];
        [mailVC setMessageBody:messageBody isHTML:isMessageBodyHTML];

        for (NSString *loggerKey in dictWithLoggers) {
            DVLogger *logger = dictWithLoggers[loggerKey];
            NSData *data = [logger logsToData];

            if (data) {
                [mailVC addAttachmentData:data
                                 mimeType:@"text/plain"
                                 fileName:[self logFilenameFromString:loggerKey]];
            }
        }
        
        [[self rootViewController] presentViewController:mailVC
                                                animated:YES
                                              completion:nil];
        
    
        return YES;
    }
    else {
//        UIAlertView *alertView = [[UIAlertView alloc] 
//            initWithTitle:@"Error"
//                  message:@"Please configure your mail settings"
//                 delegate:nil
//        cancelButtonTitle:@"OK"
//        otherButtonTitles:nil];
//
//        [alertView show];

        return NO;
    }
}

#pragma mark -  MFMailComposeViewController delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [[self rootViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -  Supporting methods

- (NSString *)logFilenameFromString:(NSString *)string
{
    NSCharacterSet *illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
    string = [[string componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];

    return [NSString stringWithFormat:@"%@.txt", string];
}

- (UIViewController *)rootViewController
{
    id delegate = [UIApplication sharedApplication].delegate;
    return [[delegate window] rootViewController];
}

@end
