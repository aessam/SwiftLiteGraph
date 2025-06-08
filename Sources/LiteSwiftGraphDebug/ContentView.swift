#if canImport(SwiftUI)
import SwiftUI
import LiteSwiftGraph

public struct ContentView: View {
    @EnvironmentObject var viewModel: GraphViewModel
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            // Sidebar
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("LiteSwiftGraph")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Visual Graph Execution")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Example Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Examples")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(GraphViewModel.GraphExample.allCases, id: \.self) { example in
                        Button(action: {
                            viewModel.selectedExample = example
                            viewModel.loadSelectedExample()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(example.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(viewModel.selectedExample == example ? .semibold : .regular)
                                    
                                    Spacer()
                                    
                                    if viewModel.selectedExample == example {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                            .font(.caption)
                                    }
                                }
                                
                                Text(example.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(viewModel.selectedExample == example ? 
                                          Color.accentColor.opacity(0.1) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                
                // Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("Enter your input...", text: $viewModel.customInput, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .padding(.horizontal)
                }
                
                // Execute Button
                Button(action: {
                    viewModel.executeGraph()
                }) {
                    HStack {
                        if viewModel.isExecuting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        
                        Text(viewModel.isExecuting ? "Executing..." : "Execute Graph")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(viewModel.isExecuting)
                .padding(.horizontal)
                
                Spacer()
            }
            .frame(minWidth: 280, maxWidth: 320)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Main Content
            TabView(selection: $selectedTab) {
                GraphVisualizationView()
                    .tabItem {
                        Label("Visualization", systemImage: "diagram.badge.gearshape")
                    }
                    .tag(0)
                
                ExecutionLogView()
                    .tabItem {
                        Label("Execution Log", systemImage: "list.bullet.rectangle")
                    }
                    .tag(1)
                
                MermaidView()
                    .tabItem {
                        Label("Graph Structure", systemImage: "flowchart")
                    }
                    .tag(2)
            }
        }
        .navigationViewStyle(.columns)
        .onAppear {
            viewModel.loadSelectedExample()
        }
    }
}

// MARK: - Graph Visualization View

struct GraphVisualizationView: View {
    @EnvironmentObject var viewModel: GraphViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Live Graph Execution")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !viewModel.currentNode.isEmpty {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Currently executing: \(viewModel.currentNode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            // Graph Visualization
            ScrollView([.horizontal, .vertical]) {
                ModernGraphCanvasView()
                    .frame(minWidth: 900, minHeight: 600)
                    .padding()
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Result Section
            if !viewModel.executionResult.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Execution Result")
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
    }
}

// MARK: - Graph Canvas View

struct GraphCanvasView: View {
    @EnvironmentObject var viewModel: GraphViewModel
    
    private let nodeSize: CGSize = CGSize(width: 120, height: 60)
    private let canvasSize: CGSize = CGSize(width: 800, height: 600)
    
    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(Color(NSColor.textBackgroundColor))
                .frame(width: canvasSize.width, height: canvasSize.height)
            
            // Edges
            ForEach(Array(viewModel.edges.enumerated()), id: \.offset) { index, edge in
                if let fromPos = nodePosition(for: edge.fromNode),
                   let toPos = nodePosition(for: edge.toNode) {
                    EdgeView(
                        from: fromPos,
                        to: toPos,
                        isExecuted: isEdgeExecuted(edge),
                        description: edge.description,
                        isConditional: edge.condition != nil
                    )
                }
            }
            
            // Nodes
            ForEach(viewModel.allNodes, id: \.self) { nodeId in
                if let position = nodePosition(for: nodeId) {
                    NodeView(
                        nodeId: nodeId,
                        isExecuted: viewModel.executedNodes.contains(nodeId),
                        isCurrent: viewModel.currentNode == nodeId,
                        isStart: nodeId == (viewModel.allNodes.first ?? "")
                    )
                    .position(position)
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }
    
    private func nodePosition(for nodeId: String) -> CGPoint? {
        guard let index = viewModel.allNodes.firstIndex(of: nodeId) else { return nil }
        
        // Simple layout algorithm - arrange in a grid
        let nodesPerRow = 3
        let row = index / nodesPerRow
        let col = index % nodesPerRow
        
        let x = 100 + CGFloat(col) * 200
        let y = 100 + CGFloat(row) * 150
        
        return CGPoint(x: x, y: y)
    }
    
    private func isEdgeExecuted(_ edge: LiteSwiftGraph.Edge) -> Bool {
        return viewModel.executedNodes.contains(edge.fromNode) && 
               viewModel.executedNodes.contains(edge.toNode)
    }
}

// MARK: - Node View

struct NodeView: View {
    let nodeId: String
    let isExecuted: Bool
    let isCurrent: Bool
    let isStart: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .stroke(borderColor, lineWidth: isCurrent ? 3 : 1)
                    .frame(width: 120, height: 60)
                
                VStack(spacing: 2) {
                    if isStart {
                        Text("START")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(nodeId)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .foregroundColor(textColor)
                
                if isCurrent {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .offset(x: 50, y: -25)
                        .scaleEffect(isExecuted ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: isExecuted)
                }
            }
            
            if isExecuted && !isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExecuted)
        .animation(.easeInOut(duration: 0.3), value: isCurrent)
    }
    
    private var backgroundColor: Color {
        if isCurrent {
            return Color.yellow.opacity(0.4)
        } else if isExecuted {
            return Color.green.opacity(0.3)
        } else {
            return Color(NSColor.controlColor)
        }
    }
    
    private var borderColor: Color {
        if isCurrent {
            return Color.orange
        } else if isExecuted {
            return Color.green
        } else {
            return Color(NSColor.separatorColor)
        }
    }
    
    private var textColor: Color {
        isCurrent ? .primary : (isExecuted ? .primary : .secondary)
    }
}

// MARK: - Edge View

struct EdgeView: View {
    let from: CGPoint
    let to: CGPoint
    let isExecuted: Bool
    let description: String
    let isConditional: Bool
    
    var body: some View {
        ZStack {
            // Edge line
            Path { path in
                path.move(to: from)
                path.addLine(to: to)
            }
            .stroke(
                isExecuted ? Color.green : Color(NSColor.tertiaryLabelColor),
                style: StrokeStyle(
                    lineWidth: isExecuted ? 3 : 1,
                    lineCap: .round,
                    dash: isConditional ? [5, 5] : []
                )
            )
            
            // Arrow head
            ArrowHead(from: from, to: to, isExecuted: isExecuted)
            
            // Description label
            if !description.isEmpty {
                Text(description)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.9))
                    .cornerRadius(4)
                    .position(midPoint)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExecuted)
    }
    
    private var midPoint: CGPoint {
        CGPoint(
            x: (from.x + to.x) / 2,
            y: (from.y + to.y) / 2
        )
    }
}

// MARK: - Arrow Head

struct ArrowHead: View {
    let from: CGPoint
    let to: CGPoint
    let isExecuted: Bool
    
    var body: some View {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 12
        let arrowAngle: CGFloat = .pi / 6
        
        Path { path in
            let arrowTip = CGPoint(
                x: to.x - 30 * cos(angle), // Offset from node edge
                y: to.y - 30 * sin(angle)
            )
            
            let arrowLeft = CGPoint(
                x: arrowTip.x - arrowLength * cos(angle - arrowAngle),
                y: arrowTip.y - arrowLength * sin(angle - arrowAngle)
            )
            
            let arrowRight = CGPoint(
                x: arrowTip.x - arrowLength * cos(angle + arrowAngle),
                y: arrowTip.y - arrowLength * sin(angle + arrowAngle)
            )
            
            path.move(to: arrowLeft)
            path.addLine(to: arrowTip)
            path.addLine(to: arrowRight)
        }
        .stroke(isExecuted ? Color.green : Color(NSColor.tertiaryLabelColor), lineWidth: 2)
        .fill(isExecuted ? Color.green : Color(NSColor.tertiaryLabelColor))
    }
}

// MARK: - Execution Log View

struct ExecutionLogView: View {
    @EnvironmentObject var viewModel: GraphViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Execution Log")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Clear") {
                    viewModel.clearLogs()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(viewModel.executionLog.enumerated()), id: \.offset) { index, logEntry in
                            Text(logEntry)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal)
                                .id(index)
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)
                .onChange(of: viewModel.executionLog.count) {
                    if !viewModel.executionLog.isEmpty {
                        withAnimation {
                            proxy.scrollTo(viewModel.executionLog.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Mermaid View

struct MermaidView: View {
    @EnvironmentObject var viewModel: GraphViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Graph Structure (Mermaid)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Copy") {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(viewModel.mermaidDiagram, forType: .string)
                    #else
                    UIPasteboard.general.string = viewModel.mermaidDiagram
                    #endif
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            ScrollView {
                Text(viewModel.mermaidDiagram)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            
            Text("You can paste this diagram into Mermaid Live Editor or any Mermaid-compatible tool.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GraphViewModel())
}
#endif