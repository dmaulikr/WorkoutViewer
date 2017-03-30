//
//  GraphCollectionViewCell.h
//  HealthKitData
//
//  Created by Bryan Gula on 3/22/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GraphCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIView *graphHolderView;
@property (strong, nonatomic) IBOutlet UIView *headerBackgroundView;
@property (strong, nonatomic) IBOutlet UIButton *weekProgressButton;
@property (strong, nonatomic) IBOutlet UILabel *progressLabel;
@property (strong, nonatomic) IBOutlet UIButton *todayProgressButton;

@end
