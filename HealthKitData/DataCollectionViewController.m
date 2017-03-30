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
    
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //[self.collectionView setBackgroundColor:[DataCollectionViewController colorFromHexString:@"#333333"]];
    
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

                [headerCell.currentPointsLabel setText:[NSString stringWithFormat:@"%.0f pts", ([self.stats[@"current"] doubleValue] + [self.stats[@"other"] doubleValue])]];
                
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
    return 5;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = @"";
    
    if (collectionView.tag == 2) {
        
        ((UICollectionViewFlowLayout*)collectionView.collectionViewLayout).sectionHeadersPinToVisibleBounds = YES;

        GraphCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"graph" forIndexPath:indexPath];
        
        if (indexPath.row == 0) {
            cell.alpha = 1.0;
            
            ScrollableGraphView *graphView = [[ScrollableGraphView alloc] initWithFrame:cell.contentView.bounds];
            graphView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            graphView.dataPointType = ScrollableGraphViewDataPointTypeCircle;
            graphView.shouldDrawBarLayer = YES;
            graphView.shouldDrawDataPoint = NO;
            graphView.dataPointSpacing = (cell.frame.size.width / 7) - 5;
            graphView.leftmostPointPadding = 60;
            
            graphView.lineColor = [UIColor clearColor];
            graphView.barWidth = 30;
            graphView.barLineWidth = 0.5;
            graphView.barLineColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
            graphView.barColor =  [[UIColor whiteColor] colorWithAlphaComponent:0.2];
            
            graphView.topMargin = 20;
            graphView.clipsToBounds = NO;
            cell.clipsToBounds = YES;
            cell.layer.cornerRadius = 8;
            graphView.backgroundFillColor = [DataCollectionViewController colorFromHexString:@"#27916F"];

            graphView.referenceLineLabelFont = [UIFont systemFontOfSize:10];
          graphView.referenceLineColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
            graphView.referenceLineLabelColor = [UIColor whiteColor];
          graphView.numberOfIntermediateReferenceLines = 3;
            graphView.shouldShowLabels = YES;
            graphView.dataPointLabelFont = [UIFont systemFontOfSize:10];
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
            [graphView set:@[@(100),@(130),@(200),@(80),@(124),@(155),@(50)] withLabels:@[@"Mon",@"Tue",@"Wed",@"Thurs",@"Fri",@"Sat",@"Sun"]];
            
            [cell.contentView addSubview:graphView];
            graphView.frame = cell.contentView.bounds;
            
            return cell;
        }

        cell.alpha = 0.0;
        
        return cell;
    }
        
    if (indexPath.row == 0) {
        identifier = @"sources";
        SourcesCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
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
        
        [header.currentPointsLabel setText:[NSString stringWithFormat:@"You have %.0f MovePoints", ([self.stats[@"current"] doubleValue])]];
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
                float offset = fabs(percentageOffset.y) * 6.0;
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
            return CGSizeMake(self.collectionView.frame.size.width - 20, self.collectionView.frame.size.height / 3.5);
        } else {
            return CGSizeMake(self.collectionView.frame.size.width, self.collectionView.frame.size.height);
        }
    }
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

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"changePage" object:@(indexPath.row)];
    
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
    return self.sources.count;
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

@end
