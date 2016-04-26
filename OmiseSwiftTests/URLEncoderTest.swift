import Foundation
import Omise
import XCTest

class URLEncoderTest: OmiseTestCase {
    func testEncodeBasic() {
        let values: OmiseObject.Attributes = ["hello": "world"]
        let result = URLEncoder.encode(values)
        XCTAssertEqual("hello", result[0].name)
        XCTAssertEqual("world", result[0].value)
    }
    
    func testEncodeMultipleTypes() {
        let values: OmiseObject.Attributes = [
            "0hello": "world",
            "1num": 42,
            "2number": NSNumber(long: 64),
            "3long": NSNumber(longLong: 1234123412341234),
            "4bool": false,
            "5boolean": NSNumber(bool: true),
            "6date": NSDate(timeIntervalSince1970: 0)
        ]
        
        let result = URLEncoder.encode(values).map({ (query) in query.value ?? "(nil)" })
        XCTAssertEqual(result, [
            "world",
            "42",
            "64",
            "1234123412341234",
            "false",
            "true",
            "1970-01-01T07:00:00+07:00"
            ])
    }
    
    func testEncodeNested() {
        let values: OmiseObject.Attributes = [
            "0outer": "normal",
            "1nested": ["inside": "inner"] as OmiseObject.Attributes,
            "2deeper": ["nesting": ["also": "works"]]
        ]
        
        let result = URLEncoder.encode(values)
        XCTAssertEqual("0outer", result[0].name)
        XCTAssertEqual("normal", result[0].value)
        XCTAssertEqual("1nested[inside]", result[1].name)
        XCTAssertEqual("inner", result[1].value)
        XCTAssertEqual("2deeper[nesting][also]", result[2].name)
        XCTAssertEqual("works", result[2].value)
    }
}