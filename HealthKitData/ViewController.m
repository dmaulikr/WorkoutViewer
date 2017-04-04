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
#import "AppDelegate.h"
@import UserNotifications;
@import WatchConnectivity;
#import "HealthKitData-Swift.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIView *collectionViewContainer;
@property (strong, nonatomic) NSString *slackUsername;
@property (strong, nonatomic) HealthKitFunctions *store;

@property (strong, nonatomic) IBOutlet CHIPageControlJaloro *pageControl;


@property (strong, nonatomic) IBOutlet UIButton *syncButton;
@property (strong, nonatomic) IBOutlet UIButton *showLogButton;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;



@property (strong, nonatomic) dispatch_semaphore_t sem;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.store = [[HealthKitFunctions alloc] init];
    self.store.healthStore = [HKHealthStore new];
    
    self.slackUsername = [[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePage:) name:@"changePage" object:nil];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bot"]];
    
    imageView.tintColor = [UIColor whiteColor];
    
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width / 2;
    imageView.frame = CGRectMake(self.view.center.x - width, self.view.center.y - width, width, width);
    imageView.center = self.view.center;
    
    [self.view insertSubview:imageView.viewForFirstBaselineLayout atIndex:0];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [HealthKitFunctions requestPermission:^(BOOL success, NSError *err) {
        if (success) {
            //[self refreshFeed:nil];
            [ViewController updateAllDataWithCompletion:^(BOOL success, NSMutableDictionary *stats, NSError *error) {
                
if (success && (stats[@"current"] != nil)) {
    dispatch_async(dispatch_get_main_queue(), ^{

       //  update UI
        NSInteger days = [ViewController daysBetweenDate:[NSDate date] andDate:stats[@"end"]];
        int goalPercentage = [@(([stats[@"current"] doubleValue] / [stats[@"goal"] doubleValue]) * 100.0) intValue];
        
        [stats setObject:@(days) forKey:@"daysLeft"];
        [stats setObject:@(goalPercentage) forKey:@"goalPercentage"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setStats" object:stats];
        
        [self.spinner stopAnimating];
        
    });
} else {
     dispatch_async(dispatch_get_main_queue(), ^{
         [self.spinner stopAnimating];
     });
}
                
            }];
        }
    }];
    
    if (self.slackUsername == nil) {
        [self showAddUsernameAlert];
    }
}

-(void)showAddUsernameAlert {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Add your Slack username to Sync Data"
                                                                   message:@"ex: \"adamrz\""
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"slack username";
        textField.textColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Do it." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alert.textFields;
        UITextField * usernameField = textfields[0];
        NSLog(@"Slack Username: %@",usernameField.text);
        
        if (usernameField.text.length > 1) {
            [[NSUserDefaults standardUserDefaults] setObject:[usernameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"slackUsername"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self syncWorkouts:nil];
        }
        
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)showLogPage:(id)sender {
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"scrollToLog" object:nil];
}

-(void)changePage:(NSNotification *)notification {
    [self.pageControl setProgress:[notification.object doubleValue]];
}

+(void)updateAllDataWithCompletion:(void(^)(BOOL success, NSMutableDictionary *stats, NSError *error))completion {
    [HealthKitFunctions getAllStepSamples:^(NSArray *stepSamples, NSError *err) {
        
            [AppDelegate checkStatus:^(BOOL success, NSDate *start, NSDate *end, NSNumber *points, NSNumber *goal, NSError *error) {
                
                if (success) {
                
                [[NSUserDefaults standardUserDefaults] setObject:points forKey:@"currentPoints"];
                [[NSUserDefaults standardUserDefaults] setObject:goal forKey:@"goal"];
                [[NSUserDefaults standardUserDefaults] setObject:end forKey:@"end"];
                [[NSUserDefaults standardUserDefaults] setObject:start forKey:@"goalStart"];
                
                [HealthKitFunctions getAllEnergyWithoutWatchOrHumanAndSortFromStepSamples:[stepSamples mutableCopy] withCompletion:^(NSNumber *cals, NSNumber* other, NSNumber* today, NSError *err) {
                    
                    [[NSUserDefaults standardUserDefaults] setObject:today forKey:@"today"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    NSMutableDictionary *stats = [@{@"start":start, @"end":end, @"current":@([cals integerValue]), @"other": other,@"goal":goal, @"today": @([today integerValue])} mutableCopy];
                    
                    if (success && ([cals doubleValue] > [points doubleValue])) {
                        [AppDelegate uploadEnergyWithStats:stats withCompletion:^(BOOL success, NSError *err) {
                            if (success) {
                                [AppDelegate updateWatchComplication:@{@"currentPoints":@([cals integerValue]), @"goalPoints":goal, @"today": @([today integerValue])}];
                                completion(YES, stats, nil);
                            } else {
                                completion(NO, nil, err);
                            }
                        }];
                    } else {
                        [AppDelegate logBackgroundDataToFileWithStats:@{} message:@"Query was run but the calculated and existing calories were the same. No Sync was sent." time:[NSDate date]];
                        completion(YES, stats, err);
                    }
                }];
                } else {
                    completion(NO, nil, err);
                }
            }];
    }];
}

- (IBAction)refreshFeed:(id)sender {

    dispatch_async(dispatch_get_main_queue(), ^{
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.spinner.center = CGPointMake(self.view.center.x, self.view.center.y);
        
        [self.view addSubview:self.spinner];
        
        [self.spinner startAnimating];
    });
}

-(void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Register Health Kit

- (IBAction)syncWorkouts:(id)sender {
    
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"slackUsername"]) {

        
        [ViewController updateAllDataWithCompletion:^(BOOL success, NSMutableDictionary *stats, NSError *error) {
            if (success && (stats[@"current"] != nil)) {
                NSLog(@"Updated and loaded new data");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"setStats" object:stats];
            } else {
                [self showAddUsernameAlert];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.spinner stopAnimating];

            });
        }];
        
    } else {
        [self showAddUsernameAlert];
    }
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

@end
