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
        HKObjectType *height = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];

        
        NSSet *readDataTypes = [NSSet setWithObjects:workoutType, mass, energyBurned, height, exerciseTime, walkingRunningDistance, steps, nil];
        
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

+ (void)getAllEnergyBurnedAndSort:(void (^)(NSNumber *, NSError *))completion {
    
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
                                          NSMutableArray *watchSamples = [NSMutableArray new];
                                          NSMutableArray *otherWorkouts = [NSMutableArray new];
                                          
                                          for(HKQuantitySample *samples in results)
                                          {
                                              HKQuantitySample *burned = (HKQuantitySample *)samples;
                                              if ([burned.description containsString:@"Watch"]) {
                                                  [watchSamples addObject:burned];
                                              } else {
                                                  [otherWorkouts addObject:burned];
                                              }
                                          }
                                          
                                          NSMutableArray *overlappingWorkouts = [NSMutableArray new];

                                          for(HKQuantitySample *other in otherWorkouts) {
                                              for(HKQuantitySample *watch in watchSamples) {
                                                  if ([HealthKitFunctions date:watch.startDate isBetweenDate:other.startDate andDate:other.endDate] && ![overlappingWorkouts containsObject:other]) {
                                                      [overlappingWorkouts addObject:other];
                                                  }
                                              }
                                          }
                                          
                                          [otherWorkouts removeObjectsInArray:overlappingWorkouts];
                                          
                                          double watchEnergy = 0.0;
                                          for (HKQuantitySample *watch in watchSamples) {
                                              watchEnergy += [watch.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
                                          }
                                          
                                          double otherEnergy = 0.0;
                                          for (HKQuantitySample *other in otherWorkouts) {
                                              otherEnergy += [other.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
                                          }
                                          
                                          
                                          completion(@(otherEnergy + watchEnergy), nil);
                                      }else{
                                          NSLog(@"Error retrieving energy %@",error);
                                          completion(nil, error);
                                      }
                                  }];
    
    // Execute the query
    [[HKHealthStore new] executeQuery:sampleQuery];
}

+ (void)getAllEnergyWithoutWatchOrHumanAndSortFromStepSamples:(NSMutableArray *)steps withCompletion:(void (^)(NSNumber *, NSError *))completion {
    
    // 2. Order the workouts by date
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:HKSampleSortIdentifierStartDate ascending:false];
    
    // 3. Create the query
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned]
                                                                 predicate:[HealthKitFunctions predicateForSamplesFromNowToDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"]]
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error)
                                  {
                                      
                                      if(!error && results) {

                                          NSMutableArray *otherWorkouts = [NSMutableArray new];
                                          
                                          //    filters to only non watch or human samples
                                          //
                                          for(HKQuantitySample *sample in results)
                                          {
                                              
                                              if (![sample.description containsString:@"Watch"] && ![sample.description containsString:@"Human"]) {
                                                  [otherWorkouts addObject:sample];
                                              }
                                          }
                                          
                                          NSMutableArray *overlappingSamples = [NSMutableArray new];
                                          
                                          //    gather all step samples that touch other workouts
                                          //
                                          for(HKQuantitySample *other in otherWorkouts) {
                                              for(HKQuantitySample *step in steps) {
                                                  if ([HealthKitFunctions date:step.startDate isBetweenDate:other.startDate andDate:other.endDate] && ![overlappingSamples containsObject:step]) {
                                                      [overlappingSamples addObject:step];
                                                  }
                                              }
                                          }
                                          
                                          //    remove overlapping samples from step array
                                          //
                                          [steps removeObjectsInArray:overlappingSamples];
                                          
                                          //    filter step samples for just one device (watch, if present, or phone)
                                          //
                                          NSMutableArray *watchStepSamples = [NSMutableArray new];
                                          NSMutableArray *phoneStepSamples = [NSMutableArray new];

                                          for (HKQuantitySample *step in steps) {
                                              if ([step.description containsString:@"Watch"]) {
                                                  [watchStepSamples addObject:step];
                                              } else if ([step.description containsString:@"iPhone"]) {
                                                  [phoneStepSamples addObject:step];
                                              }
                                          }

                                          //    total workout apps energy
                                          //
                                          double otherEnergy = 0.0;
                                          for (HKQuantitySample *other in otherWorkouts) {
                                              otherEnergy += [other.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
                                          }
                                          
                                          //    total steps that dont touch workout times
                                          //
                                          double nonoverlappingSteps = 0.0;
                                          
                                          //    add up samles from watch or phone
                                          //
                                          if (watchStepSamples.count > 0) {
                                              for (HKQuantitySample *step in watchStepSamples) {
                                                  nonoverlappingSteps += [step.quantity doubleValueForUnit:[HKUnit countUnit]];
                                              }
                                          } else {
                                              for (HKQuantitySample *step in phoneStepSamples) {
                                                  nonoverlappingSteps += [step.quantity doubleValueForUnit:[HKUnit countUnit]];
                                              }
                                          }
                                          
                                          [self convertStepsToCalories:@(nonoverlappingSteps) withCompletion:^(double cals, NSError *err) {
                                              if (!err) {
                                                  completion(@(otherEnergy + cals), nil);
                                              }
                                          }];
                                          
                                      } else{
                                          NSLog(@"Error retrieving energy %@",error);
                                          completion(nil, error);
                                      }
                                  }];
    
    // Execute the query
    [[HKHealthStore new] executeQuery:sampleQuery];
}

