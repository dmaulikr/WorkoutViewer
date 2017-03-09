 //
//  AppDelegate.m
//  HealthKitData
//
//  Created by Bryan Gula on 12/30/16.
//  Copyright © 2016 Rock My World, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "HealthKitFunctions.h"
@import WatchConnectivity;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    if ([WCSession isSupported]) {
        WCSession* session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
    
    if (self.healthStore == nil) {
        self.healthStore = [HKHealthStore new];
    }
    
    HKSampleType *steps = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    //  if you have the goal start date, if not it will be set on home page
    //
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"]) {
        
        //  setup background query for steps (once per hour max)
        //
        HKObserverQuery *stepQuery = [[HKObserverQuery alloc] initWithSampleType:steps predicate:[HealthKitFunctions predicateForSamplesFromNowToDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"]] updateHandler:^(HKObserverQuery * _Nonnull query, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
            
            //  if you have username
            //
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"] != nil) {
                
                [AppDelegate checkStatus:^(BOOL success, NSDate *start, NSDate *end, NSNumber *points, NSNumber *goal, NSError *error) {
                
                    NSMutableDictionary *stats = [@{@"start":start, @"end":end, @"current":points, @"goal":goal} mutableCopy];
                    
                    if (success) {
                        
                        //  query for new steps
                        //
                        [HealthKitFunctions getAllStepSamples:^(NSArray *stepSamples, NSError *err) {
                            [HealthKitFunctions getAllEnergyWithoutWatchOrHumanAndSortFromStepSamples:[stepSamples mutableCopy] withCompletion:^(NSNumber *cals, NSNumber *other, NSError *err) {
                                
                                //  setting new calculated Calories
                                //
                                [stats setValue:@([cals integerValue] + [other integerValue]) forKey:@"current"];
                                
                                [AppDelegate uploadEnergyWithStats:stats withCompletion:^(BOOL success, NSError *err) {
                                    if (success) {
                                        [AppDelegate logBackgroundDataToFileWithStats:stats message:@"Sync Succeeded" time:[NSDate date]];
                                        completionHandler();
                                        
                                    } else {
                                        [AppDelegate logBackgroundDataToFileWithStats:stats message:@"Upload Energy Failed" time:[NSDate date]];
                                        completionHandler();
                                    }
                                }];
                            }];
                        }];
                                
                        } else {
                            [AppDelegate logBackgroundDataToFileWithStats:stats message:@"Error - Calculating Steps For Week" time:[NSDate new]];
                            completionHandler();
                        }
                }];
    
                } else {
                    [AppDelegate logBackgroundDataToFileWithStats:nil message:@"AppDelegate Error - Username not provided" time:[NSDate new]];
                    completionHandler();    //  so you don't lose background updates
                }
            }];
        
        [self.healthStore executeQuery:stepQuery];
        
        [self.healthStore enableBackgroundDeliveryForType:steps frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                NSLog(@"Background Delivery of Step Count is Enabled.");
            }
        }];
    } else {
        [AppDelegate logBackgroundDataToFileWithStats:nil message:@"AppDelegate Error - No Goal Start Date, Background Query Not Registered" time:[NSDate new]];
    }

    return YES;
}

