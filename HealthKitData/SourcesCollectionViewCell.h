//
//  SourcesCollectionViewCell.h
//  HealthKitData
//
//  Created by Bryan Gula on 3/8/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBCircularProgressBarView.h"

@interface SourcesCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UICollectionView *overviewCollectionView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UILabel *totalCalLabel;
@property (strong, nonatomic) IBOutlet UILabel *stepsCalLabel;
@property (strong, nonatomic) IBOutlet UILabel *otherCalLabel;
@property (strong, nonatomic) IBOutlet MBCircularProgressBarView *goalPercentage;
@property (strong, nonatomic) IBOutlet MBCircularProgressBarView *daysLeft;
@property (strong, nonatomic) IBOutlet UILabel *sourcePointsLabel;
@property (strong, nonatomic) IBOutlet UIView *currentStatsView;

@end
