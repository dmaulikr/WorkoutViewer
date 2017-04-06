//
//  DataCollectionViewController.m
//  HealthKitData
//
//  Created by Bryan Gula on 3/7/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import "DataCollectionViewController.h"
#import "SourcesCollectionViewCell.h"
#import "SourceTableViewCell.h"
#import "LogsCollectionViewCell.h"
#import "WorkoutsCollectionViewCell.h"
#import "HealthKitFunctions.h"
#import "AppDelegate.h"
#import <HealthKit/HealthKit.h>
#import "WorkoutTableViewCell.h"
#import "ViewController.h"
#import "HealthKitData-Swift.h"
#import "CollectionViewHeader.h"
#import "GraphCollectionViewCell.h"
#import "LeaderboardCollectionViewCell.h"
#import "LeaderboardTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "Chameleon.h"

@interface DataCollectionViewController ()

@property (strong, nonatomic) NSMutableDictionary *stats;
@property (strong, nonatomic) NSMutableDictionary *threeMonthStepCounts;
@property (strong, nonatomic) NSMutableDictionary *oneMonthStepCounts;
@property (strong, nonatomic) NSMutableDictionary *oneWeekStepCounts;
@property (strong, nonatomic) NSMutableDictionary *leaderboard;
@property (strong, nonatomic) NSMutableArray *sortedPercentages;
@property (strong, nonatomic) NSMutableDictionary *fullStats;

@property (strong, nonatomic) NSMutableDictionary *filteredSources;
@property (strong, nonatomic) NSMutableArray *workouts;
@property (strong, nonatomic) WavesLoader*loader;
@property (strong, nonatomic) NSNumber *dayWeekOrMonth;
@property (strong, nonatomic) NSMutableArray *sortedKeys;
@property (strong, nonatomic) NSMutableArray *sortedValues;

@end

@implementation DataCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.loader = [WavesLoader createLoaderWith:[DataCollectionViewController getRMWLogoBezierPath].CGPath on:self.collectionView.viewForFirstBaselineLayout];
    self.loader.center = self.collectionView.viewForFirstBaselineLayout.center;
    self.loader.viewForFirstBaselineLayout.layer.cornerRadius = 8.0;
    self.loader.rectSize = ([UIScreen mainScreen].bounds.size.width * 0.75) / [DataCollectionViewController getRMWLogoBezierPath].bounds.size.width;
    self.loader.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.0];
    
    self.loader.loaderColor = [UIColor colorWithHexString:@"#305B70"];
    self.loader.loaderStrokeWidth = 0;
    self.loader.duration = 1.5;
    
    self.dayWeekOrMonth = @(2);
    
    self.threeMonthStepCounts = [NSMutableDictionary new];
    self.oneMonthStepCounts = [NSMutableDictionary new];
    self.oneWeekStepCounts = [NSMutableDictionary new];
    self.leaderboard = [NSMutableDictionary new];
    self.fullStats = [NSMutableDictionary new];
    self.sortedPercentages = [NSMutableArray new];


    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setStatsDictionary:) name:@"setStats" object:nil];
    
    self.collectionView.delegate = self;

    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    
    [HealthKitFunctions requestPermission:^(BOOL success, NSError *err) {
        if (success) {
            [self.loader showLoader];
            [HealthKitFunctions getDailyStepsForLast3MonthsWithCompletion:^(NSMutableDictionary *steps, NSError *err) {
                if (!err) {
                    [self.threeMonthStepCounts setDictionary:steps];
                    self.sortedKeys = [[self.threeMonthStepCounts.allKeys sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
                    self.sortedValues = [[self.threeMonthStepCounts objectsForKeys:self.sortedKeys notFoundMarker:[NSNull null]] mutableCopy];
                    [self reloadGraphView:@(2)];
                    [self getCurrentLeaderboardWithCompletion:^(NSMutableDictionary *stats, NSError *err) {
                        
                        self.sortedPercentages = [[[stats[@"sortedPercentage"] reverseObjectEnumerator] allObjects] mutableCopy];
                        self.leaderboard = stats[@"leaderboard"];
                        self.fullStats = stats[@"fullStats"];
                        
                        for (UICollectionViewCell *c in self.collectionView.visibleCells) {
                            if ([c isKindOfClass:[SourcesCollectionViewCell class]]) {
                                SourcesCollectionViewCell *sourceCell = (SourcesCollectionViewCell *)c;
                                UICollectionView *overviewCollectionView = sourceCell.overviewCollectionView;
                                for (UICollectionViewCell *o in overviewCollectionView.visibleCells) {
                                    if ([o isKindOfClass:[LeaderboardCollectionViewCell class]]) {
                                        LeaderboardCollectionViewCell *leaderboardCell = (LeaderboardCollectionViewCell *)o;
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self.loader removeLoader:YES];
                                            [leaderboardCell.rankTableView reloadData];
                                        });
                                    }
                                }
                            }
                        }
                    }];
                }
            }];
        }
    }];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)reloadGraphView:(NSNumber*)number {
    
    for (UICollectionViewCell *c in self.collectionView.visibleCells) {
        
        if ([c isKindOfClass:[SourcesCollectionViewCell class]]) {
            SourcesCollectionViewCell *sourceCell = (SourcesCollectionViewCell *)c;
            UICollectionView *overviewCollectionView = sourceCell.overviewCollectionView;
            
            self.dayWeekOrMonth = number;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                GraphCollectionViewCell *cell = (GraphCollectionViewCell *)[overviewCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                
                NSArray *finalKeys = self.sortedKeys;
                NSArray *finalValues = self.sortedValues;
                
                if (self.sortedKeys.count > 0) {
                    if ([self.dayWeekOrMonth isEqualToNumber:@(1)]) { //month
                        finalKeys = [self.sortedKeys subarrayWithRange:NSMakeRange(self.sortedKeys.count - 31, 31)];
                        finalValues = [self.sortedValues subarrayWithRange:NSMakeRange(self.sortedKeys.count - 31, 31)];
                        
                    } else if ([self.dayWeekOrMonth isEqualToNumber:@(2)]) { //week
                        finalKeys = [self.sortedKeys subarrayWithRange:NSMakeRange(self.sortedKeys.count - 7, 7)];
                        finalValues = [self.sortedValues subarrayWithRange:NSMakeRange(self.sortedKeys.count - 7, 7)];
                        
                    } else if ([self.dayWeekOrMonth isEqualToNumber:@(0)]) { // all
                        finalKeys = self.sortedKeys;
                        finalValues = self.sortedValues;
                    }
                    
                    [cell.segmentedController moveTo:[number integerValue]];
                    [cell resetGraph:finalValues yValues:finalKeys];
                }
            });
        }
    }
}

