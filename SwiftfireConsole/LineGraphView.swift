// =====================================================================================================================
//
//  File:       HistoricalUsageView.swift
//  Project:    SwiftfireConsole
//
//  Version:    0.9.13
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
//  I prefer the above two, but if these options don't suit you, you may also send me a gift from my amazon.co.uk
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
// v0.9.13 - Upgraded to Swift 3 beta
// v0.9.12 - Initial release
// =====================================================================================================================


import Foundation
import Cocoa


private let MaxSize: NSSize = NSSize(width: DBL_MAX, height: DBL_MAX)


class LineGraphView: NSView {
    
    static let yLabelLeadingMargin: CGFloat = 10.0 // Empty space in front of y-axis labels
    static let yLabelTrailingMargin: CGFloat = 10.0 // Empty space between y-axis labels and y-axis
    static let xLabelLeadingMargin: CGFloat = 10.0 // Empty space below x-axis labels (label is draw vertically)
    static let xLabelTrailingMargin: CGFloat = 10.0 // Empty space between x-axis labels and the x-axis
    static let topMargin: CGFloat = 10.0 // Empty space at the top of the chart
    static let rightMargin: CGFloat = 10.0 // Empty space at the right of the chart
    
    static let minimumChartHight: CGFloat = 100.0 // Minimum height of chart area above the x-axis
    static let minimumNofPixelsPerDataPoint: CGFloat = 10.0 // Minimum spacing between data points along the x-axis
    static let minimumNofPixelsBetweenXLabels: CGFloat = 30.0 // Supresses x-axis labels for data points in between
    
    static let rotateVertically: NSAffineTransform = {
        let trans = NSAffineTransform()
        trans.rotate(byDegrees: 90)
        return trans
    }()

    struct DataPoint {
        var label: String
        var value: Int64
        mutating func add(value: Int64) { self.value += value }
    }

    var dataPoints: Array<DataPoint> = []
    
    
    override func draw(_ dirtyRect: NSRect) {

        super.draw(dirtyRect)
        
        
        // Special case: No datapoints
        
        if dataPoints.count == 0 { drawNoDataPoints() ; return }
        
        
        // Special case: 1 datapoint
        
        if dataPoints.count == 1 { drawOneDataPoint() ; return }
        
        
        // Multiple datapoints
        
        drawDataPoints()
    }
    
    
    private func drawBackground() {
    
        let context = NSGraphicsContext.current()!.cgContext
        
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.beginPath()
        context.fill(NSMakeRect(0.0, 0.0, frame.width, frame.height))
        context.drawPath(using: CGPathDrawingMode.fill)
    }
    
    
    private func drawNoDataPoints() {
        
        
        // Draw background in a different color (white)
        
        drawBackground()

        
        // Draw message to say that there is no data
        
        let message = "No data available"
        let messageRect = (message as NSString).boundingRect(with: NSSize(width: frame.width, height: frame.height), options: NSStringDrawingOptions.truncatesLastVisibleLine, attributes: nil, context: nil)

        
        // Set the frame size
        
        let scrollView = self.enclosingScrollView!
        let contentViewSize = scrollView.contentView.frame.size
        frame.size = contentViewSize
        
        
        // Center the text
        
        let y = (frame.size.height - messageRect.size.height) / 2
        let x = (frame.size.width - messageRect.size.width) / 2
        
        (message as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: nil)
    }
    
    
    private func drawOneDataPoint() {
        
        let number = dataPoints[0].value.description
        let numberRect = (number as NSString).boundingRect(with: NSSize(width: frame.width, height: frame.height), options: NSStringDrawingOptions.truncatesLastVisibleLine, attributes: nil, context: nil)
        let yAxisPosition = LineGraphView.yLabelLeadingMargin + numberRect.size.width + LineGraphView.yLabelTrailingMargin
        
        let xAxisPosition = LineGraphView.xLabelLeadingMargin + self.maxXLabelWidth() + LineGraphView.xLabelTrailingMargin
        
        
        // Set the frame size

        let scrollView = self.enclosingScrollView!
        let contentViewSize = scrollView.contentView.frame.size
        frame.size = contentViewSize


        // Draw background in a different color (white)
        
        drawBackground()

        
        // Draw the axes
        
        let context = NSGraphicsContext.current()!.cgContext
        context.setStrokeColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        context.setLineWidth(1)
        context.moveTo(x: yAxisPosition, y: xAxisPosition)
        context.addLineTo(x: yAxisPosition, y: frame.size.height - LineGraphView.topMargin)
        context.drawPath(using: CGPathDrawingMode.stroke)
        context.moveTo(x: yAxisPosition, y: xAxisPosition)
        context.addLineTo(x: (frame.size.width - LineGraphView.rightMargin), y: xAxisPosition)
        context.drawPath(using: CGPathDrawingMode.stroke)

        
        // Draw the number label
        
        var x = LineGraphView.yLabelLeadingMargin
        var y = ((frame.height - xAxisPosition) / 2) + xAxisPosition - (numberRect.size.height / 2)
        (number as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: nil)

        
        // Draw the line for the point
        
        x = yAxisPosition
        y = ((frame.height - xAxisPosition) / 2) + xAxisPosition
        context.setStrokeColor(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0)
        context.moveTo(x: x, y: y)
        context.addLineTo(x: (frame.size.width - LineGraphView.rightMargin), y: y)
        context.drawPath(using: CGPathDrawingMode.stroke)
        context.setStrokeColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

        
        // Draw the date label at the start
        
        drawVerticalString(str: dataPoints[0].label, x: yAxisPosition, y: LineGraphView.xLabelLeadingMargin)
        
        
        // Draw the date label at the end
        
        drawVerticalString(str: dataPoints[0].label, x: frame.size.width - LineGraphView.rightMargin, y: LineGraphView.xLabelLeadingMargin)
    }
    
    
    // Determines the maximum necessary size for the Y-labels (based on the numeric value of the 'value' field in the datapoints array)
    
