#if canImport(SwiftUI)
import SwiftUI
import Combine
import LiteSwiftGraph

@MainActor
public class GraphViewModel: ObservableObject {
    @Published var isExecuting = false
    @Published var executionResult: String = ""
    @Published var executionLog: [String] = []
    @Published var currentNode: String = ""
    @Published var executedNodes: Set<String> = []
    @Published var allNodes: [String] = []
    @Published var edges: [LiteSwiftGraph.Edge] = []
    @Published var selectedExample: GraphExample = .simpleWorkflow
    @Published var customInput: String = "What is quantum computing?"
    @Published var mermaidDiagram: String = ""
    
    private var currentGraph: AgentGraph?
    private var cancellables = Set<AnyCancellable>()
    
    public enum GraphExample: String, CaseIterable {
        case simpleWorkflow = "Simple Research Workflow"
        case conditionalBranching = "Conditional Branching"
        case retryExample = "Retry & Error Handling"
        case complexWorkflow = "Complex Multi-Stage"
        
        public var description: String {
            switch self {
            case .simpleWorkflow:
                return "A linear workflow demonstrating basic graph execution"
            case .conditionalBranching:
                return "Shows conditional edges and branching logic"
            case .retryExample:
                return "Demonstrates retry mechanisms and error handling"
            case .complexWorkflow:
                return "A complex workflow with parallel processing"
            }
        }
    }
    
    public init() {
        loadSelectedExample()
    }
    
    public func loadSelectedExample() {
        switch selectedExample {
        case .simpleWorkflow:
            currentGraph = createSimpleWorkflow()
        case .conditionalBranching:
            currentGraph = createConditionalBranching()
        case .retryExample:
            currentGraph = createRetryExample()
        case .complexWorkflow:
            currentGraph = createComplexWorkflow()
        }
        
        updateGraphInfo()
    }
    
    private func updateGraphInfo() {
        guard let graph = currentGraph else { return }
        
        let graphNodes = Set(graph.getNodes())
        let edgeNodes = Set(graph.getEdges().flatMap { [$0.fromNode, $0.toNode] })
        
        // Ensure all nodes referenced in edges are included
        allNodes = Array(graphNodes.union(edgeNodes))
        edges = graph.getEdges()
        mermaidDiagram = graph.generateMermaidDiagram()
        executedNodes.removeAll()
        currentNode = ""
        executionLog.removeAll()
        executionResult = ""
    }
    
    public func executeGraph() {
        guard let graph = currentGraph else { return }
        
        isExecuting = true
        executionResult = ""
        executionLog.removeAll()
        executedNodes.removeAll()
        currentNode = ""
        
        // Create observer for live updates
        let observer = UIGraphObserver(viewModel: self)
        graph.addObserver(observer)
        
        Task.detached { [customInput] in
            do {
                await MainActor.run {
                    self.addLog("🚀 Starting graph execution...")
                }
                
                let result = try await graph.run(customInput)
                
                await MainActor.run {
                    self.executionResult = String(describing: result)
                    self.addLog("✅ Execution completed successfully!")
                    self.isExecuting = false
                    self.currentNode = ""
                }
            } catch {
                await MainActor.run {
                    self.executionResult = "❌ Error: \(error.localizedDescription)"
                    self.addLog("❌ Execution failed: \(error.localizedDescription)")
                    self.isExecuting = false
                    self.currentNode = ""
                }
            }
            
            graph.removeObserver(observer)
        }
    }
    
    public func addLog(_ message: String) {
        let timestamp = DateFormatter.timeFormatter.string(from: Date())
        executionLog.append("[\(timestamp)] \(message)")
    }
    
    public func clearLogs() {
        executionLog.removeAll()
        executionResult = ""
        executedNodes.removeAll()
        currentNode = ""
    }
}

// MARK: - Graph Examples

extension GraphViewModel {
    
    private func createSimpleWorkflow() -> AgentGraph {
        return AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                await Task.yield() // Allow UI updates
                return [
                    "input": context["input"] as! String,
                    "stage": "initialized"
                ]
            }
            
            Node.context("process") { context in
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                let input = context["input"] as! String
                return [
                    "processed": "Processed: \(input)",
                    "stage": "processed"
                ]
            }
            
            Node.context("finalize") { context in
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                let processed = context["processed"] as! String
                return [
                    "result": "Final: \(processed)",
                    "stage": "completed"
                ]
            }
            
