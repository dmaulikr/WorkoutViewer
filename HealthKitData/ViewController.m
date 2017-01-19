//
//  ViewController.m
//  HealthKitData
//
//  Created by Bryan Gula on 12/30/16.
//  Copyright © 2016 Rock My World, Inc. All rights reserved.
//

#import "ViewController.h"
#import "HealthKitFunctions.h"
#import "InsetTextField.h"
@import UserNotifications;

@interface ViewController ()

@property (strong, nonatomic) NSDate *lastSyncDate;
@property (strong, nonatomic) NSString *slackUsername;
@property (strong, nonatomic) NSNumber *totalEnergyBurnedForTheWeek;
@property (strong, nonatomic) NSMutableArray *workouts;
@property (strong, nonatomic) NSMutableArray *sources;
@property (strong, nonatomic) NSMutableArray *energy;
@property (strong, nonatomic) HealthKitFunctions *store;

@property (weak, nonatomic) IBOutlet InsetTextField *slackUsernameTextField;
@property (weak, nonatomic) IBOutlet UIView *uploadingWorkoutOverlayView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *uploadingWorkoutSpinner;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.dataTableView.delegate = self;
    self.dataTableView.dataSource = self;
    self.slackUsernameTextField.delegate = self;
    
    self.lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastSyncDate"];
    self.slackUsername = [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"];
    if (self.slackUsername != nil) {
        [self.slackUsernameTextField setText:self.slackUsername];
    }
    self.energy = [NSMutableArray new];
    
    [self.uploadingWorkoutOverlayView setHidden:NO];
    [self.uploadingWorkoutSpinner startAnimating];
}
- (IBAction)showAll:(UISwitch *)sender {
    
    if (sender.on) {
        [self.energy removeAllObjects];

        [self.store getAllEnergyBurned:^(NSMutableArray *energy, NSError *err) {
            [self.energy addObjectsFromArray:energy];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.dataTableView reloadData];
                [self.uploadingWorkoutOverlayView setHidden:YES];
                [self.uploadingWorkoutSpinner stopAnimating];
            });
            
        }];
    } else {
        [self.energy removeAllObjects];

        [self.store getAllEnergyBurned:^(NSMutableArray *energy, NSError *err) {
            
            //[self.energy addObjectsFromArray:energy];
            
            for (HKQuantitySample *sample in energy) {
                if ([[sample description] rangeOfString:@"Watch"].location == NSNotFound) {
                    [self.energy addObject:sample];
                }
            }
            
            NSMutableArray *energies = energy;
            
            double totalBurned = 0.0;
            for (HKQuantitySample *energy in energies) {
                totalBurned += [energy.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
            }
            
            self.totalEnergyBurnedForTheWeek = @(totalBurned);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.dataTableView reloadData];
                [self.uploadingWorkoutOverlayView setHidden:YES];
                [self.uploadingWorkoutSpinner stopAnimating];
            });
            
            NSLog(@"Total Energy Burned: %0.f", totalBurned);
        }];
    }
}

