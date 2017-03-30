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

@interface DataCollectionViewController ()

@property (strong, nonatomic) NSMutableDictionary *stats;
@property (strong, nonatomic) NSMutableArray *sources;
@property (strong, nonatomic) NSMutableDictionary *filteredSources;
@property (strong, nonatomic) NSMutableArray *workouts;

@end

@implementation DataCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calculateEnergyFromSources:) name:@"filterSources" object:nil];
    
    self.collectionView.delegate = self;

    
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveToLogPage) name:@"scrollToLog" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setStatsDictionary:) name:@"setStats" object:nil];
    
    [HealthKitFunctions getAllSources:^(NSMutableArray *sources, NSError *err) {
        if (err == nil) {
            self.sources = [NSMutableArray arrayWithArray:sources];
            
            
            
            for (UICollectionViewCell *c in self.collectionView.visibleCells) {
                if ([c isKindOfClass:[SourcesCollectionViewCell class]]) {
                    SourcesCollectionViewCell *cell = (SourcesCollectionViewCell *)c;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [cell.tableView reloadData];
                    });
                    
                }
            }
        }
    }];
    
    [HealthKitFunctions getAllEnergySeperatedBySource:^(HKStatistics *result, NSError *err) {
        NSLog(@"%@", result);
    }];
}

- (void)moveToLogPage {
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

-(void)setStatsDictionary:(NSNotification *)notification {
    self.stats = notification.object;
    
    for (UICollectionViewCell *c in self.collectionView.visibleCells) {
        
        if ([c isKindOfClass:[SourcesCollectionViewCell class]]) {
            SourcesCollectionViewCell *sourceCell = (SourcesCollectionViewCell *)c;
            UICollectionView *overviewCollectionView = sourceCell.overviewCollectionView;
            
            CollectionViewHeader *headerCell = (CollectionViewHeader*)[overviewCollectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

            dispatch_async(dispatch_get_main_queue(), ^{

                [headerCell.currentPointsLabel setText:[NSString stringWithFormat:@"You've earned %.0f MovePoints this week", ([self.stats[@"current"] doubleValue] + [self.stats[@"other"] doubleValue])]];
                
                [headerCell.lastSyncLabel setText:[NSString stringWithFormat:@"Last Sync was %0.fam Today", [@(arc4random_uniform(12.0)) doubleValue]]];
                
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
        return 5;
    } else {
        return 5;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = @"";
    
    // dont forget to set ALPHA OF CELL BACK TO ONE
    
    if (collectionView.tag == 2) {
        
        ((UICollectionViewFlowLayout*)collectionView.collectionViewLayout).sectionHeadersPinToVisibleBounds = YES;
        
        if (indexPath.row == 0) {
            
            GraphCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"graph" forIndexPath:indexPath];
            cell.alpha = 1.0;
            
            ScrollableGraphView *graphView = [[ScrollableGraphView alloc] initWithFrame:cell.contentView.bounds];
            graphView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            graphView.dataPointType = ScrollableGraphViewDataPointTypeCircle;
            graphView.shouldDrawBarLayer = YES;
            graphView.shouldDrawDataPoint = NO;
            graphView.dataPointSpacing = (cell.frame.size.width / 7) - 3;
            graphView.leftmostPointPadding = 60;
            
            graphView.lineColor = [UIColor clearColor];
            graphView.barWidth = 25;
            graphView.barLineWidth = 0.5;
            graphView.barLineColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
            graphView.barColor =  [[UIColor whiteColor] colorWithAlphaComponent:0.3];
            
            graphView.topMargin = 20;
            graphView.clipsToBounds = NO;
            cell.clipsToBounds = YES;
            cell.layer.cornerRadius = 8;
            graphView.backgroundFillColor = [DataCollectionViewController colorFromHexString:@"#27916F"];

            graphView.referenceLineLabelFont = [UIFont systemFontOfSize:11];
          graphView.referenceLineColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
            graphView.referenceLineLabelColor = [UIColor whiteColor];
          graphView.numberOfIntermediateReferenceLines = 3;
            graphView.shouldShowLabels = YES;
            graphView.dataPointLabelFont = [UIFont systemFontOfSize:11];
            graphView.dataPointLabelColor = [UIColor whiteColor];
            graphView.rightmostPointPadding = 20;
            graphView.dataPointLabelBottomMargin = 0;//50;
            graphView.referenceLineUnits = @"pts";
            graphView.shouldAutomaticallyDetectRange = YES;
          graphView.shouldAnimateOnStartup = YES;
          graphView.shouldAdaptRange = YES;
          graphView.adaptAnimationType = ScrollableGraphViewAnimationTypeElastic;
          graphView.animationDuration = 1.5;
          graphView.shouldRangeAlwaysStartAtZero = YES;
            [graphView set:@[@(100),@(130),@(200),@(80),@(124),@(155),@(50),@(100),@(130),@(200),@(80)] withLabels:@[@"30th",@"29th",@"28th",@"27th",@"26th",@"25th",@"24th", @"23rd", @"22nd", @"21st", @"20th", @"19th"]];
            
            [cell.graphHolderView addSubview:graphView];
            graphView.frame = cell.graphHolderView.bounds;
            
            return cell;
            
        } else if (indexPath.row == 1) {
            
            LeaderboardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"leaderboard" forIndexPath:indexPath];
            cell.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            cell.alpha = 1.0;
            cell.rankTableView.tag = 3;
            cell.rankTableView.rowHeight = 70;
            cell.rankTableView.delegate = self;
            cell.rankTableView.dataSource = self;
            cell.backgroundColor = [DataCollectionViewController colorFromHexString:@"AC281C"];
            
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
        LogsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        cell.logsTextView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        NSError *error;
        
        NSURL *logUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0] URLByAppendingPathComponent:@"/activity.txt"];
        
        NSString *log = [NSString stringWithContentsOfURL:logUrl encoding:NSUTF8StringEncoding error:&error];
        
        if (error == nil) {
            cell.logsTextView.text = log;
            if(cell.logsTextView.text.length > 0 ) {
                NSRange bottom = NSMakeRange(cell.logsTextView.text.length -1, 1);
                [cell.logsTextView scrollRangeToVisible:bottom];
            }
        }
        
        return cell;
        
    } else if (indexPath.row == 3) {
        identifier = @"week";
    } else if (indexPath.row == 4) {
        identifier = @"bot";
        return [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    }

    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.layer.borderColor = [UIColor whiteColor].CGColor;
    
    return cell;
    
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if (kind == UICollectionElementKindSectionHeader) {
        CollectionViewHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
        
        [header.currentPointsLabel setText:[NSString stringWithFormat:@"You've earned %.0f MovePoints", ([self.stats[@"current"] doubleValue])]];
        //[header.currentPointsLabel setTextColor:[DataCollectionViewController colorFromHexString:@"#333333"]];
        
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
            
            CollectionViewHeader *headerCell = (CollectionViewHeader*)[overviewCollectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (fabs(percentageOffset.y) < 0.001) {
                    NSLog(@"Updating");
                    NSDateFormatter *formatter = [NSDateFormatter new];
                    [formatter setDateStyle:NSDateFormatterShortStyle];
                    [formatter setTimeStyle:NSDateFormatterShortStyle];
                    
                    NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastSyncDate"];
                    NSString *lastSyncDateString = [formatter stringFromDate:lastSyncDate];
                    [headerCell.lastSyncLabel setText:[NSString stringWithFormat:@"Last Sync was %@", lastSyncDateString]];
                }
                float offset = fabs(percentageOffset.y) * 6.5;
                [headerCell.lastSyncLabel setAlpha:offset];
            });
        }
    }
}

// HSB color just using Hue
- (UIColor *)HSBColorForOffsetPercentage:(CGFloat)percentage
{
    CGFloat minColorHue = 0.0;
    CGFloat maxColorHue = 0.2; // this is a guess for the yellow hue.
    
    CGFloat actualHue = (maxColorHue - minColorHue) * percentage + minColorHue;
    
    // change these values to get the colours you want.
    // I find reducing the saturation to 0.8 ish gives nicer colours.
    return [UIColor colorWithHue:actualHue saturation:1.0 brightness:1.0 alpha:1.0];
}

// RGB color using all R, G, B values
- (UIColor *)RGBColorForOffsetPercentage:(CGFloat)percentage
{
    // RGB 1, 0, 0 = red
    CGFloat minColorRed = 1.0;
    CGFloat minColorGreen = 0.0;
    CGFloat minColorBlue = 0.0;
    
    // RGB 1, 1, 0 = yellow
    CGFloat maxColorRed = 1.0;
    CGFloat maxColorGreen = 1.0;
    CGFloat maxColorBlue = 0.0;
    
    // if you have specific beginning and end RGB values then set these to min and max respectively.
    // it should even work if the min value is greater than the max value.
    
    CGFloat actualRed = (maxColorRed - minColorRed) * percentage + minColorRed;
    CGFloat actualGreen = (maxColorGreen - minColorGreen) * percentage + minColorGreen;
    CGFloat actualBlue = (maxColorBlue - minColorBlue) * percentage + minColorBlue;
    
    return [UIColor colorWithRed:actualRed green:actualGreen blue:actualBlue alpha:1.0];
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
                return CGSizeMake(self.collectionView.frame.size.width - 20, 240);
            } else {
                return CGSizeMake(self.collectionView.frame.size.width - 20, self.collectionView.frame.size.height / 3.5);
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
    if (collectionView.tag == 2 && indexPath.row == 0) { // Here

        WavesLoader *loader = [WavesLoader showProgressBasedLoaderWith:[DataCollectionViewController getRMWLogoBezierPath].CGPath on:self.collectionView];
        loader.loaderColor = [DataCollectionViewController colorFromHexString:@"305B70"];
        loader.loaderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
        loader.layer.zPosition = 100;
    }
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changePage" object:@(indexPath.row)];
    
    if (indexPath.row == 0 && self.stats != nil) {
        SourcesCollectionViewCell *cell = (SourcesCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        
        [HealthKitFunctions requestPermission:^(BOOL success, NSError *err) {
            if (success) {
                [ViewController updateAllDataWithCompletion:^(BOOL success, NSMutableDictionary *stats, NSError *error) {
                    if (success && (stats[@"current"] != nil)) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [cell.totalCalLabel setText:[NSString stringWithFormat:@"%.0f pts", [stats[@"current"] doubleValue] + [stats[@"other"] doubleValue]]];
                            [cell.stepsCalLabel setText:[NSString stringWithFormat:@"%.0f pts", [stats[@"current"] doubleValue]]];
                            [cell.otherCalLabel setText:[NSString stringWithFormat:@"%.0f pts", [stats[@"other"] doubleValue]]];
                            
                        });
                    }
                }];
            }
        }];
    }
    
    if (indexPath.row == 2) {
        //LogsCollectionViewCell *cell = (LogsCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];

        //dispatch_async(dispatch_get_main_queue(), ^{
        //    [cell.logsTextView scrollRangeToVisible:NSMakeRange([cell.logsTextView.text length] - 1, 0)];
        //    [cell.logsTextView setScrollEnabled:NO];
         //   [cell.logsTextView setScrollEnabled:YES];
        //});
        
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.tag == 3) {
        return 5;
    } else {
        return self.sources.count;
    }
}