            Edge(from: "start", to: "process", description: "Initialize")
            Edge(from: "process", to: "finalize", description: "Process")
        }
    }
    
    private func createConditionalBranching() -> AgentGraph {
        return AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                let input = context["input"] as! String
                let isLong = input.count > 10
                return [
                    "input": input,
                    "isLong": isLong,
                    "stage": "analyzed"
                ]
            }
            
            Node.context("shortPath") { context in
                try await Task.sleep(nanoseconds: 500_000_000)
                return [
                    "result": "Short input processed quickly",
                    "stage": "completed"
                ]
            }
            
            Node.context("longPath") { context in
                try await Task.sleep(nanoseconds: 1_500_000_000)
                return [
                    "result": "Long input processed thoroughly",
                    "stage": "completed"
                ]
            }
            
            Edge(from: "start", to: "shortPath", description: "Short input", condition: { context in
                !(context["isLong"] as? Bool ?? false)
            })
            
            Edge(from: "start", to: "longPath", description: "Long input", condition: { context in
                context["isLong"] as? Bool ?? false
            })
        }
    }
    
    private func createRetryExample() -> AgentGraph {
        return AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                return [
                    "input": context["input"] as! String,
                    "attempts": 0
                ]
            }
            
            Node.context("unreliableService") { context in
                try await Task.sleep(nanoseconds: 800_000_000)
                
                // Simulate failure 70% of the time
                let shouldFail = Double.random(in: 0...1) < 0.7
                if shouldFail {
                    throw NSError(domain: "ServiceError", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Service temporarily unavailable"
                    ])
                }
                
                return [
                    "serviceResult": "Service call successful!",
                    "stage": "service_completed"
                ]
            }.retry(maxAttempts: 3, delay: 0.5)
             .onFailure { error, context in
                return [
                    "result": "Fallback: Used cached data instead",
                    "stage": "fallback_used"
                ]
            }
            
            Node.context("success") { context in
                let serviceResult = context["serviceResult"] as! String
                return [
                    "result": "Success: \(serviceResult)",
                    "stage": "completed"
                ]
            }
            
            Edge(from: "start", to: "unreliableService")
            Edge(from: "unreliableService", to: "success", condition: { context in
                context["serviceResult"] != nil
            })
        }
    }
    
    private func createComplexWorkflow() -> AgentGraph {
        return AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                return [
                    "query": context["input"] as! String,
                    "stage": "initialized"
                ]
            }
            
            Node.context("analyze") { context in
                try await Task.sleep(nanoseconds: 700_000_000)
                let query = context["query"] as! String
                return [
                    "queryType": query.contains("?") ? "question" : "statement",
                    "complexity": query.count > 20 ? "high" : "low",
                    "stage": "analyzed"
                ]
            }
            
            Node.context("simpleProcess") { context in
                try await Task.sleep(nanoseconds: 800_000_000)
                return [
                    "processResult": "Simple processing completed",
                    "stage": "simple_processed"
                ]
            }
            
            Node.context("complexProcess") { context in
                try await Task.sleep(nanoseconds: 1_500_000_000)
                return [
                    "processResult": "Complex analysis completed",
                    "stage": "complex_processed"
                ]
            }
            
            Node.context("validate") { context in
                try await Task.sleep(nanoseconds: 500_000_000)
                return [
                    "validated": true,
                    "stage": "validated"
                ]
            }
            
            Node.context("finalize") { context in
                try await Task.sleep(nanoseconds: 600_000_000)
                let processResult = context["processResult"] as! String
                return [
                    "result": "Final result: \(processResult) - validated and ready",
                    "stage": "completed"
                ]
            }
            
            Edge(from: "start", to: "analyze")
            
            Edge(from: "analyze", to: "simpleProcess", description: "Low complexity", condition: { context in
                context["complexity"] as? String == "low"
            })
            
            Edge(from: "analyze", to: "complexProcess", description: "High complexity", condition: { context in
                context["complexity"] as? String == "high"
            })
            
            Edge(from: "simpleProcess", to: "validate")
            Edge(from: "complexProcess", to: "validate")
            Edge(from: "validate", to: "finalize")
        }
    }
}

// MARK: - Graph Observer for UI Updates

@MainActor
class UIGraphObserver: GraphExecutionObserver {
    weak var viewModel: GraphViewModel?
    
    init(viewModel: GraphViewModel) {
        self.viewModel = viewModel
    }
    
    nonisolated func graphExecutionStarted(initialContext: GraphContext) {
        Task { @MainActor in
            viewModel?.addLog("📊 Graph execution started")
        }
    }
    
    nonisolated func nodeExecutionStarted(nodeId: String, context: GraphContext) {
        Task { @MainActor in
            viewModel?.currentNode = nodeId
            viewModel?.addLog("▶️ Executing node: \(nodeId)")
        }
    }
    
    nonisolated func nodeExecutionCompleted(nodeId: String, result: GraphContext) {
        let stage = result["stage"] as? String
        Task { @MainActor in
            viewModel?.executedNodes.insert(nodeId)
            viewModel?.addLog("✅ Completed node: \(nodeId)")
            
            if let stage = stage {
                viewModel?.addLog("   Stage: \(stage)")
            }
        }
    }
    
    nonisolated func nodeExecutionFailed(nodeId: String, error: Error) {
        Task { @MainActor in
            viewModel?.addLog("⚠️ Node \(nodeId) failed: \(error.localizedDescription)")
        }
    }
    
    nonisolated func graphExecutionCompleted(finalContext: GraphContext, executionPath: [String]) {
        Task { @MainActor [executionPath] in
            viewModel?.addLog("🎉 Graph execution completed")
            viewModel?.addLog("   Execution path: \(executionPath.joined(separator: " → "))")
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}
#endif