//
//  ViewController.h
//  HealthKitData
//
//  Created by Bryan Gula on 12/30/16.
//  Copyright © 2016 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HealthKitData-Swift.h"

@interface ViewController : UIViewController <NSURLSessionDelegate, UITextFieldDelegate>

+(void)updateAllDataWithCompletion:(void(^)(BOOL success, NSMutableDictionary *stats, NSError *error))completion;
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;



@end

