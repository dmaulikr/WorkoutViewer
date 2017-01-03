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

-(HKAuthorizationStatus) authStatus:(HKObjectType *) hkType;

-(BOOL) canWriteHeart;
-(BOOL) canWriteLocation;

-(void)requestPermission:(void (^)(BOOL success, NSError *err))completion;

// Fetches the single most recent quantity of the specified type.

- (void)mostRecentQuantitySampleOfType:(HKQuantityType *)quantityType predicate:(NSPredicate *)predicate completion:(void (^)(HKQuantity *mostRecentQuantity, NSError *error))completion;

- (void)getAllWorkouts:(void (^)(NSMutableArray *, NSError *))completion;

@end
