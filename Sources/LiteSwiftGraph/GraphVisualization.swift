import Foundation

// MARK: - Graph Visualization

extension AgentGraph {
    
    // MARK: - Mermaid Diagram Generation
    
    public func generateMermaidDiagram() -> String {
        var diagram = "graph TD;\n"
        
        // Add all nodes
        for nodeId in getNodes() {
            let shape = nodeId == getStartNodeId() ? "([Start])" : "[\"\(nodeId)\"]"
            diagram += "    \(nodeId)\(shape);\n"
        }
        
        // Add all edges
        for edge in getEdges() {
            let edgeStyle = edge.condition != nil ? "-.->|\"" : "-->|\""
            let edgeLabel = edge.description.isEmpty ? "flow" : edge.description
            diagram += "    \(edge.fromNode) \(edgeStyle)\(edgeLabel)\"| \(edge.toNode);\n"
        }
        
        return diagram
    }
    
    public func generateMermaidDiagramWithPath(_ executionPath: [String]) -> String {
        var diagram = "graph TD;\n"
        
        // Define a style for the execution path
        diagram += "    classDef executedNode fill:#FF6666,stroke:#990000,color:white,stroke-width:2px;\n"
        diagram += "    classDef executedEdge stroke:#FF0000,stroke-width:2px;\n"
        
        // Add all nodes
        for nodeId in getNodes() {
            let shape = nodeId == getStartNodeId() ? "([Start])" : "[\"\(nodeId)\"]"
            diagram += "    \(nodeId)\(shape);\n"
        }
        
        // Add all edges
        for edge in getEdges() {
            let edgeStyle = edge.condition != nil ? "-.->|\"" : "-->|\""
            let edgeLabel = edge.description.isEmpty ? "flow" : edge.description
            
            diagram += "    \(edge.fromNode) \(edgeStyle)\(edgeLabel)\"| \(edge.toNode);\n"
        }
        
        // Apply class to executed nodes
        if !executionPath.isEmpty {
            diagram += "    class " + executionPath.joined(separator: ",") + " executedNode;\n"
        }
        
        // Generate IDs for executed edges and apply class
        if executionPath.count > 1 {
            var executedEdgeIDs: [String] = []
            for i in 0..<(executionPath.count - 1) {
                let fromNode = executionPath[i]
                let toNode = executionPath[i + 1]
                
                // Find all edges between these nodes
                let relevantEdges = getEdges().filter { $0.fromNode == fromNode && $0.toNode == toNode }
                
                // Add edge IDs to the list
                for _ in relevantEdges {
                    let edgeId = "edge_\(fromNode)_\(toNode)"
                    executedEdgeIDs.append(edgeId)
                }
            }
            
            // Apply class to edges if any were found
            if !executedEdgeIDs.isEmpty {
                diagram += "    linkStyle " + executedEdgeIDs.indices.map { String($0) }.joined(separator: ",") + " stroke:#FF0000,stroke-width:2px;\n"
            }
        }
        
        return diagram
    }
    
    public func printMermaidDiagram() {
        print("=== Graph Visualization (Mermaid) ===")
        print(generateMermaidDiagram())
        print("=====================================")
    }
    
    public func printMermaidDiagramWithPath(_ executionPath: [String]) {
        print("=== Graph Execution Path (Mermaid) ===")
        print(generateMermaidDiagramWithPath(executionPath))
        print("======================================")
    }
}