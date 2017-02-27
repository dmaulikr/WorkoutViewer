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
    
@property (weak, nonatomic) IBOutlet UILabel *currentGoalLabel;
@property (weak, nonatomic) IBOutlet UILabel *remainingGoalLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLeftLabel;
@property (weak, nonatomic) IBOutlet UIButton *sourcesButton;
    

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
    self.sourcesButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.dataTableView.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.slackUsernameTextField.layer.borderColor = [UIColor whiteColor].CGColor;
    
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
        }
    }];
    
    [self getDataForSegment];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchEnergySamples) name:@"refreshEnergy" object:nil];
    
    if (self.slackUsername == nil) {
        [self showAddUsernameAlert];
    } else {
//        [self checkProgressAndGoals];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

-(void)fetchEnergySamples {
    
    [self.energy removeAllObjects];
    
    [self.store getAllEnergyBurned:^(NSMutableArray *energy, NSError *err) {
        
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

#pragma mark - Register Health Kit

-(void)getDataForSegment {
    
    [self.store getAllEnergyBurned:^(NSMutableArray *energy, NSError *err) {
        
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
            
            [self.totalWeeklyEnergyBurnedLabel setText:[NSString stringWithFormat:@"%0.f Cal", totalBurned]];
            [self.dataTableView setUserInteractionEnabled:NO];
            [self.dataTableView reloadData];
            self.dataTableView.userInteractionEnabled = YES;
            [self.uploadingWorkoutOverlayView setHidden:YES];
            [self.uploadingWorkoutSpinner stopAnimating];
            
            if (self.slackUsername != nil) {
                [self checkProgressAndGoals];
            }

        });

        NSLog(@"Total Energy Burned: %0.f", totalBurned);
    }];
}

-(void)hideControlsForUpload {
    //  show overlay, spinner, disable sync button and tableView, slackTextField
    [self.uploadingWorkoutOverlayView setHidden:NO];
    [self.uploadingWorkoutSpinner startAnimating];
    [self.dataTableView setUserInteractionEnabled:NO];
    [self.slackUsernameTextField setEnabled:NO];
}

- (void)checkProgressAndGoals
    {
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        /* Create session, and optionally set a NSURLSessionDelegate. */
        NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
        
        
        NSURL* URL = [NSURL URLWithString:@"http://adamr5.sg-host.com/adamrz/myfirstbot/api/active_goal/"];
        NSDictionary* URLParams = @{
                                    @"slack_username": [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"],
                                    };
        
        URL = NSURLByAppendingQueryParameters(URL, URLParams);
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"GET";
        
        /* Start a new Task */
        NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error == nil) {
                // Success
                NSError *err;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&err];
                
                if (err) {
                    NSLog(@"Error parsing json: %@", [err description]);
                } else {
                    
                    NSNumber *goal = [json valueForKey:@"goal_points"];
                    NSNumber *current = [json valueForKey:@"current_points"];
                    NSString *start = [json valueForKey:@"start_date"];
                    NSString *end = [json valueForKey:@"end_date"];
                    
                    NSLog(@"Goal: %@, Current: %@, Start: %@, End: %@", goal.description, current.description, start, end);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [self.currentGoalLabel setText:[NSString stringWithFormat:@"%@ Cal", goal]];
                        
                        int goalDiff = [goal intValue] - [self.totalEnergyBurnedForTheWeek intValue];
                        
                        [self.burnedEnergyLabel setText:[NSString stringWithFormat:@"%.0f Cal", [self.totalEnergyBurnedForTheWeek doubleValue]]];
                        
                        if (goalDiff > 0) {
                            [self.remainingGoalLabel setText:[NSString stringWithFormat:@"%.0f Cal", [@(goalDiff) doubleValue]]];
                        } else {
                            int positive = abs(goalDiff);
                            [self.remainingGoalLabel setText:[NSString stringWithFormat:@"+%.0f Cal", [@(positive) doubleValue]]];
                        }
                        
                        NSDateFormatter *formatter = [NSDateFormatter new];
                        [formatter setDateFormat:@"YYYY-MM-d k:m:s"];
                        
                        NSDate *startDate = [formatter dateFromString:start];
                        NSDate *endDate = [formatter dateFromString:end];
                        
                        
                        NSInteger daysLeft = [ViewController daysBetweenDate:[NSDate date] andDate:endDate];
                        
                        if (daysLeft == 1) {
                            [self.timeLeftLabel setText:[NSString stringWithFormat:@"%zd day", daysLeft]];
                        } else {
                            [self.timeLeftLabel setText:[NSString stringWithFormat:@"%zd days", daysLeft]];
                        }
                        
                        [[NSUserDefaults standardUserDefaults] setObject:goal forKey:@"goalPoints"];
                        [[NSUserDefaults standardUserDefaults] setObject:current forKey:@"currentPoints"];
                        [[NSUserDefaults standardUserDefaults] setObject:startDate forKey:@"goalStart"];
                        [[NSUserDefaults standardUserDefaults] setObject:endDate forKey:@"goalEnd"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                        //[self uploadActiveEnergy];
                        [self.dataTableView reloadData];
                    });
                }
            }
            else {
                // Failure
                NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
            }
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
        
        [cell.textLabel setText:[energyString stringByAppendingString:@" Cal"]];
        
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
        NSDateFormatter *formatter2 = [NSDateFormatter new];
        [formatter2 setDateFormat:@"hh:mm"];
        
        NSString *dateString = [formatter stringFromDate:energy.startDate];
        
        [cell.detailTextLabel setText:[[source mutableCopy] stringByAppendingString:[NSString stringWithFormat:@"     %@   ", [dateString substringToIndex:dateString.length - 3]]]];
    }

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
    
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime {
    
        NSDate *fromDate;
        NSDate *toDate;
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                     interval:NULL forDate:fromDateTime];
        [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                     interval:NULL forDate:toDateTime];
        
        NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                                   fromDate:fromDate toDate:toDate options:0];
        
        return [difference day];
}
    
/*
 * Utils: Add this section before your class implementation
 */

/**
 This creates a new query parameters string from the given NSDictionary. For
 example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
 string will be @"day=Tuesday&month=January".
 @param queryParameters The input dictionary.
 @return The created parameters string.
 */
static NSString* NSStringFromQueryParameters(NSDictionary* queryParameters)
{
    NSMutableArray* parts = [NSMutableArray array];
    [queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *part = [NSString stringWithFormat: @"%@=%@",
                          [key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
                          [value stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
                          ];
        [parts addObject:part];
    }];
    return [parts componentsJoinedByString: @"&"];
}

/**
 Creates a new URL by adding the given query parameters.
 @param URL The input URL.
 @param queryParameters The query parameter dictionary to add.
 @return A new NSURL.
 */
static NSURL* NSURLByAppendingQueryParameters(NSURL* URL, NSDictionary* queryParameters)
{
    NSString* URLString = [NSString stringWithFormat:@"%@?%@",
                           [URL absoluteString],
                           NSStringFromQueryParameters(queryParameters)
                           ];
    return [NSURL URLWithString:URLString];
}

@end
