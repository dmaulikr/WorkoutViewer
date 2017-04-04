//
//  SourceTableViewCell.m
//  HealthKitData
//
//  Created by Bryan Gula on 3/9/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import "SourceTableViewCell.h"

@implementation SourceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (IBAction)include:(UISwitch *)sender {
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"filterSources" object:sender];
    
    
    if (!sender.on) {
        [UIView animateWithDuration:0.35 animations:^{
            self.backgroundColor = [UIColor clearColor];
            self.sourceLabel.textColor= [UIColor whiteColor];
        }];
    } else {
        [UIView animateWithDuration:0.35 animations:^{
            self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
            self.sourceLabel.textColor= [UIColor blackColor];
        }];
    }
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
