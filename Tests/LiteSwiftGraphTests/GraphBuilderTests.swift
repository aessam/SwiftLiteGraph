import XCTest
@testable import LiteSwiftGraph

final class GraphBuilderTests: XCTestCase {
    
    // MARK: - AnyNode Tests
    
    func testAnyNodeCreation() {
        let node = Node("test") { (input: String) async throws -> String in
            return input.uppercased()
        }
        
        let anyNode = AnyNode(node)
        
        XCTAssertEqual(anyNode.id, "test")
        XCTAssertTrue(anyNode.node is Node<String, String>)
    }
    
    func testAnyNodeWithDifferentTypes() {
        // Test with different input/output types
        let intNode = Node("intNode") { (input: Int) async throws -> String in
            return String(input * 2)
        }
        
        let contextNode = Node.context("contextNode") { context in
            return context
        }
        
        let anyIntNode = AnyNode(intNode)
        let anyContextNode = AnyNode(contextNode)
        
        XCTAssertEqual(anyIntNode.id, "intNode")
        XCTAssertEqual(anyContextNode.id, "contextNode")
    }
    
    // MARK: - GraphBuilder Tests
    
    func testGraphBuilderWithNodes() {
        let components = GraphBuilder.buildBlock(
            Node.context("node1") { $0 },
            Node.context("node2") { $0 },
            Node.context("node3") { $0 }
        )
        
        XCTAssertEqual(components.count, 3)
        
        // Verify all components are AnyNodes
        for component in components {
            XCTAssertTrue(component is AnyNode)
        }
    }
    
    func testGraphBuilderWithEdges() {
        let components = GraphBuilder.buildBlock(
            Edge(from: "a", to: "b"),
            Edge(from: "b", to: "c"),
            Edge(from: "c", to: "d")
        )
        
        XCTAssertEqual(components.count, 3)
        
        // Verify all components are Edges
        for component in components {
            XCTAssertTrue(component is Edge)
        }
    }
    
    func testGraphBuilderMixedComponents() {
        let components = GraphBuilder.buildBlock(
            Node.context("start") { $0 },
            Edge(from: "start", to: "middle"),
            Node.context("middle") { $0 },
            Edge(from: "middle", to: "end"),
            Node.context("end") { $0 }
        )
        
        XCTAssertEqual(components.count, 5)
        
        // Count nodes and edges
        let nodes = components.compactMap { $0 as? AnyNode }
        let edges = components.compactMap { $0 as? Edge }
        
        XCTAssertEqual(nodes.count, 3)
        XCTAssertEqual(edges.count, 2)
    }
    
    func testGraphBuilderExpression() {
        // Test buildExpression for Node
        let node = Node.context("test") { $0 }
        let anyNode = GraphBuilder.buildExpression(node)
        
        XCTAssertEqual(anyNode.id, "test")
        
        // Test buildExpression for Edge
        let edge = Edge(from: "a", to: "b")
        let builtEdge = GraphBuilder.buildExpression(edge)
        
        XCTAssertEqual(builtEdge.fromNode, "a")
        XCTAssertEqual(builtEdge.toNode, "b")
    }
    
    func testGraphBuilderWithComplexNodes() {
        let components = GraphBuilder.buildBlock(
            Node.context("start") { context in
                context
            }.timeout(seconds: 5.0),
            
            Node.context("process") { context in
                var newContext = context
                newContext["processed"] = true
                return newContext
            }.retry(maxAttempts: 3),
            
            Node.context("end") { context in
                context
            }.onFailure { _, context in
                var errorContext = context
                errorContext["error"] = true
                return errorContext
            }
        )
        
        XCTAssertEqual(components.count, 3)
        
        // Verify node configurations were preserved
        if let startNode = (components[0] as? AnyNode)?.node as? Node<GraphContext, GraphContext> {
            XCTAssertEqual(startNode.timeoutSeconds, 5.0)
        } else {
            XCTFail("Failed to cast start node")
        }
        
        if let processNode = (components[1] as? AnyNode)?.node as? Node<GraphContext, GraphContext> {
            XCTAssertEqual(processNode.retryConfig?.maxAttempts, 3)
        } else {
            XCTFail("Failed to cast process node")
        }
        
        if let endNode = (components[2] as? AnyNode)?.node as? Node<GraphContext, GraphContext> {
            XCTAssertNotNil(endNode.failureHandler)
        } else {
            XCTFail("Failed to cast end node")
        }
    }
}