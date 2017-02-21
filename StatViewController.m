//
//  StatViewController.m
//  HealthKitData
//
//  Created by Bryan Gula on 2/17/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import "StatViewController.h"
#import "HealthKitFunctions.h"

@interface StatViewController ()

@end

@implementation StatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loadWatchEnergy];
    [self loadNoWatchEnergy];
    [self loadStepsBasedEnergyBurned];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadWatchEnergy {
    [HealthKitFunctions getAllEnergyBurnedFromAppleWatch:^(NSNumber *total, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.onlyWatchCalorieLabel setText:[NSString stringWithFormat:@"%.2f kCal", [total doubleValue]]];
        });
    }];
}
    
-(void)loadNoWatchEnergy {
    [HealthKitFunctions getAllEnergyBurnedWithoutWatch:^(NSNumber *total, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.noWatchCalorieLabel setText:[NSString stringWithFormat:@"%.2f kCal", [total doubleValue]]];
        });
    }];
}
    
-(void)loadStepsBasedEnergyBurned {
    
    [HealthKitFunctions getAllEnergyBurnedFromSteps:^(double cals, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.stepCalorieLabel setText:[NSString stringWithFormat:@"%.2f kCal", cals]];
        });
    }];
}
    
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
