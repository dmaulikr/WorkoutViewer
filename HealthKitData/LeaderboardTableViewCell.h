//
//  LeaderboardTableViewCell.h
//  HealthKitData
//
//  Created by Bryan Gula on 3/30/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HealthKitData-Swift.h"

@interface LeaderboardTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet SVUploader *progressView;
@property (strong, nonatomic) IBOutlet UIView *userImageView;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UIView *progressColorView;
@property (strong, nonatomic) IBOutlet UILabel *rankLabel;
@property (strong, nonatomic) IBOutlet UILabel *percentGoalLabel;

@end
