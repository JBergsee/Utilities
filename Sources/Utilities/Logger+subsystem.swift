
//
//  Logger+subsystem.swift
//  FlightBriefing
//
//  Created by Johan Nyman on 2021-07-08.
//  Copyright © 2021 JN Avionics. All rights reserved.
//
///https://developer.apple.com/forums/thread/683169


import Foundation
import OSLog
//import FirebaseCrashlytics
//import FirebaseAnalytics

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
}

#warning("Set in PPS, NFP, Parsing, etc...")
//public extension LogCategory {
//    ///Logs airline specific Journey Log
//    static let journeyLog = LogCategory(rawValue: "Journey Log")!
//}

/*
 Remember that the iOS system will store messages logged with
 notice, warning, and critical functions up to a storage limit.
 It doesn’t store trace messages at all.
 */
public class Log {
    
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    public init(firebaseInstance:Any) {
        
    }
    
    //Log errors, where an error is provided
    public class func error(_ error:Error, message:String?, in category:LogCategory) {
        if let message = message {
            
            //Internal logging
            Logger(subsystem: subsystem, category: category.rawValue).error("\(message)")
            //Notify crashlytics
            //        crashlytics().log(message)
            
        }
        //Internal logging
        Logger(subsystem: subsystem, category: category.rawValue).error("Error: \(error.localizedDescription)")
        //Notify crashlytics
        //        FIRCrashlytics.crashlytics().record(error: error)
    }
    
    //Log warnings (Errors in code, but where no error is provided by system)
    public class func warning(message:String, in category:LogCategory) {
        //Internal logging
        Logger(subsystem: subsystem, category: category.rawValue).warning("\(message)")
        //Create an error and Notify crashlytics
        //        crashlytics().recordError(createErrorr....)
    }
    
    //Log code passes and events that needs attention, but are not serious
    public class func notify(message:String, in category:LogCategory) {
        Logger(subsystem: subsystem, category: category.rawValue).warning("\(message)")
        //Notify Analytics
//        Analytics.logEvent("notification", parameters: [
//            "message": message,
//            "category": category.rawValue,
//        ])
    }
    
    
    //Log notices (for app flow and user actions
    public class func trace(message:String, in category:LogCategory) {
        //Internal logging
        Logger(subsystem: subsystem, category: category.rawValue).notice("\(message)")
        //Notify crashlytics
        //        crashlytics().log(message)
    }
    
    //Log debugging
    public class func debug(message:String, in category:LogCategory) {
        //Internal logging only, and not persisted.
        Logger(subsystem: subsystem, category: category.rawValue).debug("\(message)")
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


let subsystem = Bundle.main.bundleIdentifier!
let twoDays:TimeInterval = 60*60*24*2

//https://swiftwithmajid.com/2022/04/19/exporting-data-from-unified-logging-system-in-swift/?utm_source=swiftlee&utm_medium=swiftlee_weekly&utm_campaign=issue_112
@MainActor final class LogStore: ObservableObject {
    private static let logger = Logger(
        subsystem: subsystem,
        category: String(describing: LogStore.self)
    )
    
    @Published private(set) var entries: [String] = []
    
    func export() {
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(timeIntervalSinceLatestBoot: 1)
            entries = try store
                .getEntries(at: position)
                .compactMap { $0 as? OSLogEntryLog }
                .filter { $0.subsystem == subsystem }
                .map { "[\($0.date.formatted())] [\($0.category)] \($0.composedMessage)" }
        } catch {
            Self.logger.warning("\(error.localizedDescription, privacy: .public)")
        }
    }
}






func getLogEntries() throws -> [OSLogEntryLog] {
    Log.debug(message: "Retrieving logs from last hour...", in: .functionality)
    let logStore = try OSLogStore(scope: .currentProcessIdentifier)
    let oneHourAgo = logStore.position(date: Date().addingTimeInterval(-twoDays))
    let allEntries = try logStore.getEntries(at: oneHourAgo)
    
    return allEntries
        .compactMap { $0 as? OSLogEntryLog }
        .filter { $0.subsystem == subsystem }
}

struct SendableLog: Codable {
    let level: Int
    let date, subsystem, category, composedMessage: String
}

public func logData() -> Data? {
    let logs = try! getLogEntries()
    let sendLogs: [SendableLog] = logs.map({ SendableLog(level: $0.level.rawValue,
                                                         date: "\($0.date)",
                                                         subsystem: $0.subsystem,
                                                         category: $0.category,
                                                         composedMessage: $0.composedMessage) })
    
    // Convert object to JSON
    let jsonData = try? JSONEncoder().encode(sendLogs)
    return jsonData
}

public func logString() -> String {
    let logs = try! getLogEntries()
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

func sendLogs() {
    let logs = try! getLogEntries()
    let sendLogs: [SendableLog] = logs.map({ SendableLog(level: $0.level.rawValue,
                                                         date: "\($0.date)",
                                                         subsystem: $0.subsystem,
                                                         category: $0.category,
                                                         composedMessage: $0.composedMessage) })
    
    // Convert object to JSON
    let jsonData = try? JSONEncoder().encode(sendLogs)
    
    
    
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

