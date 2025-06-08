import Foundation
import LiteSwiftGraph

// MARK: - Graph Renderer

public struct GraphLayout {
    let nodePositions: [String: (x: Int, y: Int)]
    let canvasWidth: Int
    let canvasHeight: Int
}

public class GraphRenderer {
    private let graph: AgentGraph
    
    public init(graph: AgentGraph) {
        self.graph = graph
    }
    
    // MARK: - Layout Generation
    
    private func generateLayout() -> GraphLayout {
        let nodes = graph.getNodes().sorted()
        let edges = graph.getEdges()
        
        // Simple hierarchical layout
        var levels: [[String]] = []
        var nodeLevel: [String: Int] = [:]
        var visited: Set<String> = []
        
        // Start with the start node
        let startNode = graph.getStartNodeId()
        levels.append([startNode])
        nodeLevel[startNode] = 0
        visited.insert(startNode)
        
        // Build levels using BFS
        var currentLevel = 0
        while currentLevel < levels.count {
            var nextLevel: [String] = []
            
            for node in levels[currentLevel] {
                let outgoingEdges = edges.filter { $0.fromNode == node }
                for edge in outgoingEdges {
                    if !visited.contains(edge.toNode) {
                        nextLevel.append(edge.toNode)
                        visited.insert(edge.toNode)
                        nodeLevel[edge.toNode] = currentLevel + 1
                    }
                }
            }
            
            if !nextLevel.isEmpty {
                levels.append(nextLevel)
            }
            currentLevel += 1
        }
        
        // Add any unvisited nodes to the last level
        let unvisited = nodes.filter { !visited.contains($0) }
        if !unvisited.isEmpty {
            levels.append(unvisited)
        }
        
        // Calculate positions
        var positions: [String: (x: Int, y: Int)] = [:]
        let verticalSpacing = 4
        let horizontalSpacing = 15
        
        for (levelIndex, level) in levels.enumerated() {
            let y = levelIndex * verticalSpacing + 2
            let levelWidth = level.count * horizontalSpacing
            let startX = (80 - levelWidth) / 2 // Center on 80-char width
            
            for (nodeIndex, node) in level.enumerated() {
                let x = startX + nodeIndex * horizontalSpacing
                positions[node] = (x: max(0, x), y: y)
            }
        }
        
        let maxY = (levels.count - 1) * verticalSpacing + 4
        return GraphLayout(nodePositions: positions, canvasWidth: 80, canvasHeight: maxY)
    }
    
    // MARK: - ASCII Rendering
    
    public func renderASCII(highlightedNodes: Set<String> = [], currentNode: String? = nil) -> String {
        let layout = generateLayout()
        let edges = graph.getEdges()
        
        // Create canvas
        var canvas: [[Character]] = Array(
            repeating: Array(repeating: " ", count: layout.canvasWidth),
            count: layout.canvasHeight
        )
        
        // Draw edges first (so nodes appear on top)
        for edge in edges {
            if let fromPos = layout.nodePositions[edge.fromNode],
               let toPos = layout.nodePositions[edge.toNode] {
                drawEdge(on: &canvas, from: fromPos, to: toPos, conditional: edge.condition != nil)
            }
        }
        
        // Draw nodes
        for (node, position) in layout.nodePositions {
            let isHighlighted = highlightedNodes.contains(node)
            let isCurrent = node == currentNode
            let isStart = node == graph.getStartNodeId()
            
            drawNode(on: &canvas, at: position, name: node, 
                    highlighted: isHighlighted, current: isCurrent, start: isStart)
        }
        
        // Convert canvas to string
        return canvas.map { String($0) }.joined(separator: "\n")
    }
    
