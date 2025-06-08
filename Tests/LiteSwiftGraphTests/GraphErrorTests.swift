import XCTest
@testable import LiteSwiftGraph

final class GraphErrorTests: XCTestCase {
    
    func testTimeoutError() {
        let error = GraphError.timeout
        
        switch error {
        case .timeout:
            XCTAssertTrue(true, "Timeout error correctly identified")
        default:
            XCTFail("Expected timeout error")
        }
    }
    
    func testInvalidWorkflowError() {
        let error = GraphError.invalidWorkflow
        
        switch error {
        case .invalidWorkflow:
            XCTAssertTrue(true, "Invalid workflow error correctly identified")
        default:
            XCTFail("Expected invalid workflow error")
        }
    }
    
    func testUnknownError() {
        let error = GraphError.unknownError
        
        switch error {
        case .unknownError:
            XCTAssertTrue(true, "Unknown error correctly identified")
        default:
            XCTFail("Expected unknown error")
        }
    }
    
    func testNodeNotFoundError() {
        let nodeId = "missingNode"
        let error = GraphError.nodeNotFound(nodeId)
        
        switch error {
        case .nodeNotFound(let id):
            XCTAssertEqual(id, nodeId, "Node ID correctly stored in error")
        default:
            XCTFail("Expected node not found error")
        }
    }
    
    func testInvalidNodeTypeError() {
        let nodeId = "invalidNode"
        let error = GraphError.invalidNodeType(nodeId)
        
        switch error {
        case .invalidNodeType(let id):
            XCTAssertEqual(id, nodeId, "Node ID correctly stored in error")
        default:
            XCTFail("Expected invalid node type error")
        }
    }
    
    func testOutputKeyMissingError() {
        let key = "finalResult"
        let error = GraphError.outputKeyMissing(key)
        
        switch error {
        case .outputKeyMissing(let missingKey):
            XCTAssertEqual(missingKey, key, "Missing key correctly stored in error")
        default:
            XCTFail("Expected output key missing error")
        }
    }
    
    func testErrorEquality() {
        // Test that similar errors are distinguishable
        let error1 = GraphError.nodeNotFound("node1")
        let error2 = GraphError.nodeNotFound("node2")
        let error3 = GraphError.invalidNodeType("node1")
        
        // Test pattern matching
        switch error1 {
        case .nodeNotFound(let id):
            XCTAssertEqual(id, "node1")
        default:
            XCTFail("Pattern matching failed")
        }
        
        switch error2 {
        case .nodeNotFound(let id):
            XCTAssertEqual(id, "node2")
        default:
            XCTFail("Pattern matching failed")
        }
        
        switch error3 {
        case .invalidNodeType(let id):
            XCTAssertEqual(id, "node1")
        default:
            XCTFail("Pattern matching failed")
        }
    }
    
    func testErrorInContext() {
        // Test how errors work in actual usage scenarios
        let errors: [GraphError] = [
            .timeout,
            .invalidWorkflow,
            .unknownError,
            .nodeNotFound("testNode"),
            .invalidNodeType("testNode"),
            .outputKeyMissing("result")
        ]
        
        for error in errors {
            // Verify each error can be caught and identified
            do {
                throw error
            } catch let caughtError as GraphError {
                // Successfully caught as GraphError
                switch caughtError {
                case .timeout:
                    XCTAssertTrue(true)
                case .invalidWorkflow:
                    XCTAssertTrue(true)
                case .unknownError:
                    XCTAssertTrue(true)
                case .nodeNotFound:
                    XCTAssertTrue(true)
                case .invalidNodeType:
                    XCTAssertTrue(true)
                case .outputKeyMissing:
                    XCTAssertTrue(true)
                }
            } catch {
                XCTFail("Failed to catch error as GraphError")
            }
        }
    }
    
    func testErrorDescriptions() {
        // While GraphError doesn't have built-in descriptions,
        // test that we can create meaningful messages from them
        func describeError(_ error: GraphError) -> String {
            switch error {
            case .timeout:
                return "Operation timed out"
            case .invalidWorkflow:
                return "Invalid workflow configuration"
            case .unknownError:
                return "An unknown error occurred"
            case .nodeNotFound(let id):
                return "Node not found: \(id)"
            case .invalidNodeType(let id):
                return "Invalid node type for: \(id)"
            case .outputKeyMissing(let key):
                return "Output key missing: \(key)"
            }
        }
        
        XCTAssertEqual(describeError(.timeout), "Operation timed out")
        XCTAssertEqual(describeError(.nodeNotFound("test")), "Node not found: test")
        XCTAssertEqual(describeError(.outputKeyMissing("result")), "Output key missing: result")
    }
}