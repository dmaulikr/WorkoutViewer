//
//  LeaderboardCollectionViewCell.m
//  HealthKitData
//
//  Created by Bryan Gula on 3/23/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import "LeaderboardCollectionViewCell.h"
#import "HealthKitData-Swift.h"
#import "Chameleon.h"

@implementation LeaderboardCollectionViewCell

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    self.contentView.frame = bounds;
}

-(void)layoutSubviews {
    [self.rankTableView setBackgroundColor:[[UIColor colorWithGradientStyle:UIGradientStyleTopToBottom withFrame:self.frame andColors:@[FlatRed, FlatYellow]] colorWithAlphaComponent:0.8]];
}

@end
