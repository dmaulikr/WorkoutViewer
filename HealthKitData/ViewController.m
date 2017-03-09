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
@import WatchConnectivity;

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIView *collectionViewContainer;
@property (strong, nonatomic) NSString *slackUsername;
@property (strong, nonatomic) NSNumber *totalEnergyBurnedForTheWeek;
@property (strong, nonatomic) NSMutableArray *sources;
@property (strong, nonatomic) NSMutableArray *energy;
@property (strong, nonatomic) HealthKitFunctions *store;
    
@property (weak, nonatomic) IBOutlet UILabel *remainingGoalLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLeftLabel;
@property (strong, nonatomic) IBOutlet UIButton *syncButton;
@property (strong, nonatomic) IBOutlet UIButton *showLogButton;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) IBOutlet UILabel *daysLabel;


@property (strong, nonatomic) dispatch_semaphore_t sem;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.store = [[HealthKitFunctions alloc] init];
    self.store.healthStore = [HKHealthStore new];

    self.syncButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.showLogButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.slackUsername = [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"];
    
    self.energy = [NSMutableArray new];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.store requestPermission:^(BOOL success, NSError *err) {
        if (success) {
            [self getDataForSegment];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchEnergySamples) name:@"refreshEnergy" object:nil];
    
    if (self.slackUsername == nil) {
        [self showAddUsernameAlert];
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

- (IBAction)showLogPage:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"scrollToLog" object:nil];
    [self.pageControl setCurrentPage:3];
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
        });
        
        NSLog(@"Total Energy Burned: %0.f", totalBurned);
    }];
}

#pragma mark - Register Health Kit

-(void)getDataForSegment {
    
    [self.store getAllEnergyBurned:^(NSMutableArray *energy, NSError *err) {

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
            
            
            if (self.slackUsername != nil) {
                [self checkProgressAndGoals];
            }

        });

        NSLog(@"Total Energy Burned: %0.f", totalBurned);
    }];
}

- (IBAction)syncWorkouts:(id)sender {
    
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"slackUsername"]) {
        
        [self uploadActiveEnergy];
        
    } else {
        [self showAddUsernameAlert];
    }
}
    
- (void)uploadActiveEnergy
    {

        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
        
        NSURL* URL = [NSURL URLWithString:@"http://adamr5.sg-host.com/adamrz/myfirstbot/api/active_goal/"];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";

        [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        
        NSDictionary* bodyObject = @{
                                     @"currentPoints": self.totalEnergyBurnedForTheWeek,
                                     @"slackUsername": [[NSUserDefaults standardUserDefaults] valueForKey:@"slackUsername"],
                                     @"timeStamp": @([@([[NSDate date] timeIntervalSince1970]) integerValue])
                                     };
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyObject options:kNilOptions error:NULL];
        
        /* Start a new Task */
        NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error == nil) {
                // Success
                if (((NSHTTPURLResponse*)response).statusCode == [@(200) integerValue]) {
                    //[[NSUserDefaults standardUserDefaults] setObject:self.slackUsernameTextField.text forKey:@"slackUsername"];
                    //[[NSUserDefaults standardUserDefaults] synchronize];
                } else if (((NSHTTPURLResponse*)response).statusCode == [@(400) integerValue]) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showIncorrectSlackUsernameAlert];
                    });
                }
                NSLog(@"Energy Sync Succeeded: HTTP %ld", ((NSHTTPURLResponse*)response).statusCode);
            }
            else {
                // Failure
                NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                //  show overlay, spinner, disable sync button and tableView, slackTextField

                
            });
        }];
        [task resume];
        [session finishTasksAndInvalidate];
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
                NSLog(@"URL Session Task Succeeded: HTTP %ld", ((NSHTTPURLResponse*)response).statusCode);
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
                        
                        
                        double goalDiff = [self.totalEnergyBurnedForTheWeek doubleValue] / [goal doubleValue];
                        
                        [self.remainingGoalLabel setText:[NSString stringWithFormat:@"%.0f%%", goalDiff * 100.0]];
                        
                        
                        NSDateFormatter *formatter = [NSDateFormatter new];
                        [formatter setDateFormat:@"YYYY-MM-d k:m:s"];
                        
                        NSDate *startDate = [formatter dateFromString:start];
                        NSDate *endDate = [formatter dateFromString:end];
                        
                        
                        NSInteger daysLeft = [ViewController daysBetweenDate:[NSDate date] andDate:endDate];
                        
                        [self.timeLeftLabel setText:[NSString stringWithFormat:@"%zd", daysLeft]];
                        
                        if (daysLeft == 1) {
                            [self.daysLabel setText:@"Day"];
                        } else {
                            [self.daysLabel setText:@"Days"];

                        }
                        
                        [[NSUserDefaults standardUserDefaults] setObject:goal forKey:@"goalPoints"];
                        [[NSUserDefaults standardUserDefaults] setObject:current forKey:@"currentPoints"];
                        [[NSUserDefaults standardUserDefaults] setObject:startDate forKey:@"goalStart"];
                        [[NSUserDefaults standardUserDefaults] setObject:endDate forKey:@"goalEnd"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                        if (self.sem != nil) {
                            dispatch_semaphore_signal(self.sem);

                        }
                        
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
    [self resignFirstResponder];
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

-(void)sessionDidBecomeInactive:(WCSession *)session {
    
}

-(void)sessionDidDeactivate:(WCSession *)session {
    
}

-(void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error {
    
}

-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    
    if ([[message valueForKey:@"getEnergy"] isEqualToString:@"yes"]) {
        self.sem = dispatch_semaphore_create(0);
        [self checkProgressAndGoals];
        dispatch_semaphore_wait(self.sem, DISPATCH_TIME_FOREVER);
        replyHandler(@{@"goal":[[NSUserDefaults standardUserDefaults] objectForKey:@"goalPoints"], @"burned":self.totalEnergyBurnedForTheWeek});
    }
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
    
-(IBAction)unwindToHome:(UIStoryboardSegue *)segue {
        
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
        
        [cell.detailTextLabel setText:[[source mutableCopy] stringByAppendingString:[NSString stringWithFormat:@"%@", [dateString substringToIndex:dateString.length - 3]]]];
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

-(IBAction)sendEmail {
    // Email Subject
    NSString *emailTitle = @"FitBot Sync: Error Logs";
    
    NSError *err;
    NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/ActivityLog.txt"];
    
    NSString *messageBody = [NSString stringWithContentsOfFile:logPath
                                          usedEncoding:NSUTF8StringEncoding
                                                 error:&err];
    // To address
    NSArray *toRecipents = [NSArray arrayWithObject:@"bryan@rockmyworldmedia.com"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:nil];
    
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
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
