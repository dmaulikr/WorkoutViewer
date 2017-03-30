//
//  LeaderboardCollectionViewCell.h
//  HealthKitData
//
//  Created by Bryan Gula on 3/23/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LeaderboardCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UILabel *leaderboardTitle;
@property (strong, nonatomic) IBOutlet UIButton *todayButton;
@property (strong, nonatomic) IBOutlet UIButton *weekButton;
@property (strong, nonatomic) IBOutlet UIView *topView;
@property (strong, nonatomic) IBOutlet UIView *bottomView;
@property (strong, nonatomic) IBOutlet UIView *scalableView;


@end
