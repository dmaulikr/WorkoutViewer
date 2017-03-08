//
//  ExtensionDelegate.m
//  SyncWatch Extension
//
//  Created by Bryan Gula on 3/2/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import "ExtensionDelegate.h"
#import "InterfaceController.h"
@import HealthKit;

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
    // Perform any final initialization of your application.
    if ([WCSession isSupported]) {
        WCSession* session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
}

-(void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error
{
    if (activationState == WCSessionActivationStateActivated) {
        [session sendMessage:@{@"getEnergy":@"yes"} replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                InterfaceController *root = (InterfaceController *)[[WKExtension sharedExtension] rootInterfaceController];
                
                root.summary = [HKActivitySummary new];
                
                [root.totalBurnedLabel setText:[[[replyMessage valueForKey:@"burned"] stringValue] stringByAppendingString:@" kCal"]];
                
                [root.summary setActiveEnergyBurned:[HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:[((NSNumber *)[replyMessage valueForKey:@"burned"]) doubleValue]]];
                
                [root.summary setActiveEnergyBurnedGoal:[HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:[((NSNumber *)[replyMessage valueForKey:@"goal"]) doubleValue]]];
                
                [root.summary setAppleExerciseTime:[HKQuantity quantityWithUnit:[HKUnit minuteUnit] doubleValue:0]];
                
                [root.summary setAppleExerciseTimeGoal:[HKQuantity quantityWithUnit:[HKUnit minuteUnit] doubleValue:10]];
                
                [root.summary setAppleStandHours:[HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:0]];
                
                [root.summary setAppleStandHoursGoal:[HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:10]];
                
                
                [root.rings setActivitySummary:root.summary animated:YES];
            });
            
        } errorHandler:^(NSError * _Nonnull error) {
            
        }];
    }
}

-(void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo {
    if ([userInfo valueForKey:@"goal"] != nil) {
        [[NSUserDefaults standardUserDefaults] setObject:[userInfo valueForKey:@"goal"] forKey:@"goalPoints"];
        [[NSUserDefaults standardUserDefaults] setObject:[userInfo valueForKey:@"points"] forKey:@"currentPoints"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSLog(@"%zd", [CLKComplicationServer sharedInstance].activeComplications.count);
        
        for (CLKComplication *comp in [CLKComplicationServer sharedInstance].activeComplications) {
            
            NSLog(@"%@ - %ld", [comp description], (long)comp.family);
            [[CLKComplicationServer sharedInstance] reloadTimelineForComplication:comp];
        }
    }
}

-(void)sessionDidDeactivate:(WCSession *)session {
    
}

-(void)sessionDidBecomeInactive:(WCSession *)session {
    
}

- (void)applicationDidBecomeActive {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}

- (void)handleBackgroundTasks:(NSSet<WKRefreshBackgroundTask *> *)backgroundTasks {
    // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
    for (WKRefreshBackgroundTask * task in backgroundTasks) {
        // Check the Class of each task to decide how to process it
        if ([task isKindOfClass:[WKApplicationRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKApplicationRefreshBackgroundTask *backgroundTask = (WKApplicationRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompleted];
        } else if ([task isKindOfClass:[WKSnapshotRefreshBackgroundTask class]]) {
            // Snapshot tasks have a unique completion call, make sure to set your expiration date
            WKSnapshotRefreshBackgroundTask *snapshotTask = (WKSnapshotRefreshBackgroundTask*)task;
            [snapshotTask setTaskCompletedWithDefaultStateRestored:YES estimatedSnapshotExpiration:[NSDate distantFuture] userInfo:nil];
        } else if ([task isKindOfClass:[WKWatchConnectivityRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKWatchConnectivityRefreshBackgroundTask *backgroundTask = (WKWatchConnectivityRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompleted];
        } else if ([task isKindOfClass:[WKURLSessionRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKURLSessionRefreshBackgroundTask *backgroundTask = (WKURLSessionRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompleted];
        } else {
            // make sure to complete unhandled task types
            [task setTaskCompleted];
        }
    }
}

@end
