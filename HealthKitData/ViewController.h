//
//  ViewController.h
//  HealthKitData
//
//  Created by Bryan Gula on 12/30/16.
//  Copyright © 2016 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UISegmentedControl *healthDataSegmentedController;
@property (weak, nonatomic) IBOutlet UILabel *firstMetricLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondDetailMetricLabel;
@property (weak, nonatomic) IBOutlet UITableView *dataTableView;

@end

