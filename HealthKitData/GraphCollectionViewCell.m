//
//  GraphCollectionViewCell.m
//  HealthKitData
//
//  Created by Bryan Gula on 3/22/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import "GraphCollectionViewCell.h"

@implementation GraphCollectionViewCell

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    
    return self;
}

- (IBAction)changeSegment:(TwicketSegmentedControl *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeGraph" object:sender];
    NSLog(@"Segment Changed: %zd", sender.selectedSegmentIndex);
}


- (IBAction)showTodayProgress:(id)sender {
    
}

- (IBAction)showWeekProgress:(id)sender {
    
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    self.contentView.frame = bounds;
}

@end
