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
    
    self.store = [[HealthKitFunctions alloc] init];
    self.store.healthStore = [HKHealthStore new];

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
    self.dataTableView.userInteractionEnabled = NO;
    [self.uploadingWorkoutSpinner startAnimating];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.store requestPermission:^(BOOL success, NSError *err) {
        if (success) {
            NSLog(@"Health Kit Ready to Query");
            [self getDataForSegment];
        }
    }];
    
    
    if (self.slackUsername == nil) {
        [self showAddUsernameAlert];
    }
}

- (IBAction)manualSync:(id)sender {
    [self uploadActiveEnergy];
}


-(void)showAddUsernameAlert {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Add your Slack username to Sync Data"
                                                                   message:@"ex: \"adamrz\""
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Neat!" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)showAll:(UISwitch *)sender {
    
    if (sender.on) {
        [self.energy removeAllObjects];

        [self.store getAllEnergyBurnedForever:^(NSMutableArray *energy, NSError *err) {
            [self.energy addObjectsFromArray:energy];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.dataTableView reloadData];
                [self.uploadingWorkoutOverlayView setHidden:YES];
                [self.uploadingWorkoutSpinner stopAnimating];
            });
            
        }];
    } else {
        [self fetchEnergySamples];
    }
}

-(void)fetchEnergySamples {
    
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

-(void)getDataForSegment {
    
    [self.store getAllEnergyBurned:^(NSMutableArray *energy, NSError *err) {

        //  Include watch data
        //[self.energy addObjectsFromArray:energy];
        
        //  Excludes watch data
        for (HKQuantitySample *sample in energy) {
            if ([[sample description] rangeOfString:@"Watch"].location == NSNotFound) {
                [self.energy addObject:sample];
            }
        }
        
        double totalBurned = 0.0;
        for (HKQuantitySample *energy in self.energy) {
            totalBurned += [energy.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
        }
        
        self.totalEnergyBurnedForTheWeek = @(totalBurned);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.totalWeeklyEnergyBurnedLabel setText:[NSString stringWithFormat:@"Energy Burned in the last 7 Days: %0.f kCal", totalBurned]];
            [self.dataTableView reloadData];
            self.dataTableView.userInteractionEnabled = YES;
            [self.uploadingWorkoutOverlayView setHidden:YES];
            [self.uploadingWorkoutSpinner stopAnimating];
        });

        NSLog(@"Total Energy Burned: %0.f", totalBurned);
    }];
}

- (IBAction)syncWorkouts:(id)sender {
    
    if (self.slackUsernameTextField.text.length > 1) {
        
        [self hideControlsForUpload];
        [self uploadActiveEnergy];
        
    } else {
        
        [self showAddUsernameAlert];
    }
}

-(void)hideControlsForUpload {
    //  show overlay, spinner, disable sync button and tableView, slackTextField
    [self.uploadingWorkoutOverlayView setHidden:NO];
    [self.uploadingWorkoutSpinner startAnimating];
    [self.dataTableView setUserInteractionEnabled:NO];
    [self.slackUsernameTextField setEnabled:NO];
}

-(NSNumber *)getActiveEnergySinceLastSyncDate {
    
    double afterLastSyncEnergy = 0.0;
    
    for (HKQuantitySample *energy in self.energy) {
        if ([energy.startDate compare:self.lastSyncDate] == NSOrderedDescending) {
            afterLastSyncEnergy += [energy.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]];
        }
    }
    
    NSLog(@"Energy Since Last Sync: %@, Last Sync: %@, Now: %@", [@(afterLastSyncEnergy) stringValue], [self.lastSyncDate description], [[NSDate date] description]);
    
    return @(afterLastSyncEnergy);
}

-(void)uploadActiveEnergy {
    
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    
    NSURL* URL = [NSURL URLWithString:@"http://adamr5.sg-host.com/adamrz/myfirstbot/api/workouts/index.php"];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    
    // Headers
    
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    NSNumber *activeEnergy;
    
    //  first sync
//    if (self.lastSyncDate == nil) {
//        activeEnergy = self.totalEnergyBurnedForTheWeek;
//        self.lastSyncDate = [NSDate date];
//    } else {
        activeEnergy = [self getActiveEnergySinceLastSyncDate];
//    }
    
    NSLog(@"Active Energy being Synced: %@", [activeEnergy stringValue]);
    
    if (self.lastSyncDate == nil) {
        self.lastSyncDate = [NSDate date];
    }
    
    NSDictionary* bodyObject = @{
                                 @"timeStamp": @([@([[NSDate date] timeIntervalSince1970]) integerValue]),
                                 @"lastSync": @([@([self.lastSyncDate timeIntervalSince1970]) integerValue]),
                                 @"activeEnergy": activeEnergy,
                                 @"slackUsername": [self.slackUsernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                 };
    
    NSLog(@"%@", [bodyObject description]);
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyObject options:kNilOptions error:NULL];
    
    /* Start a new Task */
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            // Success
            NSLog(@"URL Session Task Succeeded: HTTP %ld", (long)((NSHTTPURLResponse*)response).statusCode);
            
            if (((NSHTTPURLResponse*)response).statusCode == [@(200) integerValue]) {
                //  upload worked, last sync data & username accurate
                dispatch_async(dispatch_get_main_queue(), ^{

                    self.lastSyncDate = [NSDate dateWithTimeIntervalSinceNow:0];
                    [[NSUserDefaults standardUserDefaults] setObject:self.lastSyncDate forKey:@"lastSyncDate"];
                    [[NSUserDefaults standardUserDefaults] setObject:self.slackUsernameTextField.text forKey:@"slackUsername"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    if (![activeEnergy isEqualToNumber:@(0)]) {
                        [self showSuccessfulUpload];
                    } else {
                        [self showNoEnergySinceLastSyncAlert];
                    }
                });
            } else if (((NSHTTPURLResponse*)response).statusCode == [@(400) integerValue]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showIncorrectSlackUsernameAlert];
                });
            }
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
            
        });
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

- (IBAction)dismissKeyboard:(id)sender {
    [self.slackUsernameTextField resignFirstResponder];
}

-(void)showIncorrectSlackUsernameAlert {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Incorrect Slack Username"
                                                                   message:@"Remove @ or email suffixes from your username and try again. ex: \"adamrz\""
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Dope" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)showNoEnergySinceLastSyncAlert {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Nothing to Sync"
                                                                   message:@"There was no active energy change since last FitBot sync"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Nice, I'll go move!" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
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

-(void)showSuccessfulUpload {
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = @"Energy Successfully Uploaded!";
    content.body = @"Check Slack for Fitbot updates";
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

-(void)showFailedUpload {
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = @"Energy Uploaded Failed!";
    content.body = @"Re-Enter your Slack username and try again.";
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
        
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.dateStyle = NSDateFormatterShortStyle;
        
        [cell.detailTextLabel setText:[[source mutableCopy] stringByAppendingString:[NSString stringWithFormat:@" - %@", [formatter stringFromDate:energy.startDate]]]];
    }

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
