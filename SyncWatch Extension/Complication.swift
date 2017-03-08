//
//  Complication.swift
//  HealthKitData
//
//  Created by Bryan Gula on 3/2/17.
//  Copyright © 2017 Rock My World, Inc. All rights reserved.
//

import WatchKit
import ClockKit

class Complication: NSObject, CLKComplicationDataSource {
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.backward, .forward])
    }

    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {

        var entry : CLKComplicationTimelineEntry?
        let now = Date()
        
        let points = UserDefaults.standard.object(forKey: "currentPoints")
        print(points ?? "nothing")
        let goal = UserDefaults.standard.object(forKey: "goalPoints")
        print(goal ?? "nothing")
        
        // Create the template and timeline entry.
        if complication.family == .modularSmall {
            
            let textTemplate = CLKComplicationTemplateModularSmallSimpleText()
            textTemplate.textProvider = CLKSimpleTextProvider(text: points as! String, shortText: goal as! String?)
            
            // Create the entry.
            entry = CLKComplicationTimelineEntry(date: now, complicationTemplate: textTemplate)
        }
        else if complication.family == .extraLarge {

            let template = CLKComplicationTemplateExtraLargeSimpleText()
            template.textProvider = CLKSimpleTextProvider(text: "20") //(points as! NSNumber).stringValue
            entry = CLKComplicationTimelineEntry(date: now, complicationTemplate: template)
        
        }
        
        // Pass the timeline entry back to ClockKit.
        handler(entry)
        
    }
    
    func getNextRequestedUpdateDate(handler: @escaping (Date?) -> Void) {
        handler(Date().addingTimeInterval(100))
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        
        let points = UserDefaults.standard.object(forKey: "currentPoints")
        print(points ?? "nothing")
        let goal = UserDefaults.standard.object(forKey: "goalPoints")
        print(goal ?? "nothing")
        
        switch complication.family {
    
            case .modularSmall:
                let template = CLKComplicationTemplateModularSmallRingText()
                template.fillFraction = (points as! NSNumber).floatValue / (goal as! NSNumber).floatValue
                template.textProvider = CLKSimpleTextProvider(text: (points as! NSNumber).stringValue)
                handler(template)
            
            case .extraLarge:
                let template = CLKComplicationTemplateExtraLargeSimpleText()
                template.textProvider = CLKSimpleTextProvider(text: "200 cals")//(points as! NSNumber).stringValue)
                handler(template)
            
            //case .circularSmall: break
            
        default:
            handler(nil)
        }
        
    }
    
    func getPrivacyBehaviorForComplication(
        complication: CLKComplication,
        withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
}
