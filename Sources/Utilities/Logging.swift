
//
//  Logger+subsystem.swift
//  FlightBriefing
//
//  Created by Johan Nyman on 2021-07-08.
//  Copyright © 2021 JN Avionics. All rights reserved.
//
///https://developer.apple.com/forums/thread/683169


import UIKit
import OSLog


@objc public protocol FirebaseWrapping {
    func crashlyticsLog(_ message:String)
    func crashlyticsError(_ error:Error)
    func analyticsLog(_ event:String, parameters: [String:Any]?)
}



public struct LogCategory:RawRepresentable {
    public var rawValue: String
    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
    public static let model = LogCategory(rawValue: "Model")!
    public static let appState = LogCategory(rawValue: "Application State")!
    public static let functionality = LogCategory(rawValue: "Functionality")!
    public static let network = LogCategory(rawValue: "Network")!
    public static let coredata = LogCategory(rawValue: "Core Data")!
    public static let view = LogCategory(rawValue: "View")!
    //public static let  = LogCategory(rawValue: "")
    fileprivate static let unknown = LogCategory(rawValue: "Unknown, change this!")!
}

//Use this in dependent projects:
//public extension LogCategory {
//    ///Logs airline specific Journey Log
//    static let journeyLog = LogCategory(rawValue: "Journey Log")!
//}


@objc public enum logLevel: Int {
    case fault, // Bug in program
         error, //Error object thrown
         notify, //Notice about specific occurrence
         trace, //Follow program execution
         debug // Useful for debugging only
}

/*
 Remember that the iOS system will store messages logged with
 notice, warning, and critical functions up to a storage limit.
 It doesn’t store debug messages at all.
 https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code
 */
@objc public class Log: NSObject {
    
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    @objc public static var firebase: FirebaseWrapping?
    
    @objc public class func log(message: String, level: logLevel, category: String?) {
        let cat = LogCategory(rawValue: category ?? "Category not set") ?? .unknown
        
        switch level {
        case .error:
            let localizedDescription: String = NSLocalizedString("Error in ObjC code", comment: "Refer to Objective C code")
            let error = Log.createError(localizedDescription)
            Log.error(error, message: message, in: cat)
            break
        case .fault:
            Log.fault(message: message, in: cat)
            break
        case .notify:
            Log.notify(message: message, in: cat)
            break
        case .trace:
            Log.trace(message: message, in: cat)
            break
        case .debug:
            Log.debug(message: message, in: cat)
            break
        }
    }
    
    //Log errors, where an error object is thrown
    //Optional message
    public class func error(_ error:Error, message:String?, in category:LogCategory) {
        if let message = message {
            
            //Internal logging (message)
            Logger(subsystem: subsystem, category: category.rawValue).error("Error: \(message, privacy: .public)")
            //Notify crashlytics (log message)
            firebase?.crashlyticsLog(message)
            
        }
        //Internal logging (error)
        Logger(subsystem: subsystem, category: category.rawValue).error("Description: \(error.localizedDescription)")
        //Notify crashlytics (record as error)
        firebase?.crashlyticsError(error)
    }
    
    //Log faults (Errors in code, but where no error object is provided)
    public class func fault(message:String, in category:LogCategory) {
        //Internal logging
        Logger(subsystem: subsystem, category: category.rawValue).fault("Fault: \(message, privacy: .public)")
        //Create an error and Notify crashlytics
        firebase?.crashlyticsError(Log.createError(message))
    }
    
    @available(*, deprecated, message: "Use Log.fault() instead ...")
    public class func warning(message:String, in category:LogCategory) {
        Log.fault(message: message, in: category)
    }
    
    //Log code passes and events that needs attention, but are not necessarily serious
    public class func notify(message:String, in category:LogCategory) {
        Logger(subsystem: subsystem, category: category.rawValue).fault("Attention: \(message, privacy: .public)")
        //Notify crashlytics
        firebase?.crashlyticsLog("Attention: \(message)")
        //Notify Analytics as well
        firebase?.analyticsLog("Attention", parameters: [
            "message": message,
            "category": category.rawValue,
        ])
    }
    
    
    //Log notices (for app flow and user actions)
    public class func trace(message:String, in category:LogCategory) {
        //Internal logging
        Logger(subsystem: subsystem, category: category.rawValue).notice("\(message, privacy: .public)")
        //Notify crashlytics
        firebase?.crashlyticsLog(message)
    }
    
    //Log debugging
    public class func debug(message:String, in category:LogCategory) {
        //Internal logging only, and not persisted.
        Logger(subsystem: subsystem, category: category.rawValue).debug("\(message, privacy: .public)")
        //Don't notify crashlytics
    }
    
    
    
    //Convenience function for creating errors
    public static func createError(_ message: String, code: Int = 0, domain: String = "FlightBriefingErrorDomain", function: String = #function, file: String = #file, line: Int = #line) -> NSError {
        
        let functionKey = "\(domain).function"
        let fileKey = "\(domain).file"
        let lineKey = "\(domain).line"
        
        let error = NSError(domain: domain, code: code, userInfo: [
            NSLocalizedDescriptionKey: message,
            functionKey: function,
            fileKey: file,
            lineKey: line
        ])
        
        return error
    }
}



extension Log {
    
    private class func getLogEntries(since:TimeInterval) throws -> [OSLogEntryLog] {
        Log.debug(message: "Retrieving logs from last \(since/3600) hours...", in: .functionality)
        let logStore = try OSLogStore(scope: .currentProcessIdentifier)
        let startTime = logStore.position(date: Date().addingTimeInterval(-since))
        let allEntries = try logStore.getEntries(at: startTime)
        
        return allEntries
            .compactMap { $0 as? OSLogEntryLog }
            .filter { $0.subsystem == Log.subsystem }
    }
    
    struct SendableLog: Codable {
        let level: Int
        let date, subsystem, category, composedMessage: String
    }
    
    public class func logData(since:TimeInterval) -> Data? {
        let logs = try! Log.getLogEntries(since: since)
        let sendLogs: [SendableLog] = logs.map({ SendableLog(level: $0.level.rawValue,
                                                             date: "\($0.date)",
                                                             subsystem: $0.subsystem,
                                                             category: $0.category,
                                                             composedMessage: $0.composedMessage) })
        
        // Convert object to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try? encoder.encode(sendLogs)
        return jsonData
    }
    
    public class func logString(since:TimeInterval) -> String {
        let logs = try! Log.getLogEntries(since: since)
        let sendLogs: [SendableLog] = logs.map({ SendableLog(level: $0.level.rawValue,
                                                             date: "\($0.date)",
                                                             subsystem: $0.subsystem,
                                                             category: $0.category,
                                                             composedMessage: $0.composedMessage) })
        var logBook = ""
        for log in sendLogs {
            logBook.append(contentsOf: String("\(log.date) [\(log.category)] (level \(log.level)): \(log.composedMessage)\n"))
        }
        return logBook
    }
    
    func sendLogs(since:TimeInterval) {
        let logs = try! Log.getLogEntries(since: since)
        let sendLogs: [SendableLog] = logs.map({ SendableLog(level: $0.level.rawValue,
                                                             date: "\($0.date)",
                                                             subsystem: $0.subsystem,
                                                             category: $0.category,
                                                             composedMessage: $0.composedMessage) })
        
        // Convert object to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try? encoder.encode(sendLogs)        
        
        //@TODO: Upload to firebase
        // Send to my API
        let url = URL(string: "http://x.x.x.x:8000")! // IP address and port of Python server
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
        }
        task.resume()
    }
}
