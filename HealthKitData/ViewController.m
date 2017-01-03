//
//  ViewController.m
//  HealthKitData
//
//  Created by Bryan Gula on 12/30/16.
//  Copyright © 2016 Rock My World, Inc. All rights reserved.
//

#import "ViewController.h"
#import "HealthKitFunctions.h"

@interface ViewController ()

@property (strong, nonatomic) NSMutableArray *workouts;
@property (strong, nonatomic) NSMutableArray *minutes;
@property (strong, nonatomic) NSMutableArray *energy;
@property (strong, nonatomic) NSMutableArray *distance;
@property (strong, nonatomic) HealthKitFunctions *store;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.dataTableView.delegate = self;
    self.dataTableView.dataSource = self;
    
    self.workouts = [NSMutableArray new];
    self.minutes = [NSMutableArray new];
    self.energy = [NSMutableArray new];
    self.distance = [NSMutableArray new];

    
    [self.healthDataSegmentedController addTarget:self
                         action:@selector(action:)
               forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Register Health Kit

-(void)viewDidAppear:(BOOL)animated {
    self.store = [[HealthKitFunctions alloc] init];
    self.store.healthStore = [HKHealthStore new];
    [self.store requestPermission:^(BOOL success, NSError *err) {
        if (success) {
            NSLog(@"Health Kit Ready to Query");
            [self getDataForSegment];
        }
    }];
}

-(void)getDataForSegment {
    switch (self.healthDataSegmentedController.selectedSegmentIndex) {
        case 0:
            [self.store getAllWorkouts:^(NSMutableArray *workouts, NSError *err) {
                if (workouts) {
                    [self.workouts addObjectsFromArray:workouts];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.dataTableView reloadData];

                    });
                    
                } else {
                    NSLog(@"Can't get workouts - %@", [err description]);
                }
            }];
            break;
            //        case 1:
            //            break;
            //        case 2:
            //            break;
            //        case 3:
            //            break;
//        default:
//            
//            break;
    }
}

#pragma mark - Segmented Controller Methods

-(void)action:(id)sender {

}

#pragma mark - TableView Delegate & Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (self.healthDataSegmentedController.selectedSegmentIndex) {
        case 0:
            return self.workouts.count;
            break;
        case 1:
            return self.minutes.count;
            break;
        case 2:
            return self.energy.count;
            break;
        case 3:
            return self.distance.count;
            break;
        default:
            return 0;
            break;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"healthCell"];
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    NSDateComponentsFormatter *dateFormatter = [[NSDateComponentsFormatter alloc] init];
    dateFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleShort;
    dateFormatter.includesApproximationPhrase = NO;
    dateFormatter.includesTimeRemainingPhrase = NO;
    dateFormatter.allowedUnits = NSCalendarUnitMinute;
    
    switch (self.healthDataSegmentedController.selectedSegmentIndex) {
        case 0: {
            cell.detailTextLabel.text = @"";
            HKWorkout *workout = [self.workouts objectAtIndex:indexPath.row];
            [cell.detailTextLabel setText:[formatter stringFromDate:workout.startDate]];
            [cell.textLabel setText:[dateFormatter stringFromTimeInterval:workout.duration]];
            
//            NSDate *startDate = dateFormatter.stringFromDate(workout.startDate)
//            cell.textLabel.text = startDate
//            
//            var detailText = "Duration: " + durationFormatter.stringFromTimeInterval(workout.duration)!
//            detailText += " Distance: "
//            if distanceUnit == .Kilometers {
//                let distanceInKM = workout.totalDistance.doubleValueForUnit(HKUnit.meterUnitWithMetricPrefix(HKMetricPrefix.Kilo))
//                detailText += distanceFormatter.stringFromValue(distanceInKM, unit: NSLengthFormatterUnit.Kilometer)
//            }
//            else {
//                let distanceInMiles = workout.totalDistance.doubleValueForUnit(HKUnit.mileUnit())
//                detailText += distanceFormatter.stringFromValue(distanceInMiles, unit: NSLengthFormatterUnit.Mile)
//                
//            }
//            let energyBurned = workout.totalEnergyBurned.doubleValueForUnit(HKUnit.jouleUnit())
//            detailText += " Energy: " + energyFormatter.stringFromJoules(energyBurned)
//            cell.detailTextLabel.text = detailText;
            
            break;
        }
        case 1: {
            cell.detailTextLabel.text = @"";
            HKWorkout *workout = [self.workouts objectAtIndex:indexPath.row];
            [cell.detailTextLabel setText:[formatter stringFromDate:workout.startDate]];
            [cell.textLabel setText:[dateFormatter stringFromTimeInterval:workout.duration]];
            break;
        }
        case 2: {
            break;
        }
        case 3: {
            break;
        }
        default: {
            return 0;
            break;
        }
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIAlertController *alert = [[UIAlertController alloc] init];
    [alert setTitle:@"Workout Summary"];
    
    UIAlertAction *done = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDestructive handler:nil];
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setDateFormat:@"HH:mm"];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    
    NSDateComponentsFormatter *dateFormatter = [[NSDateComponentsFormatter alloc] init];
    dateFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleShort;
    dateFormatter.includesApproximationPhrase = NO;
    dateFormatter.includesTimeRemainingPhrase = NO;
    dateFormatter.allowedUnits = NSCalendarUnitMinute;
    
    HKWorkout *workout = [self.workouts objectAtIndex:indexPath.row];
    NSString *startDate = [formatter stringFromDate:workout.startDate];
    NSString *endDate = [formatter stringFromDate:workout.endDate];

    NSString *duration = [dateFormatter stringFromTimeInterval:workout.duration];
    
    NSString *distanceInMiles = [NSString stringWithFormat:@"%.1f",[workout.totalDistance doubleValueForUnit:[HKUnit mileUnit]]];
    NSString *energyBurned = [NSString stringWithFormat:@"%.0f", [workout.totalEnergyBurned doubleValueForUnit:[HKUnit kilocalorieUnit]]];
    
    [alert addAction:done];
                           
    [alert setMessage:[NSString stringWithFormat:@"Started: %@, Ended: %@, Duration: %@, Distance: %@ Miles, Energy Burned: %@ Calories", startDate, endDate, duration, distanceInMiles, energyBurned]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
