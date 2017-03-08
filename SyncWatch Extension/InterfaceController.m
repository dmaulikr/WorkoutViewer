//
//  ActivityInterfaceController.m
//  HealthKitData
//
//  Created by Bryan Gula on 3/2/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//


#import "InterfaceController.h"
@import WatchKit;
@import HealthKit;
@import WatchConnectivity;

@interface InterfaceController ()

@end

@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    

}

-(void)willActivate {
    
    [super willActivate];
    if ([WCSession defaultSession].activationState == WCSessionActivationStateActivated) {
        

        [[WCSession defaultSession] sendMessage:@{@"getEnergy":@"yes"} replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.summary = [HKActivitySummary new];
                
                [self.totalBurnedLabel setText:[NSString stringWithFormat:@"%.0f kCal", [[replyMessage valueForKey:@"burned"] doubleValue]]];
                
                [self.summary setActiveEnergyBurned:[HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:[((NSNumber *)[replyMessage valueForKey:@"burned"]) doubleValue]]];
                
                [self.summary setActiveEnergyBurnedGoal:[HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:[((NSNumber *)[replyMessage valueForKey:@"goal"]) doubleValue]]];
                
                [self.summary setAppleExerciseTime:[HKQuantity quantityWithUnit:[HKUnit minuteUnit] doubleValue:0]];
                
                [self.summary setAppleExerciseTimeGoal:[HKQuantity quantityWithUnit:[HKUnit minuteUnit] doubleValue:10]];
                
                [self.summary setAppleStandHours:[HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:0]];
                
                [self.summary setAppleStandHoursGoal:[HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:10]];
                
                
                [self.rings setActivitySummary:self.summary animated:YES];
            });
            
        } errorHandler:^(NSError * _Nonnull error) {
            
        }];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



