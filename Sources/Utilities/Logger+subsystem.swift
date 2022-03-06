
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


public extension Logger {
    static let subsystem = Bundle.main.bundleIdentifier!
    
    /// Logs view events
    static let view = Logger(subsystem: subsystem, category: "View")
    
    ///Logging of functions that are used throughout the execution of a normal flight
    static let functionality = Logger(subsystem: subsystem, category: "Functionality")
    
    ///Logs Core Data events
    static let coredata = Logger(subsystem: subsystem, category: "CoreData")
    
    ///Logs error in model
    static let model = Logger(subsystem: subsystem, category: "Model")
    
    ///Logs connectivity and network events
    static let network = Logger(subsystem: subsystem, category: "Network")
    
    ///Logs events with firebase
    static let firebase = Logger(subsystem: subsystem, category: "Firebase")
    
    ///Logs application state
    static let appState = Logger(subsystem: subsystem, category: "Application State")
    
    ///Logs parsing
    static let parsing = Logger(subsystem: subsystem, category: "Parsing")
    
    //Convenience function for creating errors
    static func Error(_ message: String, code: Int = 0, domain: String = "FlightBriefingErrorDomain", function: String = #function, file: String = #file, line: Int = #line) -> NSError {
        
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

let subsystem = Bundle.main.bundleIdentifier
let twoDays:TimeInterval = 60*60*24*2

func getLogEntries() throws -> [OSLogEntryLog] {
    Logger.functionality.debug("Retrieving logs from last hour...")
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

