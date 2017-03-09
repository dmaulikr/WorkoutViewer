//
//  LogsCollectionViewCell.m
//  HealthKitData
//
//  Created by Bryan Gula on 3/8/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import "LogsCollectionViewCell.h"
#import "AppDelegate.h"

@implementation LogsCollectionViewCell

- (IBAction)sendEmail:(id)sender {
    // Email Subject
    NSString *emailTitle = @"FitBot Sync Logs";
    
    NSError *error;
    
    NSURL *logUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0] URLByAppendingPathComponent:@"/activity.txt"];
    
    NSData *data = [NSData dataWithContentsOfURL:logUrl];
    
    NSString *log = [NSString stringWithContentsOfURL:logUrl encoding:NSUTF8StringEncoding error:&error];

    if (error == nil) {
        // To address
        NSArray *toRecipents = [NSArray arrayWithObject:@"bryan@rockmyworldmedia.com"];
        
        MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
        mc.mailComposeDelegate = self;
        [mc setSubject:emailTitle];
        [mc setMessageBody:log isHTML:NO];
        [mc setToRecipients:toRecipents];
        
        // Present mail view controller on screen
        [[[UIApplication sharedApplication].keyWindow rootViewController] presentViewController:mc animated:YES completion:nil];
    } else {
        [AppDelegate logBackgroundDataToFileWithStats:@{@"Error" :[error description]} message:@"Log File Not Loading" time:[NSDate date]];
    }
}


-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{

    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [[[UIApplication sharedApplication].keyWindow rootViewController] dismissViewControllerAnimated:YES completion:NULL];
}

@end
