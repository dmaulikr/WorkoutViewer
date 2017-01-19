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
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound;
    center.delegate = self;
    
    [center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            NSLog(@"Notification Permission Granted");
        } else {
            NSLog(@"Notification Permission Not Granted");
        }
    }];

    
    self.healthStore = [HKHealthStore new];
    
    //HKSampleType *workout = [HKObjectType quantityTypeForIdentifier:HKWorkoutTypeIdentifier];
    HKSampleType *energy = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    
    HKObserverQuery *energyQuery = [[HKObserverQuery alloc] initWithSampleType:energy predicate:[HealthKitFunctions predicateForSamplesToday] updateHandler:^(HKObserverQuery * _Nonnull query, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
        
        [self updateEnergy:^(BOOL *success, NSError *error) {
            completionHandler();
        }];
        
    }];
    
//    HKObserverQuery *workoutQuery = [[HKObserverQuery alloc] initWithSampleType:workout predicate:nil updateHandler:^(HKObserverQuery * _Nonnull query, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
//        
//        [self updateWorkout:^(BOOL *success, NSError *error) {
//            completionHandler();
//        }];
//        
//    }];
    
    
    [self.healthStore executeQuery:energyQuery];
    //[self.healthStore executeQuery:workoutQuery];
    
    
    [self.healthStore enableBackgroundDeliveryForType:energy frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError * _Nullable error) {
        
    }];
    
//    [self.healthStore enableBackgroundDeliveryForType:workout frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError * _Nullable error) {
//        
//    }];

    return YES;
}

-(void)updateEnergy:(void(^)(BOOL *success, NSError *error))completion {
    HKSampleType *energy = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];

    HKAnchoredObjectQuery *anchoredQuery = [[HKAnchoredObjectQuery alloc] initWithType:energy predicate:[HealthKitFunctions predicateForSamplesToday] anchor:self.anchor limit:HKObjectQueryNoLimit resultsHandler:^(HKAnchoredObjectQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable sampleObjects, NSArray<HKDeletedObject *> * _Nullable deletedObjects, HKQueryAnchor * _Nullable newAnchor, NSError * _Nullable error) {
        
        double totalEnergy = 0.0;
        for (HKQuantitySample *sample in sampleObjects) {
            totalEnergy += [sample.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
            NSLog(@"Energy: %@", [@([sample.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]]) stringValue]);
        }
        
        self.anchor = newAnchor;
    
        if ([sampleObjects count] > 0) {
            NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"];
            if (username) {
                [self uploadEnergy:@(totalEnergy)];
            }
        }
    }];
    
    [self.healthStore executeQuery:anchoredQuery];
}

-(void)updateWorkout:(void(^)(BOOL *success, NSError *error))completion {
    
}

-(void)showNotificationForWorkout {
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = @"New Active Energy Logged!";
    content.body = @"Uploading to FitBot now.. here come those Move Points!";
    content.sound = [UNNotificationSound defaultSound];
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1
                                                                                                    repeats:NO];
    NSString *identifier = @"NewWorkoutLocalNotification";
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                          content:content trigger:trigger];
    
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Something went wrong scheduling a notification: %@",error);
        }
    }];
}

-(void)uploadEnergy:(NSNumber *)totalEnergy {
    
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    NSURL* URL = [NSURL URLWithString:@"http://adamr5.sg-host.com/adamrz/myfirstbot/api/workouts/index.php"];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    
    // Headers
    
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    // JSON Body
    
    NSDate *lastSync = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastSyncDate"];
    
    NSDictionary* bodyObject = @{
                                 @"timeStamp": @([@([[NSDate date] timeIntervalSince1970]) integerValue]),
                                 @"lastSync": @([@([lastSync timeIntervalSince1970]) integerValue]),
                                 @"activeEnergy": totalEnergy,
                                 @"slackUsername": [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"]
                                 };
    
    NSLog(@"%@", [bodyObject description]);
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyObject options:kNilOptions error:NULL];
    
    /* Start a new Task */
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            // Success
            NSLog(@"URL Session Task Succeeded: HTTP %ld", (long)((NSHTTPURLResponse*)response).statusCode);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showNotificationForWorkout];
            });
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"lastSyncDate"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else {
            // Failure
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
        }
        
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert);
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    completionHandler();
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
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
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
