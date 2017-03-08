//
//  InterfaceController.h
//  SyncWatch Extension
//
//  Created by Bryan Gula on 3/2/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceController : WKInterfaceController
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *totalBurnedLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceActivityRing *rings;
@property (strong, nonatomic) HKActivitySummary *summary;
@end
