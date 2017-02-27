 //
//  AppDelegate.m
//  HealthKitData
//
//  Created by Bryan Gula on 12/30/16.
//  Copyright © 2016 Rock My World, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "HealthKitFunctions.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.healthStore = [HKHealthStore new];
    
    HKSampleType *energy = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    
    HKObserverQuery *energyQuery = [[HKObserverQuery alloc] initWithSampleType:energy predicate:[HealthKitFunctions predicateForSamplesFromNowToDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"]] updateHandler:^(HKObserverQuery * _Nonnull query, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"] != nil) {
            NSLog(@"hit first query, %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"]);
            [self updateEnergy:^(BOOL *success, NSError *error) {
                completionHandler();
            }];
        }
    }];
    
    [self.healthStore executeQuery:energyQuery];
    
    [self.healthStore enableBackgroundDeliveryForType:energy frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError * _Nullable error) {
        
    }];

    return YES;
}

-(void)updateEnergy:(void(^)(BOOL *success, NSError *error))completion {
    HKSampleType *energy = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];

    HKAnchoredObjectQuery *anchoredQuery = [[HKAnchoredObjectQuery alloc] initWithType:energy predicate:[HealthKitFunctions predicateForSamplesFromNowToDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"]] anchor:nil limit:HKObjectQueryNoLimit resultsHandler:^(HKAnchoredObjectQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable sampleObjects, NSArray<HKDeletedObject *> * _Nullable deletedObjects, HKQueryAnchor * _Nullable newAnchor, NSError * _Nullable error) {
        
        double afterLastSyncEnergy = 0.0;
        
        NSLog(@"hit second query");
        
        for (HKQuantitySample *energy in sampleObjects) {
            if ([[energy description] rangeOfString:@"Watch"].location == NSNotFound) {
                afterLastSyncEnergy += [energy.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
            }
        }
    
        if (afterLastSyncEnergy > 0.0) {
            NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"];
            if (username) {
                [self checkProgressAndGoals:@(afterLastSyncEnergy)];
            }
        }
    }];
    
    [self.healthStore executeQuery:anchoredQuery];
}

-(IBAction)unwindToHome:(UIStoryboardSegue*)sender {
    
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
        
        NSNumber *currentPoints = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentPoints"];
        
        if ([totalEnergy intValue] > [currentPoints intValue]) {
            [task resume];
            [session finishTasksAndInvalidate];
        } else {
            NSLog(@"Energy is 0 so no upload trigger");
        }
    }
    
}


- (void)checkProgressAndGoals:(NSNumber *)progress
{
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    /* Create session, and optionally set a NSURLSessionDelegate. */
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    
    NSURL* URL = [NSURL URLWithString:@"http://adamr5.sg-host.com/adamrz/myfirstbot/api/active_goal/"];
    NSDictionary* URLParams = @{
                                @"slack_username": [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"],
                                };
    
    URL = NSURLByAppendingQueryParameters(URL, URLParams);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    
    /* Start a new Task */
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            // Success
            NSLog(@"URL Session Task Succeeded: HTTP %ld", ((NSHTTPURLResponse*)response).statusCode);
            NSError *err;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&err];
            
            if (err) {
                NSLog(@"Error parsing json: %@", [err description]);
            } else {
                
                NSNumber *goal = [json valueForKey:@"goal_points"];
                NSNumber *current = [json valueForKey:@"current_points"];
                NSString *start = [json valueForKey:@"start_date"];
                NSString *end = [json valueForKey:@"end_date"];
                
                NSLog(@"Goal: %@, Current: %@, Start: %@, End: %@", goal.description, current.description, start, end);
                

                    NSDateFormatter *formatter = [NSDateFormatter new];
                    [formatter setDateFormat:@"YYYY-MM-d k:m:s"];
                    
                    NSDate *startDate = [formatter dateFromString:start];
                    NSDate *endDate = [formatter dateFromString:end];
                    
                    
                    NSInteger daysLeft = [ViewController daysBetweenDate:[NSDate date] andDate:endDate];
                
                    [[NSUserDefaults standardUserDefaults] setObject:goal forKey:@"goalPoints"];
                    [[NSUserDefaults standardUserDefaults] setObject:current forKey:@"currentPoints"];
                    [[NSUserDefaults standardUserDefaults] setObject:startDate forKey:@"goalStart"];
                    [[NSUserDefaults standardUserDefaults] setObject:endDate forKey:@"goalEnd"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    [self uploadEnergy:progress];

            }
        }
        else {
            // Failure
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
        }
    }];
    [task resume];
    [session finishTasksAndInvalidate];
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

/*
 * Utils: Add this section before your class implementation
 */

/**
 This creates a new query parameters string from the given NSDictionary. For
 example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
 string will be @"day=Tuesday&month=January".
 @param queryParameters The input dictionary.
 @return The created parameters string.
 */
static NSString* NSStringFromQueryParameters(NSDictionary* queryParameters)
{
    NSMutableArray* parts = [NSMutableArray array];
    [queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *part = [NSString stringWithFormat: @"%@=%@",
                          [key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
                          [value stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
                          ];
        [parts addObject:part];
    }];
    return [parts componentsJoinedByString: @"&"];
}

/**
 Creates a new URL by adding the given query parameters.
 @param URL The input URL.
 @param queryParameters The query parameter dictionary to add.
 @return A new NSURL.
 */
static NSURL* NSURLByAppendingQueryParameters(NSURL* URL, NSDictionary* queryParameters)
{
    NSString* URLString = [NSString stringWithFormat:@"%@?%@",
                           [URL absoluteString],
                           NSStringFromQueryParameters(queryParameters)
                           ];
    return [NSURL URLWithString:URLString];
}


@end
