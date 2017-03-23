//
//  ComplicationController.m
//  Sync Extension
//
//  Created by Bryan Gula on 3/17/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

#import "ComplicationController.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import "ExtensionDelegate.h"

@interface ComplicationController ()

@end

@implementation ComplicationController

#pragma mark - Timeline Configuration

- (void)getSupportedTimeTravelDirectionsForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimeTravelDirections directions))handler {
    handler(CLKComplicationTimeTravelDirectionForward|CLKComplicationTimeTravelDirectionBackward);
}

- (void)getTimelineStartDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate * __nullable date))handler {
    handler(nil);
}

- (void)getTimelineEndDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate * __nullable date))handler {
    handler(nil);
}

- (void)getPrivacyBehaviorForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationPrivacyBehavior privacyBehavior))handler {
    handler(CLKComplicationPrivacyBehaviorShowOnLockScreen);
}

#pragma mark - Timeline Population

- (void)getCurrentTimelineEntryForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimelineEntry * __nullable))handler {
    // Call the handler with the current timeline entry
    CLKComplicationTimelineEntry *entry;
    NSDate *now = [NSDate date];
    
    ExtensionDelegate* myDelegate = (ExtensionDelegate*)[[WKExtension sharedExtension] delegate];
    NSNumber *points = [myDelegate.stats objectForKey:@"currentPoints"];
    NSNumber *goal = [myDelegate.stats objectForKey:@"goalPoints"];
    NSNumber *days = [myDelegate.stats objectForKey:@"days"];
    NSNumber *today = [myDelegate.stats objectForKey:@"today"];
    
    if (!points) {
        points = @(0);
    }
    
    if (!goal) {
        goal = @(0);
    }
    
    if (complication.family == CLKComplicationFamilyExtraLarge) {
        
        CLKComplicationTemplateExtraLargeStackText *xLarge = [[CLKComplicationTemplateExtraLargeStackText alloc] init];
        xLarge.highlightLine2 = YES;
        CLKTextProvider *text1 = [CLKTextProvider textProviderWithFormat:@"%0.f", [points doubleValue]];
        CLKTextProvider *text2 = [CLKTextProvider textProviderWithFormat:@"%0.f%%", [points doubleValue]/[goal doubleValue]*100.0];
        
        if ([goal isEqualToNumber:@(0)]) {
            text2 = [CLKTextProvider textProviderWithFormat:@"0%%"];
        }
        xLarge.line1TextProvider = text1;
        xLarge.line2TextProvider = text2;
        
        entry = [CLKComplicationTimelineEntry entryWithDate:now complicationTemplate:xLarge];
        
        handler(entry);
        
    } else if (complication.family == CLKComplicationFamilyModularLarge) {
        
        CLKComplicationTemplateModularLargeStandardBody *mLarge = [[CLKComplicationTemplateModularLargeStandardBody alloc] init];
        CLKTextProvider *row0 = [CLKTextProvider textProviderWithFormat:@"Weekly Goal: %0.f%%", ([points doubleValue] / [goal doubleValue]) * 100.00];
        
        CLKTextProvider *row1 = [CLKTextProvider textProviderWithFormat:@"%0.f of %.0f", [points doubleValue], [goal doubleValue]];
        
        CLKTextProvider *row2 = [CLKTextProvider textProviderWithFormat:@"%0.f earned today", [today doubleValue]];


        mLarge.headerTextProvider = row0;
        mLarge.body1TextProvider = row1;
        mLarge.body2TextProvider = row2;
        
        entry = [CLKComplicationTimelineEntry entryWithDate:now complicationTemplate:mLarge];
        
        handler(entry);
        
    } else if (complication.family == CLKComplicationFamilyModularSmall) {
        
        CLKComplicationTemplateModularSmallStackText *mSmall = [[CLKComplicationTemplateModularSmallStackText alloc] init];
        
        mSmall.highlightLine2 = YES;
        CLKTextProvider *text1 = [CLKTextProvider textProviderWithFormat:@"%0.f", [points doubleValue]];
        CLKTextProvider *text2 = [CLKTextProvider textProviderWithFormat:@"%0.f%%", [points doubleValue]/[goal doubleValue]*100.0];
        
        if ([goal isEqualToNumber:@(0)]) {
            text2 = [CLKTextProvider textProviderWithFormat:@"0%%"];
        }
        
        mSmall.line1TextProvider = text1;
        mSmall.line2TextProvider = text2;
        
        entry = [CLKComplicationTimelineEntry entryWithDate:now complicationTemplate:mSmall];
        
        handler(entry);
    }
    
    
    handler(nil);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication beforeDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
    // Call the handler with the timeline entries prior to the given date
    handler(nil);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication afterDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
    // Call the handler with the timeline entries after to the given date
    handler(nil);
}

#pragma mark - Placeholder Templates

- (void)getLocalizableSampleTemplateForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTemplate * __nullable complicationTemplate))handler {
    // This method will be called once per supported complication, and the results will be cached
    
    if (complication.family == CLKComplicationFamilyExtraLarge) {
        
        CLKComplicationTemplateExtraLargeStackText *xLarge = [[CLKComplicationTemplateExtraLargeStackText alloc] init];
        xLarge.highlightLine2 = YES;
        CLKTextProvider *text1 = [CLKTextProvider textProviderWithFormat:@"0 pts"];
        CLKTextProvider *text2 = [CLKTextProvider textProviderWithFormat:@"0%%"];
        xLarge.line1TextProvider = text1;
        xLarge.line2TextProvider = text2;
        
        handler(xLarge);
        
    } else if (complication.family == CLKComplicationFamilyModularLarge) {
        
        CLKComplicationTemplateModularLargeStandardBody *mLarge = [[CLKComplicationTemplateModularLargeStandardBody alloc] init];
        CLKTextProvider *row0 = [CLKTextProvider textProviderWithFormat:@"MovePoints Goal: -%%"];
        
        CLKTextProvider *row1 = [CLKTextProvider textProviderWithFormat:@"Loading.."];
        
        CLKTextProvider *row2 = [CLKTextProvider textProviderWithFormat:@"Loading.."];
        
        mLarge.headerTextProvider = row0;
        mLarge.body1TextProvider = row1;
        mLarge.body2TextProvider = row2;
        
        handler(mLarge);
    } else if (complication.family == CLKComplicationFamilyModularSmall) {
        
        CLKComplicationTemplateModularSmallStackText *mSmall = [[CLKComplicationTemplateModularSmallStackText alloc] init];
        
        mSmall.highlightLine2 = YES;
        CLKTextProvider *text1 = [CLKTextProvider textProviderWithFormat:@"Points"];
        CLKTextProvider *text2 = [CLKTextProvider textProviderWithFormat:@"-%%"];
        
        mSmall.line1TextProvider = text1;
        mSmall.line2TextProvider = text2;
        
        handler(mSmall);
    }
    
    handler(nil);
}

@end
