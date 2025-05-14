import XCTest
@testable import BalanceFetcher

final class ScriptExecutorTests: XCTestCase {
    var scriptExecutor: ScriptExecutor!
    
    override func setUp() {
        super.setUp()
        scriptExecutor = ScriptExecutor()
    }
    
    override func tearDown() {
        scriptExecutor = nil
        super.tearDown()
    }
    
    func testTestCommand() {
        let result = scriptExecutor.executeTestCommand()
        
        switch result {
        case .success(let output):
            XCTAssertEqual(output, "$1,234.56", "Test command should return the expected output")
        case .failure(let error):
            XCTFail("Test command should not fail. Error: \(error)")
        }
    }
}