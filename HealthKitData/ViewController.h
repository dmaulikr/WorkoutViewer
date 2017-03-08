//
//  ViewController.h
//  HealthKitData
//
//  Created by Bryan Gula on 12/30/16.
//  Copyright © 2016 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@import WatchConnectivity;

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSURLSessionDelegate, UITextFieldDelegate, WCSessionDelegate>

@property (weak, nonatomic) IBOutlet UILabel *firstMetricLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondDetailMetricLabel;
@property (weak, nonatomic) IBOutlet UITableView *dataTableView;
@property (weak, nonatomic) IBOutlet UILabel *totalWeeklyEnergyBurnedLabel;
@property (weak, nonatomic) IBOutlet UILabel *burnedEnergyLabel;

@end

