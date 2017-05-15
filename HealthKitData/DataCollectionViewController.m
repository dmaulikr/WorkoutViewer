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

@interface DataCollectionViewController ()

@property (strong, nonatomic) NSMutableDictionary *stats;
@property (strong, nonatomic) NSMutableArray *sources;
@property (strong, nonatomic) NSMutableArray *workouts;

@end

@implementation DataCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
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
}

-(void)viewDidLayoutSubviews {
    //[self.collectionView reloadData];
}

- (void)moveToLogPage {
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

-(void)setStatsDictionary:(NSNotification *)notification {
    self.stats = notification.object;
    
    for (UICollectionViewCell *c in self.collectionView.visibleCells) {
        if ([c isKindOfClass:[SourcesCollectionViewCell class]]) {
            SourcesCollectionViewCell *cell = (SourcesCollectionViewCell *)c;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [cell.totalCalLabel setText:[NSString stringWithFormat:@"%.0f pts", [self.stats[@"current"] doubleValue]]];
                [cell.stepsCalLabel setText:[NSString stringWithFormat:@"%.0f pts", [self.stats[@"current"] doubleValue] - [self.stats[@"other"] doubleValue]]];

                [cell.otherCalLabel setText:[NSString stringWithFormat:@"%.0f pts", [self.stats[@"other"] doubleValue]]];
            });
            
        }
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = @"";
    
    if (indexPath.row == 0) {
        identifier = @"sources";
        SourcesCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        cell.tableView.tag = 1;
        cell.tableView.delegate = self;
        cell.tableView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        return cell;
    } else if (indexPath.row == 1) {
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
        
    }

    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.layer.borderColor = [UIColor whiteColor].CGColor;
    
    return cell;
}

-(void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark <UICollectionViewDelegate>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return CGSizeMake(self.collectionView.frame.size.width, self.collectionView.frame.size.height);
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changePage" object:@(indexPath.row)];
    
    if (indexPath.row == 0 && self.stats != nil) {
        SourcesCollectionViewCell *cell = (SourcesCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        [cell.totalCalLabel setText:[[self.stats[@"current"] stringValue] stringByAppendingString:@" cal"]];

        [HealthKitFunctions getAllStepSamples:^(NSArray *stepSamples, NSError *err) {
            
            NSMutableArray *watchStepSamples = [NSMutableArray new];
            NSMutableArray *phoneStepSamples = [NSMutableArray new];
            
            for (HKQuantitySample *step in stepSamples) {
                if ([step.description containsString:@"Watch"]) {
                    [watchStepSamples addObject:step];
                } else if ([step.description containsString:@"iPhone"]) {
                    [phoneStepSamples addObject:step];
                }
            }
            
            int steps = 0;

            if (watchStepSamples.count > 0) {
                for (HKQuantitySample *step in stepSamples) {
                    steps += [step.quantity doubleValueForUnit:[HKUnit countUnit]];
                }
            } else {
                for (HKQuantitySample *step in stepSamples) {
                    steps += [step.quantity doubleValueForUnit:[HKUnit countUnit]];
                }
            }
            
            [HealthKitFunctions convertStepsToCalories:@(steps) withCompletion:^(double cals, NSError *err) {
                if (err == nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [cell.stepsCalLabel setText:[NSString stringWithFormat:@"%.0f cal", cals]];
                        [cell.otherCalLabel setText:[NSString stringWithFormat:@"%.0f cal", [self.stats[@"current"] doubleValue]- cals]];
                    });
                }
            }];
        }];
    }
    
    if (indexPath.row == 2) {
        LogsCollectionViewCell *cell = (LogsCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];

        dispatch_async(dispatch_get_main_queue(), ^{
            [cell.logsTextView scrollRangeToVisible:NSMakeRange([cell.logsTextView.text length] - 1, 0)];
            [cell.logsTextView setScrollEnabled:NO];
            [cell.logsTextView setScrollEnabled:YES];
        });
        
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sources.count;
}


-(void)calculateEnergyFromSources:(NSNotification *)notification {
    [HealthKitFunctions getAllEnergyBurnedWithFilters:notification.object withCompletion:^(NSMutableDictionary *totalSources, NSError *err) {
        NSLog(@"%@", totalSources.description);
        
        SourcesCollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        
    }];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //    source table view
    if (tableView.tag == 1) {
        SourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"source"];
        
        HKSource *source = [self.sources objectAtIndex:indexPath.row];
        
        [cell.sourceLabel setText:source.name];
        
        
        
        if ([source.description containsString:@"Human"]) {
            [cell.includeSwitch setOn:NO];
        } else {
            [cell.includeSwitch setOn:YES];
        }
        
        return cell;
        
    } else if (tableView.tag == 2) {
        
        WorkoutTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"workouts"];
        
    }
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"source"];
    
//        NSString *energyString = [NSString stringWithFormat:@"%.2f", [energy.quantity doubleValueForUnit:[HKUnit kilocalorieUnit]]];
//        
//        NSString *source;
//        if ([[energy description] rangeOfString:@"Watch"].location != NSNotFound) {
//            source = @"Watch";
//        } else if ([[energy description] rangeOfString:@"iPhone"].location != NSNotFound) {
//            source = @"iPhone";
//        } else if ([[energy description] rangeOfString:@"Human"].location != NSNotFound) {
//            source = @"Human";
//        } else if ([[energy description] rangeOfString:@"Endomondo"].location != NSNotFound) {
//            source = @"Endomondo";
//        } else {
//            source = @"Other";
//        }
//    
    //}
    
    return [tableView dequeueReusableCellWithIdentifier:@"source"];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
