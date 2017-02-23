 //
//  AppDelegate.m
//  HealthKitData
//
//  Created by Bryan Gula on 12/30/16.
//  Copyright © 2016 Rock My World, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "HealthKitFunctions.h"

@interface AppDelegate ()

@property (strong, nonatomic) HKQueryAnchor *anchor;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.healthStore = [HKHealthStore new];
    
    HKSampleType *energy = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    
    HKObserverQuery *energyQuery = [[HKObserverQuery alloc] initWithSampleType:energy predicate:[HealthKitFunctions predicateForSamplesFromNowToDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"]] updateHandler:^(HKObserverQuery * _Nonnull query, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"] != nil) {
            //[self updateEnergy:^(BOOL *success, NSError *error) {
                completionHandler();
            //}];
        }
    }];
    
    [self.healthStore executeQuery:energyQuery];
    
    [self.healthStore enableBackgroundDeliveryForType:energy frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError * _Nullable error) {
        
    }];

    return YES;
}

-(void)updateEnergy:(void(^)(BOOL *success, NSError *error))completion {
    HKSampleType *energy = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];

    HKAnchoredObjectQuery *anchoredQuery = [[HKAnchoredObjectQuery alloc] initWithType:energy predicate:[HealthKitFunctions predicateForSamplesFromNowToDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"]] anchor:self.anchor limit:HKObjectQueryNoLimit resultsHandler:^(HKAnchoredObjectQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable sampleObjects, NSArray<HKDeletedObject *> * _Nullable deletedObjects, HKQueryAnchor * _Nullable newAnchor, NSError * _Nullable error) {
        
        double afterLastSyncEnergy = 0.0;
        
        for (HKQuantitySample *energy in sampleObjects) {
            if ([[energy description] rangeOfString:@"Watch"].location == NSNotFound) {
                afterLastSyncEnergy += [energy.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
            }
        }

        self.anchor = newAnchor;
    
        if (afterLastSyncEnergy > 0.0) {
            NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"];
            if (username) {
                [self uploadEnergy:@(afterLastSyncEnergy)];
            }
        }
    }];
    
    [self.healthStore executeQuery:anchoredQuery];
}
    
-(void)uploadEnergy:(NSNumber *)totalEnergy {
    {
        
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
        
        NSURL* URL = [NSURL URLWithString:@"http://adamr5.sg-host.com/adamrz/myfirstbot/api/active_goal/"];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";
        
        [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        
        NSDictionary* bodyObject = @{
                                     @"currentPoints": totalEnergy,
                                     @"slackUsername": [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"],
                                     @"timeStamp": @([@([[NSDate date] timeIntervalSince1970]) integerValue])
                                     };
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyObject options:kNilOptions error:NULL];
        
        /* Start a new Task */
        NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error == nil) {
                // Success
                if (((NSHTTPURLResponse*)response).statusCode == [@(200) integerValue]) {

                } else if (((NSHTTPURLResponse*)response).statusCode == [@(400) integerValue]) {
                    

                }
                NSLog(@"Energy Sync Succeeded: HTTP %ld", ((NSHTTPURLResponse*)response).statusCode);
            }
            else {
                // Failure
                NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
            }
        }];
        [task resume];
        [session finishTasksAndInvalidate];
    }
    
}
    
- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshEnergy" object:nil];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
