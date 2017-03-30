//
//  LeaderboardTableViewCell.h
//  HealthKitData
//
//  Created by Bryan Gula on 3/30/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LeaderboardTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIView *userImageView;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UIView *progressColorView;

@end
