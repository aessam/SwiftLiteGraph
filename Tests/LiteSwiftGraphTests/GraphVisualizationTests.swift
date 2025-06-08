import XCTest
@testable import LiteSwiftGraph

final class GraphVisualizationTests: XCTestCase {
    
    // MARK: - Mermaid Diagram Tests
    
    func testSimpleMermaidDiagram() {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { $0 }
            Node.context("end") { $0 }
            Edge(from: "start", to: "end")
        }
        
        let diagram = graph.generateMermaidDiagram()
        
        // Verify diagram structure
        XCTAssertTrue(diagram.contains("graph TD;"))
        XCTAssertTrue(diagram.contains("start([Start])"))
        XCTAssertTrue(diagram.contains("end[\"end\"]"))
        XCTAssertTrue(diagram.contains("start -->|\"flow\"| end"))
    }
    
    func testMermaidDiagramWithConditionalEdges() {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { $0 }
            Node.context("branchA") { $0 }
            Node.context("branchB") { $0 }
            
            Edge(from: "start", to: "branchA", description: "condition A", condition: { _ in true })
            Edge(from: "start", to: "branchB", description: "condition B", condition: { _ in false })
        }
        
        let diagram = graph.generateMermaidDiagram()
        
        // Verify conditional edges use dashed lines
        XCTAssertTrue(diagram.contains("start -.->|\"condition A\"| branchA"))
        XCTAssertTrue(diagram.contains("start -.->|\"condition B\"| branchB"))
    }
    
    func testMermaidDiagramWithExecutionPath() {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { $0 }
            Node.context("middle") { $0 }
            Node.context("end") { $0 }
            Edge(from: "start", to: "middle")
            Edge(from: "middle", to: "end")
        }
        
        let executionPath = ["start", "middle", "end"]
        let diagram = graph.generateMermaidDiagramWithPath(executionPath)
        
        // Verify diagram contains style definitions
        XCTAssertTrue(diagram.contains("classDef executedNode"))
        XCTAssertTrue(diagram.contains("class start,middle,end executedNode"))
    }
    
    func testEmptyExecutionPath() {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { $0 }
        }
        
        let diagram = graph.generateMermaidDiagramWithPath([])
        
        // Should not contain any class applications
        XCTAssertFalse(diagram.contains("class "))
    }
    
    func testComplexGraphVisualization() {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            // Multiple nodes
            Node.context("start") { $0 }
            Node.context("process1") { $0 }
            Node.context("process2") { $0 }
            Node.context("decision") { $0 }
            Node.context("pathA") { $0 }
            Node.context("pathB") { $0 }
            Node.context("merge") { $0 }
            Node.context("end") { $0 }
            
            // Complex edge structure
            Edge(from: "start", to: "process1")
            Edge(from: "process1", to: "process2")
            Edge(from: "process2", to: "decision")
            Edge(from: "decision", to: "pathA", description: "option A", condition: { _ in true })
            Edge(from: "decision", to: "pathB", description: "option B", condition: { _ in false })
            Edge(from: "pathA", to: "merge")
            Edge(from: "pathB", to: "merge")
            Edge(from: "merge", to: "end")
        }
        
        let diagram = graph.generateMermaidDiagram()
        
        // Verify all nodes are present
        XCTAssertTrue(diagram.contains("start([Start])"))
        XCTAssertTrue(diagram.contains("process1[\"process1\"]"))
        XCTAssertTrue(diagram.contains("process2[\"process2\"]"))
        XCTAssertTrue(diagram.contains("decision[\"decision\"]"))
        XCTAssertTrue(diagram.contains("pathA[\"pathA\"]"))
        XCTAssertTrue(diagram.contains("pathB[\"pathB\"]"))
        XCTAssertTrue(diagram.contains("merge[\"merge\"]"))
        XCTAssertTrue(diagram.contains("end[\"end\"]"))
        
        // Verify edge count (8 edges total)
        let edgeCount = diagram.components(separatedBy: "->").count - 1
        XCTAssertEqual(edgeCount, 8)
    }
    
    // MARK: - Path Highlighting Tests
    
    func testPartialExecutionPath() {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { $0 }
            Node.context("middle") { $0 }
            Node.context("end") { $0 }
            Edge(from: "start", to: "middle")
            Edge(from: "middle", to: "end")
        }
        
        // Only executed part of the path
        let partialPath = ["start", "middle"]
        let diagram = graph.generateMermaidDiagramWithPath(partialPath)
        
        // Should highlight only executed nodes
        XCTAssertTrue(diagram.contains("class start,middle executedNode"))
        XCTAssertFalse(diagram.contains("class start,middle,end executedNode"))
    }
    
    func testCyclicExecutionPath() {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { $0 }
            Node.context("loop") { $0 }
            Node.context("end") { $0 }
            Edge(from: "start", to: "loop")
            Edge(from: "loop", to: "loop", description: "repeat")
            Edge(from: "loop", to: "end", description: "exit")
        }
        
        // Path with cycle
        let cyclicPath = ["start", "loop", "loop", "loop", "end"]
        let diagram = graph.generateMermaidDiagramWithPath(cyclicPath)
        
        // All unique nodes should be highlighted
        XCTAssertTrue(diagram.contains("class start,loop,loop,loop,end executedNode"))
    }
    
    // MARK: - Edge Cases
    
    func testSingleNodeGraph() {
        let graph = AgentGraph(startNode: "only", outputKey: "result", debug: false) {
            Node.context("only") { $0 }
        }
        
        let diagram = graph.generateMermaidDiagram()
        
        XCTAssertTrue(diagram.contains("only([Start])"))
        XCTAssertFalse(diagram.contains("-->")) // No edges
    }
    
    func testDisconnectedNodes() {
        let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { $0 }
            Node.context("isolated1") { $0 }
            Node.context("isolated2") { $0 }
            Node.context("connected") { $0 }
            Edge(from: "start", to: "connected")
        }
        
        let diagram = graph.generateMermaidDiagram()
        
        // All nodes should appear even if disconnected
        XCTAssertTrue(diagram.contains("start([Start])"))
        XCTAssertTrue(diagram.contains("isolated1[\"isolated1\"]"))
        XCTAssertTrue(diagram.contains("isolated2[\"isolated2\"]"))
        XCTAssertTrue(diagram.contains("connected[\"connected\"]"))
        
        // Only one edge
        let edgeCount = diagram.components(separatedBy: "-->").count - 1
        XCTAssertEqual(edgeCount, 1)
    }
    
    func testSpecialCharactersInNodeNames() {
        let graph = AgentGraph(startNode: "start-node", outputKey: "result", debug: false) {
            Node.context("start-node") { $0 }
            Node.context("node_with_underscore") { $0 }
            Node.context("node123") { $0 }
            Edge(from: "start-node", to: "node_with_underscore")
            Edge(from: "node_with_underscore", to: "node123")
        }
        
        let diagram = graph.generateMermaidDiagram()
        
        // Verify special characters are handled
        XCTAssertTrue(diagram.contains("start-node([Start])"))
        XCTAssertTrue(diagram.contains("node_with_underscore[\"node_with_underscore\"]"))
        XCTAssertTrue(diagram.contains("node123[\"node123\"]"))
    }
}