-(void)calculateEnergyFromSources:(NSNotification *)notification {
    
    UISwitch *toggle = (UISwitch *)notification.object;
    
    SourcesCollectionViewCell *cell = (SourcesCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    CGPoint hitPoint = [toggle convertPoint:CGPointZero toView:cell.tableView];
    NSIndexPath *index = [cell.tableView indexPathForRowAtPoint:hitPoint];
        
    if (!self.filteredSources) {
        self.filteredSources = [NSMutableDictionary new];
    }
    
    NSLog(@"%@", ((HKSource *)[self.sources objectAtIndex:index.row]).bundleIdentifier);
    
    if (toggle.on) {
        [self.filteredSources setObject:@(0) forKey:((HKSource *)[self.sources objectAtIndex:index.row]).bundleIdentifier];
    } else {
        [self.filteredSources removeObjectForKey:((HKSource *)[self.sources objectAtIndex:index.row]).bundleIdentifier];
    }
    
    
    [HealthKitFunctions getAllEnergyBurnedWithFilters:self.filteredSources withCompletion:^(NSMutableDictionary *totalSources, NSError *err) {
        NSLog(@"%@", totalSources.description);
        
        double allPoints = 0.0;
        for (NSString *key in totalSources.allKeys) {
            allPoints += [totalSources[key] doubleValue];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell.sourcePointsLabel setText:[NSString stringWithFormat:@"%.0f pts", allPoints]];
        });
    }];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //    source table view
    if (tableView.tag == 1) {
        SourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"source"];
        
        HKSource *source = [self.sources objectAtIndex:indexPath.row];
        
        [cell.sourceLabel setText:source.name];
        [cell.includeSwitch setOn:NO];
        
        return cell;
        
    } else if (tableView.tag == 2) {
        
        WorkoutTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"workouts"];
        
        return cell;
        
    } else if (tableView.tag == 3) {
        LeaderboardTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"leaderboardCell"];
        cell.backgroundColor = [UIColor clearColor];
        
        // you'll have alerady loaded everyone's data, trigger animation here and pass data
        
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

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}