    private func maxYLabelWidth() -> CGFloat {
        return dataPoints.reduce(CGFloat(0.0), combine: {
            let width = ($1.value.description as NSString).boundingRect(
                with: MaxSize,
                options: NSStringDrawingOptions.truncatesLastVisibleLine,
                attributes: nil,
                context: nil)
                .size.width
            return $0 > width ? $0 : width
        })
    }
    
    
    // Determines the maximum necessary size for the X-labels (based on the 'label' field in the datapoints array)
    
    private func maxXLabelWidth() -> CGFloat {
        return dataPoints.reduce(CGFloat(0.0), combine: {
            let width = ($1.label as NSString).boundingRect(
                with: MaxSize,
                options: NSStringDrawingOptions.truncatesLastVisibleLine,
                attributes: nil,
                context: nil)
                .size.width
            return $0 > width ? $0 : width
        })
    }

    
    // Determine the upper limit for auto-ranging along the Y-axis
    
    private func autorangeHighLimit() -> Int64 {
        
        // Find highest value in datapoints
        let maxValue = dataPoints.reduce(0, combine: { $0 > $1.value ? $0 : $1.value })
        
        // Auto ranging values
        let autorangeArray: Array<Int64> = [10, 20, 50]
        
        // The result
        var limit: Int64?
        
        // A factor that is applied to the auto ranging values
        var factor: Int64 = 1
        
        // Find the first auto range value that is higher than the maxValue, keep increasing the factor until an auto-range value is found.
        while limit == nil {
            for f in autorangeArray {
                if (f * factor) >= maxValue {
                    limit = f * factor
                    break
                }
            }
            factor *= 10
        }
        
        // Result
        return limit!
    }
    
    
    private func drawDataPoints() {

        // This is the size that is available without scrolling
        let contentViewSize = self.enclosingScrollView!.contentView.frame.size
        
        let maxYLabelWidth = self.maxYLabelWidth() // The width of the longest Y label in pixels
        let maxXLabelWidth = self.maxXLabelWidth() // The width of the longest X label in pixels
        
        let yAxisPosition = LineGraphView.yLabelLeadingMargin + maxYLabelWidth + LineGraphView.yLabelTrailingMargin
        let xAxisPosition = LineGraphView.xLabelLeadingMargin + maxXLabelWidth + LineGraphView.xLabelTrailingMargin

        // Determine the width of the view
        let availableWidthForDataPoints = contentViewSize.width - yAxisPosition - LineGraphView.rightMargin
        let availableWidthPerDataPoint = availableWidthForDataPoints / CGFloat(dataPoints.count - 1)
        let pixelsPerDataPoint = max(availableWidthPerDataPoint, LineGraphView.minimumNofPixelsPerDataPoint)
        let frameWidth = pixelsPerDataPoint * CGFloat(dataPoints.count - 1) + yAxisPosition + LineGraphView.rightMargin

        // Determine the height of the view
        let necessaryFrameHeight = xAxisPosition + LineGraphView.minimumChartHight
        let frameHeight = max(necessaryFrameHeight, contentViewSize.height)
        
        // Set the frame size
        frame.size = NSSize(width: frameWidth, height: frameHeight)
        
        // Draw background in a different color (white)
        drawBackground()
        
        // Draw the x and y axes
        let context = NSGraphicsContext.current()!.cgContext
        context.setStrokeColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        context.setLineWidth(1)
        context.moveTo(x: yAxisPosition, y: xAxisPosition)
        context.addLineTo(x: yAxisPosition, y: frame.size.height - LineGraphView.topMargin)
        context.drawPath(using: CGPathDrawingMode.stroke)
        context.moveTo(x: yAxisPosition, y: xAxisPosition)
        context.addLineTo(x: frame.size.width - LineGraphView.rightMargin, y: xAxisPosition)
        context.drawPath(using: CGPathDrawingMode.stroke)

        
        // Draw the y-labels and support lines
        let yPixelsPerUnit = (frameHeight - LineGraphView.topMargin - xAxisPosition) / 10
        let autorangeUpperLimit = autorangeHighLimit()
        for i in 0 ... 10 {
            let label = ((autorangeUpperLimit/10) * Int64(i)).description as NSString
            let boundingRect = label.boundingRect(with: NSSize(width: frame.height, height: frame.height), options: NSStringDrawingOptions.truncatesLastVisibleLine, attributes: nil, context: nil)
            var x = LineGraphView.yLabelLeadingMargin + (maxYLabelWidth - boundingRect.size.width)
            var y = xAxisPosition - (boundingRect.size.height / 2) + yPixelsPerUnit * CGFloat(i)
            label.draw(at: NSPoint(x: x, y: y), withAttributes: nil)
            if i == 0 { continue } // Don't draw horizontal line over the x-axis
            x = yAxisPosition
            y += (boundingRect.size.height / 2)
            context.setStrokeColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1)
            context.moveTo(x: x, y: y)
            context.addLineTo(x: (frame.size.width - LineGraphView.rightMargin), y: y)
            context.drawPath(using: CGPathDrawingMode.stroke)
            context.setStrokeColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        }
        
        
        // Draw the date labels & x-axis ticks
        var pixelCountDown: CGFloat = 0.0
        var dpXOffset: CGFloat = 0.0
        var dpY: CGFloat = LineGraphView.xLabelLeadingMargin
        for dp in dataPoints {
            
            // Date label
            if pixelCountDown <= 0.0 {
                drawVerticalString(str: dp.label, x: yAxisPosition + dpXOffset, y: dpY)
                pixelCountDown = LineGraphView.minimumNofPixelsBetweenXLabels
            }
            
            // x-Axis ticks
            if dpXOffset > 0 { // No tick on the y-Axis
                context.moveTo(x: yAxisPosition + dpXOffset, y: xAxisPosition - 2)
                context.addLineTo(x: yAxisPosition + dpXOffset, y: xAxisPosition + 2)
                context.drawPath(using: CGPathDrawingMode.stroke)
            }
            
            pixelCountDown -= pixelsPerDataPoint
            dpXOffset += pixelsPerDataPoint
        }
        
        
        // Draw the chart line
        dpXOffset = 0.0
        dpY = xAxisPosition + CGFloat(dataPoints[0].value) * yPixelsPerUnit
        context.setStrokeColor(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0)
        context.moveTo(x: yAxisPosition + dpXOffset, y: dpY)
        for dp in dataPoints {
            if dpXOffset > 0 { // Do not draw the first point
                context.addLineTo(x: yAxisPosition + dpXOffset, y: xAxisPosition + CGFloat(dp.value) * yPixelsPerUnit)
            }
            dpXOffset += pixelsPerDataPoint
        }
        context.drawPath(using: CGPathDrawingMode.stroke)
    }
    
    
    private func drawVerticalString(str: String, x: CGFloat, y: CGFloat) {
        let context = NSGraphicsContext.current()!.cgContext
        context.saveGState()
        let strRect = (str as NSString).boundingRect(with: NSSize(width: frame.height, height: frame.height), options: NSStringDrawingOptions.truncatesLastVisibleLine, attributes: nil, context: nil)
        let nx = y
        let ny = -x - (strRect.size.height / 2)
        LineGraphView.rotateVertically.concat()
        (str as NSString).draw(at: NSPoint(x: nx, y: ny), withAttributes: nil)
        context.restoreGState()
    }
}
