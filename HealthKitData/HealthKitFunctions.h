//
//  HealthKitFunctions.h
//  HealthKitData
//
//  Created by Bryan Gula on 12/30/16.
//  Copyright © 2016 Rock My World, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HealthKit/HealthKit.h>
#import "AppDelegate.h"

@interface HealthKitFunctions : NSObject

@property (strong, nonatomic) HKHealthStore *healthStore;

+(void)requestPermission:(void (^)(BOOL success, NSError *err))completion;

+ (NSPredicate *)predicateForSamplesToday;
+ (NSPredicate *)predicateForSamplesWeek;
+ (NSPredicate *)predicateForSamplesFromNowToDate:(NSDate *)date;

- (void)getAllEnergyBurned:(void (^)(NSMutableArray *, NSError *))completion;
+(void)getAllSources:(void (^)(NSMutableArray *, NSError *))completion;

+ (void)getAllEnergyWithoutWatchOrHumanAndSortFromStepSamples:(NSMutableArray *)steps withCompletion:(void (^)(NSNumber *stepEnergy, NSNumber *otherEnergy, NSError *))completion;
+ (void)getAllEnergyBurnedWithFilters:(NSMutableDictionary *)filterTags withCompletion:(void (^)(NSMutableDictionary *totalSources, NSError *err))completion;
+ (void)getAllEnergyBurnedFromAppleWatch:(void (^)(NSNumber *, NSError *))completion;
+ (void)getAllEnergyBurnedWithoutWatch:(void (^)(NSNumber *, NSError *))completion;
+ (void)getAllEnergyBurnedFromSteps:(void (^)(double, NSError *))completionHandler;
+ (void)getStepsPerMileFromHeight:(void (^)(double, NSError *))completionHandler;
+ (void)getAllEnergyBurnedAndSort:(void (^)(NSNumber *, NSError *))completion;
+ (void)convertStepsToCalories:(NSNumber *)steps withCompletion:(void (^)(double, NSError *))completionHandler;
+ (void)getAllStepSamples:(void (^)(NSArray* stepSamples, NSError *err))completionHandler;
+(void)getBodyMass:(void (^)(double mass, NSError *err))completionHandler;

@end
