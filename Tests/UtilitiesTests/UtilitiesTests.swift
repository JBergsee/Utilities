import XCTest
@testable import Utilities
import OSLog


final class UtilitiesTests: XCTestCase {

    func testMinuteStrings() {
        
        let minutes:Int64 = -1 //not set
        XCTAssert(Utilities.timeStringWith(minutes: minutes) == "", "Got time from unset value")

        let minutes2:UInt = 10
        XCTAssert(Utilities.timeStringWith(minutes: minutes2) == "00:10", "Wrong time")
     
        let minutes3:Int = 120
        XCTAssert(Utilities.timeStringWith(minutes: minutes3) == "02:00", "Wrong time")
     
        let minutes4:Int32 = 60*24+61
        XCTAssert(Utilities.timeStringWith(minutes: minutes4) == "01:01", "Wrong time")
        
        let minutes5:UInt = 60*(24+23)+59
        XCTAssert(Utilities.timeStringWith(minutes: minutes5) == "23:59", "Wrong time")

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
  
    func testStringSlicing() {
        let noD = "A0208/22 NOTAMN\nQ) VVHM/QMXHW/IV/BO/A/000/999/1049N10640E005\nA) VVTS B) 2201260958 C) PERM\nE) THE INSTALLATION OF THE LGT SYSTEM AND SIGNBOARDS ON TWY S (THE\nPORTION FM S5 TO S6) AND TWY S6, DETAILS AS FLW:\n1. ON TWY S (THE PORTION FM S5 TO S6):\n- TWY EGDE LGT\n- TWY CL LGT\n- IMT HLDG PSN LGT\n- SIGNBOARDS\n2. ON TWY S6: \n- TWY EGDE LGT\n- TWY CL LGT\n- STOP BARS LGT\n- SIGNBOARDS\nHR OF OPS: H24\nREF AIP VIET NAM PAGE AD 2.VVTS-7 DATED 30 MAR 2021.\n"
        
        let withD = "A0688/22 NOTAMN\nQ) MMFR/QMRLC/IV/NBO/A/000/999/2031N10319W005\nA) MMGL B) 2202060600 C) 2202270930\nD) 06 13 20 27 0600-0930\nE) RWY 10/28 CLSD\n"
        
        
        let test1 = noD.slice(from: "\nD) ", to: "\nE)")
        XCTAssert(test1 == nil, "Got something I shouldn't")
        
        let test2 = withD.slice(from: "\nD) ", to: "\nE)")
        XCTAssert(test2 == "06 13 20 27 0600-0930", "Got something I shouldn't")
        
    }
    func testRangeFinding() {
        let testString = "(abeam) A long name with bea"
        let searchA = "a"
        var ranges = testString.ranges(ofText: searchA)
        XCTAssert(ranges.count == 5)
        XCTAssert(ranges[0] == NSRange(location: 1, length: 1))
        XCTAssert(ranges[1] == NSRange(location: 4, length: 1))
        XCTAssert(ranges[2] == NSRange(location: 8, length: 1))
        XCTAssert(ranges[3] == NSRange(location: 16, length: 1))
        XCTAssert(ranges[4] == NSRange(location: 27, length: 1))

        let excludeBea = "Bea"
        ranges = testString.ranges(ofText: searchA, excludeText: excludeBea)
        XCTAssert(ranges.count == 3)
        XCTAssert(ranges[0] == NSRange(location: 1, length: 1))
        XCTAssert(ranges[1] == NSRange(location: 8, length: 1))
        XCTAssert(ranges[2] == NSRange(location: 16, length: 1))

    }
}
