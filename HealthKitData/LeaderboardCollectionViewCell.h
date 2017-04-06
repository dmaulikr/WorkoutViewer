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
@property (strong, nonatomic) IBOutlet UITableView *rankTableView;
@property (weak, nonatomic) IBOutlet UILabel *dateRangeLabel;


@end
