// =====================================================================================================================
//
//  File:       TimedClosure.swift
//  Project:    Swiftfire
//
//  Version:    0.9.10
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/Swiftfire
//
//  Copyright:  (c) 2016 Marinus van der Lugt, All rights reserved.
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
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
// v0.9.10 - Added debuggin output
//         - Moved request for execution to observer of nextExecution
//         - Removed private from 'once'.
// v0.9.7  - Initial release
// =====================================================================================================================

import Foundation

typealias NoParametersNoReturn = () -> ()

final class TimedClosure {
    
    private var closure: NoParametersNoReturn
    private var queue: DispatchQueue
    var once: Bool
    private var previousExecution: Date
    private var delay: TimeInterval?
    private var wallclockDelay: WallclockTime?
    var doNotExecute = false
    
    
    // Writing to this variable will trigger an execution request to be issued.
    
    private var nextExecution: Date {
        didSet {
            var delta = nextExecution.timeIntervalSinceNow
            if delta < 0 { delta = 0 }
            log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Delay = \(delta)")
            let dpt = DispatchTime.now() + delta * Double(NSEC_PER_SEC)
            queue.after(when: dpt) { [weak self] in self?.execute() }
        }
    }

    private var calendar = Calendar.current
    
    
    /**
     Initializes the object with the execution of the closure in the given queue after the specified delay.
     
     - Note: The user should ensure that the created object is still available at execution time.
     
     - Parameter queue: The queue in which the closure will be executed.
     - Parameter wallclockTime: The delay after which the closure should be started.
     - Parameter closure: The closure to be executed.
     - Parameter once: If set to 'true', then de closure will be executed only once. If the default value 'false' is used, the closure will be executed periodically.
     */

    init(queue: DispatchQueue, delay: TimeInterval, closure: NoParametersNoReturn, once: Bool = false) {
        
        self.previousExecution = Date() // Simulate execution
        
        self.queue = queue
        self.closure = closure
        self.once = once
        self.delay = delay
        
        self.nextExecution = previousExecution.addingTimeInterval(delay)
    }
    
    
    /**
     Initializes the object with the execution of the closure in the given queue after the specified wallclock delay.
     
     - Note: The user should ensure that the created object is still available at execution time.

     - Parameter queue: The queue in which the closure will be executed.
     - Parameter wallclockTime: The wallclock time after which the closure should be started.
     - Parameter closure: The closure to be executed.
     - Parameter once: If set to 'true', then de closure will be executed only once. If the default value 'false' is used, the closure will be executed periodically.
     */

    init(queue: DispatchQueue, delay: WallclockTime, closure: NoParametersNoReturn, once: Bool = false) {
        
        self.previousExecution = Date() // Simulate execution
        
        self.queue = queue
        self.closure = closure
        self.once = once
        self.wallclockDelay = delay
        
        self.nextExecution = previousExecution + delay
    }

    
    /**
     Initializes the object with the execution of the closure in the given queue at the specified wallclock time. The closure can be once or periodically.
     
     - Note: The user should ensure that the created object is still available at execution time.
     
     - Parameter queue: The queue in which the closure will be executed.
     - Parameter wallclockTime: The wallclock time when the closure should be started. This is always in the future.
     - Parameter closure: The closure to be executed.
     - Parameter once: If set to 'true', then de closure will be executed only once. If the default value 'false' is used, the closure will be executed at the given wallclock time every day.
     */
    
    init(queue: DispatchQueue, wallclockTime: WallclockTime, closure: NoParametersNoReturn, once: Bool = false) {
        
        self.previousExecution = Date() // Simulate execution
        
        self.queue = queue
        self.closure = closure
        self.once = once

        self.nextExecution = Date.firstFutureDate(with: wallclockTime)
    }
    
    
    /**
     Will prevent the execution of the closure the next time it is scheduled, and thereafter.
     - Note: Does not deallocate/free this object.
     */
    
    func cancel() {
        once = true
        doNotExecute = true
    }
    
    
    // Executes the closure and set up the next execution.
    
    private func execute() {
        
        log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Started execution")
        
        
        // Check if the user cancelled
        
        if !doNotExecute {
            
        
            // Execute the closure

            log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Executing closure")
            
            closure()
        }

        
        // Repeat as necessary
        
        if !once {
            
            // Note: by using the calculated execution times rather than the actual execution time a creep in execution time is prevented.
            previousExecution = nextExecution

            if let delay = delay {
                nextExecution = previousExecution.addingTimeInterval(delay)
            } else if let wallclockDelay = wallclockDelay {
                nextExecution = previousExecution + wallclockDelay
            } else {
                nextExecution = calendar.date(byAdding: Calendar.Unit.day, value: 1, to: previousExecution as Date, options: Calendar.Options.matchFirst)!
            }
        }
    }
}