-(void)setStatsDictionary:(NSNotification *)notification {
    self.stats = notification.object;
    
    for (UICollectionViewCell *c in self.collectionView.visibleCells) {
        
        if ([c isKindOfClass:[SourcesCollectionViewCell class]]) {
            SourcesCollectionViewCell *sourceCell = (SourcesCollectionViewCell *)c;
            UICollectionView *overviewCollectionView = sourceCell.overviewCollectionView;
            
            CollectionViewHeader *headerCell = (CollectionViewHeader*)[overviewCollectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

            dispatch_async(dispatch_get_main_queue(), ^{
                [headerCell.currentPointsLabel setText:[NSString stringWithFormat:@"%.0f Cals", ([self.stats[@"current"] doubleValue] + [self.stats[@"other"] doubleValue])]];
                
                NSDateFormatter *formatter = [NSDateFormatter new];
                [formatter setDateStyle:NSDateFormatterShortStyle];
                [formatter setTimeStyle:NSDateFormatterShortStyle];
                
                NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastSyncDate"];
                NSString *lastSyncDateString = [formatter stringFromDate:lastSyncDate];
                [headerCell.lastSyncLabel setText:[NSString stringWithFormat:@"Last Sync was %@", lastSyncDateString]];
                
                if (self.stats[@"goalPercentage"]) {
                    
                }
            });
        }
    }
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView.tag == 2) { // Sources CollectionViewCell
        return 2;
    } else {
        return 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = @"workouts";
    
    collectionView.delegate = self;
    
    // dont forget to set ALPHA OF CELL BACK TO ONE
    
    if (collectionView.tag == 2) {
        
        ((UICollectionViewFlowLayout*)collectionView.collectionViewLayout).sectionHeadersPinToVisibleBounds = YES;
        
        if (indexPath.row == 0) {
            
            GraphCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"graph" forIndexPath:indexPath];
            cell.segmentedController.delegate = self;
            [self reloadGraphView:@(1)];
            
            return cell;
            
        } else if (indexPath.row == 1) {
            
            LeaderboardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"leaderboard" forIndexPath:indexPath];
            cell.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            cell.alpha = 1.0;
            
            cell.rankTableView.tag = 3;
            cell.rankTableView.rowHeight = 60;
            cell.rankTableView.delegate = self;
            cell.rankTableView.dataSource = self;
            cell.backgroundColor = [UIColor clearColor];
            
            return cell;
        }
        
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"graph" forIndexPath:indexPath];

        cell.alpha = 0.0;
        
        return cell;
    }
        
    if (indexPath.row == 0) {
        identifier = @"sources";
        SourcesCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        [cell.overviewCollectionView setBackgroundColor:[UIColor clearColor]];
        cell.overviewCollectionView.tag = 2;
        cell.overviewCollectionView.allowsSelection = YES;
        cell.overviewCollectionView.delegate = self;
        cell.overviewCollectionView.dataSource = self;
        
        return cell;
    } else if (indexPath.row == 1) {
        identifier = @"workouts";
        WorkoutsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        cell.tableView.tag = 2;
        cell.tableView.delegate = self;
        cell.tableView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        return cell;
    } else if (indexPath.row == 2) {
        identifier = @"logs";
        return [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    }

    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.layer.borderColor = [UIColor whiteColor].CGColor;
    
    return cell;
    
}

-(void)didSelect:(NSInteger)segmentIndex {
    [self reloadGraphView:@(segmentIndex)];
}


-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if (kind == UICollectionElementKindSectionHeader) {
        CollectionViewHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
        
        NSString *username = [DataCollectionViewController getFirstNameForSlackUsername:[[NSUserDefaults standardUserDefaults] objectForKey:@"slackUsername"]];
        
        if (!username) {
            [header.titleHeaderMessageLabel setText:@"FitBot + Me"];
        } else {
            [header.titleHeaderMessageLabel setText:[NSString stringWithFormat:@"%@ + FitBot", username]];
        }
        
        [header.currentPointsLabel setText:[NSString stringWithFormat:@"%.0f Cals", ([self.stats[@"current"] doubleValue])]];

        
        header.currentPointsLabel.layer.shadowOpacity = 1.0;
        header.currentPointsLabel.layer.shadowRadius = 0.0;
        header.currentPointsLabel.layer.shadowColor = [UIColor darkGrayColor].CGColor;
        header.currentPointsLabel.layer.shadowOffset = CGSizeMake(1.0, 1.0);
        return header;
    }
    
    return nil;
}

-(void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// this just calculates the percentages now and passes it off to another method.
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // vertical
    CGFloat maximumVerticalOffset = scrollView.contentSize.height - CGRectGetHeight(scrollView.frame);
    CGFloat currentVerticalOffset = scrollView.contentOffset.y;
    
    // horizontal
    CGFloat maximumHorizontalOffset = scrollView.contentSize.width - CGRectGetWidth(scrollView.frame);
    CGFloat currentHorizontalOffset = scrollView.contentOffset.x;
    
    // percentages
    CGFloat percentageHorizontalOffset = currentHorizontalOffset / maximumHorizontalOffset;
    CGFloat percentageVerticalOffset = currentVerticalOffset / maximumVerticalOffset;
    
    [self scrollView:scrollView didScrollToPercentageOffset:CGPointMake(percentageHorizontalOffset, percentageVerticalOffset)];
}

// this just gets the percentage offset.
// 0,0 = no scroll
// 1,1 = maximum scroll
- (void)scrollView:(UIScrollView *)scrollView didScrollToPercentageOffset:(CGPoint)percentageOffset
{

    for (UICollectionViewCell *c in self.collectionView.visibleCells) {
        
        if ([c isKindOfClass:[SourcesCollectionViewCell class]]) {
            SourcesCollectionViewCell *sourceCell = (SourcesCollectionViewCell *)c;
            UICollectionView *overviewCollectionView = sourceCell.overviewCollectionView;
            overviewCollectionView.delegate = self;
            overviewCollectionView.dataSource = self;
            
            CollectionViewHeader *headerCell = (CollectionViewHeader*)[overviewCollectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [headerCell.lastSyncLabel setTextColor:[UIColor whiteColor]];
                
                if (percentageOffset.y > -0.1) {
                    
                    float offset = fabs(percentageOffset.y) * 6.5;
                    if (fabs(percentageOffset.y) < 0.001) {
                        NSLog(@"Updating");
                        NSDateFormatter *formatter = [NSDateFormatter new];
                        [formatter setDateStyle:NSDateFormatterShortStyle];
                        [formatter setTimeStyle:NSDateFormatterShortStyle];
                        
                        NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastSyncDate"];
                        NSString *lastSyncDateString = [formatter stringFromDate:lastSyncDate];
                        [headerCell.lastSyncLabel setText:[NSString stringWithFormat:@"Last Sync was %@", lastSyncDateString]];
                    }

                    [headerCell setBackgroundColor:[[UIColor colorWithHexString:@"#222E40"] colorWithAlphaComponent:percentageOffset.y * 6.5]];
                    
                    [headerCell.lastSyncLabel setAlpha:offset];
                }
            });
        }
    }
}

#pragma mark <UICollectionViewDelegate>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)) {
        if (collectionView.tag == 2) {
            return CGSizeMake(self.collectionView.frame.size.width - 20 , self.collectionView.frame.size.height / 4);
        } else {
            return CGSizeMake(self.collectionView.frame.size.width /2 , self.collectionView.frame.size.height / 2);

        }
    } else {
        if (collectionView.tag == 2) {
            if (indexPath.row == 1 && indexPath.section == 0) {
                return CGSizeMake(self.collectionView.frame.size.width - 20, 940);
            } else if (indexPath.row == 2 && indexPath.section == 0) {
                return CGSizeMake(self.collectionView.frame.size.width - 20, 150);
            } else {
                return CGSizeMake(self.collectionView.frame.size.width - 20, self.collectionView.frame.size.height / 3);
            }
        } else {
            return CGSizeMake(self.collectionView.frame.size.width, self.collectionView.frame.size.height);
        }
    }
}



-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
   [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self updateCollectionViewLayoutWithSize:size];
}