    private func drawNode(on canvas: inout [[Character]], at position: (x: Int, y: Int), 
                         name: String, highlighted: Bool, current: Bool, start: Bool) {
        let nodeWidth = min(name.count + 4, 12)
        let displayName = String(name.prefix(nodeWidth - 4))
        
        // Node box characters
        let topLeft = current ? "╔" : (highlighted ? "┏" : "┌")
        let topRight = current ? "╗" : (highlighted ? "┓" : "┐")
        let bottomLeft = current ? "╚" : (highlighted ? "┗" : "└")
        let bottomRight = current ? "╝" : (highlighted ? "┛" : "┘")
        let horizontal = current ? "═" : (highlighted ? "━" : "─")
        let vertical = current ? "║" : (highlighted ? "┃" : "│")
        
        let y = position.y
        let x = position.x
        
        // Ensure we're within canvas bounds
        guard y > 0 && y < canvas.count - 1 else { return }
        
        // Draw top line
        if x < canvas[0].count {
            canvas[y-1][x] = Character(topLeft)
            for i in 1..<nodeWidth-1 {
                if x + i < canvas[0].count {
                    canvas[y-1][x+i] = Character(horizontal)
                }
            }
            if x + nodeWidth - 1 < canvas[0].count {
                canvas[y-1][x+nodeWidth-1] = Character(topRight)
            }
        }
        
        // Draw middle line with name
        if x < canvas[0].count {
            canvas[y][x] = Character(vertical)
            
            let label = start ? "START" : displayName
            let padding = (nodeWidth - label.count - 2) / 2
            let paddedLabel = String(repeating: " ", count: padding) + label
            
            for (i, char) in paddedLabel.enumerated() {
                if x + i + 1 < canvas[0].count {
                    canvas[y][x+i+1] = char
                }
            }
            
            if x + nodeWidth - 1 < canvas[0].count {
                canvas[y][x+nodeWidth-1] = Character(vertical)
            }
        }
        
        // Draw bottom line
        if y + 1 < canvas.count && x < canvas[0].count {
            canvas[y+1][x] = Character(bottomLeft)
            for i in 1..<nodeWidth-1 {
                if x + i < canvas[0].count {
                    canvas[y+1][x+i] = Character(horizontal)
                }
            }
            if x + nodeWidth - 1 < canvas[0].count {
                canvas[y+1][x+nodeWidth-1] = Character(bottomRight)
            }
        }
    }
    
    private func drawEdge(on canvas: inout [[Character]], 
                         from: (x: Int, y: Int), to: (x: Int, y: Int), 
                         conditional: Bool) {
        // Simple vertical line drawing
        let fromY = from.y + 2
        let toY = to.y - 1
        let midX = (from.x + to.x) / 2 + 5 // Offset to center of node
        
        if fromY < toY && midX < canvas[0].count {
            for y in fromY..<toY {
                if y < canvas.count {
                    canvas[y][midX] = conditional ? "┊" : "│"
                }
            }
            
            // Add arrow
            if toY - 1 >= 0 && toY - 1 < canvas.count {
                canvas[toY-1][midX] = "▼"
            }
        }
    }
    
    // MARK: - Live Rendering
    
    public func renderLive(executionPath: [String], currentNode: String?) -> String {
        let highlighted = Set(executionPath)
        return renderASCII(highlightedNodes: highlighted, currentNode: currentNode)
    }
}

// MARK: - ASCII Visualization Extension

extension AgentGraph {
    public func generateASCIIDiagram() -> String {
        var diagram = ""
        let nodesList = getNodes().sorted()
        
        // Simple ASCII representation
        diagram += "Graph Structure:\n"
        diagram += "===============\n\n"
        
        for nodeId in nodesList {
            let marker = nodeId == getStartNodeId() ? "[START]" : "[NODE]"
            diagram += "\(marker) \(nodeId)\n"
            
            // Find outgoing edges
            let outgoingEdges = getEdges().filter { $0.fromNode == nodeId }
            for edge in outgoingEdges {
                let arrow = edge.condition != nil ? "  --?->" : "  --->"
                let desc = edge.description.isEmpty ? "" : " (\(edge.description))"
                diagram += "\(arrow) \(edge.toNode)\(desc)\n"
            }
            diagram += "\n"
        }
        
        return diagram
    }
    
    public func printASCIIDiagram() {
        print(generateASCIIDiagram())
    }
}

// MARK: - Debug Coordinator

public class GraphDebugCoordinator {
    private let graph: AgentGraph
    private let console: GraphDebugConsole
    private let renderer: GraphRenderer
    private var executionPath: [String] = []
    private var currentNode: String?
    
    public init(graph: AgentGraph) {
        self.graph = graph
        self.console = GraphDebugConsole(graph: graph)
        self.renderer = GraphRenderer(graph: graph)
        
        // Create custom observer
        let observer = DebugCoordinatorObserver(coordinator: self)
        graph.addObserver(observer)
    }
    
    private func updateVisualization() {
        print("\n=== Graph Visualization ===")
        print(renderer.renderLive(executionPath: executionPath, currentNode: currentNode))
        print("==========================\n")
    }
    
    fileprivate func handleNodeStarted(nodeId: String) {
        currentNode = nodeId
        updateVisualization()
    }
    
    fileprivate func handleNodeCompleted(nodeId: String) {
        if !executionPath.contains(nodeId) {
            executionPath.append(nodeId)
        }
        currentNode = nil
        updateVisualization()
    }
}

// Helper observer for coordinator
private class DebugCoordinatorObserver: GraphExecutionObserver {
    weak var coordinator: GraphDebugCoordinator?
    
    init(coordinator: GraphDebugCoordinator) {
        self.coordinator = coordinator
    }
    
    func nodeExecutionStarted(nodeId: String, context: GraphContext) {
        coordinator?.handleNodeStarted(nodeId: nodeId)
    }
    
    func nodeExecutionCompleted(nodeId: String, result: GraphContext) {
        coordinator?.handleNodeCompleted(nodeId: nodeId)
    }
}