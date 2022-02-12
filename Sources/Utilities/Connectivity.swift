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
import OSLog

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

@objc public enum ConnectivityStatus: Int64 {
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


extension NWPath.Status: CustomStringConvertible {
    public var description: String {
        if (self == .satisfied) { return "'satisfied'" }
        if (self == .unsatisfied) { return "'unsatisfied'" }
        if (self == .requiresConnection) { return "'requires connection'" }
        return "unknown"
    }
}


@objcMembers
public class ConnectivityMonitor : NSObject {
    
    //Singleton
    @objc public static let sharedMonitor = ConnectivityMonitor()

    //Public property
    @objc public var currentStatus : ConnectivityStatus = .unknown
    
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
        Logger.network.info("Connectivity status: \(path.status, privacy: .public)")
        Logger.network.info("Available interfaces: \(path.availableInterfaces, privacy: .public)")
        
        
        var newStatus : ConnectivityStatus
        
        if path.status == .satisfied {
            Logger.network.log("Connectivity: We have internet!\n")
            newStatus = .connected
        } else {
            Logger.network.log("Connectivity: No internet available.\n")
            newStatus = .notConnected
        }
        //Update status if it has changed
        if (newStatus != self.currentStatus) {
            
            //update current status before sending notification
            self.currentStatus = newStatus

            //Send a notification if the status have changed. Provide self as object.
            NotificationCenter.default.post(name: .ConnectivityDidChange, object: self)
        }
        
    }
    
    @objc public func isOnline() -> Bool {
        Logger.network.debug("Current path status is \(self.monitor.currentPath.status, privacy: .public)...")
        Logger.network.debug("...while connectivity status is \(self.currentStatus, privacy: .public)")

        return currentStatus == .connected
    }
    
    deinit {
        monitor.cancel()
    }
    
}


/** Obective C version */

//- (void)setupNetworkMonitor
//{
//    //Create Queue
//    dispatch_queue_attr_t attrs = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, DISPATCH_QUEUE_PRIORITY_DEFAULT);
//    self.monitorQueue = dispatch_queue_create("network-monitor", attrs);
//
//    //Create monitor
//    self.connectivityMonitor = nw_path_monitor_create();
//    nw_path_monitor_set_queue(self.connectivityMonitor, self.monitorQueue);
//
//    //The update handler
//    nw_path_monitor_set_update_handler(self.connectivityMonitor, ^(nw_path_t _Nonnull path) {
//        nw_path_status_t status = nw_path_get_status(path);
//        //
//        switch (status) {
//
//            case nw_path_status_satisfied: {
//                // Network is usable
//                NSLog(@"The internet is working!");
//                break;
//            }
//            case nw_path_status_invalid:
//                // Network path is invalid
//            case nw_path_status_satisfiable:
//                // Network may be usable
//            case nw_path_status_unsatisfied: {
//                // Network is not usable
//                NSLog(@"The internet is down.");
//                break;
//            }
//        }
//    });
//
//    nw_path_monitor_start(self.connectivityMonitor);
//}

