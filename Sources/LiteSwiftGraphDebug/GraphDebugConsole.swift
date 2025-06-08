import Foundation
import LiteSwiftGraph

// MARK: - Debug Console

public class GraphDebugConsole: GraphExecutionObserver {
    private var startTime: Date?
    private var currentNodeId: String?
    private var executionPath: [String] = []
    private var contextSnapshot: GraphContext = [:]
    private let graph: AgentGraph
    
    public init(graph: AgentGraph) {
        self.graph = graph
        graph.addObserver(self)
    }
    
    deinit {
        graph.removeObserver(self)
    }
    
    // MARK: - Console Display
    
    private func clearConsole() {
        print("\u{001B}[2J\u{001B}[H") // Clear screen and move cursor to top
    }
    
    private func drawBox(title: String, content: [String], width: Int = 60) {
        let horizontalLine = String(repeating: "═", count: width - 2)
        
        print("╔\(horizontalLine)╗")
        
        // Title
        let titlePadding = (width - title.count - 2) / 2
        let titleLine = String(repeating: " ", count: titlePadding) + title + String(repeating: " ", count: width - titlePadding - title.count - 2)
        print("║\(titleLine)║")
        
        print("╠\(horizontalLine)╣")
        
        // Content
        for line in content {
            let truncated = String(line.prefix(width - 4))
            let padded = truncated.padding(toLength: width - 2, withPad: " ", startingAt: 0)
            print("║\(padded)║")
        }
        
        print("╚\(horizontalLine)╝")
    }
    
    private func formatContextVariables() -> [String] {
        var lines: [String] = []
        
        for (key, value) in contextSnapshot.sorted(by: { $0.key < $1.key }) {
            let valueStr: String
            
            switch value {
            case let str as String:
                valueStr = "\"\(str)\""
            case let num as Int:
                valueStr = String(num)
            case let num as Double:
                valueStr = String(format: "%.2f", num)
            case let bool as Bool:
                valueStr = bool ? "true" : "false"
            case let array as [Any]:
                valueStr = "[\(array.count) items]"
            case let dict as [String: Any]:
                valueStr = "{\(dict.count) entries}"
            default:
                valueStr = String(describing: type(of: value))
            }
            
            lines.append(" • \(key): \(valueStr)")
        }
        
        return lines.isEmpty ? [" (No variables)"] : lines
    }
    
    private func formatExecutionPath() -> [String] {
        var lines: [String] = []
        let allNodes = graph.getNodes().sorted()
        
        for node in allNodes {
            let symbol: String
            let status: String
            
            if node == currentNodeId {
                symbol = "▶"
                status = "(executing...)"
            } else if executionPath.contains(node) {
                symbol = "●"
                status = "✓"
            } else {
                symbol = "○"
                status = ""
            }
            
            lines.append(" \(symbol) \(node) \(status)")
        }
        
        return lines
    }
    
    private func formatProgress() -> String {
        let executed = executionPath.count
        let total = graph.getNodes().count
        let percentage = total > 0 ? Double(executed) / Double(total) : 0.0
        let filled = Int(percentage * 20)
        let empty = 20 - filled
        
        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
        return " Progress: \(bar) (\(executed)/\(total))"
    }
    
    private func updateDisplay() {
        clearConsole()
        
        // Title
        drawBox(title: "Graph Execution Monitor", content: [
            " Current Node: [\(currentNodeId ?? "none")]",
            " Stage: \(contextSnapshot["stage"] as? String ?? "unknown")",
            formatProgress()
        ])
        
        // Execution Path
        print("")
        drawBox(title: "Execution Path", content: formatExecutionPath())
        
        // Context Variables
        print("")
        drawBox(title: "Context Variables", content: formatContextVariables())
        
        // Timing
        if let startTime = startTime {
            let elapsed = Date().timeIntervalSince(startTime)
            print("\n Elapsed Time: \(String(format: "%.2f", elapsed))s")
        }
    }
    
    // MARK: - GraphExecutionObserver
    
    public func graphExecutionStarted(initialContext: GraphContext) {
        startTime = Date()
        executionPath = []
        contextSnapshot = initialContext
        updateDisplay()
    }
    
    public func nodeExecutionStarted(nodeId: String, context: GraphContext) {
        currentNodeId = nodeId
        contextSnapshot = context
        updateDisplay()
    }
    
    public func nodeExecutionCompleted(nodeId: String, result: GraphContext) {
        if !executionPath.contains(nodeId) {
            executionPath.append(nodeId)
        }
        contextSnapshot = result
        currentNodeId = nil
        updateDisplay()
    }
    
    public func nodeExecutionFailed(nodeId: String, error: Error) {
        print("\n⚠️  Error in node '\(nodeId)': \(error)")
    }
    
    public func graphExecutionCompleted(finalContext: GraphContext, executionPath: [String]) {
        self.executionPath = executionPath
        contextSnapshot = finalContext
        currentNodeId = nil
        updateDisplay()
        
        print("\n✅ Execution completed!")
        if let elapsed = startTime.map({ Date().timeIntervalSince($0) }) {
            print("   Total time: \(String(format: "%.2f", elapsed))s")
        }
    }
}

// MARK: - Interactive Debug Console

public class InteractiveDebugConsole: GraphDebugConsole {
    private var isPaused = false
    private var stepMode = false
    private let pauseLock = NSLock()
    
    public override func nodeExecutionStarted(nodeId: String, context: GraphContext) {
        super.nodeExecutionStarted(nodeId: nodeId, context: context)
        
        if stepMode {
            print("\n⏸  Paused at node: \(nodeId)")
            print("   Press ENTER to continue, 'c' to continue without stepping...")
            
            if let input = readLine() {
                if input.lowercased() == "c" {
                    stepMode = false
                    print("   Continuing execution...")
                }
            }
        }
    }
    
    public func enableStepMode() {
        stepMode = true
    }
    
    public func disableStepMode() {
        stepMode = false
    }
}