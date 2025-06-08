import XCTest
@testable import LiteSwiftGraph

final class GraphCoreTests: XCTestCase {
    
    // MARK: - Node Tests
    
    func testNodeCreation() {
        let node = Node("testNode") { (input: String) async throws -> String in
            return "Hello, \(input)"
        }
        
        XCTAssertEqual(node.id, "testNode")
        XCTAssertNil(node.retryConfig)
        XCTAssertNil(node.timeoutSeconds)
        XCTAssertNil(node.failureHandler)
    }
    
    func testNodeWithTimeout() {
        let node = Node("testNode") { (input: String) async throws -> String in
            return input
        }.timeout(seconds: 5.0)
        
        XCTAssertEqual(node.timeoutSeconds, 5.0)
    }
    
    func testNodeWithRetry() {
        let node = Node("testNode") { (input: String) async throws -> String in
            return input
        }.retry(maxAttempts: 3, delay: 1.0)
        
        XCTAssertNotNil(node.retryConfig)
        XCTAssertEqual(node.retryConfig?.maxAttempts, 3)
        XCTAssertEqual(node.retryConfig?.delay, 1.0)
    }
    
    func testNodeWithFailureHandler() async throws {
        let node = Node("testNode") { (input: String) async throws -> String in
            throw TestError.simulatedError
        }.onFailure { error, input in
            return "Handled: \(input)"
        }
        
        XCTAssertNotNil(node.failureHandler)
    }
    
    func testNodeChaining() {
        let node = Node("testNode") { (input: String) async throws -> String in
            return input
        }
        .timeout(seconds: 5.0)
        .retry(maxAttempts: 3)
        .onFailure { _, _ in return "failed" }
        
        XCTAssertEqual(node.id, "testNode")
        XCTAssertEqual(node.timeoutSeconds, 5.0)
        XCTAssertEqual(node.retryConfig?.maxAttempts, 3)
        XCTAssertNotNil(node.failureHandler)
    }
    
    // MARK: - Edge Tests
    
    func testEdgeCreation() {
        let edge = Edge(from: "nodeA", to: "nodeB")
        
        XCTAssertEqual(edge.fromNode, "nodeA")
        XCTAssertEqual(edge.toNode, "nodeB")
        XCTAssertNil(edge.condition)
        XCTAssertEqual(edge.description, "")
    }
    
    func testEdgeWithDescription() {
        let edge = Edge(from: "nodeA", to: "nodeB", description: "Success path")
        
        XCTAssertEqual(edge.description, "Success path")
    }
    
    func testEdgeWithCondition() {
        let edge = Edge(from: "nodeA", to: "nodeB", description: "Conditional") { context in
            return context["shouldProceed"] as? Bool ?? false
        }
        
        XCTAssertNotNil(edge.condition)
        
        // Test condition
        let context1: GraphContext = ["shouldProceed": true]
        let context2: GraphContext = ["shouldProceed": false]
        
        XCTAssertTrue(edge.condition!(context1))
        XCTAssertFalse(edge.condition!(context2))
    }
    
    // MARK: - GraphContext Tests
    
    func testGraphContextUsage() {
        var context: GraphContext = [:]
        
        // Test adding various types
        context["string"] = "test"
        context["number"] = 42
        context["array"] = [1, 2, 3]
        context["dict"] = ["nested": "value"]
        
        XCTAssertEqual(context["string"] as? String, "test")
        XCTAssertEqual(context["number"] as? Int, 42)
        XCTAssertEqual(context["array"] as? [Int], [1, 2, 3])
        XCTAssertEqual((context["dict"] as? [String: String])?["nested"], "value")
    }
    
    // MARK: - RetryConfig Tests
    
    func testRetryConfigCreation() {
        let config = RetryConfig(maxAttempts: 5, delay: 2.0)
        
        XCTAssertEqual(config.maxAttempts, 5)
        XCTAssertEqual(config.delay, 2.0)
    }
    
    // MARK: - Context Node Extension Tests
    
    func testContextNodeCreation() {
        let node = Node.context("contextNode") { context in
            var newContext = context
            newContext["processed"] = true
            return newContext
        }
        
        XCTAssertEqual(node.id, "contextNode")
    }
    
    func testContextNodeExecution() async throws {
        let node = Node.context("contextNode") { context in
            var newContext = context
            let input = context["input"] as? String ?? ""
            newContext["output"] = "Processed: \(input)"
            return newContext
        }
        
        let inputContext: GraphContext = ["input": "test"]
        let result = try await node.handler(inputContext)
        
        XCTAssertEqual(result["output"] as? String, "Processed: test")
        XCTAssertEqual(result["input"] as? String, "test")
    }
}

// MARK: - Test Helpers

enum TestError: Error {
    case simulatedError
    case timeout
}