+(UIBezierPath *)getRMWLogoBezierPath {
    UIColor* fillColor5 = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(248.49, 100.66)];
    [bezierPath addCurveToPoint: CGPointMake(249.58, 104.76) controlPoint1: CGPointMake(247.66, 102.09) controlPoint2: CGPointMake(248.15, 103.93)];
    [bezierPath addLineToPoint: CGPointMake(362.5, 170.26)];
    [bezierPath addLineToPoint: CGPointMake(301.25, 197.57)];
    [bezierPath addLineToPoint: CGPointMake(300.71, 150.76)];
    [bezierPath addCurveToPoint: CGPointMake(297.71, 147.79) controlPoint1: CGPointMake(300.69, 149.12) controlPoint2: CGPointMake(299.35, 147.79)];
    [bezierPath addCurveToPoint: CGPointMake(196.1, 148.05) controlPoint1: CGPointMake(297.7, 147.79) controlPoint2: CGPointMake(196.1, 148.05)];
    [bezierPath addCurveToPoint: CGPointMake(193.1, 151.05) controlPoint1: CGPointMake(194.45, 148.06) controlPoint2: CGPointMake(193.11, 149.4)];
    [bezierPath addLineToPoint: CGPointMake(193.02, 198.26)];
    [bezierPath addCurveToPoint: CGPointMake(185.55, 195) controlPoint1: CGPointMake(193.02, 198.26) controlPoint2: CGPointMake(190.1, 196.99)];
    [bezierPath addCurveToPoint: CGPointMake(132.68, 171.92) controlPoint1: CGPointMake(169.4, 187.95) controlPoint2: CGPointMake(132.68, 171.92)];
    [bezierPath addCurveToPoint: CGPointMake(152.41, 160.18) controlPoint1: CGPointMake(132.68, 171.92) controlPoint2: CGPointMake(140.93, 167.02)];
    [bezierPath addCurveToPoint: CGPointMake(213.66, 123.73) controlPoint1: CGPointMake(171.56, 148.79) controlPoint2: CGPointMake(199.7, 132.04)];
    [bezierPath addCurveToPoint: CGPointMake(219.48, 125.78) controlPoint1: CGPointMake(215.26, 125.01) controlPoint2: CGPointMake(217.28, 125.78)];
    [bezierPath addCurveToPoint: CGPointMake(228.78, 116.48) controlPoint1: CGPointMake(224.62, 125.78) controlPoint2: CGPointMake(228.78, 121.61)];
    [bezierPath addCurveToPoint: CGPointMake(219.48, 107.18) controlPoint1: CGPointMake(228.78, 111.34) controlPoint2: CGPointMake(224.62, 107.18)];
    [bezierPath addCurveToPoint: CGPointMake(213.66, 109.23) controlPoint1: CGPointMake(217.28, 107.18) controlPoint2: CGPointMake(215.25, 107.95)];
    [bezierPath addCurveToPoint: CGPointMake(210.18, 116.48) controlPoint1: CGPointMake(211.54, 110.93) controlPoint2: CGPointMake(210.18, 113.55)];
    [bezierPath addCurveToPoint: CGPointMake(210.44, 118.66) controlPoint1: CGPointMake(210.18, 117.23) controlPoint2: CGPointMake(210.27, 117.96)];
    [bezierPath addCurveToPoint: CGPointMake(148.17, 155.72) controlPoint1: CGPointMake(196.45, 126.99) controlPoint2: CGPointMake(168.41, 143.68)];
    [bezierPath addCurveToPoint: CGPointMake(124.59, 169.76) controlPoint1: CGPointMake(134.63, 163.78) controlPoint2: CGPointMake(124.59, 169.76)];
    [bezierPath addCurveToPoint: CGPointMake(123.13, 172.52) controlPoint1: CGPointMake(123.62, 170.33) controlPoint2: CGPointMake(123.06, 171.4)];
    [bezierPath addCurveToPoint: CGPointMake(124.93, 175.08) controlPoint1: CGPointMake(123.2, 173.65) controlPoint2: CGPointMake(123.89, 174.63)];
    [bezierPath addLineToPoint: CGPointMake(194.81, 205.59)];
    [bezierPath addCurveToPoint: CGPointMake(196.01, 205.84) controlPoint1: CGPointMake(195.2, 205.76) controlPoint2: CGPointMake(195.61, 205.84)];
    [bezierPath addCurveToPoint: CGPointMake(197.65, 205.36) controlPoint1: CGPointMake(196.59, 205.84) controlPoint2: CGPointMake(197.16, 205.68)];
    [bezierPath addCurveToPoint: CGPointMake(199.01, 202.85) controlPoint1: CGPointMake(198.5, 204.8) controlPoint2: CGPointMake(199.01, 203.86)];
    [bezierPath addLineToPoint: CGPointMake(199.1, 154.05)];
    [bezierPath addLineToPoint: CGPointMake(294.74, 153.8)];
    [bezierPath addLineToPoint: CGPointMake(295.31, 202.2)];
    [bezierPath addCurveToPoint: CGPointMake(296.69, 204.69) controlPoint1: CGPointMake(295.32, 203.21) controlPoint2: CGPointMake(295.84, 204.15)];
    [bezierPath addCurveToPoint: CGPointMake(299.53, 204.91) controlPoint1: CGPointMake(297.54, 205.24) controlPoint2: CGPointMake(298.61, 205.32)];
    [bezierPath addLineToPoint: CGPointMake(370.31, 173.35)];
    [bezierPath addCurveToPoint: CGPointMake(372.08, 170.77) controlPoint1: CGPointMake(371.34, 172.89) controlPoint2: CGPointMake(372.02, 171.9)];
    [bezierPath addCurveToPoint: CGPointMake(370.59, 168.02) controlPoint1: CGPointMake(372.14, 169.64) controlPoint2: CGPointMake(371.57, 168.58)];
    [bezierPath addLineToPoint: CGPointMake(252.59, 99.57)];
    [bezierPath addCurveToPoint: CGPointMake(248.49, 100.66) controlPoint1: CGPointMake(251.15, 98.74) controlPoint2: CGPointMake(249.32, 99.23)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(498.33, 178.14)];
    [bezierPath addCurveToPoint: CGPointMake(478.75, 197.73) controlPoint1: CGPointMake(498.33, 188.96) controlPoint2: CGPointMake(489.56, 197.73)];
    [bezierPath addCurveToPoint: CGPointMake(466.95, 193.75) controlPoint1: CGPointMake(474.31, 197.73) controlPoint2: CGPointMake(470.24, 196.24)];
    [bezierPath addLineToPoint: CGPointMake(432.2, 209.04)];
    [bezierPath addLineToPoint: CGPointMake(432.2, 320.38)];
    [bezierPath addLineToPoint: CGPointMake(454.34, 309.31)];
    [bezierPath addCurveToPoint: CGPointMake(454.27, 307.79) controlPoint1: CGPointMake(454.3, 308.81) controlPoint2: CGPointMake(454.27, 308.3)];
    [bezierPath addCurveToPoint: CGPointMake(473.85, 288.2) controlPoint1: CGPointMake(454.27, 296.97) controlPoint2: CGPointMake(463.03, 288.2)];
    [bezierPath addCurveToPoint: CGPointMake(493.44, 307.79) controlPoint1: CGPointMake(484.67, 288.2) controlPoint2: CGPointMake(493.44, 296.97)];
    [bezierPath addCurveToPoint: CGPointMake(473.85, 327.37) controlPoint1: CGPointMake(493.44, 318.6) controlPoint2: CGPointMake(484.67, 327.37)];
    [bezierPath addCurveToPoint: CGPointMake(462.06, 323.4) controlPoint1: CGPointMake(469.42, 327.37) controlPoint2: CGPointMake(465.34, 325.88)];
    [bezierPath addLineToPoint: CGPointMake(432.2, 337.86)];
    [bezierPath addLineToPoint: CGPointMake(432.2, 389.12)];
    [bezierPath addCurveToPoint: CGPointMake(412.96, 400.07) controlPoint1: CGPointMake(432.2, 389.12) controlPoint2: CGPointMake(423.52, 394.06)];
    [bezierPath addCurveToPoint: CGPointMake(406.96, 403.48) controlPoint1: CGPointMake(411.01, 401.18) controlPoint2: CGPointMake(408.99, 402.32)];
    [bezierPath addCurveToPoint: CGPointMake(375.62, 421.31) controlPoint1: CGPointMake(391.87, 412.06) controlPoint2: CGPointMake(375.62, 421.31)];
    [bezierPath addLineToPoint: CGPointMake(397.41, 439.13)];
    [bezierPath addCurveToPoint: CGPointMake(405.7, 437.27) controlPoint1: CGPointMake(399.93, 437.95) controlPoint2: CGPointMake(402.73, 437.27)];
    [bezierPath addCurveToPoint: CGPointMake(425.29, 456.85) controlPoint1: CGPointMake(416.52, 437.27) controlPoint2: CGPointMake(425.29, 446.04)];
    [bezierPath addCurveToPoint: CGPointMake(405.7, 476.44) controlPoint1: CGPointMake(425.29, 467.67) controlPoint2: CGPointMake(416.52, 476.44)];
    [bezierPath addCurveToPoint: CGPointMake(386.12, 456.85) controlPoint1: CGPointMake(394.89, 476.44) controlPoint2: CGPointMake(386.12, 467.67)];
    [bezierPath addCurveToPoint: CGPointMake(386.94, 451.25) controlPoint1: CGPointMake(386.12, 454.91) controlPoint2: CGPointMake(386.41, 453.03)];
    [bezierPath addLineToPoint: CGPointMake(360.71, 429.78)];
    [bezierPath addCurveToPoint: CGPointMake(360.7, 429.79) controlPoint1: CGPointMake(360.8, 429.87) controlPoint2: CGPointMake(360.76, 429.85)];
    [bezierPath addCurveToPoint: CGPointMake(331.31, 405.72) controlPoint1: CGPointMake(359.43, 428.75) controlPoint2: CGPointMake(346.62, 418.26)];
    [bezierPath addCurveToPoint: CGPointMake(406.96, 362.97) controlPoint1: CGPointMake(367.26, 385.41) controlPoint2: CGPointMake(406.96, 362.97)];
    [bezierPath addLineToPoint: CGPointMake(406.96, 403.48)];
    [bezierPath addLineToPoint: CGPointMake(412.96, 400.07)];
    [bezierPath addLineToPoint: CGPointMake(412.96, 357.83)];
    [bezierPath addCurveToPoint: CGPointMake(411.47, 355.24) controlPoint1: CGPointMake(412.96, 356.77) controlPoint2: CGPointMake(412.39, 355.78)];
    [bezierPath addCurveToPoint: CGPointMake(409.63, 354.85) controlPoint1: CGPointMake(410.9, 354.91) controlPoint2: CGPointMake(410.26, 354.78)];
    [bezierPath addCurveToPoint: CGPointMake(408.48, 355.22) controlPoint1: CGPointMake(409.23, 354.89) controlPoint2: CGPointMake(408.84, 355.02)];
    [bezierPath addCurveToPoint: CGPointMake(326.33, 401.64) controlPoint1: CGPointMake(408.48, 355.22) controlPoint2: CGPointMake(364.68, 379.97)];
    [bezierPath addCurveToPoint: CGPointMake(275.69, 360.16) controlPoint1: CGPointMake(302.73, 382.31) controlPoint2: CGPointMake(275.69, 360.16)];
    [bezierPath addLineToPoint: CGPointMake(275.69, 260.85)];
    [bezierPath addLineToPoint: CGPointMake(432.46, 191.51)];
    [bezierPath addCurveToPoint: CGPointMake(459.24, 179.67) controlPoint1: CGPointMake(435.23, 190.23) controlPoint2: CGPointMake(459.24, 179.67)];
    [bezierPath addCurveToPoint: CGPointMake(459.16, 178.14) controlPoint1: CGPointMake(459.2, 179.16) controlPoint2: CGPointMake(459.16, 178.66)];
    [bezierPath addCurveToPoint: CGPointMake(478.75, 158.56) controlPoint1: CGPointMake(459.16, 167.33) controlPoint2: CGPointMake(467.93, 158.56)];
    [bezierPath addCurveToPoint: CGPointMake(498.33, 178.14) controlPoint1: CGPointMake(489.56, 158.56) controlPoint2: CGPointMake(498.33, 167.33)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(246.88, 167.61)];
    [bezierPath addCurveToPoint: CGPointMake(235.33, 169.63) controlPoint1: CGPointMake(242.83, 167.61) controlPoint2: CGPointMake(238.94, 168.32)];
    [bezierPath addCurveToPoint: CGPointMake(212.98, 201.51) controlPoint1: CGPointMake(222.3, 174.35) controlPoint2: CGPointMake(212.98, 186.84)];
    [bezierPath addCurveToPoint: CGPointMake(246.88, 235.41) controlPoint1: CGPointMake(212.98, 220.23) controlPoint2: CGPointMake(228.16, 235.41)];
    [bezierPath addCurveToPoint: CGPointMake(280.78, 201.51) controlPoint1: CGPointMake(265.61, 235.41) controlPoint2: CGPointMake(280.78, 220.23)];
    [bezierPath addCurveToPoint: CGPointMake(246.88, 167.61) controlPoint1: CGPointMake(280.78, 182.78) controlPoint2: CGPointMake(265.61, 167.61)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(406.19, 228.5)];
    [bezierPath addCurveToPoint: CGPointMake(403.19, 231.5) controlPoint1: CGPointMake(404.54, 228.5) controlPoint2: CGPointMake(403.19, 229.84)];
    [bezierPath addLineToPoint: CGPointMake(403.19, 324.53)];
    [bezierPath addLineToPoint: CGPointMake(329.26, 366.66)];
    [bezierPath addCurveToPoint: CGPointMake(307.4, 349.05) controlPoint1: CGPointMake(329.26, 366.66) controlPoint2: CGPointMake(314.08, 354.43)];
    [bezierPath addCurveToPoint: CGPointMake(304.31, 346.56) controlPoint1: CGPointMake(305.51, 347.54) controlPoint2: CGPointMake(304.31, 346.56)];
    [bezierPath addCurveToPoint: CGPointMake(304.31, 345.54) controlPoint1: CGPointMake(304.31, 346.56) controlPoint2: CGPointMake(304.31, 346.2)];
    [bezierPath addCurveToPoint: CGPointMake(304.31, 280) controlPoint1: CGPointMake(304.31, 337.16) controlPoint2: CGPointMake(304.31, 280)];
    [bezierPath addLineToPoint: CGPointMake(354.19, 257.64)];
    [bezierPath addCurveToPoint: CGPointMake(354.19, 292.7) controlPoint1: CGPointMake(354.19, 257.64) controlPoint2: CGPointMake(354.19, 280.92)];
    [bezierPath addCurveToPoint: CGPointMake(347.98, 301.48) controlPoint1: CGPointMake(350.58, 293.98) controlPoint2: CGPointMake(347.98, 297.42)];
    [bezierPath addCurveToPoint: CGPointMake(357.28, 310.78) controlPoint1: CGPointMake(347.98, 306.61) controlPoint2: CGPointMake(352.15, 310.78)];
    [bezierPath addCurveToPoint: CGPointMake(366.58, 301.48) controlPoint1: CGPointMake(362.42, 310.78) controlPoint2: CGPointMake(366.58, 306.61)];
    [bezierPath addCurveToPoint: CGPointMake(360.19, 292.64) controlPoint1: CGPointMake(366.58, 297.36) controlPoint2: CGPointMake(363.91, 293.86)];
    [bezierPath addCurveToPoint: CGPointMake(360.19, 253.01) controlPoint1: CGPointMake(360.19, 279.8) controlPoint2: CGPointMake(360.19, 253.01)];
    [bezierPath addCurveToPoint: CGPointMake(358.83, 250.49) controlPoint1: CGPointMake(360.19, 251.99) controlPoint2: CGPointMake(359.68, 251.04)];
    [bezierPath addCurveToPoint: CGPointMake(355.97, 250.27) controlPoint1: CGPointMake(357.97, 249.94) controlPoint2: CGPointMake(356.9, 249.85)];
    [bezierPath addLineToPoint: CGPointMake(300.08, 275.32)];
    [bezierPath addCurveToPoint: CGPointMake(298.31, 278.05) controlPoint1: CGPointMake(299, 275.8) controlPoint2: CGPointMake(298.31, 276.87)];
    [bezierPath addCurveToPoint: CGPointMake(298.31, 338.73) controlPoint1: CGPointMake(298.31, 278.05) controlPoint2: CGPointMake(298.31, 319.71)];
    [bezierPath addCurveToPoint: CGPointMake(298.31, 348) controlPoint1: CGPointMake(298.31, 344.35) controlPoint2: CGPointMake(298.31, 348)];
    [bezierPath addCurveToPoint: CGPointMake(299.42, 350.34) controlPoint1: CGPointMake(298.31, 348.91) controlPoint2: CGPointMake(298.72, 349.77)];
    [bezierPath addLineToPoint: CGPointMake(327.09, 372.61)];
    [bezierPath addCurveToPoint: CGPointMake(328.97, 373.28) controlPoint1: CGPointMake(327.64, 373.05) controlPoint2: CGPointMake(328.3, 373.28)];
    [bezierPath addCurveToPoint: CGPointMake(330.46, 372.88) controlPoint1: CGPointMake(329.48, 373.28) controlPoint2: CGPointMake(329.99, 373.15)];
    [bezierPath addLineToPoint: CGPointMake(407.68, 328.88)];
    [bezierPath addCurveToPoint: CGPointMake(409.19, 326.28) controlPoint1: CGPointMake(408.62, 328.35) controlPoint2: CGPointMake(409.19, 327.36)];
    [bezierPath addLineToPoint: CGPointMake(409.19, 231.5)];
    [bezierPath addCurveToPoint: CGPointMake(406.19, 228.5) controlPoint1: CGPointMake(409.19, 229.84) controlPoint2: CGPointMake(407.85, 228.5)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(39.17, 179.73)];
    [bezierPath addCurveToPoint: CGPointMake(39.09, 181.26) controlPoint1: CGPointMake(39.17, 180.25) controlPoint2: CGPointMake(39.13, 180.75)];
    [bezierPath addCurveToPoint: CGPointMake(64.48, 192.43) controlPoint1: CGPointMake(39.09, 181.26) controlPoint2: CGPointMake(62.58, 191.6)];
    [bezierPath addCurveToPoint: CGPointMake(64.6, 192.48) controlPoint1: CGPointMake(64.56, 192.47) controlPoint2: CGPointMake(64.6, 192.48)];
    [bezierPath addCurveToPoint: CGPointMake(143.02, 227.3) controlPoint1: CGPointMake(64.48, 192.43) controlPoint2: CGPointMake(104, 209.98)];
    [bezierPath addCurveToPoint: CGPointMake(218.62, 260.86) controlPoint1: CGPointMake(181.06, 244.18) controlPoint2: CGPointMake(218.62, 260.86)];
    [bezierPath addCurveToPoint: CGPointMake(218.62, 347.44) controlPoint1: CGPointMake(218.62, 260.86) controlPoint2: CGPointMake(218.62, 320.69)];
    [bezierPath addCurveToPoint: CGPointMake(218.62, 360.11) controlPoint1: CGPointMake(218.62, 355.15) controlPoint2: CGPointMake(218.62, 360.11)];
    [bezierPath addCurveToPoint: CGPointMake(132.75, 430.28) controlPoint1: CGPointMake(218.62, 360.11) controlPoint2: CGPointMake(136.95, 426.85)];
    [bezierPath addCurveToPoint: CGPointMake(132.63, 430.37) controlPoint1: CGPointMake(132.75, 430.28) controlPoint2: CGPointMake(132.71, 430.31)];
    [bezierPath addCurveToPoint: CGPointMake(106.53, 451.94) controlPoint1: CGPointMake(130.36, 432.26) controlPoint2: CGPointMake(106.53, 451.94)];
    [bezierPath addCurveToPoint: CGPointMake(107.23, 457.09) controlPoint1: CGPointMake(106.97, 453.59) controlPoint2: CGPointMake(107.23, 455.3)];
    [bezierPath addCurveToPoint: CGPointMake(87.65, 476.67) controlPoint1: CGPointMake(107.23, 467.9) controlPoint2: CGPointMake(98.47, 476.67)];
    [bezierPath addCurveToPoint: CGPointMake(68.06, 457.09) controlPoint1: CGPointMake(76.83, 476.67) controlPoint2: CGPointMake(68.06, 467.9)];
    [bezierPath addCurveToPoint: CGPointMake(87.65, 437.5) controlPoint1: CGPointMake(68.06, 446.27) controlPoint2: CGPointMake(76.83, 437.5)];
    [bezierPath addCurveToPoint: CGPointMake(96.35, 439.56) controlPoint1: CGPointMake(90.78, 437.5) controlPoint2: CGPointMake(93.73, 438.25)];
    [bezierPath addLineToPoint: CGPointMake(118.07, 422.06)];
    [bezierPath addLineToPoint: CGPointMake(64.6, 392.14)];
    [bezierPath addLineToPoint: CGPointMake(64.6, 329.55)];
    [bezierPath addLineToPoint: CGPointMake(36.25, 317.01)];
    [bezierPath addCurveToPoint: CGPointMake(24.48, 320.96) controlPoint1: CGPointMake(32.97, 319.48) controlPoint2: CGPointMake(28.9, 320.96)];
    [bezierPath addCurveToPoint: CGPointMake(4.9, 301.38) controlPoint1: CGPointMake(13.66, 320.96) controlPoint2: CGPointMake(4.9, 312.19)];
    [bezierPath addCurveToPoint: CGPointMake(24.48, 281.79) controlPoint1: CGPointMake(4.9, 290.56) controlPoint2: CGPointMake(13.66, 281.79)];
    [bezierPath addCurveToPoint: CGPointMake(44.07, 301.38) controlPoint1: CGPointMake(35.3, 281.79) controlPoint2: CGPointMake(44.07, 290.56)];
    [bezierPath addCurveToPoint: CGPointMake(43.99, 302.93) controlPoint1: CGPointMake(44.07, 301.9) controlPoint2: CGPointMake(44.03, 302.42)];
    [bezierPath addLineToPoint: CGPointMake(64.6, 312.05)];
    [bezierPath addLineToPoint: CGPointMake(64.6, 209.97)];
    [bezierPath addLineToPoint: CGPointMake(31.37, 195.35)];
    [bezierPath addCurveToPoint: CGPointMake(19.58, 199.32) controlPoint1: CGPointMake(28.09, 197.83) controlPoint2: CGPointMake(24.02, 199.32)];
    [bezierPath addCurveToPoint: CGPointMake(0, 179.73) controlPoint1: CGPointMake(8.77, 199.32) controlPoint2: CGPointMake(0, 190.55)];
    [bezierPath addCurveToPoint: CGPointMake(19.58, 160.15) controlPoint1: CGPointMake(0, 168.92) controlPoint2: CGPointMake(8.77, 160.15)];
    [bezierPath addCurveToPoint: CGPointMake(39.17, 179.73) controlPoint1: CGPointMake(30.4, 160.15) controlPoint2: CGPointMake(39.17, 168.92)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(90.88, 234.38)];
    [bezierPath addCurveToPoint: CGPointMake(81.58, 243.68) controlPoint1: CGPointMake(85.75, 234.38) controlPoint2: CGPointMake(81.58, 238.54)];
    [bezierPath addCurveToPoint: CGPointMake(87.86, 252.47) controlPoint1: CGPointMake(81.58, 247.75) controlPoint2: CGPointMake(84.21, 251.22)];
    [bezierPath addCurveToPoint: CGPointMake(87.86, 270.99) controlPoint1: CGPointMake(87.86, 257.32) controlPoint2: CGPointMake(87.86, 263.69)];
    [bezierPath addCurveToPoint: CGPointMake(87.86, 376.33) controlPoint1: CGPointMake(87.86, 310.23) controlPoint2: CGPointMake(87.86, 376.33)];
    [bezierPath addCurveToPoint: CGPointMake(89.37, 378.94) controlPoint1: CGPointMake(87.86, 377.41) controlPoint2: CGPointMake(88.44, 378.4)];
    [bezierPath addLineToPoint: CGPointMake(129.04, 401.6)];
    [bezierPath addCurveToPoint: CGPointMake(130.53, 402) controlPoint1: CGPointMake(129.5, 401.87) controlPoint2: CGPointMake(130.02, 402)];
    [bezierPath addCurveToPoint: CGPointMake(132.43, 401.32) controlPoint1: CGPointMake(131.21, 402) controlPoint2: CGPointMake(131.88, 401.77)];
    [bezierPath addLineToPoint: CGPointMake(195.6, 349.48)];
    [bezierPath addCurveToPoint: CGPointMake(196.69, 347.17) controlPoint1: CGPointMake(196.29, 348.91) controlPoint2: CGPointMake(196.69, 348.06)];
    [bezierPath addLineToPoint: CGPointMake(196.69, 278.83)];
    [bezierPath addCurveToPoint: CGPointMake(194.93, 276.1) controlPoint1: CGPointMake(196.69, 277.65) controlPoint2: CGPointMake(196.01, 276.59)];
    [bezierPath addLineToPoint: CGPointMake(135.76, 249.27)];
    [bezierPath addCurveToPoint: CGPointMake(132.9, 249.48) controlPoint1: CGPointMake(134.83, 248.85) controlPoint2: CGPointMake(133.76, 248.93)];
    [bezierPath addCurveToPoint: CGPointMake(131.52, 252) controlPoint1: CGPointMake(132.04, 250.03) controlPoint2: CGPointMake(131.52, 250.98)];
    [bezierPath addCurveToPoint: CGPointMake(131.52, 334.04) controlPoint1: CGPointMake(131.52, 252) controlPoint2: CGPointMake(131.52, 316.81)];
    [bezierPath addCurveToPoint: CGPointMake(125.13, 342.88) controlPoint1: CGPointMake(127.81, 335.26) controlPoint2: CGPointMake(125.13, 338.76)];
    [bezierPath addCurveToPoint: CGPointMake(134.43, 352.18) controlPoint1: CGPointMake(125.13, 348.01) controlPoint2: CGPointMake(129.3, 352.18)];
    [bezierPath addCurveToPoint: CGPointMake(143.73, 342.88) controlPoint1: CGPointMake(139.57, 352.18) controlPoint2: CGPointMake(143.73, 348.01)];
    [bezierPath addCurveToPoint: CGPointMake(140.61, 335.93) controlPoint1: CGPointMake(143.73, 340.11) controlPoint2: CGPointMake(142.53, 337.63)];
    [bezierPath addCurveToPoint: CGPointMake(137.52, 334.1) controlPoint1: CGPointMake(139.72, 335.13) controlPoint2: CGPointMake(138.67, 334.51)];
    [bezierPath addCurveToPoint: CGPointMake(137.52, 256.65) controlPoint1: CGPointMake(137.52, 317.56) controlPoint2: CGPointMake(137.52, 256.65)];
    [bezierPath addLineToPoint: CGPointMake(190.69, 280.77)];
    [bezierPath addLineToPoint: CGPointMake(190.69, 345.75)];
    [bezierPath addLineToPoint: CGPointMake(130.22, 395.37)];
    [bezierPath addCurveToPoint: CGPointMake(127.73, 393.94) controlPoint1: CGPointMake(130.22, 395.37) controlPoint2: CGPointMake(129.29, 394.84)];
    [bezierPath addCurveToPoint: CGPointMake(93.86, 374.59) controlPoint1: CGPointMake(119.51, 389.25) controlPoint2: CGPointMake(93.86, 374.59)];
    [bezierPath addCurveToPoint: CGPointMake(93.86, 289.49) controlPoint1: CGPointMake(93.86, 374.59) controlPoint2: CGPointMake(93.86, 327.42)];
    [bezierPath addCurveToPoint: CGPointMake(93.86, 252.49) controlPoint1: CGPointMake(93.86, 274.59) controlPoint2: CGPointMake(93.86, 261.12)];
    [bezierPath addCurveToPoint: CGPointMake(100.18, 243.68) controlPoint1: CGPointMake(97.54, 251.25) controlPoint2: CGPointMake(100.18, 247.77)];
    [bezierPath addCurveToPoint: CGPointMake(97.16, 236.81) controlPoint1: CGPointMake(100.18, 240.96) controlPoint2: CGPointMake(99.02, 238.51)];
    [bezierPath addCurveToPoint: CGPointMake(90.88, 234.38) controlPoint1: CGPointMake(95.51, 235.3) controlPoint2: CGPointMake(93.3, 234.38)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(235.28, 406.28)];
    [bezierPath addCurveToPoint: CGPointMake(225.98, 415.58) controlPoint1: CGPointMake(230.15, 406.28) controlPoint2: CGPointMake(225.98, 410.44)];
    [bezierPath addCurveToPoint: CGPointMake(232.3, 424.39) controlPoint1: CGPointMake(225.98, 419.67) controlPoint2: CGPointMake(228.63, 423.15)];
    [bezierPath addCurveToPoint: CGPointMake(232.28, 457.55) controlPoint1: CGPointMake(232.28, 429.78) controlPoint2: CGPointMake(232.28, 439.57)];
    [bezierPath addCurveToPoint: CGPointMake(232.51, 460.3) controlPoint1: CGPointMake(232.28, 458.93) controlPoint2: CGPointMake(232.28, 459.59)];
    [bezierPath addCurveToPoint: CGPointMake(235.13, 462.13) controlPoint1: CGPointMake(232.91, 461.4) controlPoint2: CGPointMake(233.96, 462.13)];
    [bezierPath addLineToPoint: CGPointMake(235.43, 462.13)];
    [bezierPath addCurveToPoint: CGPointMake(238.06, 460.3) controlPoint1: CGPointMake(236.61, 462.13) controlPoint2: CGPointMake(237.66, 461.4)];
    [bezierPath addLineToPoint: CGPointMake(238.09, 460.18)];
    [bezierPath addCurveToPoint: CGPointMake(238.28, 457.55) controlPoint1: CGPointMake(238.28, 459.59) controlPoint2: CGPointMake(238.28, 458.93)];
    [bezierPath addCurveToPoint: CGPointMake(238.28, 424.39) controlPoint1: CGPointMake(238.28, 457.55) controlPoint2: CGPointMake(238.28, 434.24)];
    [bezierPath addCurveToPoint: CGPointMake(244.58, 415.58) controlPoint1: CGPointMake(241.95, 423.14) controlPoint2: CGPointMake(244.58, 419.67)];
    [bezierPath addCurveToPoint: CGPointMake(239.38, 407.23) controlPoint1: CGPointMake(244.58, 411.91) controlPoint2: CGPointMake(242.46, 408.74)];
    [bezierPath addCurveToPoint: CGPointMake(235.28, 406.28) controlPoint1: CGPointMake(238.15, 406.62) controlPoint2: CGPointMake(236.75, 406.28)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(314.46, 415.25)];
    [bezierPath addCurveToPoint: CGPointMake(343.9, 439.34) controlPoint1: CGPointMake(329.73, 427.75) controlPoint2: CGPointMake(342.63, 438.31)];
    [bezierPath addCurveToPoint: CGPointMake(274.42, 478.86) controlPoint1: CGPointMake(325.04, 450.07) controlPoint2: CGPointMake(294.46, 467.46)];
    [bezierPath addCurveToPoint: CGPointMake(274.42, 437.88) controlPoint1: CGPointMake(274.42, 478.75) controlPoint2: CGPointMake(274.42, 437.88)];
    [bezierPath addCurveToPoint: CGPointMake(314.46, 415.25) controlPoint1: CGPointMake(274.42, 437.88) controlPoint2: CGPointMake(292.05, 427.91)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(274.51, 20.33)];
    [bezierPath addCurveToPoint: CGPointMake(262.93, 38.2) controlPoint1: CGPointMake(274.51, 28.29) controlPoint2: CGPointMake(269.76, 35.13)];
    [bezierPath addLineToPoint: CGPointMake(262.93, 80.18)];
    [bezierPath addCurveToPoint: CGPointMake(427.53, 173.79) controlPoint1: CGPointMake(262.93, 80.18) controlPoint2: CGPointMake(400.25, 158.28)];
    [bezierPath addCurveToPoint: CGPointMake(262.99, 246.71) controlPoint1: CGPointMake(422.94, 175.82) controlPoint2: CGPointMake(262.99, 246.71)];
    [bezierPath addCurveToPoint: CGPointMake(257.61, 254.97) controlPoint1: CGPointMake(259.72, 248.16) controlPoint2: CGPointMake(257.61, 251.4)];
    [bezierPath addLineToPoint: CGPointMake(257.61, 364.45)];
    [bezierPath addCurveToPoint: CGPointMake(258.22, 367.7) controlPoint1: CGPointMake(257.61, 365.57) controlPoint2: CGPointMake(257.82, 366.67)];
    [bezierPath addCurveToPoint: CGPointMake(260.92, 371.44) controlPoint1: CGPointMake(258.77, 369.14) controlPoint2: CGPointMake(259.7, 370.44)];
    [bezierPath addCurveToPoint: CGPointMake(309.48, 411.17) controlPoint1: CGPointMake(260.92, 371.44) controlPoint2: CGPointMake(286.65, 392.5)];
    [bezierPath addCurveToPoint: CGPointMake(269.94, 433.52) controlPoint1: CGPointMake(287.17, 423.78) controlPoint2: CGPointMake(269.94, 433.52)];
    [bezierPath addCurveToPoint: CGPointMake(268.42, 436.13) controlPoint1: CGPointMake(269, 434.05) controlPoint2: CGPointMake(268.42, 435.05)];
    [bezierPath addLineToPoint: CGPointMake(268.42, 482.27)];
    [bezierPath addCurveToPoint: CGPointMake(271.04, 480.78) controlPoint1: CGPointMake(268.42, 482.27) controlPoint2: CGPointMake(269.67, 481.56)];
    [bezierPath addCurveToPoint: CGPointMake(268.42, 482.27) controlPoint1: CGPointMake(270.14, 481.29) controlPoint2: CGPointMake(269.26, 481.79)];
    [bezierPath addCurveToPoint: CGPointMake(254.52, 490.18) controlPoint1: CGPointMake(259.97, 487.07) controlPoint2: CGPointMake(254.52, 490.18)];
    [bezierPath addLineToPoint: CGPointMake(254.52, 523.55)];
    [bezierPath addCurveToPoint: CGPointMake(266.1, 541.41) controlPoint1: CGPointMake(261.34, 526.61) controlPoint2: CGPointMake(266.1, 533.45)];
    [bezierPath addCurveToPoint: CGPointMake(246.51, 561) controlPoint1: CGPointMake(266.1, 552.23) controlPoint2: CGPointMake(257.33, 561)];
    [bezierPath addCurveToPoint: CGPointMake(226.93, 541.41) controlPoint1: CGPointMake(235.7, 561) controlPoint2: CGPointMake(226.93, 552.23)];
    [bezierPath addCurveToPoint: CGPointMake(238.51, 523.55) controlPoint1: CGPointMake(226.93, 533.45) controlPoint2: CGPointMake(231.69, 526.61)];
    [bezierPath addLineToPoint: CGPointMake(238.51, 489.47)];
    [bezierPath addCurveToPoint: CGPointMake(149.8, 439.82) controlPoint1: CGPointMake(238.51, 489.47) controlPoint2: CGPointMake(179.71, 456.56)];
    [bezierPath addCurveToPoint: CGPointMake(233.39, 371.38) controlPoint1: CGPointMake(149.82, 439.83) controlPoint2: CGPointMake(233.39, 371.38)];
    [bezierPath addCurveToPoint: CGPointMake(236.7, 364.39) controlPoint1: CGPointMake(235.48, 369.67) controlPoint2: CGPointMake(236.7, 367.1)];
    [bezierPath addLineToPoint: CGPointMake(236.7, 254.98)];
    [bezierPath addCurveToPoint: CGPointMake(231.33, 246.72) controlPoint1: CGPointMake(236.7, 251.41) controlPoint2: CGPointMake(234.59, 248.17)];
    [bezierPath addCurveToPoint: CGPointMake(125.75, 199.86) controlPoint1: CGPointMake(231.33, 246.72) controlPoint2: CGPointMake(172.31, 220.52)];
    [bezierPath addCurveToPoint: CGPointMake(70.41, 175.29) controlPoint1: CGPointMake(95.68, 186.51) controlPoint2: CGPointMake(70.8, 175.47)];
    [bezierPath addCurveToPoint: CGPointMake(77.86, 170.91) controlPoint1: CGPointMake(72.43, 174.1) controlPoint2: CGPointMake(74.94, 172.63)];
    [bezierPath addCurveToPoint: CGPointMake(120.31, 145.92) controlPoint1: CGPointMake(88.02, 164.93) controlPoint2: CGPointMake(103.17, 156.01)];
    [bezierPath addCurveToPoint: CGPointMake(217.97, 88.44) controlPoint1: CGPointMake(152.55, 126.95) controlPoint2: CGPointMake(191.8, 103.85)];
    [bezierPath addCurveToPoint: CGPointMake(246.93, 71.41) controlPoint1: CGPointMake(235.32, 78.23) controlPoint2: CGPointMake(246.93, 71.41)];
    [bezierPath addLineToPoint: CGPointMake(246.93, 38.2)];
    [bezierPath addCurveToPoint: CGPointMake(235.34, 20.33) controlPoint1: CGPointMake(240.1, 35.13) controlPoint2: CGPointMake(235.34, 28.29)];
    [bezierPath addCurveToPoint: CGPointMake(235.47, 18.08) controlPoint1: CGPointMake(235.34, 19.57) controlPoint2: CGPointMake(235.39, 18.82)];
    [bezierPath addCurveToPoint: CGPointMake(254.93, 0.75) controlPoint1: CGPointMake(236.59, 8.32) controlPoint2: CGPointMake(244.87, 0.75)];
    [bezierPath addCurveToPoint: CGPointMake(274.51, 20.33) controlPoint1: CGPointMake(265.75, 0.75) controlPoint2: CGPointMake(274.51, 9.52)];
    [bezierPath closePath];
    [fillColor5 setFill];
    [bezierPath fill];
    
    return bezierPath;
}


@end
