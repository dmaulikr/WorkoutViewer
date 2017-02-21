//
//  StatViewController.h
//  HealthKitData
//
//  Created by Bryan Gula on 2/17/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatViewController : UIViewController

    @property (weak, nonatomic) IBOutlet UILabel *onlyWatchCalorieLabel;
    
    @property (weak, nonatomic) IBOutlet UILabel *noWatchCalorieLabel;
    
    @property (weak, nonatomic) IBOutlet UILabel *stepCalorieLabel;
    
    @property (weak, nonatomic) IBOutlet UILabel *duplicatesAndOverlapRemovedLabel;
    
    
@end