- (void)updateCollectionViewLayoutWithSize:(CGSize)size {
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.itemSize = (size.width < size.height) ? CGSizeMake(self.collectionView.frame.size.width , self.collectionView.frame.size.height) : CGSizeMake(self.collectionView.frame.size.width /2 , self.collectionView.frame.size.height);
    [layout invalidateLayout];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (collectionView.tag == 2 && [[collectionView cellForItemAtIndexPath:indexPath] isKindOfClass:[LeaderboardCollectionViewCell class]]) { // Here

        [self.loader showLoader];
    
        [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.loader removeLoader:YES];
                [self.loader removeFromSuperview];
                
            });
        }];
    }
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {

}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.tag == 3) {
        return self.sortedPercentages.count;
    } else if (tableView.tag == 2) {
        return 5;
    } else {
        return 0;
    }
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView.tag == 2) {
        
        WorkoutTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"workouts"];
        
        return cell;
        
    } else if (tableView.tag == 3) {

        [tableView setBackgroundColor:[[UIColor colorWithGradientStyle:UIGradientStyleTopToBottom withFrame:tableView.frame andColors:@[FlatRed, FlatYellow]] colorWithAlphaComponent:0.8]];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        LeaderboardTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"leaderboardCell"];
        cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.contentView.clipsToBounds = NO;

        
        [cell.contentView setBackgroundColor:[UIColor clearColor]];

        UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, 0, cell.contentView.bounds.size.height)];
        
        [colorView setBackgroundColor:cell.progressColorView.backgroundColor];
        [cell.progressColorView setBackgroundColor:[UIColor clearColor]];
        colorView.clipsToBounds = NO;
        
        [cell.contentView insertSubview:colorView atIndex:0];
        
        [cell.usernameLabel setBackgroundColor:[UIColor clearColor]];
        cell.userImageView.layer.cornerRadius = cell.userImageView.frame.size.height / 2.0;
        
        NSNumber *userKeyPercentage = self.sortedPercentages[indexPath.row];
        [cell.percentGoalLabel setText:[NSString stringWithFormat:@"%0.f%%", [userKeyPercentage doubleValue]]];
        [cell.usernameLabel setText:[self.leaderboard objectForKey:userKeyPercentage]];
        
        colorView.layer.shadowOpacity = 0.8;
        colorView.layer.shadowRadius = 0.0;
        colorView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
        colorView.layer.shadowOffset = CGSizeMake(2.0, 2.0);
        
        [cell.rankLabel setText:[@(indexPath.row + 1) stringValue]];
        
        [colorView setFrame:CGRectMake(cell.frame.size.width * ([userKeyPercentage floatValue] / 100.0), cell.frame.origin.y, cell.frame.size.width - (cell.frame.size.width * ([userKeyPercentage floatValue] / 100.0)), cell.contentView.bounds.size.height)];
        
        return cell;
    }
    
    return [tableView dequeueReusableCellWithIdentifier:@"source"];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView.tag == 1) {
        SourceTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell include:nil];
    }
}

+(NSString *)getFirstNameForSlackUsername:(NSString *)slackUsername {
    
    NSDictionary *names = @{
        @"gula":@"Bryan",
        @"aldenado": @"Alden",
        @"ericw": @"Eric",
        @"adamrz": @"Adam",
        @"satomi":@"Satomi",
        @"raymondcchan":@"Ray",
        @"kish26":@"Kishore",
        @"colby":@"Colby",
        @"djmthrasher":@"Marc",
        @"derek":@"Derek"
    };
    
    return names[slackUsername];
}

-(void)getCurrentLeaderboardWithCompletion:(void (^)(NSMutableDictionary *steps, NSError *err))completion {
    NSURL* URL = [NSURL URLWithString:@"https://fitbotdev.rockmyrun.com/v1/points/leaderboard/old"];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            
            NSError *err;
            // Success
            if (((NSHTTPURLResponse*)response).statusCode == 200) {
                NSArray *payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
                if (err) {
                    NSLog(@"Error Unencoding JSON for Leaderboard: %@", [err description]);
                } else {
                    //  Turn dates into NSDate start & end date
                    NSDateFormatter *formatter = [NSDateFormatter new];
                    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
                    [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
                    NSMutableArray *sortedPercentage = [NSMutableArray new];
                    NSMutableDictionary *leaderboard = [NSMutableDictionary new];
                    NSMutableDictionary *fullStats = [NSMutableDictionary new];
                    
                    for (NSDictionary *d in payload) {
                        NSString *fullName = [NSString stringWithFormat:@"%@ %@", d[@"first_name"], d[@"last_name"]];
                        NSString *trimName = [NSString stringWithFormat:@"%@ %@", d[@"first_name"], [d[@"last_name"] substringToIndex:1]];
                        NSString *firstName = d[@"first_name"];
                        NSString *lastName = d[@"last_name"];
                        NSDate *startDate = [formatter dateFromString:d[@"start_date"]];
                        NSDate *endDate = [formatter dateFromString:d[@"end_date"]];
                        NSNumber *goalPoints = d[@"goal_points"];
                        NSNumber *currentPoints = d[@"current_points"];
                        NSNumber *percentage = @(([currentPoints doubleValue] / [goalPoints doubleValue]) * 100.0);
                        
                        [leaderboard setObject:trimName forKey:percentage];
                        [fullStats setObject:@{@"":fullName,@"":trimName,@"firstName":firstName,@"lastName":lastName,@"startDate":startDate,@"endDate":endDate,@"goalPoints":goalPoints,@"currentPoints":currentPoints,@"percentage": percentage} forKey:fullName];
                        
                    }
                    
                    sortedPercentage = [[leaderboard.allKeys sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
                    completion([@{@"sortedPercentage":sortedPercentage, @"leaderboard":leaderboard, @"fullStats":fullStats} mutableCopy],nil);
                }
            }
        }
        else {
            // Failure
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
        }
    }];
    [task resume];
    [[NSURLSession sharedSession] finishTasksAndInvalidate];
}

