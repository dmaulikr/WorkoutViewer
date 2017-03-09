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
#import "HealthKitFunctions.h"
#import "AppDelegate.h"
#import <HealthKit/HealthKit.h>

@interface DataCollectionViewController ()

@property (strong, nonatomic) NSMutableDictionary *stats;

@end

@implementation DataCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveToLogPage) name:@"scrollToLog" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setStatsDictionary:) name:@"setStats" object:nil];
}

- (void)moveToLogPage {
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

-(void)setStatsDictionary:(NSNotification *)notification {
    self.stats = notification.object;
    
    for (UICollectionViewCell *c in self.collectionView.visibleCells) {
        if ([c isKindOfClass:[SourcesCollectionViewCell class]]) {
            SourcesCollectionViewCell *cell = (SourcesCollectionViewCell *)c;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [cell.totalCalLabel setText:[[self.stats[@"current"] stringValue] stringByAppendingString:@" cal"]];
                [cell.stepsCalLabel setText:[NSString stringWithFormat:@"%.0f cal", [self.stats[@"current"] doubleValue] - [self.stats[@"other"] doubleValue]]];
                [cell.otherCalLabel setText:[NSString stringWithFormat:@"%.0f cal", [self.stats[@"other"] doubleValue]]];
            });
            
        }
    }
    
    [[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] setNeedsDisplay];
    
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 4;
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
        identifier = @"workouts";
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
        
//    } else if (indexPath.row == 3) {
//        identifier = @"week";
    } else if (indexPath.row == 3) {
        identifier = @"bot";
        return [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
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

//            if( cell.logsTextView.text.length > 0 ) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    NSRange bottom = NSMakeRange(cell.logsTextView.text.length - 1, 1);
//                    [cell.logsTextView scrollRangeToVisible:bottom];
//                });
//            }
        
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //    source table view
    if (tableView.tag == 0) {
        SourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"source"];
        //cell.
        
        return cell;
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
    
    //return cell;
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