- (IBAction)showWatchOnly:(UISwitch *)sender {
    
    if (sender.on) {
        [self.store getAllEnergyBurned:^(NSMutableArray *energy, NSError *err) {
            
            //[self.energy addObjectsFromArray:energy];
            [self.energy removeAllObjects];
            
            for (HKQuantitySample *sample in energy) {
                if ([[sample description] rangeOfString:@"Watch"].location != NSNotFound) {
                    [self.energy addObject:sample];
                }
            }
            
            NSMutableArray *energies = energy;
            
            double totalBurned = 0.0;
            for (HKQuantitySample *energy in energies) {
                totalBurned += [energy.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
            }
            
            self.totalEnergyBurnedForTheWeek = @(totalBurned);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.dataTableView reloadData];
                [self.uploadingWorkoutOverlayView setHidden:YES];
                [self.uploadingWorkoutSpinner stopAnimating];
            });
            
            NSLog(@"Total Energy Burned: %0.f", totalBurned);
        }];
        
    } else {
        [self.energy removeAllObjects];

        [self.store getAllEnergyBurned:^(NSMutableArray *energy, NSError *err) {
            
            //[self.energy addObjectsFromArray:energy];
            
            for (HKQuantitySample *sample in energy) {
                if ([[sample description] rangeOfString:@"Watch"].location == NSNotFound) {
                    [self.energy addObject:sample];
                }
            }
            
            NSMutableArray *energies = energy;
            
            double totalBurned = 0.0;
            for (HKQuantitySample *energy in energies) {
                totalBurned += [energy.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
            }
            
            self.totalEnergyBurnedForTheWeek = @(totalBurned);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.dataTableView reloadData];
                [self.uploadingWorkoutOverlayView setHidden:YES];
                [self.uploadingWorkoutSpinner stopAnimating];
            });
            
            NSLog(@"Total Energy Burned: %0.f", totalBurned);
        }];
    }
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
    
    [self.store getAllEnergyBurned:^(NSMutableArray *energy, NSError *err) {

        //[self.energy addObjectsFromArray:energy];
        
        for (HKQuantitySample *sample in energy) {
            if ([[sample description] rangeOfString:@"Watch"].location == NSNotFound) {
                [self.energy addObject:sample];
            }
        }
        
        NSMutableArray *energies = energy;

        double totalBurned = 0.0;
        for (HKQuantitySample *energy in energies) {
            totalBurned += [energy.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
        }
        
        self.totalEnergyBurnedForTheWeek = @(totalBurned);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataTableView reloadData];
            [self.uploadingWorkoutOverlayView setHidden:YES];
            [self.uploadingWorkoutSpinner stopAnimating];
        });

        NSLog(@"Total Energy Burned: %0.f", totalBurned);
    }];
    
    [self.store getAllSources:^(NSMutableArray *sources, NSError *err) {
        if (err) {
        
        } else {
            self.sources = sources;
        }
    }];
}

- (IBAction)syncWorkouts:(id)sender {
    
    if (self.slackUsernameTextField.text.length > 3) {
        
        NSMutableArray *workoutsSinceLastUploadedDate = [NSMutableArray new];
        
        //  get all workouts not uploaded last time
        
        if (self.lastSyncDate == nil || ![self.slackUsernameTextField.text isEqualToString:self.slackUsername]) {
            
            for (HKWorkout *workout in self.workouts) {
                [workoutsSinceLastUploadedDate addObject:[self buildDictionaryForWorkout:workout]];
            }
            
            if ([workoutsSinceLastUploadedDate count] > 0) {
                [self uploadWorkouts:workoutsSinceLastUploadedDate];
                [self hideControlsForUpload];
            }
            
        } else {
            
            NSMutableArray *filteredWorkouts = [self filterWorkouts:self.workouts];
            
            if ([filteredWorkouts count] > 0) {
                [self uploadWorkouts:filteredWorkouts];
                [self hideControlsForUpload];
            }
        }
    }
}

-(void)hideControlsForUpload {
    //  show overlay, spinner, disable sync button and tableView, slackTextField
    [self.uploadingWorkoutOverlayView setHidden:NO];
    [self.uploadingWorkoutSpinner startAnimating];
    [self.dataTableView setUserInteractionEnabled:NO];
    [self.slackUsernameTextField setEnabled:NO];
}

-(NSMutableArray *)filterWorkouts:(NSMutableArray *)workouts {
    
    NSMutableArray *workoutsSinceLastUploadedDate = [NSMutableArray new];
    
    //  get all workouts not uploaded last time
    
    for (HKWorkout *workout in self.workouts) {
        //  if workout dates are not asending, date is after sync or equal to it
        if ([workout.startDate compare:self.lastSyncDate] != NSOrderedAscending) {
            [workoutsSinceLastUploadedDate addObject:[self buildDictionaryForWorkout:workout]];
        }
    }
    
    return workoutsSinceLastUploadedDate;
}

