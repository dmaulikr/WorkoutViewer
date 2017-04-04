//
//  DataCollectionViewController.h
//  HealthKitData
//
//  Created by Bryan Gula on 3/7/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ANDBackgroundChartView.h"
#import "HealthKitData-Swift.h"

@interface DataCollectionViewController : UICollectionViewController <UITableViewDelegate, UITableViewDataSource>

+ (UIColor *)colorFromHexString:(NSString *)hexString;

@end
