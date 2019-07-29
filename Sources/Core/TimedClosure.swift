// =====================================================================================================================
//
//  File:       TimedClosure.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2019 Marinus van der Lugt, All rights reserved.
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
//  Like you, I need to make a living:
//
//   - You can send payment (you choose the amount) via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (again: rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================


import Foundation


/// General purpose closure signature

typealias NoParametersNoReturn = () -> ()


/// Allows execution of a closure at a given time, repeatedly if necessary.

final class TimedClosure {
    
    
    /// The closure that will be executed.
    
    private var closure: NoParametersNoReturn
    
    
    /// The distach queue on which the closure wil be executed.
    
    private var queue: DispatchQueue
    
    
    /// If true, the closure will only be executed once. Otherwise it will be executed repeatedly.
    
    var once: Bool
    
    
    /// The time of the previous execution
    
    private var previousExecution: Date
    
    
    /// The delay between executions
    
    private var delay: TimeInterval?
    
    
    /// The wallclock time of executions
    
    private var wallclockDelay: WallclockTime?
    
    
    /// If set to true, the execution will be cancelled.
    
    var doNotExecute = false
    
    
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

    init(queue: DispatchQueue, delay: TimeInterval, closure: @escaping NoParametersNoReturn, once: Bool = false) {
        
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

    init(queue: DispatchQueue, delay: WallclockTime, closure: @escaping NoParametersNoReturn, once: Bool = false) {
        
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
    
    init(queue: DispatchQueue, wallclockTime: WallclockTime, closure: @escaping NoParametersNoReturn, once: Bool = false) {
        
        self.previousExecution = Date() // Simulate execution
        
        self.queue = queue
        self.closure = closure
        self.once = once

        self.nextExecution = Date.firstFutureDate(with: wallclockTime)
    }
    
    
    /// Will prevent the execution of the closure the next time it is scheduled, and thereafter.
    ///
    /// - Note: Does not deallocate/free this object.
    
    func cancel() {
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
