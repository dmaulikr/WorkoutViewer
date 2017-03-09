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

+(void)updateAllDataWithCompletion:(void(^)(BOOL success, NSMutableDictionary *stats, NSError *error))completion;


@end

