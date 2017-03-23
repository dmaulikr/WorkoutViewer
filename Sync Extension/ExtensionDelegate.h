//
//  ExtensionDelegate.h
//  SyncWatch Extension
//
//  Created by Bryan Gula on 3/2/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <WatchKit/WatchKit.h>
@import WatchConnectivity;

@interface ExtensionDelegate : NSObject <WKExtensionDelegate, WCSessionDelegate>

@property (strong, nonatomic) NSNumber *points;
@property (strong, nonatomic) NSNumber *goal;
@property (strong, nonatomic) NSNumber *days;
@property (strong, nonatomic) NSNumber *today;

@property (strong, nonatomic) NSMutableDictionary *stats;


@end
