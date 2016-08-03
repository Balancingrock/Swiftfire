// =====================================================================================================================
//
//  File:       HistoricalUsageWindowController.swift
//  Project:    SwiftfireConsole
//
//  Version:    0.9.12
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/SwiftfireConsole
//
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
//
//  License:    Use or redistribute this code any way you like with the following two provision:
//
//  1) You ACCEPT this source code AS IS without any guarantees that it will work as intended. Any liability from its
//  use is YOURS.
//
//  2) You WILL NOT seek damages from the author or balancingrock.nl.
//
//  I also ask you to please leave this header with the source code.
//
//  I strongly believe that the Non Agression Principle is the way for societies to function optimally. I thus reject
//  the implicit use of force to extract payment. Since I cannot negotiate with you about the price of this code, I
//  have choosen to leave it up to you to determine its price. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  whishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/blog/google to ensure that you actually pay me and not some imposter)
//
//  For private and non-profit use the suggested price is the price of 1 good cup of coffee, say $4.
//  For commercial use the suggested price is the price of 1 good meal, say $20.
//
//  You are however encouraged to pay more ;-)
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// v0.9.12 - Initial release
// =====================================================================================================================

import Foundation
import Cocoa

class HistoricalUsageWindowController: NSWindowController {
    
    var pathPart: CDPathPart

    static var dateLabelFormatter: DateFormatter = {
        let ltf = DateFormatter()
        ltf.dateFormat = "yyyy.MM.dd"
        return ltf
    }()

    
    @IBOutlet weak var startDatePicker: NSDatePicker!
    @IBOutlet weak var endDatePicker: NSDatePicker!
    @IBOutlet weak var periodSelectionPopup: NSPopUpButton!
    @IBOutlet weak var urlLabel: NSTextField!
    @IBOutlet weak var historicalUsageView: LineGraphView!
    
    override var windowNibName: String? { return "HistoricalUsageWindow" }
    
    
    init(pathPart: CDPathPart) {
        self.pathPart = pathPart
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func handleStartDatePickerAction(sender: AnyObject?) {
        self.update()
    }
    
    @IBAction func handleEndDatePickerAction(sender: AnyObject?) {
        self.update()
    }
    
    @IBAction func handlePeriodSelectionPopupAction(sender: AnyObject?) {
        self.update()
    }
    
    override func windowDidLoad() {
        let today = Calendar.current.startOfDay(for: NSDate() as Date)
        let sometimeago = Calendar.current.date(byAdding: Calendar.Unit.month, value: -1, to: today, options: Calendar.Options.matchNextTime)
        startDatePicker.dateValue = sometimeago!
        endDatePicker.dateValue = today
        periodSelectionPopup.selectItem(at: 0)
        urlLabel.stringValue = pathPart.fullUrl
        update()
    }
    
    private func update() {
        
        func periodStep(start: Int64) -> Int64 {
            
            let selectedPeriod = periodSelectionPopup.indexOfSelectedItem
            
            if selectedPeriod == 0 { // Daily
                return Date.fromJavaDate(value: start).javaDateBeginOfTomorrow
            }
            
            if selectedPeriod == 1 { // Weekly
                return Date.fromJavaDate(value: start).javaDateBeginOfNextWeek
            }
            
            // Monthly
            return Date.fromJavaDate(value: start).javaDateBeginOfNextMonth
        }

        // The selected duration of a point in the chart
        let selectedPeriod = periodSelectionPopup.indexOfSelectedItem
        
        // The range of days of which the count must be included in the chart
        let dayRangeStart = startDatePicker.dateValue.javaDateBeginOfDay
        let dayRangeEnd = endDatePicker.dateValue.javaDateBeginOfDay
        
        // The range of days displayed in the chart
        let chartRangeStart: Int64
        let chartRangeEnd: Int64
        if selectedPeriod == 0 {
            // Daily, no adjustment necessary
            chartRangeStart = startDatePicker.dateValue.javaDateBeginOfDay
            chartRangeEnd = endDatePicker.dateValue.javaDateBeginOfDay
        } else if selectedPeriod == 1 {
            // Weekly, adjust to start at monday
            chartRangeStart = startDatePicker.dateValue.javaDateBeginOfWeek
            chartRangeEnd = endDatePicker.dateValue.javaDateBeginOfWeek
        } else {
            // Monthly, adjust to start of month
            chartRangeStart = startDatePicker.dateValue.javaDateBeginOfMonth
            chartRangeEnd = endDatePicker.dateValue.javaDateBeginOfMonth
        }
        
        // Create all datapoints (each datapoint = 1 period)
        var date = chartRangeStart
        var dataPoints: Array<LineGraphView.DataPoint> = []
        while date <= chartRangeEnd {
            let label = HistoricalUsageWindowController.dateLabelFormatter.string(from: Date.fromJavaDate(value: date))
            dataPoints.append(LineGraphView.DataPoint(label: label, value: 0))
            date = periodStep(start: date)
        }
        
        // The end of the current period
        var periodEndsBeforeDay = periodStep(start: dayRangeStart)
        
        // The index of the datapoint to be updated
        var periodIndex = 0
        
        // Start at the end of the counters
        var counterOrNil = pathPart.counterList
        while counterOrNil!.next != nil { counterOrNil = counterOrNil!.next }
        
        // Fill in the counter values
        while let counter = counterOrNil {
            
            // Only if the counter falls in the correct range
            if counter.forDay >= dayRangeStart && counter.forDay <= dayRangeEnd {
            
                // Skip to the proper period when necessary
                while counter.forDay >= periodEndsBeforeDay {
                    periodIndex += 1
                    periodEndsBeforeDay = periodStep(start: periodEndsBeforeDay)
                }
            
                dataPoints[periodIndex].add(value: counter.count)
            }
            
            counterOrNil = counter.previous
        }
        
        historicalUsageView!.dataPoints = dataPoints
        historicalUsageView!.needsDisplay = true
    }
}
