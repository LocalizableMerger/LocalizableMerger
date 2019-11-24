import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(localizable_mergerTests.allTests),
    ]
}
#endif
