//
//  alert.m
//  SportShooting2
//
//  Created by Othman Sbai on 6/23/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "alert.h"

void ShowResult(NSString *format, ...)
{
    va_list argumentList;
    va_start(argumentList, format);
    
    NSString* message = [[NSString alloc] initWithFormat:format arguments:argumentList];
    va_end(argumentList);
    NSString * newMessage = [message hasSuffix:@":(null)"] ? [message stringByReplacingOccurrencesOfString:@":(null)" withString:@" successful!"] : message;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController* alertView = [UIAlertController alertControllerWithTitle:nil message:newMessage preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        
        [alertView addAction:okAction];

        
        [[[[[UIApplication sharedApplication]delegate]window]rootViewController] presentViewController:alertView animated:YES completion:nil];
    });
}