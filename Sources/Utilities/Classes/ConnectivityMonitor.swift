//
//  Connectivity.swift
//  FlightBriefing
//
//  Created by Johan Nyman on 2021-03-24.
//  Copyright © 2021 JN Avionics. All rights reserved.
//

/** Some reading:
 https://developer.apple.com/forums/thread/105822 (Objective C code)
 https://medium.com/@rwbutler/solving-the-captive-portal-problem-on-ios-9a53ba2b381e (alternative via pod)
 https://github.com/rwbutler/Connectivity (Used as inspiration)
 https://learnappmaking.com/nwpathmonitor-internet-connectivity/ (Used to get started)
 */


/*** NOTE: NOTIFICATIONS ARE UNRELIABLE ON SIMULATOR, TEST ON REAL DEVICE. **/


import Foundation
import Network
import JBLogging



//For Swift
public extension Notification.Name {
    static let ConnectivityDidChange = Notification.Name("Connectivity changed")
}

//For Obj C compatibility
@objc public extension NSNotification {
    static var ConnectivityDidChange: NSString {
        return Notification.Name.ConnectivityDidChange.rawValue as NSString
    }
}

@objc public enum ConnectivityStatus: Int64, Sendable {
    case unknown = 0
    case notConnected = 1
    case connected = 2
}

extension ConnectivityStatus: CustomStringConvertible {
    public var description: String {
        if (self == .unknown) { return "'unknown'" }
        if (self == .notConnected) { return "'not connected'" }
        if (self == .connected) { return "'connected'" }
        return "'out of scope'"
    }
}


extension NWPath.Status: @retroactive CustomStringConvertible {
    public var description: String {
        if (self == .satisfied) { return "'satisfied'" }
        if (self == .unsatisfied) { return "'unsatisfied'" }
        if (self == .requiresConnection) { return "'requires connection'" }
        return "unknown"
    }
}


@objcMembers
public class ConnectivityMonitor: NSObject {
    
    //Singleton
    @objc(sharedMonitor) public static let shared = ConnectivityMonitor()

    //Public property
    @objc public var currentStatus: ConnectivityStatus = .unknown
    
    //Private properties
    let monitor = NWPathMonitor()
    
    //To ensure that the class is not initializationable from outside
    private override init() {
        
        super.init()
        
        //Declare an update handler that will get called every time connectivity changes
        monitor.pathUpdateHandler = handleUpdate(path:)
        
        //Start the monitor to receive connectivity updates.
        //We do this by assigning the monitor to a background dispatch queue.
        //let queue = DispatchQueue(label:"Monitor-queue", qos: .background)
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
    }
    
    func handleUpdate(path:NWPath) {
        Log.debug(message: "Connectivity status: \(path.status)", in: .network)
        Log.debug(message: "Available interfaces: \(path.availableInterfaces)", in: .network)
        
        var newStatus: ConnectivityStatus
        
        if path.status == .satisfied {
            Log.trace(message: "Connectivity: We have internet!\n", in: .network)
            newStatus = .connected
        } else {
            Log.trace(message: "Connectivity: No internet available.\n", in: .network)
            newStatus = .notConnected
        }
        
        //Update status if it has changed
        if (newStatus != currentStatus) {
            
            //update current status before sending notification
            currentStatus = newStatus

            //Send a notification if the status have changed. Provide self as object.
            NotificationCenter.default.post(name: .ConnectivityDidChange, object: self)
        }
    }
    
    @objc public func isOnline() -> Bool {
        Log.debug(message: "Current path status is \(self.monitor.currentPath.status)...", in: .network)
        Log.debug(message: "...while connectivity status is \(self.currentStatus)", in: .network)

        return currentStatus == .connected
    }
    
    deinit {
        monitor.cancel()
    }
    
}
