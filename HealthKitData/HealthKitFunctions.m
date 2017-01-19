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

- (void)mostRecentQuantitySampleOfType:(HKQuantityType *)quantityType predicate:(NSPredicate *)predicate completion:(void (^)(HKQuantity *, NSError *))completion {
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    // Since we are interested in retrieving the user's latest sample, we sort the samples in descending order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType predicate:nil limit:1 sortDescriptors:@[timeSortDescriptor] resultsHandler:^(HKSampleQuery *resultQuery, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            
            return;
        }
        
        if (completion) {
            // If quantity isn't in the database, return nil in the completion block.
            HKQuantitySample *quantitySample = results.firstObject;
            HKQuantity *quantity = quantitySample.quantity;
            
            completion(quantity, error);
        }
    }];
    
    [self.healthStore executeQuery:query];
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
                                              NSLog(@"%@", [burned description]);
                                              [energy addObject:burned];
                                          }
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

- (HKQuantity *)calculateBasalBurnTodayFromWeight:(HKQuantity *)weight height:(HKQuantity *)height dateOfBirth:(NSDate *)dateOfBirth biologicalSex:(HKBiologicalSexObject *)biologicalSex {
    // Only calculate Basal Metabolic Rate (BMR) if we have enough information about the user
    if (!weight || !height || !dateOfBirth || !biologicalSex) {
        return nil;
    }
    
    // Note the difference between calling +unitFromString: vs creating a unit from a string with
    // a given prefix. Both of these are equally valid, however one may be more convenient for a given
    // use case.
    double heightInCentimeters = [height doubleValueForUnit:[HKUnit unitFromString:@"cm"]];
    double weightInKilograms = [weight doubleValueForUnit:[HKUnit gramUnitWithMetricPrefix:HKMetricPrefixKilo]];
    
    NSDate *now = [NSDate date];
    NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:dateOfBirth toDate:now options:NSCalendarWrapComponents];
    NSUInteger ageInYears = ageComponents.year;
    
    // BMR is calculated in kilocalories per day.
    double BMR = [self calculateBMRFromWeight:weightInKilograms height:heightInCentimeters age:ageInYears biologicalSex:[biologicalSex biologicalSex]];
    
    // Figure out how much of today has completed so we know how many kilocalories the user has burned.
    NSDate *startOfToday = [[NSCalendar currentCalendar] startOfDayForDate:now];
    NSDate *endOfToday = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfToday options:0];
    
    NSTimeInterval secondsInDay = [endOfToday timeIntervalSinceDate:startOfToday];
    double percentOfDayComplete = [now timeIntervalSinceDate:startOfToday] / secondsInDay;
    
    double kilocaloriesBurned = BMR * percentOfDayComplete;
    
    return [HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:kilocaloriesBurned];
}

/// Returns BMR value in kilocalories per day. Note that there are different ways of calculating the
/// BMR. In this example we chose an arbitrary function to calculate BMR based on weight, height, age,
/// and biological sex.
- (double)calculateBMRFromWeight:(double)weightInKilograms height:(double)heightInCentimeters age:(NSUInteger)ageInYears biologicalSex:(HKBiologicalSex)biologicalSex {
    [self requestPermission:nil];
    
    double BMR;
    
    // The BMR equation is different between males and females.
    if (biologicalSex == HKBiologicalSexMale) {
        BMR = 66.0 + (13.8 * weightInKilograms) + (5 * heightInCentimeters) - (6.8 * ageInYears);
    }
    else {
        BMR = 655 + (9.6 * weightInKilograms) + (1.8 * heightInCentimeters) - (4.7 * ageInYears);
    }
    
    return BMR;
}

#pragma mark - Query Helper Methods

+ (NSPredicate *)predicateForSamplesToday {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *now = [NSDate date];
    
    NSDate *startDate = [calendar startOfDayForDate:now];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}

+ (NSPredicate *)predicateForSamplesWeek {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:-604800];
    
    NSDate *startDate = [calendar startOfDayForDate:now];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:7 toDate:startDate options:0];
    
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}

@end
