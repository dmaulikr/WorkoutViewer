//
//  SourceTableViewCell.h
//  HealthKitData
//
//  Created by Bryan Gula on 3/9/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SourceTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *sourceLabel;
@property (strong, nonatomic) IBOutlet UISwitch *includeSwitch;


@end