-(NSDictionary * )buildDictionaryForWorkout:(HKWorkout *)workout {
    return @{
             @"duration": @([@(workout.duration) integerValue]),
             @"workoutType": (workout.workoutActivityType == HKWorkoutActivityTypeRunning) ? @"Running" : @"Other",
             @"end": @([@([workout.endDate timeIntervalSince1970]) integerValue]),
             @"energyBurned": @([@([workout.totalEnergyBurned doubleValueForUnit:[HKUnit kilocalorieUnit]]) integerValue]),
             @"distance": @([workout.totalDistance doubleValueForUnit:[HKUnit mileUnit]]),
             @"start": @([@([workout.startDate timeIntervalSince1970]) integerValue])
           };
}

-(void)uploadWorkouts:(NSMutableArray *)workouts {
    
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    
    NSURL* URL = [NSURL URLWithString:@"http://adamr5.sg-host.com/adamrz/myfirstbot/api/workouts/index.php"];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    
    // Headers
    
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    // JSON Body
    
    NSDictionary* bodyObject = @{
                                 @"timeStamp": @([@([[NSDate date] timeIntervalSince1970]) integerValue]),
                                 @"lastSync": @([@([self.lastSyncDate timeIntervalSince1970]) integerValue]),
                                 @"activeEnergy": self.totalEnergyBurnedForTheWeek,
                                 @"slackUsername": [self.slackUsernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                 };
    
    NSLog(@"%@", [bodyObject description]);
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyObject options:kNilOptions error:NULL];
    
    /* Start a new Task */
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            // Success
            NSLog(@"URL Session Task Succeeded: HTTP %ld", (long)((NSHTTPURLResponse*)response).statusCode);
            self.lastSyncDate = [NSDate dateWithTimeIntervalSinceNow:0];
            [[NSUserDefaults standardUserDefaults] setObject:self.lastSyncDate forKey:@"lastSyncDate"];
            [[NSUserDefaults standardUserDefaults] setObject:self.slackUsernameTextField.text forKey:@"slackUsername"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else {
            // Failure
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //  show overlay, spinner, disable sync button and tableView, slackTextField
            [self.uploadingWorkoutOverlayView setHidden:YES];
            [self.uploadingWorkoutSpinner stopAnimating];
            [self.dataTableView setUserInteractionEnabled:YES];
            [self.slackUsernameTextField setEnabled:YES];
            
            //[self showNotificationForWorkout];
        });
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

- (IBAction)dismissKeyboard:(id)sender {
    [self.slackUsernameTextField resignFirstResponder];
}

-(void)showNotificationForWorkout {
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = @"New Active Energy Logged!";
    content.body = @"Uploading to FitBot now.. here come those Move Points!";
    content.sound = [UNNotificationSound defaultSound];
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1
                                                                                                    repeats:NO];
    NSString *identifier = @"NewWorkoutLocalNotification";
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                          content:content trigger:trigger];
    
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Something went wrong scheduling a notification: %@",error);
        }
    }];
}


#pragma mark - TableView Delegate & Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.energy.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"healthCell"];
    if ([self.energy count] > 1) {
        
        HKQuantitySample *energy = [self.energy objectAtIndex:indexPath.row];
        
        NSString *energyString = [NSString stringWithFormat:@"%.2f", [energy.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]]];
        
        [cell.textLabel setText:[energyString stringByAppendingString:@" kCal"]];
        
        NSString *source;
        if ([[energy description] rangeOfString:@"Watch"].location != NSNotFound) {
            source = @"Watch";
        } else if ([[energy description] rangeOfString:@"iPhone"].location != NSNotFound) {
            source = @"iPhone";
        } else if ([[energy description] rangeOfString:@"Human"].location != NSNotFound) {
            source = @"Human";
        } else if ([[energy description] rangeOfString:@"Endomondo"].location != NSNotFound) {
            source = @"Endomondo";
        } else {
            source = @"Other";
        }
        
        [cell.detailTextLabel setText:source];
    }

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - NSURLSession Delegate

-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    
}

@end
