//
//  HealthKitFunctions.h
//  HealthKitData
//
//  Created by Bryan Gula on 12/30/16.
//  Copyright © 2016 Rock My World, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HealthKit/HealthKit.h>

@interface HealthKitFunctions : NSObject

@property (strong, nonatomic) HKHealthStore *healthStore;

-(void)requestPermission:(void (^)(BOOL success, NSError *err))completion;

- (void)mostRecentQuantitySampleOfType:(HKQuantityType *)quantityType predicate:(NSPredicate *)predicate completion:(void (^)(HKQuantity *mostRecentQuantity, NSError *error))completion;

+ (NSPredicate *)predicateForSamplesToday;
+ (NSPredicate *)predicateForSamplesWeek;

- (void)getAllWorkouts:(void (^)(NSMutableArray *, NSError *))completion;
- (void)getAllEnergyBurned:(void (^)(NSMutableArray *, NSError *))completion;
- (void)getAllSources:(void (^)(NSMutableArray *, NSError *))completion;

@end
