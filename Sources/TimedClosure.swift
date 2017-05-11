// =====================================================================================================================
//
//  File:       TimedClosure.swift
//  Project:    Swiftfire
//
//  Version:    0.10.7
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2017 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that voluntarism is the way for societies to function optimally. Thus I have choosen to leave it
//  up to you to determine the price for this code. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
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
// 0.10.7 - Merged SwiftfireCore into Swiftfire
// 0.9.17 - Header update
// 0.9.15 - General update and switch to frameworks
// 0.9.14 - Upgraded to Xcode 8 beta 6
// 0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.10 - Added debuggin output
//        - Moved request for execution to observer of nextExecution
//        - Removed private from 'once'.
// 0.9.7  - Initial release
// =====================================================================================================================


import Foundation


/// General purpose closure signature

public typealias NoParametersNoReturn = () -> ()


/// Allows execution of a closure at a given time, repeatedly if necessary.

public final class TimedClosure {
    
    
    /// The closure that will be executed.
    
    private var closure: NoParametersNoReturn
    
    
    /// The distach queue on which the closure wil be executed.
    
    private var queue: DispatchQueue
    
    
    /// If true, the closure will only be executed once. Otherwise it will be executed repeatedly.
    
    public var once: Bool
    
    
    /// The time of the previous execution
    
    private var previousExecution: Date
    
    
    /// The delay between executions
    
    private var delay: TimeInterval?
    
    
    /// The wallclock time of executions
    
    private var wallclockDelay: WallclockTime?
    
    
    /// If set to true, the execution will be cancelled.
    
    public var doNotExecute = false
    
    
    /// Writing to this variable will trigger an execution request to be issued.
    
    private var nextExecution: Date {
        didSet {
            var delta = nextExecution.timeIntervalSinceNow
            if delta < 0 { delta = 0 }
            let dpt = DispatchTime.now() + delta * Double(NSEC_PER_SEC)
            queue.asyncAfter(deadline: dpt) { [weak self] in self?.execute() }
        }
    }

    
    /// The calendar in use.
    
    private var calendar = Calendar.current
    
    
    /// Creates a new execution request.
    ///
    /// - Note: The user should ensure that the created object is still available at execution time.
    ///
    /// - Parameters:
    ///   - queue: The queue in which the closure will be executed.
    ///   - wallclockTime: The delay after which the closure should be started.
    ///   - closure: The closure to be executed.
    ///   - once: If set to 'true', then de closure will be executed only once. If the default value 'false' is used, the closure will be executed periodically.

    public init(queue: DispatchQueue, delay: TimeInterval, closure: @escaping NoParametersNoReturn, once: Bool = false) {
        
        self.previousExecution = Date() // Simulate execution
        
        self.queue = queue
        self.closure = closure
        self.once = once
        self.delay = delay
        
        self.nextExecution = previousExecution.addingTimeInterval(delay)
    }
    
    
    /// Creates a new execution request.
    ///
    /// - Note: The user should ensure that the created object is still available at execution time.
    ///
    /// - Parameters:
    ///   - queue: The queue in which the closure will be executed.
    ///   - wallclockTime: The wallclock time after which the closure should be started.
    ///   - closure: The closure to be executed.
    ///   - once: If set to 'true', then de closure will be executed only once. If the default value 'false' is used, the closure will be executed periodically.

    public init(queue: DispatchQueue, delay: WallclockTime, closure: @escaping NoParametersNoReturn, once: Bool = false) {
        
        self.previousExecution = Date() // Simulate execution
        
        self.queue = queue
        self.closure = closure
        self.once = once
        self.wallclockDelay = delay
        
        self.nextExecution = previousExecution + delay
    }

    
    /// Creates a new execution request.
    ///
    /// - Note: The user should ensure that the created object is still available at execution time.
    ///
    /// - Parameters:
    ///   - queue: The queue in which the closure will be executed.
    ///   - wallclockTime: The wallclock time when the closure should be started. This is always in the future.
    ///   - closure: The closure to be executed.
    ///   - once: If set to 'true', then de closure will be executed only once. If the default value 'false' is used, the closure will be executed at the given wallclock time every day.
    
    public init(queue: DispatchQueue, wallclockTime: WallclockTime, closure: @escaping NoParametersNoReturn, once: Bool = false) {
        
        self.previousExecution = Date() // Simulate execution
        
        self.queue = queue
        self.closure = closure
        self.once = once

        self.nextExecution = Date.firstFutureDate(with: wallclockTime)
    }
    
    
    /// Will prevent the execution of the closure the next time it is scheduled, and thereafter.
    ///
    /// - Note: Does not deallocate/free this object.
    
    public func cancel() {
        once = true
        doNotExecute = true
    }
    
    
    /// Executes the closure and set up the next execution.
    
    private func execute() {

        
        // Execute the closure if the user did not cancel
        
        if !doNotExecute { closure() }

        
        // Repeat as necessary
        
        if !once {
            
            // Note: by using the calculated execution times rather than the actual execution time a creep in execution time is prevented.
            previousExecution = nextExecution

            if let delay = delay {
                nextExecution = previousExecution.addingTimeInterval(delay)
            } else if let wallclockDelay = wallclockDelay {
                nextExecution = previousExecution + wallclockDelay
            } else {
                nextExecution = calendar.date(byAdding: .day, value: 1, to: previousExecution as Date)!
            }
        }
    }
}