+ (void)getAllEnergyBurnedWithoutWatch:(void (^)(NSNumber *, NSError *))completion {
//    
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

+ (void)getAllStepSamples:(void (^)(NSArray* stepSamples, NSError *err))completionHandler {
    // 2. Order the workouts by date
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:HKSampleSortIdentifierStartDate ascending:false];
    
    NSLog(@"Getting Step Samples from %@ to Now", [[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"]);
    
    // 3. Create the query
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]
                                                                 predicate:[HealthKitFunctions predicateForSamplesFromNowToDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"]]
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error)
                                  {
                                      
                                      if(!error && results){
                                          completionHandler(results, nil);
                                      }else{
                                          NSLog(@"Error retrieving energy %@",error);
                                          completionHandler(nil, error);
                                      }
                                  }];
    
    // Execute the query
    [[HKHealthStore new] executeQuery:sampleQuery];
}

+ (void)totalSteps:(void (^)(int steps, NSError *err))completionHandler {
    HKQuantityType *steps = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    HKStatisticsQuery *stepsStats = [[HKStatisticsQuery alloc] initWithQuantityType:steps quantitySamplePredicate:[HKQuery predicateForSamplesWithStartDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"goalStart"] endDate:[NSDate date] options:HKQueryOptionStrictStartDate] options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery * _Nonnull query, HKStatistics * _Nullable result, NSError * _Nullable error) {
        
        if (result) {
            
            //  all steps
            int totalSteps = [result.sumQuantity doubleValueForUnit:[HKUnit countUnit]];
            completionHandler(totalSteps, nil);

        } else {
            completionHandler(0.0, error);
        }
    }];
    
    [[HKHealthStore new] executeQuery:stepsStats];
}

+ (void)getAllEnergyBurnedFromSteps:(void (^)(double, NSError *))completionHandler {
    
    [self totalSteps:^(int steps, NSError *err) {
        
        [self getBodyMass:^(double mass, NSError *err) {
            
            double calsPerMile = mass * 0.57;
            
            [self getStepsPerMileFromHeight:^(double stepsPerMile, NSError *err) {
                double calsPerStep = calsPerMile / stepsPerMile;
                double calsForSteps = calsPerStep * steps;
                completionHandler(calsForSteps, nil);
            }];
            
        }];
    }];
}

+ (void)getBodyMass:(void (^)(double mass, NSError *err))completionHandler {
    HKSampleQuery *bodyMassQuery =
    [[HKSampleQuery alloc] initWithSampleType:
     [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]
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
         
         completionHandler(pounds, nil);
     }];
    
    [[HKHealthStore new] executeQuery:bodyMassQuery];
}

+ (void)convertStepsToCalories:(NSNumber *)steps withCompletion:(void (^)(double, NSError *))completionHandler {

    [self getBodyMass:^(double mass, NSError *err) {
        
        double calsPerMile = mass * 0.57;
        
        [HealthKitFunctions getStepsPerMileFromHeight:^(double stepsPerMile, NSError *err) {
            double calsPerStep = calsPerMile / stepsPerMile;
            double calsForSteps = calsPerStep * [steps doubleValue];
            completionHandler(calsForSteps, nil);
        }];

    }];
}

+(void)getStepsPerMileFromHeight:(void (^)(double, NSError *))completionHandler {
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight]
                                                                 predicate:nil
                                                                     limit:1
                                                           sortDescriptors:nil
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error)
                                  {
                                      NSNumber *inches;
                                      
                                      NSDictionary *inchToCals = @{@(66):@(2286),@(67):@(2252),@(68):@(2218),@(69):@(2186),@(70):@(2155),@(71):@(2125),@(72):@(2095),@(73):@(2067),@(74):@(2039),@(75):@(2011),@(76):@(1985)};
                                      
                                      if (results.count == 1) {
                                          HKQuantitySample *height = results[0];
                                          inches = @([height.quantity doubleValueForUnit:[HKUnit inchUnit]]);
                                          NSLog(@"Your height: %.0f inches", [inches doubleValue]);
                                      } else {
                                          inches = @(70);
                                      }

                                      NSNumber *calsForSteps = (inchToCals[inches] != 0) ? inchToCals[inches] : @(2000);
                                      completionHandler([calsForSteps doubleValue], nil);
                                      
                                  }];
    
    // Execute the query
    [[HKHealthStore new] executeQuery:sampleQuery];
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
