//
//  LeaderboardCollectionViewCell.m
//  HealthKitData
//
//  Created by Bryan Gula on 3/23/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import "LeaderboardCollectionViewCell.h"
#import "HealthKitData-Swift.h"

@implementation LeaderboardCollectionViewCell

- (IBAction)showTodayRank:(id)sender {
    [self.weekRankButton setEnabled:YES];
    [self.weekRankButton.titleLabel setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightThin]];
    [self.todayRankButton setEnabled:NO];
    [self.todayRankButton.titleLabel setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightMedium]];
    
    //[self setUserInteractionEnabled:NO];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.contentView.alpha = 0.5;
    } completion:^(BOOL finished) {

        
    }];
    
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    self.contentView.frame = bounds;
}

- (IBAction)showWeekStats:(id)sender {
    [self.weekRankButton setEnabled:NO];
    [self.weekRankButton.titleLabel setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightThin]];
    [self.todayRankButton setEnabled:YES];
    [self.weekRankButton.titleLabel setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightMedium]];
    
    //[self setUserInteractionEnabled:NO];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.contentView.alpha = 0.5;
    }];
}

@end
