//
//  UIBezierPath+SVG.h
//  svg_test
//
//  Created by Arthur Evstifeev on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//	Modified by Michael Redig 9/28/14

#define SKUBezierPath UIBezierPath
#define addLineToPointSKU addLineToPoint
#define addCurveToPointSKU addCurveToPoint
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


@interface SKUBezierPath (SVG)

- (void)addPathFromSVGString:(NSString *)svgString;
+ (SKUBezierPath *)bezierPathWithSVGString:(NSString *)svgString;

@end
