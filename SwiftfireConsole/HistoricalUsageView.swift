// =====================================================================================================================
//
//  File:       HistoricalUsageView.swift
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



class HistoricalUsageView: NSView {
    
    static let numberLeadingMargin: CGFloat = 10.0
    static let numberTrailingMargin: CGFloat = 10.0
    static let dateLeadingMargin: CGFloat = 10.0
    static let dateTrailingMargin: CGFloat = 10.0

    static var dateLabelFormatter: NSDateFormatter = {
        let ltf = NSDateFormatter()
        ltf.dateFormat = "yyyy.MM.dd"
        return ltf
    }()
    
    var pathPart: CDPathPart?
    
    
    override func drawRect(dirtyRect: NSRect) {
        log.atLevelDebug(id: -1, source: #file.source(#function, #line))
        super.drawRect(dirtyRect)
        
        
        // Draw background in a different color (white)
        
        drawBackground()
        
        
        // Create datapoints (if necessary)
        
        if dataPoints.count == 0 { dataPoints = createDataPoints(pathPart!) }
        
        
        // Special case: No datapoints
        
        if dataPoints.count == 0 { drawNoDataPoints() ; return }
        
        
        // Special case: 1 datapoint
        
        if dataPoints.count == 1 { drawOneDataPoint() ; return }
        
        drawOneDataPoint()
    }
    
    private func drawBackground() {
    
        let context = NSGraphicsContext.currentContext()!.CGContext
        
        CGContextSetFillColorWithColor(context, CGColorCreateGenericRGB(1, 1, 1, 1))
        CGContextBeginPath(context)
        CGContextFillRect(context, NSMakeRect(0.0, 0.0, frame.width, frame.height))
        CGContextDrawPath(context, CGPathDrawingMode.Fill)
    }
    
    
    private func drawNoDataPoints() {
        
        let message = "No data available"
        let messageRect = (message as NSString).boundingRectWithSize(NSSize(width: frame.height, height: frame.height), options: NSStringDrawingOptions.TruncatesLastVisibleLine, attributes: nil, context: nil)

        
        // Center the text
        
        let y = (frame.size.height - messageRect.size.height) / 2
        let x = (frame.size.width - messageRect.size.width) / 2
        
        (message as NSString).drawAtPoint(NSPoint(x: x, y: y), withAttributes: nil)
    }
    
    
    private func drawOneDataPoint() {
        
        let number = dataPoints[0].count.description
        let numberRect = (number as NSString).boundingRectWithSize(NSSize(width: frame.height, height: frame.height), options: NSStringDrawingOptions.TruncatesLastVisibleLine, attributes: nil, context: nil)
        let yAxisPosition = HistoricalUsageView.numberLeadingMargin + numberRect.size.width + HistoricalUsageView.numberTrailingMargin
        
        let dateStr = HistoricalUsageView.dateLabelFormatter.stringFromDate(dataPoints[0].date)
        let dateLabelRect = (dateStr as NSString).boundingRectWithSize(NSSize(width: frame.height, height: frame.height), options: NSStringDrawingOptions.TruncatesLastVisibleLine, attributes: nil, context: nil)
        let xAxisPosition = HistoricalUsageView.dateLeadingMargin + dateLabelRect.size.width + HistoricalUsageView.dateTrailingMargin
        
        
        // Draw the axis
        
        let context = NSGraphicsContext.currentContext()!.CGContext
        CGContextSetRGBStrokeColor(context, 0.5, 0.5, 0.5, 1.0)
        CGContextSetLineWidth(context, 1)
        CGContextMoveToPoint(context, yAxisPosition, xAxisPosition)
        CGContextAddLineToPoint(context, yAxisPosition, frame.size.height)
        CGContextDrawPath(context, CGPathDrawingMode.Stroke)
        CGContextMoveToPoint(context, yAxisPosition, xAxisPosition)
        CGContextAddLineToPoint(context, frame.size.width, xAxisPosition)
        CGContextDrawPath(context, CGPathDrawingMode.Stroke)

        
        // Draw the number label
        
        var x = HistoricalUsageView.numberLeadingMargin
        var y = ((frame.height - xAxisPosition) / 2) + xAxisPosition - (numberRect.size.height / 2)
        (number as NSString).drawAtPoint(NSPoint(x: x, y: y), withAttributes: nil)

        
        // Draw the line for the point
        
        x = yAxisPosition
        y = ((frame.height - xAxisPosition) / 2) + xAxisPosition
        CGContextSetRGBStrokeColor(context, 0.8, 0.8, 0.0, 1.0)
        CGContextMoveToPoint(context, x, y)
        CGContextAddLineToPoint(context, frame.size.width, y)
        CGContextDrawPath(context, CGPathDrawingMode.Stroke)
        CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0)

        
        // Draw the date label at the start
        
        drawVerticalString(dateStr, x: yAxisPosition, y: HistoricalUsageView.dateLeadingMargin)
        
        
        // Draw the date label at the end
        
        drawVerticalString(dateStr, x: frame.size.width - (dateLabelRect.size.height / 2), y: HistoricalUsageView.dateLeadingMargin)
    }
    