+(UIBezierPath *)getRMWLogoBezierPath {

    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(82.28, 33.96)];
    [bezierPath addCurveToPoint: CGPointMake(82.64, 35.33) controlPoint1: CGPointMake(82, 34.44) controlPoint2: CGPointMake(82.16, 35.05)];
    [bezierPath addLineToPoint: CGPointMake(120.03, 57.1)];
    [bezierPath addLineToPoint: CGPointMake(99.75, 66.18)];
    [bezierPath addLineToPoint: CGPointMake(99.56, 50.62)];
    [bezierPath addCurveToPoint: CGPointMake(98.57, 49.63) controlPoint1: CGPointMake(99.56, 50.07) controlPoint2: CGPointMake(99.12, 49.63)];
    [bezierPath addCurveToPoint: CGPointMake(64.93, 49.72) controlPoint1: CGPointMake(98.57, 49.63) controlPoint2: CGPointMake(64.93, 49.72)];
    [bezierPath addCurveToPoint: CGPointMake(63.94, 50.71) controlPoint1: CGPointMake(64.38, 49.72) controlPoint2: CGPointMake(63.94, 50.16)];
    [bezierPath addLineToPoint: CGPointMake(63.91, 66.41)];
    [bezierPath addCurveToPoint: CGPointMake(61.44, 65.33) controlPoint1: CGPointMake(63.91, 66.41) controlPoint2: CGPointMake(62.94, 65.99)];
    [bezierPath addCurveToPoint: CGPointMake(43.93, 57.65) controlPoint1: CGPointMake(56.09, 62.98) controlPoint2: CGPointMake(43.93, 57.65)];
    [bezierPath addCurveToPoint: CGPointMake(50.46, 53.75) controlPoint1: CGPointMake(43.93, 57.65) controlPoint2: CGPointMake(46.66, 56.02)];
    [bezierPath addCurveToPoint: CGPointMake(70.74, 41.63) controlPoint1: CGPointMake(56.8, 49.96) controlPoint2: CGPointMake(66.12, 44.4)];
    [bezierPath addCurveToPoint: CGPointMake(72.67, 42.31) controlPoint1: CGPointMake(71.27, 42.06) controlPoint2: CGPointMake(71.94, 42.31)];
    [bezierPath addCurveToPoint: CGPointMake(75.75, 39.22) controlPoint1: CGPointMake(74.37, 42.31) controlPoint2: CGPointMake(75.75, 40.93)];
    [bezierPath addCurveToPoint: CGPointMake(72.67, 36.13) controlPoint1: CGPointMake(75.75, 37.51) controlPoint2: CGPointMake(74.37, 36.13)];
    [bezierPath addCurveToPoint: CGPointMake(70.74, 36.81) controlPoint1: CGPointMake(71.94, 36.13) controlPoint2: CGPointMake(71.27, 36.38)];
    [bezierPath addCurveToPoint: CGPointMake(69.59, 39.22) controlPoint1: CGPointMake(70.04, 37.38) controlPoint2: CGPointMake(69.59, 38.25)];
    [bezierPath addCurveToPoint: CGPointMake(69.68, 39.95) controlPoint1: CGPointMake(69.59, 39.47) controlPoint2: CGPointMake(69.62, 39.71)];
    [bezierPath addCurveToPoint: CGPointMake(49.06, 52.27) controlPoint1: CGPointMake(65.05, 42.72) controlPoint2: CGPointMake(55.76, 48.26)];
    [bezierPath addCurveToPoint: CGPointMake(41.25, 56.93) controlPoint1: CGPointMake(44.58, 54.95) controlPoint2: CGPointMake(41.25, 56.93)];
    [bezierPath addCurveToPoint: CGPointMake(40.77, 57.85) controlPoint1: CGPointMake(40.93, 57.12) controlPoint2: CGPointMake(40.75, 57.48)];
    [bezierPath addCurveToPoint: CGPointMake(41.36, 58.7) controlPoint1: CGPointMake(40.79, 58.23) controlPoint2: CGPointMake(41.02, 58.55)];
    [bezierPath addLineToPoint: CGPointMake(64.5, 68.85)];
    [bezierPath addCurveToPoint: CGPointMake(64.9, 68.93) controlPoint1: CGPointMake(64.63, 68.9) controlPoint2: CGPointMake(64.77, 68.93)];
    [bezierPath addCurveToPoint: CGPointMake(65.44, 68.77) controlPoint1: CGPointMake(65.09, 68.93) controlPoint2: CGPointMake(65.28, 68.88)];
    [bezierPath addCurveToPoint: CGPointMake(65.89, 67.93) controlPoint1: CGPointMake(65.72, 68.58) controlPoint2: CGPointMake(65.89, 68.27)];
    [bezierPath addLineToPoint: CGPointMake(65.92, 51.71)];
    [bezierPath addLineToPoint: CGPointMake(97.59, 51.63)];
    [bezierPath addLineToPoint: CGPointMake(97.78, 67.72)];
    [bezierPath addCurveToPoint: CGPointMake(98.23, 68.55) controlPoint1: CGPointMake(97.78, 68.05) controlPoint2: CGPointMake(97.95, 68.37)];
    [bezierPath addCurveToPoint: CGPointMake(99.17, 68.62) controlPoint1: CGPointMake(98.52, 68.73) controlPoint2: CGPointMake(98.87, 68.75)];
    [bezierPath addLineToPoint: CGPointMake(122.61, 58.13)];
    [bezierPath addCurveToPoint: CGPointMake(123.2, 57.27) controlPoint1: CGPointMake(122.95, 57.98) controlPoint2: CGPointMake(123.18, 57.64)];
    [bezierPath addCurveToPoint: CGPointMake(122.7, 56.35) controlPoint1: CGPointMake(123.22, 56.9) controlPoint2: CGPointMake(123.03, 56.54)];
    [bezierPath addLineToPoint: CGPointMake(83.63, 33.6)];
    [bezierPath addCurveToPoint: CGPointMake(82.28, 33.96) controlPoint1: CGPointMake(83.16, 33.32) controlPoint2: CGPointMake(82.55, 33.49)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(165, 59.72)];
    [bezierPath addCurveToPoint: CGPointMake(158.52, 66.23) controlPoint1: CGPointMake(165, 63.32) controlPoint2: CGPointMake(162.1, 66.23)];
    [bezierPath addCurveToPoint: CGPointMake(154.61, 64.91) controlPoint1: CGPointMake(157.05, 66.23) controlPoint2: CGPointMake(155.7, 65.74)];
    [bezierPath addLineToPoint: CGPointMake(143.1, 69.99)];
    [bezierPath addLineToPoint: CGPointMake(143.1, 107.01)];
    [bezierPath addLineToPoint: CGPointMake(150.43, 103.33)];
    [bezierPath addCurveToPoint: CGPointMake(150.41, 102.82) controlPoint1: CGPointMake(150.42, 103.16) controlPoint2: CGPointMake(150.41, 102.99)];
    [bezierPath addCurveToPoint: CGPointMake(156.89, 96.31) controlPoint1: CGPointMake(150.41, 99.22) controlPoint2: CGPointMake(153.31, 96.31)];
    [bezierPath addCurveToPoint: CGPointMake(163.38, 102.82) controlPoint1: CGPointMake(160.48, 96.31) controlPoint2: CGPointMake(163.38, 99.22)];
    [bezierPath addCurveToPoint: CGPointMake(156.89, 109.33) controlPoint1: CGPointMake(163.38, 106.42) controlPoint2: CGPointMake(160.48, 109.33)];
    [bezierPath addCurveToPoint: CGPointMake(152.99, 108.01) controlPoint1: CGPointMake(155.43, 109.33) controlPoint2: CGPointMake(154.08, 108.84)];
    [bezierPath addLineToPoint: CGPointMake(143.1, 112.82)];
    [bezierPath addLineToPoint: CGPointMake(143.1, 129.86)];
    [bezierPath addCurveToPoint: CGPointMake(136.73, 133.5) controlPoint1: CGPointMake(143.1, 129.86) controlPoint2: CGPointMake(140.23, 131.5)];
    [bezierPath addCurveToPoint: CGPointMake(134.75, 134.63) controlPoint1: CGPointMake(136.09, 133.87) controlPoint2: CGPointMake(135.42, 134.25)];
    [bezierPath addCurveToPoint: CGPointMake(124.37, 140.56) controlPoint1: CGPointMake(129.75, 137.49) controlPoint2: CGPointMake(124.37, 140.56)];
    [bezierPath addLineToPoint: CGPointMake(131.58, 146.49)];
    [bezierPath addCurveToPoint: CGPointMake(134.33, 145.87) controlPoint1: CGPointMake(132.42, 146.09) controlPoint2: CGPointMake(133.35, 145.87)];
    [bezierPath addCurveToPoint: CGPointMake(140.81, 152.38) controlPoint1: CGPointMake(137.91, 145.87) controlPoint2: CGPointMake(140.81, 148.78)];
    [bezierPath addCurveToPoint: CGPointMake(134.33, 158.89) controlPoint1: CGPointMake(140.81, 155.97) controlPoint2: CGPointMake(137.91, 158.89)];
    [bezierPath addCurveToPoint: CGPointMake(127.84, 152.38) controlPoint1: CGPointMake(130.75, 158.89) controlPoint2: CGPointMake(127.84, 155.97)];
    [bezierPath addCurveToPoint: CGPointMake(128.12, 150.51) controlPoint1: CGPointMake(127.84, 151.73) controlPoint2: CGPointMake(127.94, 151.1)];
    [bezierPath addLineToPoint: CGPointMake(119.43, 143.38)];
    [bezierPath addCurveToPoint: CGPointMake(119.43, 143.38) controlPoint1: CGPointMake(119.46, 143.41) controlPoint2: CGPointMake(119.45, 143.4)];
    [bezierPath addCurveToPoint: CGPointMake(109.7, 135.38) controlPoint1: CGPointMake(119.01, 143.04) controlPoint2: CGPointMake(114.77, 139.55)];
    [bezierPath addCurveToPoint: CGPointMake(134.75, 121.17) controlPoint1: CGPointMake(121.6, 128.63) controlPoint2: CGPointMake(134.75, 121.17)];
    [bezierPath addLineToPoint: CGPointMake(134.75, 134.63)];
    [bezierPath addLineToPoint: CGPointMake(136.73, 133.5)];
    [bezierPath addLineToPoint: CGPointMake(136.73, 119.46)];
    [bezierPath addCurveToPoint: CGPointMake(136.24, 118.6) controlPoint1: CGPointMake(136.73, 119.1) controlPoint2: CGPointMake(136.54, 118.78)];
    [bezierPath addCurveToPoint: CGPointMake(135.63, 118.47) controlPoint1: CGPointMake(136.05, 118.49) controlPoint2: CGPointMake(135.84, 118.44)];
    [bezierPath addCurveToPoint: CGPointMake(135.25, 118.59) controlPoint1: CGPointMake(135.5, 118.48) controlPoint2: CGPointMake(135.37, 118.52)];
    [bezierPath addCurveToPoint: CGPointMake(108.05, 134.02) controlPoint1: CGPointMake(135.25, 118.59) controlPoint2: CGPointMake(120.75, 126.82)];
    [bezierPath addCurveToPoint: CGPointMake(91.28, 120.23) controlPoint1: CGPointMake(100.24, 127.6) controlPoint2: CGPointMake(91.28, 120.23)];
    [bezierPath addLineToPoint: CGPointMake(91.28, 87.22)];
    [bezierPath addLineToPoint: CGPointMake(143.19, 64.17)];
    [bezierPath addCurveToPoint: CGPointMake(152.06, 60.23) controlPoint1: CGPointMake(144.11, 63.74) controlPoint2: CGPointMake(152.06, 60.23)];
    [bezierPath addCurveToPoint: CGPointMake(152.03, 59.72) controlPoint1: CGPointMake(152.04, 60.06) controlPoint2: CGPointMake(152.03, 59.89)];
    [bezierPath addCurveToPoint: CGPointMake(158.52, 53.21) controlPoint1: CGPointMake(152.03, 56.13) controlPoint2: CGPointMake(154.93, 53.21)];
    [bezierPath addCurveToPoint: CGPointMake(165, 59.72) controlPoint1: CGPointMake(162.1, 53.21) controlPoint2: CGPointMake(165, 56.13)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(81.74, 56.22)];
    [bezierPath addCurveToPoint: CGPointMake(77.92, 56.89) controlPoint1: CGPointMake(80.4, 56.22) controlPoint2: CGPointMake(79.11, 56.46)];
    [bezierPath addCurveToPoint: CGPointMake(70.52, 67.49) controlPoint1: CGPointMake(73.6, 58.46) controlPoint2: CGPointMake(70.52, 62.61)];
    [bezierPath addCurveToPoint: CGPointMake(81.74, 78.76) controlPoint1: CGPointMake(70.52, 73.71) controlPoint2: CGPointMake(75.55, 78.76)];
    [bezierPath addCurveToPoint: CGPointMake(92.97, 67.49) controlPoint1: CGPointMake(87.94, 78.76) controlPoint2: CGPointMake(92.97, 73.71)];
    [bezierPath addCurveToPoint: CGPointMake(81.74, 56.22) controlPoint1: CGPointMake(92.97, 61.26) controlPoint2: CGPointMake(87.94, 56.22)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(134.49, 76.46)];
    [bezierPath addCurveToPoint: CGPointMake(133.5, 77.46) controlPoint1: CGPointMake(133.94, 76.46) controlPoint2: CGPointMake(133.5, 76.91)];
    [bezierPath addLineToPoint: CGPointMake(133.5, 108.39)];
    [bezierPath addLineToPoint: CGPointMake(109.02, 122.39)];
    [bezierPath addCurveToPoint: CGPointMake(101.78, 116.54) controlPoint1: CGPointMake(109.02, 122.39) controlPoint2: CGPointMake(103.99, 118.33)];
    [bezierPath addCurveToPoint: CGPointMake(100.76, 115.71) controlPoint1: CGPointMake(101.16, 116.03) controlPoint2: CGPointMake(100.76, 115.71)];
    [bezierPath addCurveToPoint: CGPointMake(100.76, 115.37) controlPoint1: CGPointMake(100.76, 115.71) controlPoint2: CGPointMake(100.76, 115.59)];
    [bezierPath addCurveToPoint: CGPointMake(100.76, 93.58) controlPoint1: CGPointMake(100.76, 112.58) controlPoint2: CGPointMake(100.76, 93.58)];
    [bezierPath addLineToPoint: CGPointMake(117.28, 86.15)];
    [bezierPath addCurveToPoint: CGPointMake(117.28, 97.81) controlPoint1: CGPointMake(117.28, 86.15) controlPoint2: CGPointMake(117.28, 93.89)];
    [bezierPath addCurveToPoint: CGPointMake(115.22, 100.72) controlPoint1: CGPointMake(116.08, 98.23) controlPoint2: CGPointMake(115.22, 99.38)];
    [bezierPath addCurveToPoint: CGPointMake(118.3, 103.81) controlPoint1: CGPointMake(115.22, 102.43) controlPoint2: CGPointMake(116.6, 103.81)];
    [bezierPath addCurveToPoint: CGPointMake(121.38, 100.72) controlPoint1: CGPointMake(120, 103.81) controlPoint2: CGPointMake(121.38, 102.43)];
    [bezierPath addCurveToPoint: CGPointMake(119.26, 97.79) controlPoint1: CGPointMake(121.38, 99.35) controlPoint2: CGPointMake(120.49, 98.19)];
    [bezierPath addCurveToPoint: CGPointMake(119.26, 84.61) controlPoint1: CGPointMake(119.26, 93.52) controlPoint2: CGPointMake(119.26, 84.61)];
    [bezierPath addCurveToPoint: CGPointMake(118.81, 83.77) controlPoint1: CGPointMake(119.26, 84.27) controlPoint2: CGPointMake(119.09, 83.96)];
    [bezierPath addCurveToPoint: CGPointMake(117.86, 83.7) controlPoint1: CGPointMake(118.53, 83.59) controlPoint2: CGPointMake(118.17, 83.56)];
    [bezierPath addLineToPoint: CGPointMake(99.36, 92.03)];
    [bezierPath addCurveToPoint: CGPointMake(98.77, 92.94) controlPoint1: CGPointMake(99, 92.19) controlPoint2: CGPointMake(98.77, 92.54)];
    [bezierPath addCurveToPoint: CGPointMake(98.77, 113.11) controlPoint1: CGPointMake(98.77, 92.94) controlPoint2: CGPointMake(98.77, 106.78)];
    [bezierPath addCurveToPoint: CGPointMake(98.77, 116.19) controlPoint1: CGPointMake(98.77, 114.98) controlPoint2: CGPointMake(98.77, 116.19)];
    [bezierPath addCurveToPoint: CGPointMake(99.14, 116.97) controlPoint1: CGPointMake(98.77, 116.49) controlPoint2: CGPointMake(98.91, 116.78)];
    [bezierPath addLineToPoint: CGPointMake(108.3, 124.37)];
    [bezierPath addCurveToPoint: CGPointMake(108.92, 124.59) controlPoint1: CGPointMake(108.48, 124.52) controlPoint2: CGPointMake(108.7, 124.59)];
    [bezierPath addCurveToPoint: CGPointMake(109.42, 124.46) controlPoint1: CGPointMake(109.09, 124.59) controlPoint2: CGPointMake(109.26, 124.55)];
    [bezierPath addLineToPoint: CGPointMake(134.98, 109.83)];
    [bezierPath addCurveToPoint: CGPointMake(135.49, 108.97) controlPoint1: CGPointMake(135.29, 109.66) controlPoint2: CGPointMake(135.49, 109.33)];
    [bezierPath addLineToPoint: CGPointMake(135.49, 77.46)];
    [bezierPath addCurveToPoint: CGPointMake(134.49, 76.46) controlPoint1: CGPointMake(135.49, 76.91) controlPoint2: CGPointMake(135.04, 76.46)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(12.97, 60.25)];
    [bezierPath addCurveToPoint: CGPointMake(12.94, 60.76) controlPoint1: CGPointMake(12.97, 60.42) controlPoint2: CGPointMake(12.96, 60.59)];
    [bezierPath addCurveToPoint: CGPointMake(21.35, 64.47) controlPoint1: CGPointMake(12.94, 60.76) controlPoint2: CGPointMake(20.72, 64.19)];
    [bezierPath addCurveToPoint: CGPointMake(21.39, 64.49) controlPoint1: CGPointMake(21.38, 64.48) controlPoint2: CGPointMake(21.39, 64.49)];
    [bezierPath addCurveToPoint: CGPointMake(47.35, 76.06) controlPoint1: CGPointMake(21.35, 64.47) controlPoint2: CGPointMake(34.44, 70.3)];
    [bezierPath addCurveToPoint: CGPointMake(72.39, 87.22) controlPoint1: CGPointMake(59.95, 81.68) controlPoint2: CGPointMake(72.39, 87.22)];
    [bezierPath addCurveToPoint: CGPointMake(72.39, 116) controlPoint1: CGPointMake(72.39, 87.22) controlPoint2: CGPointMake(72.39, 107.11)];
    [bezierPath addCurveToPoint: CGPointMake(72.39, 120.21) controlPoint1: CGPointMake(72.39, 118.57) controlPoint2: CGPointMake(72.39, 120.21)];
    [bezierPath addCurveToPoint: CGPointMake(43.95, 143.54) controlPoint1: CGPointMake(72.39, 120.21) controlPoint2: CGPointMake(45.34, 142.4)];
    [bezierPath addCurveToPoint: CGPointMake(43.92, 143.57) controlPoint1: CGPointMake(43.95, 143.54) controlPoint2: CGPointMake(43.94, 143.55)];
    [bezierPath addCurveToPoint: CGPointMake(35.27, 150.74) controlPoint1: CGPointMake(43.16, 144.2) controlPoint2: CGPointMake(35.27, 150.74)];
    [bezierPath addCurveToPoint: CGPointMake(35.51, 152.45) controlPoint1: CGPointMake(35.42, 151.29) controlPoint2: CGPointMake(35.51, 151.86)];
    [bezierPath addCurveToPoint: CGPointMake(29.02, 158.97) controlPoint1: CGPointMake(35.51, 156.05) controlPoint2: CGPointMake(32.6, 158.97)];
    [bezierPath addCurveToPoint: CGPointMake(22.54, 152.45) controlPoint1: CGPointMake(25.44, 158.97) controlPoint2: CGPointMake(22.54, 156.05)];
    [bezierPath addCurveToPoint: CGPointMake(29.02, 145.94) controlPoint1: CGPointMake(22.54, 148.86) controlPoint2: CGPointMake(25.44, 145.94)];
    [bezierPath addCurveToPoint: CGPointMake(31.9, 146.63) controlPoint1: CGPointMake(30.06, 145.94) controlPoint2: CGPointMake(31.03, 146.19)];
    [bezierPath addLineToPoint: CGPointMake(39.09, 140.81)];
    [bezierPath addLineToPoint: CGPointMake(21.39, 130.86)];
    [bezierPath addLineToPoint: CGPointMake(21.39, 110.05)];
    [bezierPath addLineToPoint: CGPointMake(12, 105.89)];
    [bezierPath addCurveToPoint: CGPointMake(8.11, 107.2) controlPoint1: CGPointMake(10.92, 106.71) controlPoint2: CGPointMake(9.57, 107.2)];
    [bezierPath addCurveToPoint: CGPointMake(1.62, 100.69) controlPoint1: CGPointMake(4.52, 107.2) controlPoint2: CGPointMake(1.62, 104.29)];
    [bezierPath addCurveToPoint: CGPointMake(8.11, 94.18) controlPoint1: CGPointMake(1.62, 97.09) controlPoint2: CGPointMake(4.52, 94.18)];
    [bezierPath addCurveToPoint: CGPointMake(14.59, 100.69) controlPoint1: CGPointMake(11.69, 94.18) controlPoint2: CGPointMake(14.59, 97.09)];
    [bezierPath addCurveToPoint: CGPointMake(14.56, 101.21) controlPoint1: CGPointMake(14.59, 100.86) controlPoint2: CGPointMake(14.58, 101.04)];
    [bezierPath addLineToPoint: CGPointMake(21.39, 104.24)];
    [bezierPath addLineToPoint: CGPointMake(21.39, 70.3)];
    [bezierPath addLineToPoint: CGPointMake(10.39, 65.44)];
    [bezierPath addCurveToPoint: CGPointMake(6.48, 66.76) controlPoint1: CGPointMake(9.3, 66.27) controlPoint2: CGPointMake(7.95, 66.76)];
    [bezierPath addCurveToPoint: CGPointMake(0, 60.25) controlPoint1: CGPointMake(2.9, 66.76) controlPoint2: CGPointMake(0, 63.85)];
    [bezierPath addCurveToPoint: CGPointMake(6.48, 53.74) controlPoint1: CGPointMake(0, 56.65) controlPoint2: CGPointMake(2.9, 53.74)];
    [bezierPath addCurveToPoint: CGPointMake(12.97, 60.25) controlPoint1: CGPointMake(10.07, 53.74) controlPoint2: CGPointMake(12.97, 56.65)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(30.09, 78.42)];
    [bezierPath addCurveToPoint: CGPointMake(27.01, 81.51) controlPoint1: CGPointMake(28.39, 78.42) controlPoint2: CGPointMake(27.01, 79.8)];
    [bezierPath addCurveToPoint: CGPointMake(29.09, 84.43) controlPoint1: CGPointMake(27.01, 82.86) controlPoint2: CGPointMake(27.88, 84.02)];
    [bezierPath addCurveToPoint: CGPointMake(29.09, 90.59) controlPoint1: CGPointMake(29.09, 86.04) controlPoint2: CGPointMake(29.09, 88.16)];
    [bezierPath addCurveToPoint: CGPointMake(29.09, 125.61) controlPoint1: CGPointMake(29.09, 103.63) controlPoint2: CGPointMake(29.09, 125.61)];
    [bezierPath addCurveToPoint: CGPointMake(29.59, 126.47) controlPoint1: CGPointMake(29.09, 125.97) controlPoint2: CGPointMake(29.28, 126.3)];
    [bezierPath addLineToPoint: CGPointMake(42.73, 134.01)];
    [bezierPath addCurveToPoint: CGPointMake(43.22, 134.14) controlPoint1: CGPointMake(42.88, 134.1) controlPoint2: CGPointMake(43.05, 134.14)];
    [bezierPath addCurveToPoint: CGPointMake(43.85, 133.91) controlPoint1: CGPointMake(43.44, 134.14) controlPoint2: CGPointMake(43.67, 134.06)];
    [bezierPath addLineToPoint: CGPointMake(64.76, 116.68)];
    [bezierPath addCurveToPoint: CGPointMake(65.13, 115.91) controlPoint1: CGPointMake(64.99, 116.49) controlPoint2: CGPointMake(65.13, 116.21)];
    [bezierPath addLineToPoint: CGPointMake(65.13, 93.19)];
    [bezierPath addCurveToPoint: CGPointMake(64.54, 92.29) controlPoint1: CGPointMake(65.13, 92.8) controlPoint2: CGPointMake(64.9, 92.45)];
    [bezierPath addLineToPoint: CGPointMake(44.95, 83.37)];
    [bezierPath addCurveToPoint: CGPointMake(44, 83.44) controlPoint1: CGPointMake(44.64, 83.23) controlPoint2: CGPointMake(44.29, 83.25)];
    [bezierPath addCurveToPoint: CGPointMake(43.55, 84.27) controlPoint1: CGPointMake(43.72, 83.62) controlPoint2: CGPointMake(43.55, 83.94)];
    [bezierPath addCurveToPoint: CGPointMake(43.55, 111.55) controlPoint1: CGPointMake(43.55, 84.27) controlPoint2: CGPointMake(43.55, 105.82)];
    [bezierPath addCurveToPoint: CGPointMake(41.43, 114.49) controlPoint1: CGPointMake(42.32, 111.96) controlPoint2: CGPointMake(41.43, 113.12)];
    [bezierPath addCurveToPoint: CGPointMake(44.51, 117.58) controlPoint1: CGPointMake(41.43, 116.19) controlPoint2: CGPointMake(42.81, 117.58)];
    [bezierPath addCurveToPoint: CGPointMake(47.59, 114.49) controlPoint1: CGPointMake(46.21, 117.58) controlPoint2: CGPointMake(47.59, 116.19)];
    [bezierPath addCurveToPoint: CGPointMake(46.56, 112.18) controlPoint1: CGPointMake(47.59, 113.57) controlPoint2: CGPointMake(47.19, 112.74)];
    [bezierPath addCurveToPoint: CGPointMake(45.53, 111.57) controlPoint1: CGPointMake(46.26, 111.91) controlPoint2: CGPointMake(45.92, 111.7)];
    [bezierPath addCurveToPoint: CGPointMake(45.53, 85.82) controlPoint1: CGPointMake(45.53, 106.07) controlPoint2: CGPointMake(45.53, 85.82)];
    [bezierPath addLineToPoint: CGPointMake(63.14, 93.84)];
    [bezierPath addLineToPoint: CGPointMake(63.14, 115.44)];
    [bezierPath addLineToPoint: CGPointMake(43.12, 131.94)];
    [bezierPath addCurveToPoint: CGPointMake(42.29, 131.46) controlPoint1: CGPointMake(43.12, 131.94) controlPoint2: CGPointMake(42.81, 131.76)];
    [bezierPath addCurveToPoint: CGPointMake(31.08, 125.03) controlPoint1: CGPointMake(39.57, 129.9) controlPoint2: CGPointMake(31.08, 125.03)];
    [bezierPath addCurveToPoint: CGPointMake(31.08, 96.74) controlPoint1: CGPointMake(31.08, 125.03) controlPoint2: CGPointMake(31.08, 109.35)];
    [bezierPath addCurveToPoint: CGPointMake(31.08, 84.44) controlPoint1: CGPointMake(31.08, 91.79) controlPoint2: CGPointMake(31.08, 87.31)];
    [bezierPath addCurveToPoint: CGPointMake(33.17, 81.51) controlPoint1: CGPointMake(32.29, 84.02) controlPoint2: CGPointMake(33.17, 82.87)];
    [bezierPath addCurveToPoint: CGPointMake(32.17, 79.23) controlPoint1: CGPointMake(33.17, 80.6) controlPoint2: CGPointMake(32.79, 79.79)];
    [bezierPath addCurveToPoint: CGPointMake(30.09, 78.42) controlPoint1: CGPointMake(31.62, 78.72) controlPoint2: CGPointMake(30.89, 78.42)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(77.9, 135.56)];
    [bezierPath addCurveToPoint: CGPointMake(74.82, 138.66) controlPoint1: CGPointMake(76.2, 135.56) controlPoint2: CGPointMake(74.82, 136.95)];
    [bezierPath addCurveToPoint: CGPointMake(76.92, 141.59) controlPoint1: CGPointMake(74.82, 140.02) controlPoint2: CGPointMake(75.7, 141.17)];
    [bezierPath addCurveToPoint: CGPointMake(76.91, 152.61) controlPoint1: CGPointMake(76.91, 143.38) controlPoint2: CGPointMake(76.91, 146.63)];
    [bezierPath addCurveToPoint: CGPointMake(76.98, 153.52) controlPoint1: CGPointMake(76.91, 153.07) controlPoint2: CGPointMake(76.91, 153.29)];
    [bezierPath addCurveToPoint: CGPointMake(77.85, 154.13) controlPoint1: CGPointMake(77.12, 153.89) controlPoint2: CGPointMake(77.46, 154.13)];
    [bezierPath addLineToPoint: CGPointMake(77.95, 154.13)];
    [bezierPath addCurveToPoint: CGPointMake(78.82, 153.52) controlPoint1: CGPointMake(78.34, 154.13) controlPoint2: CGPointMake(78.69, 153.89)];
    [bezierPath addLineToPoint: CGPointMake(78.83, 153.48)];
    [bezierPath addCurveToPoint: CGPointMake(78.9, 152.61) controlPoint1: CGPointMake(78.9, 153.29) controlPoint2: CGPointMake(78.9, 153.07)];
    [bezierPath addCurveToPoint: CGPointMake(78.9, 141.58) controlPoint1: CGPointMake(78.9, 152.61) controlPoint2: CGPointMake(78.9, 144.86)];
    [bezierPath addCurveToPoint: CGPointMake(80.98, 138.66) controlPoint1: CGPointMake(80.11, 141.17) controlPoint2: CGPointMake(80.98, 140.01)];
    [bezierPath addCurveToPoint: CGPointMake(79.26, 135.88) controlPoint1: CGPointMake(80.98, 137.44) controlPoint2: CGPointMake(80.28, 136.38)];
    [bezierPath addCurveToPoint: CGPointMake(77.9, 135.56) controlPoint1: CGPointMake(78.85, 135.68) controlPoint2: CGPointMake(78.39, 135.56)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(104.12, 138.55)];
    [bezierPath addCurveToPoint: CGPointMake(113.87, 146.56) controlPoint1: CGPointMake(109.17, 142.7) controlPoint2: CGPointMake(113.45, 146.21)];
    [bezierPath addCurveToPoint: CGPointMake(90.86, 159.69) controlPoint1: CGPointMake(107.62, 150.12) controlPoint2: CGPointMake(97.5, 155.9)];
    [bezierPath addCurveToPoint: CGPointMake(90.86, 146.07) controlPoint1: CGPointMake(90.86, 159.66) controlPoint2: CGPointMake(90.86, 146.07)];
    [bezierPath addCurveToPoint: CGPointMake(104.12, 138.55) controlPoint1: CGPointMake(90.86, 146.07) controlPoint2: CGPointMake(96.7, 142.76)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(90.89, 7.26)];
    [bezierPath addCurveToPoint: CGPointMake(87.06, 13.2) controlPoint1: CGPointMake(90.89, 9.9) controlPoint2: CGPointMake(89.32, 12.18)];
    [bezierPath addLineToPoint: CGPointMake(87.06, 27.15)];
    [bezierPath addCurveToPoint: CGPointMake(141.56, 58.27) controlPoint1: CGPointMake(87.06, 27.15) controlPoint2: CGPointMake(132.52, 53.12)];
    [bezierPath addCurveToPoint: CGPointMake(87.08, 82.52) controlPoint1: CGPointMake(140.04, 58.95) controlPoint2: CGPointMake(87.08, 82.52)];
    [bezierPath addCurveToPoint: CGPointMake(85.3, 85.26) controlPoint1: CGPointMake(85.99, 83) controlPoint2: CGPointMake(85.3, 84.07)];
    [bezierPath addLineToPoint: CGPointMake(85.3, 121.66)];
    [bezierPath addCurveToPoint: CGPointMake(85.5, 122.74) controlPoint1: CGPointMake(85.3, 122.03) controlPoint2: CGPointMake(85.37, 122.4)];
    [bezierPath addCurveToPoint: CGPointMake(86.39, 123.98) controlPoint1: CGPointMake(85.68, 123.22) controlPoint2: CGPointMake(85.99, 123.65)];
    [bezierPath addCurveToPoint: CGPointMake(102.47, 137.19) controlPoint1: CGPointMake(86.39, 123.98) controlPoint2: CGPointMake(94.91, 130.98)];
    [bezierPath addCurveToPoint: CGPointMake(89.38, 144.62) controlPoint1: CGPointMake(95.08, 141.38) controlPoint2: CGPointMake(89.38, 144.62)];
    [bezierPath addCurveToPoint: CGPointMake(88.87, 145.49) controlPoint1: CGPointMake(89.07, 144.8) controlPoint2: CGPointMake(88.87, 145.13)];
    [bezierPath addLineToPoint: CGPointMake(88.87, 160.83)];
    [bezierPath addCurveToPoint: CGPointMake(89.74, 160.33) controlPoint1: CGPointMake(88.87, 160.83) controlPoint2: CGPointMake(89.29, 160.59)];
    [bezierPath addCurveToPoint: CGPointMake(88.87, 160.83) controlPoint1: CGPointMake(89.44, 160.5) controlPoint2: CGPointMake(89.15, 160.67)];
    [bezierPath addCurveToPoint: CGPointMake(84.27, 163.46) controlPoint1: CGPointMake(86.08, 162.42) controlPoint2: CGPointMake(84.27, 163.46)];
    [bezierPath addLineToPoint: CGPointMake(84.27, 174.55)];
    [bezierPath addCurveToPoint: CGPointMake(88.11, 180.49) controlPoint1: CGPointMake(86.53, 175.57) controlPoint2: CGPointMake(88.11, 177.84)];
    [bezierPath addCurveToPoint: CGPointMake(81.62, 187) controlPoint1: CGPointMake(88.11, 184.09) controlPoint2: CGPointMake(85.2, 187)];
    [bezierPath addCurveToPoint: CGPointMake(75.14, 180.49) controlPoint1: CGPointMake(78.04, 187) controlPoint2: CGPointMake(75.14, 184.09)];
    [bezierPath addCurveToPoint: CGPointMake(78.97, 174.55) controlPoint1: CGPointMake(75.14, 177.84) controlPoint2: CGPointMake(76.71, 175.57)];
    [bezierPath addLineToPoint: CGPointMake(78.97, 163.22)];
    [bezierPath addCurveToPoint: CGPointMake(49.6, 146.71) controlPoint1: CGPointMake(78.97, 163.22) controlPoint2: CGPointMake(59.5, 152.28)];
    [bezierPath addCurveToPoint: CGPointMake(77.27, 123.96) controlPoint1: CGPointMake(49.61, 146.72) controlPoint2: CGPointMake(77.27, 123.96)];
    [bezierPath addCurveToPoint: CGPointMake(78.37, 121.64) controlPoint1: CGPointMake(77.97, 123.39) controlPoint2: CGPointMake(78.37, 122.54)];
    [bezierPath addLineToPoint: CGPointMake(78.37, 85.26)];
    [bezierPath addCurveToPoint: CGPointMake(76.59, 82.52) controlPoint1: CGPointMake(78.37, 84.08) controlPoint2: CGPointMake(77.67, 83)];
    [bezierPath addCurveToPoint: CGPointMake(41.64, 66.94) controlPoint1: CGPointMake(76.59, 82.52) controlPoint2: CGPointMake(57.05, 73.81)];
    [bezierPath addCurveToPoint: CGPointMake(23.31, 58.77) controlPoint1: CGPointMake(31.68, 62.5) controlPoint2: CGPointMake(23.44, 58.83)];
    [bezierPath addCurveToPoint: CGPointMake(25.78, 57.32) controlPoint1: CGPointMake(23.98, 58.38) controlPoint2: CGPointMake(24.81, 57.89)];
    [bezierPath addCurveToPoint: CGPointMake(39.84, 49.01) controlPoint1: CGPointMake(29.14, 55.33) controlPoint2: CGPointMake(34.16, 52.36)];
    [bezierPath addCurveToPoint: CGPointMake(72.17, 29.9) controlPoint1: CGPointMake(50.51, 42.7) controlPoint2: CGPointMake(63.51, 35.02)];
    [bezierPath addCurveToPoint: CGPointMake(81.76, 24.24) controlPoint1: CGPointMake(77.92, 26.51) controlPoint2: CGPointMake(81.76, 24.24)];
    [bezierPath addLineToPoint: CGPointMake(81.76, 13.2)];
    [bezierPath addCurveToPoint: CGPointMake(77.92, 7.26) controlPoint1: CGPointMake(79.5, 12.18) controlPoint2: CGPointMake(77.92, 9.9)];
    [bezierPath addCurveToPoint: CGPointMake(77.97, 6.51) controlPoint1: CGPointMake(77.92, 7) controlPoint2: CGPointMake(77.94, 6.75)];
    [bezierPath addCurveToPoint: CGPointMake(84.41, 0.75) controlPoint1: CGPointMake(78.34, 3.27) controlPoint2: CGPointMake(81.08, 0.75)];
    [bezierPath addCurveToPoint: CGPointMake(90.89, 7.26) controlPoint1: CGPointMake(87.99, 0.75) controlPoint2: CGPointMake(90.89, 3.66)];
    [bezierPath closePath];
//    [fillColor5 setFill];
//    [bezierPath fill];

    // scale it
    CGFloat scale = ([UIScreen mainScreen].bounds.size.width * 0.75) / bezierPath.bounds.size.width;
    [bezierPath applyTransform:CGAffineTransformMakeScale(scale, scale)];
    
    // move it
    CGSize translation = CGSizeMake(scale, scale);
    [bezierPath applyTransform:CGAffineTransformMakeTranslation(translation.width,
                                                          translation.height)];
    
    return bezierPath;
}


@end
