import XCTest
@testable import Utilities
import OSLog

//let sut = Utilities()

final class UtilitiesTests: XCTestCase {


    func testMinuteStrings() {
        
        var minutes:Int64 = -1 //not set
        XCTAssert(Utilities.minutesToTimeString(minutes) == "", "Got time from unset value")

        minutes = 10
        XCTAssert(Utilities.minutesToTimeString(minutes) == "00:10", "Wrong time")
     
        minutes = 120
        XCTAssert(Utilities.minutesToTimeString(minutes) == "02:00", "Wrong time")
     
        minutes = 60*24+61
        XCTAssert(Utilities.minutesToTimeString(minutes) == "01:01", "Wrong time")
        
        minutes = 60*(24+23)+59
        XCTAssert(Utilities.minutesToTimeString(minutes) == "23:59", "Wrong time")

    }
    
    func testValueStrings() {
        var value:Double = -1
        XCTAssert(Utilities.stringValueIfSet(value, withDecimals: 3) == "", "Got unset value")
        
        value = Double.pi
        XCTAssert(Utilities.stringValueIfSet(value, withDecimals: 0) == "3", "Got errouneous string")
        XCTAssert(Utilities.stringValueIfSet(value, withDecimals: 1) == "3.1", "Got errouneous string")
        XCTAssert(Utilities.stringValueIfSet(value, withDecimals: 3) == "3.142", "Got errouneous string")
        XCTAssert(Utilities.stringValueIfSet(value, withDecimals: 4) == "3.1416", "Got errouneous string")
        
        value = 1.990
        XCTAssert(Utilities.stringValueIfSet(value, withDecimals: 0) == "2", "Got errouneous string")
        XCTAssert(Utilities.stringValueIfSet(value, withDecimals: 1) == "2.0", "Got errouneous string")
        XCTAssert(Utilities.stringValueIfSet(value, withDecimals: 2) == "1.99", "Got errouneous string")

    }

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
