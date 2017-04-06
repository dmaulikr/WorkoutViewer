//
//  GraphCollectionViewCell.m
//  HealthKitData
//
//  Created by Bryan Gula on 3/22/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import "GraphCollectionViewCell.h"
#import "HealthKitData-Swift.h"
#import "DataCollectionViewController.h"

@implementation GraphCollectionViewCell

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    
    return self;
}

-(void)didSelect:(NSInteger)segmentIndex {
    self.selectedIndex = @(segmentIndex);
}

-(void)layoutSubviews {
    [super layoutSubviews];
    [self.segmentedController setSegmentItems:@[@"Today", @"Week", @"Month"]];
    self.segmentedController.sliderBackgroundColor = [DataCollectionViewController colorFromHexString:@"#27916F"];
    self.segmentedController.backgroundColor = [UIColor clearColor];
    self.segmentedController.isSliderShadowHidden = YES;
    self.segmentedController.segmentsBackgroundColor = [UIColor clearColor];
}

-(void)resetGraph:(NSArray *)xValues yValues:(NSArray *)yValues {
    
    [self.graphView removeFromSuperview];

    self.alpha = 1.0;
    self.layer.cornerRadius = 8;
    self.graphView = [[ScrollableGraphView alloc] initWithFrame:self.contentView.bounds];
    self.graphView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.graphView.dataPointType = ScrollableGraphViewDataPointTypeSquare;
    self.graphView.leftmostPointPadding = 70;
    self.graphView.rightmostPointPadding = 70;
    self.graphView.topMargin = 20;
    self.graphView.lineColor = [UIColor clearColor];
    self.graphView.barLineWidth = 0.5;
    self.graphView.barWidth = 30;
    self.graphView.dataPointSpacing = 15;

    if (xValues.count == 7) {
        self.graphView.barWidth = (self.frame.size.width / 7) - 15;
        self.graphView.dataPointSpacing = self.graphView.barWidth + 15;
    } else if (xValues.count == 31) {
        self.graphView.barWidth = 25;
        self.graphView.dataPointSpacing = 45;
    }
    
    self.graphView.barLineColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    self.graphView.barColor =  [[UIColor whiteColor] colorWithAlphaComponent:0.3];
    self.clipsToBounds = YES;
    self.graphView.clipsToBounds = YES;
    self.graphView.shouldAutomaticallyDetectRange = YES;
    self.graphView.shouldAnimateOnStartup = YES;
    self.graphView.shouldAdaptRange = YES;
    self.graphView.shouldRangeAlwaysStartAtZero = YES;
    self.graphView.shouldDrawBarLayer = YES;
    self.graphView.shouldDrawDataPoint = NO;
    self.graphView.backgroundFillColor = [DataCollectionViewController colorFromHexString:@"#27916F"];
    
    self.graphView.referenceLineLabelFont = [UIFont systemFontOfSize:12];
    self.graphView.referenceLineColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    self.graphView.referenceLineLabelColor = [UIColor whiteColor];
    self.graphView.numberOfIntermediateReferenceLines = 4;
    self.graphView.shouldShowLabels = YES;
    self.graphView.dataPointLabelFont = [UIFont systemFontOfSize:12];
    self.graphView.dataPointLabelColor = [UIColor whiteColor];
    self.graphView.rightmostPointPadding = 20;
    self.graphView.dataPointLabelBottomMargin = 0;//50;
    self.graphView.referenceLineUnits = @"Cal";
    self.graphView.adaptAnimationType = ScrollableGraphViewAnimationTypeEaseOut;
    self.graphView.animationDuration = 1.5;
    
    [self.graphView set:xValues withLabels:yValues];
    
    self.graphHolderView.layer.cornerRadius = 8;
    self.graphView.shouldShowLabels = YES;
    self.graphView.frame = self.graphHolderView.bounds;
    
    [self.graphHolderView addSubview:self.graphView];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    self.contentView.frame = bounds;
}

@end
