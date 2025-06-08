#if canImport(SwiftUI)
import SwiftUI
import LiteSwiftGraph

// MARK: - AgentGraph SwiftUI Extensions

extension AgentGraph {
    
    /// Returns a SwiftUI view for debugging and visualizing your graph
    /// Usage: YourGraph.graphView()
    @MainActor
    public func graphView() -> some View {
        GraphDebugView(graph: self)
    }
    
    /// Returns a SwiftUI view with live execution monitoring
    /// Usage: YourGraph.liveView()
    @MainActor 
    public func liveView() -> some View {
        GraphLiveView(graph: self)
    }
    
    /// Returns a compact SwiftUI view showing just the graph structure
    /// Usage: YourGraph.structureView()
    @MainActor
    public func structureView() -> some View {
        GraphStructureView(graph: self)
    }
}

// MARK: - Graph Debug View

public struct GraphDebugView: View {
    private let graph: AgentGraph
    @StateObject private var viewModel: GraphViewModel
    
    public init(graph: AgentGraph) {
        self.graph = graph
        self._viewModel = StateObject(wrappedValue: GraphViewModel())
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Graph Debug View")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Refresh") {
                    loadGraphStructure()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            // Graph Visualization
            ScrollView([.horizontal, .vertical]) {
                ModernGraphCanvasView()
                    .frame(minWidth: 600, minHeight: 400)
                    .padding()
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Graph Info
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Nodes: \(graph.getNodes().count)")
                    Text("Edges: \(graph.getEdges().count)")
                    Text("Start: \(graph.getStartNodeId())")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .environmentObject(viewModel)
        .onAppear {
            loadGraphStructure()
        }
    }
    
    private func loadGraphStructure() {
        viewModel.allNodes = graph.getNodes()
        viewModel.edges = graph.getEdges()
        viewModel.mermaidDiagram = graph.generateMermaidDiagram()
    }
}

// MARK: - Graph Live View

public struct GraphLiveView: View {
    private let graph: AgentGraph
    @StateObject private var viewModel: GraphViewModel
    @State private var inputText: String = ""
    
    public init(graph: AgentGraph) {
        self.graph = graph
        self._viewModel = StateObject(wrappedValue: GraphViewModel())
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Controls
            HStack {
                Text("Live Graph Execution")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack {
                    TextField("Input", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                    
                    Button("Execute") {
                        executeGraph()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isExecuting)
                    
                    if viewModel.isExecuting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .padding()
            
            // Live Graph Visualization
            ScrollView([.horizontal, .vertical]) {
                ModernGraphCanvasView()
                    .frame(minWidth: 700, minHeight: 500)
                    .padding()
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Execution Result
            if !viewModel.executionResult.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Result")
                        .font(.headline)
                    
                    Text(viewModel.executionResult)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                .padding()
            }
            
            Spacer()
        }
        .environmentObject(viewModel)
        .onAppear {
            setupLiveView()
        }
    }
    
    private func setupLiveView() {
        viewModel.allNodes = graph.getNodes()
        viewModel.edges = graph.getEdges()
        viewModel.mermaidDiagram = graph.generateMermaidDiagram()
        
        // Add observer for live updates
        let observer = UIGraphObserver(viewModel: viewModel)
        graph.addObserver(observer)
    }
    
    private func executeGraph() {
        Task {
            await viewModel.executeCustomGraph(inputText, graph: graph)
        }
    }
}

// MARK: - Graph Structure View

public struct GraphStructureView: View {
    private let graph: AgentGraph
    @State private var mermaidDiagram: String = ""
    
    public init(graph: AgentGraph) {
        self.graph = graph
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Graph Structure")
                    .font(.headline)
                
                Spacer()
                
                Button("Copy Mermaid") {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(mermaidDiagram, forType: .string)
                    #else
                    UIPasteboard.general.string = mermaidDiagram
                    #endif
                }
                .buttonStyle(.bordered)
            }
            
            // Compact graph info
            HStack(spacing: 20) {
                Label("\(graph.getNodes().count)", systemImage: "circle")
                Label("\(graph.getEdges().count)", systemImage: "arrow.right")
                Label(graph.getStartNodeId(), systemImage: "play.circle")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            // ASCII representation
            ScrollView {
                Text(graph.generateASCIIDiagram())
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .onAppear {
            mermaidDiagram = graph.generateMermaidDiagram()
        }
    }
}

// MARK: - GraphViewModel Extension

extension GraphViewModel {
    @MainActor
    func executeCustomGraph(_ input: String, graph: AgentGraph) async {
        isExecuting = true
        executionResult = ""
        executedNodes.removeAll()
        currentNode = ""
        executionLog.removeAll()
        
        addLog("🚀 Starting execution with input: \(input)")
        
        await Task.detached {
            do {
                let result = try await graph.run(input)
                let resultString = String(describing: result)
                
                await MainActor.run {
                    self.executionResult = resultString
                    self.addLog("✅ Execution completed successfully")
                    self.isExecuting = false
                }
            } catch {
                let errorMessage = error.localizedDescription
                
                await MainActor.run {
                    self.executionResult = "❌ Error: \(errorMessage)"
                    self.addLog("❌ Execution failed: \(errorMessage)")
                    self.isExecuting = false
                }
            }
        }.value
    }
}

#endif