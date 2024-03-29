//
//  GraphCollectionViewCell.h
//  HealthKitData
//
//  Created by Bryan Gula on 3/22/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HealthKitData-Swift.h"

@interface GraphCollectionViewCell : UICollectionViewCell<TwicketSegmentedControlDelegate>

@property (strong, nonatomic) IBOutlet UIView *graphHolderView;
@property (strong, nonatomic) ScrollableGraphView *graphView;
@property (strong, nonatomic) IBOutlet UIView *headerBackgroundView;
@property (strong, nonatomic) IBOutlet UIButton *weekProgressButton;
@property (strong, nonatomic) IBOutlet UILabel *progressLabel;
@property (strong, nonatomic) IBOutlet UIButton *todayProgressButton;
@property (strong, nonatomic) IBOutlet TwicketSegmentedControl *segmentedController;
@property (strong, nonatomic) NSNumber *selectedIndex;

-(void)resetGraph:(NSArray *)xValues yValues:(NSArray *)yValues;

@end
