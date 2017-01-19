//
//  InsetTextField.m
//  HealthKitData
//
//  Created by Bryan Gula on 1/17/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import "InsetTextField.h"

@implementation InsetTextField

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 10, 10);
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 10, 10);
}

@end
