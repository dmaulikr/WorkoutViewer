//
//  WorkoutTableViewCell.h
//  HealthKitData
//
//  Created by Bryan Gula on 3/9/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WorkoutTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *calorieLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (strong, nonatomic) IBOutlet UILabel *sourceNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *dayLabel;
@property (strong, nonatomic) IBOutlet UILabel *timespanLabel;

@end