+(void)logBackgroundDataToFileWithStats:(NSDictionary *)stats message:(NSString *)reason time:(NSDate *)timestamp {
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"MMM dd, YYYY @ HH:mm:ss"];
    
    NSMutableDictionary *mutableStats = [stats mutableCopy];
    
    [mutableStats setObject:[formatter stringFromDate:[NSDate date]] forKey:@"logDate"];
    [mutableStats setObject:[formatter stringFromDate:stats[@"start"]] forKey:@"start"];
    [mutableStats setObject:[formatter stringFromDate:stats[@"end"]] forKey:@"end"];
    
    NSMutableString *formattedOutput = [NSMutableString new];
    
    for (NSString *key in mutableStats.allKeys) {
        [formattedOutput appendString:[NSString stringWithFormat:@"%@ = %@\n", key, [mutableStats[key] description]]];
    }
    
    NSString *logEntry = [NSString stringWithFormat:@"\n%@ - %@\n%@-----\n", reason, [formatter stringFromDate:timestamp], formattedOutput];
    
    NSLog(@"%@", logEntry);
    
    NSError *error;
    
    NSURL *logUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0] URLByAppendingPathComponent:@"/activity.txt"];
    
    BOOL fileMade = NO;
    
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:logUrl.relativePath];
    
    if(!exists) {
        fileMade = [[NSFileManager defaultManager] createFileAtPath:logUrl.relativePath contents:[logEntry dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        
        exists = [[NSFileManager defaultManager] fileExistsAtPath:logUrl.relativePath];
    }
    
    NSData *data = [NSData dataWithContentsOfURL:logUrl];
    
    NSString *logs = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSLog(@"Log File Made? %zd, Exists? %d", fileMade, exists);
    
    if (error == nil) {
        NSString *updatedLog = [NSString stringWithFormat:@"%@\n-----%@", logs, logEntry];
        
        NSLog(@"Updated Log: %@", updatedLog);
    
        BOOL writeResult = [updatedLog writeToURL:logUrl atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            NSLog(@"Error Writing Log to File: %@", [error description]);
        } else {
            NSLog(@"Log Successfully Written to File");
        }
    }
    
}

+(void)checkStatus:(void(^)(BOOL success, NSDate *start, NSDate *end, NSNumber *points, NSNumber *goal, NSError *error))completion {
    
    NSURL* URL = [NSURL URLWithString:@"http://adamr5.sg-host.com/adamrz/myfirstbot/api/active_goal/"];
    NSDictionary* URLParams = @{
                                @"slack_username": [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"],
                                };
    
    URL = NSURLByAppendingQueryParameters(URL, URLParams);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    
    /* Start a new Task */
    NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            
            // Success
            NSLog(@"Checked Progress & Goal: HTTP %ld", ((NSHTTPURLResponse*)response).statusCode);
            NSError *err;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&err];
            
            if (err) {
                
                NSLog(@"Error parsing Checking Goals JSON: %@", [err description]);
                completion(NO, nil, nil, nil, nil, err);
                
            } else {
                
                NSNumber *goal = [json valueForKey:@"goal_points"];
                NSNumber *current = @([[json valueForKey:@"current_points"] integerValue]);
                NSString *start = [json valueForKey:@"start_date"];
                NSString *end = [json valueForKey:@"end_date"];
                
                NSLog(@"Goal: %@, Current: %@, Start: %@, End: %@", goal.description, current.description, start, end);
            
                //  Turn dates into NSDate start & end date
                NSDateFormatter *formatter = [NSDateFormatter new];
                [formatter setDateFormat:@"YYYY-MM-d k:m:s"];
                
                NSDate *startDate = [formatter dateFromString:start];
                NSDate *endDate = [formatter dateFromString:end];
                
                completion(YES, startDate, endDate, current, goal, nil);
            }
        }
        else {
            // Failure
            NSLog(@"Check Goals & Progress Session Task Failed: %@", [error localizedDescription]);
            completion(NO, nil, nil, nil, nil, error);
        }
    }];
    
    [task resume];
    [[NSURLSession sharedSession] finishTasksAndInvalidate];
}

-(void)updateWatchComplication:(NSNumber *)energyBurned {
    if ([WCSession defaultSession].activationState == WCSessionActivationStateActivated && [[WCSession defaultSession] isComplicationEnabled]) {
        NSLog(@"sending complication data");
        //[[WCSession defaultSession] transferCurrentComplicationUserInfo:@{@"burned": [[NSUserDefaults standardUserDefaults] objectForKey:@"currentPoints"], @"goal": [[NSUserDefaults standardUserDefaults] objectForKey:@"goalPoints"] }];
                [[WCSession defaultSession] transferCurrentComplicationUserInfo:@{@"burned": energyBurned, @"goal": @([energyBurned intValue] * 2) }];
        
    }
}
    
+(void)uploadEnergyWithStats:(NSDictionary *)stats withCompletion:(void(^)(BOOL success, NSError *err))completion {
//    
        NSURL* URL = [NSURL URLWithString:@"http://adamr5.sg-host.com/adamrz/myfirstbot/api/active_goal/"];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";
    
        [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        
        NSDictionary* bodyObject = @{
                                     @"currentPoints": stats[@"current"],
                                     @"slackUsername": [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"],
                                     @"timeStamp": @([@([[NSDate date] timeIntervalSince1970]) integerValue])
                                     };
        
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyObject options:kNilOptions error:NULL];
        
        /* Start a new Task */
        NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error == nil) {
                // Success
                if (((NSHTTPURLResponse*)response).statusCode == [@(200) integerValue]) {
                    
                    completion(YES, nil);
                    
                } else if (((NSHTTPURLResponse*)response).statusCode == [@(400) integerValue]) {
                    
                    completion(NO, nil);
                }
            }
            else {
                // Failure
                NSLog(@"Upload Energy Failed: %@", [error localizedDescription]);
                completion(NO, nil);
            }
        }];
        [task resume];
        [[NSURLSession sharedSession] finishTasksAndInvalidate];
}

-(void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error {
    
    if (activationState == WCSessionActivationStateActivated) {
        
    }
}

-(void)sessionDidDeactivate:(WCSession *)session {
    
}

-(void)sessionDidBecomeInactive:(WCSession *)session {
    
}

-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    
    if ([[message valueForKey:@"getEnergy"] isEqualToString:@"yes"]) {
        [HealthKitFunctions getAllStepSamples:^(NSArray *stepSamples, NSError *err) {
           [HealthKitFunctions getAllEnergyWithoutWatchOrHumanAndSortFromStepSamples:[stepSamples mutableCopy] withCompletion:^(NSNumber *cals, NSNumber *other, NSError *err) {
               [AppDelegate checkStatus:^(BOOL success, NSDate *start, NSDate *end, NSNumber *points, NSNumber *goal, NSError *error) {
                   replyHandler(@{@"goal":@([goal integerValue]), @"burned":@([cals integerValue] + [other integerValue])});
               }];
           }];
        }];
    }
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
