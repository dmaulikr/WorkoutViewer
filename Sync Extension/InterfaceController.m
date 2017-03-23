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
    [self refresh];
}

-(void)refresh {
    if ([WCSession defaultSession].activationState == WCSessionActivationStateActivated) {
        
        
        [[WCSession defaultSession] sendMessage:@{@"getEnergy":@"yes"} replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.summary = [HKActivitySummary new];
                
                double burned = [[replyMessage valueForKey:@"burned"] doubleValue];
                
                double goal = [[replyMessage valueForKey:@"goal"] doubleValue];
                
                double days = abs([[replyMessage valueForKey:@"days"] intValue]);
                
                double daily = (goal / days);
                double today = [[replyMessage valueForKey:@"today"] doubleValue];
                
                //double remainingToday = daily - today;
                
                [self.dailyGoalRemaining setText:[NSString stringWithFormat:@"%0.f", today]];
                
                [self.totalBurnedLabel setText:[NSString stringWithFormat:@"%.0f", burned]];
                
                [self.goalLabel setText:[NSString stringWithFormat:@"%.0f", goal]];
                
                [self.timeRemainingLabel setText:[NSString stringWithFormat:@"%.0f", days]];
                
                [self.summary setActiveEnergyBurned:[HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:[((NSNumber *)[replyMessage valueForKey:@"burned"]) doubleValue]]];
                
                [self.summary setActiveEnergyBurnedGoal:[HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:[((NSNumber *)[replyMessage valueForKey:@"goal"]) doubleValue]]];
                
                [self.summary setAppleExerciseTime:[HKQuantity quantityWithUnit:[HKUnit minuteUnit] doubleValue:today]];
                
                [self.summary setAppleExerciseTimeGoal:[HKQuantity quantityWithUnit:[HKUnit minuteUnit] doubleValue:daily]];
                
                [self.summary setAppleStandHours:[HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:[@(fabs(7 - days)) doubleValue]]];
                
                [self.summary setAppleStandHoursGoal:[HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:7]];
                

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



