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
        HKObjectType *steps = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        HKObjectType *mass = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];

        
        NSSet *readDataTypes = [NSSet setWithObjects:workoutType, mass, energyBurned, exerciseTime, walkingRunningDistance, steps, nil];
        
        [self.healthStore requestAuthorizationToShareTypes:nil readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            if (success) {
                completion(YES, nil);
            } else {
                completion(NO, error);
            }
        }];
    }
}

- (void)getAllEnergyBurned:(void (^)(NSMutableArray *, NSError *))completion {
    
    // 2. Order the workouts by date
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:HKSampleSortIdentifierStartDate ascending:false];
    
    // 3. Create the query
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned]
                                                                 predicate:[HealthKitFunctions predicateForSamplesFromNowToDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"]]
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
    
+ (void)getAllEnergyBurnedFromAppleWatch:(void (^)(NSNumber *, NSError *))completion {
        
        // 2. Order the workouts by date
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:HKSampleSortIdentifierStartDate ascending:false];
        
        // 3. Create the query
        HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned]
                                                                     predicate:[HealthKitFunctions predicateForSamplesFromNowToDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"]]
                                                                         limit:HKObjectQueryNoLimit
                                                               sortDescriptors:@[sortDescriptor]
                                                                resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error)
                                      {
                                          
                                          if(!error && results){

                                              double watchEnergy = 0.0;
                                              for(HKQuantitySample *samples in results)
                                              {
                                                  
                                                  HKQuantitySample *burned = (HKQuantitySample *)samples;
                                                  if ([burned.description containsString:@"Watch"]) {
                                                      watchEnergy += [burned.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
                                                  }
                                              }
                                              NSLog(@"Got all active energy for the week.");
                                              completion(@(watchEnergy), nil);
                                          }else{
                                              NSLog(@"Error retrieving energy %@",error);
                                              completion(nil, error);
                                          }
                                      }];
        
        // Execute the query
        [[HKHealthStore new] executeQuery:sampleQuery];
}
    
+ (void)getAllEnergyBurnedWithoutWatch:(void (^)(NSNumber *, NSError *))completion {
    
    // 2. Order the workouts by date
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:HKSampleSortIdentifierStartDate ascending:false];
    
    // 3. Create the query
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned]
                                                                 predicate:[HealthKitFunctions predicateForSamplesFromNowToDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"]]
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error)
                                  {
                                      
                                      if(!error && results){
                                          
                                          double noWatchEnergy = 0.0;
                                          for(HKQuantitySample *samples in results)
                                          {
                                              
                                              HKQuantitySample *burned = (HKQuantitySample *)samples;
                                              if (![burned.description containsString:@"Watch"]) {
                                                  noWatchEnergy += [burned.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
                                              }
                                          }
                                          NSLog(@"Got all active energy for the week.");
                                          completion(@(noWatchEnergy), nil);
                                      }else{
                                          NSLog(@"Error retrieving energy %@",error);
                                          completion(nil, error);
                                      }
                                  }];
    
    // Execute the query
    [[HKHealthStore new] executeQuery:sampleQuery];
}
    
+ (void)getAllEnergyBurnedFromSteps:(void (^)(double, NSError *))completionHandler {
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *interval = [[NSDateComponents alloc] init];
    interval.day = 7;
    
    // Set the anchor date to Monday at 3:00 a.m.
    NSDateComponents *anchorComponents =
    [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth |
     NSCalendarUnitYear | NSCalendarUnitWeekday fromDate:[NSDate date]];
    
    
    NSDate *anchorDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"];
    
    HKQuantityType *quantityType =
    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    // Create the query
    HKStatisticsCollectionQuery *query =
    [[HKStatisticsCollectionQuery alloc]
     initWithQuantityType:quantityType
     quantitySamplePredicate:nil
     options:HKStatisticsOptionCumulativeSum
     anchorDate:anchorDate
     intervalComponents:interval];
    
    // Set the results handler
    query.initialResultsHandler =
    ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection *results, NSError *error) {
        
        if (error) {
            // Perform proper error handling here
            NSLog(@"*** An error occurred while calculating the statistics: %@ ***",
                  error.localizedDescription);
            abort();
        }
        
        NSDate *endDate = [NSDate date];
        NSDate *startDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"];
        
        // Plot the weekly step counts over the past 3 months
        [results
         enumerateStatisticsFromDate:startDate
         toDate:endDate
         withBlock:^(HKStatistics *result, BOOL *stop) {
             
             HKQuantity *quantity = result.sumQuantity;
             if (quantity) {
                 double value = [quantity doubleValueForUnit:[HKUnit countUnit]];
                 
                 HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]
                                                                              predicate:nil
                                                                                  limit:1
                                                                        sortDescriptors:nil
                                                                         resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error)
                                               {
                                                   double pounds;
                                                   
                                                   if (results.count > 0) {
                                                       HKQuantitySample *weight = results[0];
                                                       pounds = [weight.quantity doubleValueForUnit:[HKUnit poundUnit]];
                                                       NSLog(@"Your weight: %.0f", pounds);
                                                   } else {
                                                       pounds = 185;
                                                   }
                                                   
                                                   double calsPerMile = pounds * 0.57;
                                                   double stepsPerMile = 2125.0; //someone 6 feet
                                                   double calsPerStep = calsPerMile / stepsPerMile;
                                                   double calsForSteps = calsPerStep * value;
                                                   completionHandler(calsForSteps, nil);
                                                   
                                               }];
                 
                 // Execute the query
                 [[HKHealthStore new] executeQuery:sampleQuery];
                 
                 
                 completionHandler(value, nil);
             }
             
         }];
    };
    
    [[HKHealthStore new] executeQuery:query];
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
    
+ (NSPredicate *)predicateForSamplesFromNowToDate:(NSDate *)date {
    if (date == nil) {
        date = [NSDate dateWithTimeIntervalSinceNow:-604800];
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *startDate = [calendar startOfDayForDate:date];
    NSDate *endDate = [NSDate date];

    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}
    
+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    if ([date compare:beginDate] == NSOrderedAscending)
    return NO;
    
    if ([date compare:endDate] == NSOrderedDescending)
    return NO;
    
    return YES;
}

@end
