//
//  LogsCollectionViewCell.h
//  HealthKitData
//
//  Created by Bryan Gula on 3/8/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface LogsCollectionViewCell : UICollectionViewCell <MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UITextView *logsTextView;

@property (strong, nonatomic) IBOutlet UIButton *emailToBryan;

@end
