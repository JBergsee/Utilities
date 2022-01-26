import XCTest
@testable import Utilities
import OSLog

final class UtilitiesTests: XCTestCase {



    func testLogging() {
        
        var logs = [OSLogEntryLog]()
        
        measure {
            //Getting logs is pretty slow, preferably this should be on a background thread
            logs = try! getLogEntries()
        }
        XCTAssert(logs.count > 0, "No logs!")
        print("**************************** Log: ****************************")
        logs.forEach { entry in
            print("\(entry.subsystem): \(entry.composedMessage)")
        }
        print("**************************** End log: ************************")

    }
}
