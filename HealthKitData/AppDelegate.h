//
//  AppDelegate.h
//  HealthKitData
//
//  Created by Bryan Gula on 12/30/16.
//  Copyright © 2016 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>
@import WatchConnectivity;

@interface AppDelegate : UIResponder <UIApplicationDelegate, WCSessionDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) HKHealthStore *healthStore;
@property (strong, nonatomic) NSMutableDictionary *stats;

+(void)logBackgroundDataToFileWithStats:(NSDictionary *)stats message:(NSString *)reason time:(NSDate *)timestamp;
+(void)checkStatus:(void(^)(BOOL success, NSDate *start, NSDate *end, NSNumber *points, NSNumber *goal, NSError *error))completion;

+(void)checkStatusForUsername:(NSString *)username withCompletion:(void(^)(NSDictionary *stats, NSError *err))completion;

+(void)uploadEnergyWithStats:(NSDictionary *)stats withCompletion:(void(^)(BOOL success, NSError *err))completion;
+(void)updateWatchComplication:(NSDictionary *)stats;

@end

