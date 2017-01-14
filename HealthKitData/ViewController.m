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

@property (strong, nonatomic) NSDate *lastSyncDate;
@property (strong, nonatomic) NSString *slackUsername;
@property (strong, nonatomic) NSMutableArray *workouts;
@property (strong, nonatomic) HealthKitFunctions *store;
@property (weak, nonatomic) IBOutlet UITextField *slackUsernameTextField;
@property (weak, nonatomic) IBOutlet UIButton *syncWorkoutButton;

@property (weak, nonatomic) IBOutlet UIView *uploadingWorkoutOverlayView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *uploadingWorkoutSpinner;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.dataTableView.delegate = self;
    self.dataTableView.dataSource = self;
    
    self.lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastSyncDate"];
    self.slackUsername = [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"];
    if (self.slackUsername != nil) {
        [self.slackUsernameTextField setText:self.slackUsername];
    }
    self.workouts = [NSMutableArray new];
    
    [self.uploadingWorkoutOverlayView setHidden:YES];
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

    [self.store getAllWorkouts:^(NSMutableArray *workouts, NSError *err) {
        if (workouts) {
            [self.workouts addObjectsFromArray:workouts];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.dataTableView reloadData];
                //  push unsynced workouts to server
            });
            
        } else {
            NSLog(@"Can't get workouts - %@", [err description]);
        }
    }];
}

- (IBAction)syncWorkouts:(id)sender {
    
    if (self.slackUsernameTextField.text.length > 3) {
        
        NSMutableArray *workoutsSinceLastUploadedDate = [NSMutableArray new];
        
        //  get all workouts not uploaded last time
        
        if (self.lastSyncDate == nil || ![self.slackUsernameTextField.text isEqualToString:self.slackUsername]) { //
            
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
    [self.syncWorkoutButton setEnabled:NO];
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
                                 @"timeStamp": @([[NSDate date] timeIntervalSince1970]),
                                 @"lastSync": @([self.lastSyncDate timeIntervalSince1970]),
                                 @"workouts": workouts,
                                 @"slackUsername": self.slackUsernameTextField.text
                                 };
    
    NSLog(@"%@", [bodyObject description]);
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyObject options:kNilOptions error:NULL];
    
    /* Start a new Task */
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            // Success
            NSLog(@"URL Session Task Succeeded: HTTP %ld", ((NSHTTPURLResponse*)response).statusCode);
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
            [self.syncWorkoutButton setEnabled:YES];
            [self.slackUsernameTextField setEnabled:YES];
            
        });
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

- (IBAction)dismissKeyboard:(id)sender {
    [self.slackUsernameTextField resignFirstResponder];
}


#pragma mark - TableView Delegate & Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.workouts.count;
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
    
    cell.detailTextLabel.text = @"";
    HKWorkout *workout = [self.workouts objectAtIndex:indexPath.row];
    [cell.detailTextLabel setText:[formatter stringFromDate:workout.startDate]];
    [cell.textLabel setText:[dateFormatter stringFromTimeInterval:workout.duration]];

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

#pragma mark - NSURLSession Delegate

-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    
}

@end
