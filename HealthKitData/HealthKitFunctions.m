//
//  HealthKitFunctions.m
//  HealthKitData
//
//  Created by Bryan Gula on 12/30/16.
//  Copyright © 2016 Rock My World, Inc. All rights reserved.
//

#import "HealthKitFunctions.h"

@implementation HealthKitFunctions

-(void)requestPermission:(void (^)(BOOL success, NSError *err))completion {
    if( self.healthStore ) {
        
        HKSampleType *workoutType = [HKQuantityType workoutType];
        HKQuantityType *energyBurned = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
        HKObjectType *exerciseTime = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierAppleExerciseTime];
        HKObjectType *walkingRunningDistance = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];

        NSSet *readDataTypes = [NSSet setWithObjects:workoutType, energyBurned, exerciseTime, walkingRunningDistance, nil];
        
        [self.healthStore requestAuthorizationToShareTypes:nil readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            if (success) {
                completion(YES, nil);
            } else {
                completion(NO, error);
            }
        }];
    }
}

- (void)getAllWorkouts:(void (^)(NSMutableArray *, NSError *))completion {

    // 2. Order the workouts by date
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:HKSampleSortIdentifierStartDate ascending:false];
    
    // 3. Create the query
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:[HKWorkoutType workoutType]
                                                                 predicate:nil
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error)
                                  {
                                      
                                      if(!error && results){
                                          NSMutableArray *workouts = [NSMutableArray new];
                                          for(HKQuantitySample *samples in results)
                                          {
                                              // your code here
                                              HKWorkout *workout = (HKWorkout *)samples;
                                              [workouts addObject:workout];
                                          }
                                          completion(workouts, nil);
                                      }else{
                                          NSLog(@"Error retrieving workouts %@",error);
                                          completion(nil, error);
                                      }
                                  }];
    
    // Execute the query
    [self.healthStore executeQuery:sampleQuery];
}

- (void)getAllEnergyBurned:(void (^)(NSMutableArray *, NSError *))completion {
    
    // 2. Order the workouts by date
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:HKSampleSortIdentifierStartDate ascending:false];
    
    // 3. Create the query
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned]
                                                                 predicate:[HealthKitFunctions predicateForSamplesWeek]
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error)
                                  {
                                      
                                      if(!error && results){
                                          NSMutableArray *energy = [NSMutableArray new];
                                          for(HKQuantitySample *samples in results)
                                          {
                                              // your code here
                                              HKQuantitySample *burned = (HKQuantitySample *)samples;
                                              [energy addObject:burned];
                                          }
                                          NSLog(@"Got all active energy for the week.");
                                          completion(energy, nil);
                                      }else{
                                          NSLog(@"Error retrieving energy %@",error);
                                          completion(nil, error);
                                      }
                                  }];
    
    // Execute the query
    [self.healthStore executeQuery:sampleQuery];
}

- (void)getAllEnergyBurnedForever:(void (^)(NSMutableArray *, NSError *))completion {
    
    // 2. Order the workouts by date
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:HKSampleSortIdentifierStartDate ascending:false];
    
    // 3. Create the query
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned]
                                                                 predicate:nil
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error)
                                  {
                                      
                                      if(!error && results){
                                          NSMutableArray *energy = [NSMutableArray new];
                                          for(HKQuantitySample *samples in results)
                                          {
                                              // your code here
                                              HKQuantitySample *burned = (HKQuantitySample *)samples;
                                              [energy addObject:burned];
                                          }
                                          NSLog(@"Got all active energy for the week.");
                                          completion(energy, nil);
                                      }else{
                                          NSLog(@"Error retrieving energy %@",error);
                                          completion(nil, error);
                                      }
                                  }];
    
    // Execute the query
    [self.healthStore executeQuery:sampleQuery];
}

- (void)getAllSources:(void (^)(NSMutableArray *, NSError *))completion {
    
    HKSampleType *sampleType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    
    HKSourceQuery *query = [[HKSourceQuery alloc] initWithSampleType:sampleType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error) {
        
        
        if (error) {
            NSLog(@"*** An error occured while gathering the sources for step date.%@ ***", error.localizedDescription);
            abort();
        } else {
            completion([NSMutableArray arrayWithArray:[sources allObjects]], nil);
        }
    }];
    
    [self.healthStore executeQuery:query];
}

#pragma mark - Query Helper Methods

+ (NSPredicate *)predicateForSamplesToday {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *twentyFourHoursBeforeToday = [NSDate dateWithTimeIntervalSinceNow:-86400];
    
    NSDate *startDate = [calendar startOfDayForDate:twentyFourHoursBeforeToday];
    NSDate *endDate = [NSDate date];
    
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}

+ (NSPredicate *)predicateForSamplesWeek {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *weekAgo = [NSDate dateWithTimeIntervalSinceNow:-604800];
    
    NSDate *startDate = [calendar startOfDayForDate:weekAgo];
    NSDate *endDate = [NSDate date];
    
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}

@end
