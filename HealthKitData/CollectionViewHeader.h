//
//  CollectionViewHeader.h
//  HealthKitData
//
//  Created by Bryan Gula on 3/22/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionViewHeader : UICollectionReusableView

@property (strong, nonatomic) IBOutlet UILabel *currentPointsLabel;
@property (strong, nonatomic) IBOutlet UILabel *lastSyncLabel;
@property (strong, nonatomic) IBOutlet UILabel *titleHeaderMessageLabel;

@end