    static let rotateVertically: NSAffineTransform = {
        let trans = NSAffineTransform()
        trans.rotateByDegrees(90)
        return trans
    }()
    
    private func drawVerticalString(str: String, x: CGFloat, y: CGFloat) {
        let context = NSGraphicsContext.currentContext()!.CGContext
        CGContextSaveGState(context)
        let strRect = (str as NSString).boundingRectWithSize(NSSize(width: frame.height, height: frame.height), options: NSStringDrawingOptions.TruncatesLastVisibleLine, attributes: nil, context: nil)
        let nx = y
        let ny = -x - (strRect.size.height / 2)
        HistoricalUsageView.rotateVertically.concat()
        (str as NSString).drawAtPoint(NSPoint(x: nx, y: ny), withAttributes: nil)
        CGContextRestoreGState(context)
    }
    
    // Private definitions
    
    private struct DataPoint {
        var date: NSDate
        var count: Int64
        mutating func add(count: Int64) { self.count += count }
    }
    
    private var dataPoints: Array<DataPoint> = []
    
    
    // Creates an array with date/count entries for the given path part.
    
    private func createDataPoints(pathPart: CDPathPart) -> Array<DataPoint> {
        
        
        // First create a 1:1 list of data points
        
        var unfilteredDataPoints: Array<DataPoint> = []
        var counter = pathPart.counterList
        while counter!.next != nil { counter = counter!.next } // Start at the end for a chronological ordered sequence
        while counter != nil {
            let date = NSCalendar.currentCalendar().startOfDayForDate(NSDate.fromJavaDate(counter!.startDate))
            let dataPoint = DataPoint(date: date, count: counter!.count)
            unfilteredDataPoints.append(dataPoint)
            counter = counter!.previous
        }
        
        
        // Special case
        
        if unfilteredDataPoints.count <= 1 { return unfilteredDataPoints }
        
        
        // Coalecense same date into a single data point
        
        var dataPoints : Array<DataPoint> = []
        var lastDp = unfilteredDataPoints[0]
        unfilteredDataPoints.removeAtIndex(0)
        var lastDpWasProcessed = false
        for dp in unfilteredDataPoints {
            if dp.date == lastDp.date {
                lastDp.add(dp.count)
                lastDpWasProcessed = true
            } else {
                dataPoints.append(lastDp)
                // lastDpWasProcessed = true // Algorithmically speaking this should be present, but practically that would be nonsense
                lastDp = dp
                lastDpWasProcessed = false
            }
        }
        if !lastDpWasProcessed { dataPoints.append(lastDp) }
        
        return dataPoints
    }
}