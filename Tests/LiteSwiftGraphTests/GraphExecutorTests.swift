import XCTest
@testable import LiteSwiftGraph

final class GraphExecutorTests: XCTestCase {
    
    // MARK: - Basic Execution Tests
    
    func testSimpleLinearExecution() async throws {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                var newContext = context
                newContext["value"] = 1
                return newContext
            }
            
            Node.context("middle") { context in
                var newContext = context
                let value = context["value"] as? Int ?? 0
                newContext["value"] = value + 1
                return newContext
            }
            
            Node.context("end") { context in
                var newContext = context
                let value = context["value"] as? Int ?? 0
                newContext["result"] = value + 1
                return newContext
            }
            
            Edge(from: "start", to: "middle")
            Edge(from: "middle", to: "end")
        }
        
        let result = try await graph.run("test input")
        XCTAssertEqual(result as? Int, 3)
    }
    
    func testStartNodeNotFound() async throws {
        let graph = AgentGraph(startNode: "missingStart", outputKey: "result", debug: false) {
            Node.context("someNode") { $0 }
        }
        
        do {
            _ = try await graph.run("test")
            XCTFail("Should have thrown nodeNotFound error")
        } catch GraphError.nodeNotFound(let id) {
            XCTAssertEqual(id, "missingStart")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testMissingOutputKey() async throws {
        let graph = AgentGraph(startNode: "start", outputKey: "missingKey", debug: false) {
            Node.context("start") { context in
                var newContext = context
                newContext["wrongKey"] = "value"
                return newContext
            }
        }
        
        do {
            _ = try await graph.run("test")
            XCTFail("Should have thrown outputKeyMissing error")
        } catch GraphError.outputKeyMissing(let key) {
            XCTAssertEqual(key, "missingKey")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Conditional Execution Tests
    
    func testConditionalBranching() async throws {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                var newContext = context
                newContext["branch"] = context["input"] as? String == "left"
                return newContext
            }
            
            Node.context("leftBranch") { context in
                var newContext = context
                newContext["result"] = "went left"
                return newContext
            }
            
            Node.context("rightBranch") { context in
                var newContext = context
                newContext["result"] = "went right"
                return newContext
            }
            
            Edge(from: "start", to: "leftBranch", condition: { context in
                context["branch"] as? Bool == true
            })
            
            Edge(from: "start", to: "rightBranch", condition: { context in
                context["branch"] as? Bool == false
            })
        }
        
        // Test left branch
        let leftResult = try await graph.run("left")
        XCTAssertEqual(leftResult as? String, "went left")
        
        // Test right branch
        let rightResult = try await graph.run("right")
        XCTAssertEqual(rightResult as? String, "went right")
    }
    
    // MARK: - Error Handling Tests
    
    func testNodeFailureWithHandler() async throws {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                throw TestError.simulatedError
            }.onFailure { error, context in
                var newContext = context
                newContext["result"] = "handled error"
                return newContext
            }
        }
        
        let result = try await graph.run("test")
        XCTAssertEqual(result as? String, "handled error")
    }
    
    func testNodeFailureWithoutHandler() async throws {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                throw TestError.simulatedError
            }
        }
        
        do {
            _ = try await graph.run("test")
            XCTFail("Should have thrown error")
        } catch TestError.simulatedError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Retry Tests
    
    func testNodeRetrySuccess() async throws {
        var attemptCount = 0
        
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                attemptCount += 1
                if attemptCount < 3 {
                    throw TestError.simulatedError
                }
                var newContext = context
                newContext["result"] = "success after \(attemptCount) attempts"
                return newContext
            }.retry(maxAttempts: 3, delay: 0.01) // Short delay for tests
        }
        
        let result = try await graph.run("test")
        XCTAssertEqual(attemptCount, 3)
        XCTAssertEqual(result as? String, "success after 3 attempts")
    }
    
    func testNodeRetryFailure() async throws {
        var attemptCount = 0
        
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                attemptCount += 1
                throw TestError.simulatedError
            }.retry(maxAttempts: 2, delay: 0.01)
        }
        
        do {
            _ = try await graph.run("test")
            XCTFail("Should have thrown error after retries")
        } catch TestError.simulatedError {
            XCTAssertEqual(attemptCount, 2)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Timeout Tests
    
    func testNodeTimeout() async throws {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                var newContext = context
                newContext["result"] = "completed"
                return newContext
            }.timeout(seconds: 0.1) // 100ms timeout
        }
        
        do {
            _ = try await graph.run("test")
            XCTFail("Should have timed out")
        } catch GraphError.timeout {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Complex Flow Tests
    
    func testCycleDetection() async throws {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                var newContext = context
                newContext["count"] = 1
                return newContext
            }
            
            Node.context("loop") { context in
                var newContext = context
                let count = (context["count"] as? Int ?? 0) + 1
                newContext["count"] = count
                return newContext
            }
            
            Edge(from: "start", to: "loop")
            Edge(from: "loop", to: "loop") // Self-loop
        }
        
        do {
            _ = try await graph.run("test")
            XCTFail("Should have detected cycle")
        } catch GraphError.invalidWorkflow {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testMultiplePathsToSameNode() async throws {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                var newContext = context
                newContext["path"] = "start"
                return newContext
            }
            
            Node.context("pathA") { context in
                var newContext = context
                newContext["path"] = (context["path"] as? String ?? "") + "->A"
                return newContext
            }
            
            Node.context("pathB") { context in
                var newContext = context
                newContext["path"] = (context["path"] as? String ?? "") + "->B"
                return newContext
            }
            
            Node.context("end") { context in
                var newContext = context
                let path = context["path"] as? String ?? ""
                newContext["result"] = path + "->end"
                return newContext
            }
            
            // Multiple paths: start -> A -> end, start -> B -> end
            Edge(from: "start", to: "pathA", condition: { context in
                context["input"] as? String == "A"
            })
            Edge(from: "start", to: "pathB", condition: { context in
                context["input"] as? String == "B"
            })
            Edge(from: "pathA", to: "end")
            Edge(from: "pathB", to: "end")
        }
        
        let resultA = try await graph.run("A")
        XCTAssertEqual(resultA as? String, "start->A->end")
        
        let resultB = try await graph.run("B")
        XCTAssertEqual(resultB as? String, "start->B->end")
    }
    
    // MARK: - Debug Mode Tests
    
    func testDebugMode() async throws {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: true) {
            Node.context("start") { context in
                var newContext = context
                newContext["result"] = "debug test"
                return newContext
            }
        }
        
        // This test mainly verifies that debug mode doesn't break execution
        let result = try await graph.run("test")
        XCTAssertEqual(result as? String, "debug test")
    }
}