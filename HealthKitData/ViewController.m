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

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIView *collectionViewContainer;
@property (strong, nonatomic) NSString *slackUsername;
@property (strong, nonatomic) HealthKitFunctions *store;
    
@property (weak, nonatomic) IBOutlet UILabel *remainingGoalLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLeftLabel;
@property (strong, nonatomic) IBOutlet UIButton *syncButton;
@property (strong, nonatomic) IBOutlet UIButton *showLogButton;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) IBOutlet UILabel *daysLabel;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;


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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePage:) name:@"changePage" object:nil];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [HealthKitFunctions requestPermission:^(BOOL success, NSError *err) {
        if (success) {
            [self refreshFeed:nil];
            [ViewController updateAllDataWithCompletion:^(BOOL success, NSMutableDictionary *stats, NSError *error) {
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{

                       //  update UI
                        NSInteger days = [ViewController daysBetweenDate:[NSDate date] andDate:stats[@"end"]];
                        int goalPercentage = [@(([stats[@"current"] doubleValue] / [stats[@"goal"] doubleValue]) * 100.0) intValue];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"setStats" object:stats];
                        
                        [self.timeLeftLabel setText:[@(days) stringValue]];
                        [self.remainingGoalLabel setText:[NSString stringWithFormat:@"%@%%", [@(goalPercentage) stringValue]]];
                        
                        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
                        // 200 is example side of the big view, but you can apply any formula to it. For example relative to superview, or screen bounds
                        CGFloat multiplier = 200 / MAX(self.remainingGoalLabel.frame.size.height, self.remainingGoalLabel.frame.size.width);
                        bounceAnimation.values =
                          @[@(1 - 0.1 * multiplier),
                            @(1 + 0.3 * multiplier),
                            @(1 + 0.1 * multiplier),
                            @1.0];
                            bounceAnimation.duration = 0.25;
                            bounceAnimation.removedOnCompletion = YES;
                            bounceAnimation.fillMode = kCAFillModeForwards;
                            [self.remainingGoalLabel.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
                            [self.timeLeftLabel.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
                        
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"scrollToLog" object:nil];
    [self.pageControl setCurrentPage:1];
}

-(void)changePage:(NSNotification *)notification {
    [self.pageControl setCurrentPage:[notification.object integerValue]];
}

+(void)updateAllDataWithCompletion:(void(^)(BOOL success, NSMutableDictionary *stats, NSError *error))completion {
    [HealthKitFunctions getAllStepSamples:^(NSArray *stepSamples, NSError *err) {
        
            [AppDelegate checkStatus:^(BOOL success, NSDate *start, NSDate *end, NSNumber *points, NSNumber *goal, NSError *error) {
                
                [HealthKitFunctions getAllEnergyWithoutWatchOrHumanAndSortFromStepSamples:[stepSamples mutableCopy] withCompletion:^(NSNumber *cals, NSNumber* other, NSError *err) {
                    
                    NSMutableDictionary *stats = [@{@"start":start, @"end":end, @"current":@([cals integerValue]), @"other": other,@"goal":goal} mutableCopy];
                    
                    if (success) {
                        [AppDelegate uploadEnergyWithStats:stats withCompletion:^(BOOL success, NSError *err) {
                            if (success) {
                                completion(YES, stats, nil);
                            } else {
                                completion(NO, nil, err);
                            }
                        }];
                    }
                }];
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.syncButton setAlpha:0.5];
            [self.syncButton setEnabled:NO];
            [self refreshFeed:nil];
        });
        
        [ViewController updateAllDataWithCompletion:^(BOOL success, NSMutableDictionary *stats, NSError *error) {
            if (success) {
                NSLog(@"Updated and loaded new data");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"setStats" object:stats];
            } else {
                [self showAddUsernameAlert];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.spinner stopAnimating];
                [self.syncButton setAlpha:1.0];
                [self.syncButton setEnabled:YES];
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
