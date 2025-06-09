# SwiftUI Integration

Build beautiful SwiftUI applications with LiteSwiftGraph debugging and visualization.

## Overview

LiteSwiftGraph provides seamless SwiftUI integration through instant extension methods and comprehensive UI components. This tutorial shows you how to build visual graph applications.

## Instant SwiftUI Views

Just like calling `graph.generateMermaidDiagram()`, you can get instant SwiftUI views when `LiteSwiftGraphDebug` is imported.

### Three Extension Methods

```swift
import SwiftUI
import LiteSwiftGraph
import LiteSwiftGraphDebug

let yourGraph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
    // Your graph definition...
}

// 🎯 Get instant SwiftUI views
yourGraph.graphView()      // Debug visualization
yourGraph.liveView()       // Live execution with controls  
yourGraph.structureView()  // Compact structure overview
```

## Building a Simple Debug App

Create a complete SwiftUI application in just a few lines:

```swift
import SwiftUI
import LiteSwiftGraph
import LiteSwiftGraphDebug

// Your graph
func createTextProcessor() -> AgentGraph {
    return AgentGraph(startNode: "analyze", outputKey: "result", debug: false) {
        Node.context("analyze") { context in
            let text = context["input"] as! String
            return [
                "text": text,
                "wordCount": text.split(separator: " ").count
            ]
        }
        
        Node.context("process") { context in
            let wordCount = context["wordCount"] as! Int
            let text = context["text"] as! String
            return [
                "result": "Processed '\(text)' with \(wordCount) words"
            ]
        }
        
        Edge(from: "analyze", to: "process")
    }
}

// Instant debug app
@main
struct GraphDebugApp: App {
    let textProcessor = createTextProcessor()
    
    var body: some Scene {
        WindowGroup("Debug View") {
            textProcessor.graphView()
        }
        .defaultSize(width: 800, height: 600)
        
        WindowGroup("Live Execution") {
            textProcessor.liveView()
        }
        .defaultSize(width: 900, height: 700)
        
        WindowGroup("Structure") {
            textProcessor.structureView()
        }
        .defaultSize(width: 400, height: 500)
    }
}
```

## Embedding in Existing Applications

Integrate graph debugging into your existing SwiftUI applications:

```swift
struct MyAppContentView: View {
    let myGraph = createMyGraph()
    @State private var showingDebugView = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Your main application content
                Text("My Application")
                    .font(.title)
                
                Button("Show Graph Debug") {
                    showingDebugView = true
                }
                
                // Embed structure view inline
                GroupBox("Graph Overview") {
                    myGraph.structureView()
                        .frame(height: 200)
                }
            }
            .sheet(isPresented: $showingDebugView) {
                NavigationView {
                    myGraph.graphView()
                        .navigationTitle("Graph Debug")
                        .navigationBarItems(trailing: Button("Done") {
                            showingDebugView = false
                        })
                }
            }
        }
    }
}
```

## Building a Multi-Graph Application

Manage multiple graphs in a single application:

```swift
struct MultiGraphApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedGraph = 0
    
    let graphs = [
        ("Text Processor", createTextProcessor()),
        ("Data Pipeline", createDataPipeline()),
        ("AI Workflow", createAIWorkflow())
    ]
    
    var body: some View {
        NavigationView {
            // Sidebar with graph selection
            List {
                ForEach(graphs.indices, id: \.self) { index in
                    Button(graphs[index].0) {
                        selectedGraph = index
                    }
                    .foregroundColor(selectedGraph == index ? .accentColor : .primary)
                }
            }
            .navigationTitle("Graphs")
            
            // Main content area
            TabView {
                graphs[selectedGraph].1.graphView()
                    .tabItem {
                        Label("Debug", systemImage: "bug")
                    }
                
                graphs[selectedGraph].1.liveView()
                    .tabItem {
                        Label("Execute", systemImage: "play")
                    }
                
                graphs[selectedGraph].1.structureView()
                    .tabItem {
                        Label("Structure", systemImage: "diagram")
                    }
            }
        }
    }
}
```

## Advanced SwiftUI Integration

For full control, use the traditional approach with `GraphViewModel`:

```swift
@main
struct AdvancedGraphApp: App {
    @StateObject private var viewModel = GraphViewModel()
    
    var body: some Scene {
        WindowGroup {
            AdvancedContentView()
                .environmentObject(viewModel)
        }
    }
}

struct AdvancedContentView: View {
    @EnvironmentObject var viewModel: GraphViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            // Advanced sidebar with controls
            VStack(alignment: .leading, spacing: 20) {
                // Graph selection
                VStack(alignment: .leading) {
                    Text("Graph Examples")
                        .font(.headline)
                    
                    ForEach(GraphViewModel.GraphExample.allCases, id: \.self) { example in
                        Button(example.rawValue) {
                            viewModel.selectedExample = example
                            viewModel.loadSelectedExample()
                        }
                        .foregroundColor(viewModel.selectedExample == example ? .accentColor : .primary)
                    }
                }
                
                Divider()
                
                // Input controls
                VStack(alignment: .leading) {
                    Text("Input")
                        .font(.headline)
                    
                    TextField("Enter input...", text: $viewModel.customInput)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Execute") {
                        viewModel.executeGraph()
                    }
                    .disabled(viewModel.isExecuting)
                }
                
                Spacer()
            }
            .frame(minWidth: 250)
            .padding()
            
            // Main content with tabs
            TabView(selection: $selectedTab) {
                GraphVisualizationView()
                    .tabItem {
                        Label("Visualization", systemImage: "diagram")
                    }
                    .tag(0)
                
                ExecutionLogView()
                    .tabItem {
                        Label("Execution Log", systemImage: "list.bullet")
                    }
                    .tag(1)
                
                MermaidView()
                    .tabItem {
                        Label("Mermaid", systemImage: "flowchart")
                    }
                    .tag(2)
            }
        }
    }
}
```

## Custom Graph Visualizations

Create custom visualizations using the graph data:

```swift
struct CustomGraphView: View {
    let graph: AgentGraph
    @State private var nodes: [String] = []
    @State private var edges: [LiteSwiftGraph.Edge] = []
    
    var body: some View {
        Canvas { context, size in
            // Custom drawing code
            drawCustomGraph(context: context, size: size)
        }
        .onAppear {
            loadGraphData()
        }
    }
    
    private func loadGraphData() {
        nodes = graph.getNodes()
        edges = graph.getEdges()
    }
    
    private func drawCustomGraph(context: GraphicsContext, size: CGSize) {
        // Your custom visualization logic
        let nodeSize: CGFloat = 60
        let spacing: CGFloat = 120
        
        // Draw nodes
        for (index, node) in nodes.enumerated() {
            let x = CGFloat(index) * spacing + 50
            let y = size.height / 2
            
            // Draw node circle
            let rect = CGRect(x: x - nodeSize/2, y: y - nodeSize/2, 
                            width: nodeSize, height: nodeSize)
            context.fill(Path(ellipseIn: rect), with: .color(.blue))
            
            // Draw node label
            context.draw(Text(node), at: CGPoint(x: x, y: y))
        }
        
        // Draw edges
        for edge in edges {
            if let fromIndex = nodes.firstIndex(of: edge.fromNode),
               let toIndex = nodes.firstIndex(of: edge.toNode) {
                
                let fromX = CGFloat(fromIndex) * spacing + 50
                let toX = CGFloat(toIndex) * spacing + 50
                let y = size.height / 2
                
                let path = Path { path in
                    path.move(to: CGPoint(x: fromX, y: y))
                    path.addLine(to: CGPoint(x: toX, y: y))
                }
                
                context.stroke(path, with: .color(.gray), lineWidth: 2)
            }
        }
    }
}
```

## Interactive Graph Editor

Build an interactive graph editor:

```swift
struct GraphEditorView: View {
    @State private var nodes: [GraphNode] = []
    @State private var selectedNode: GraphNode?
    
    var body: some View {
        ZStack {
            // Canvas for graph
            Canvas { context, size in
                // Draw nodes and edges
                drawGraph(context: context, size: size)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Handle node dragging
                        if let node = selectedNode {
                            updateNodePosition(node, to: value.location)
                        }
                    }
            )
            
            // Controls overlay
            VStack {
                HStack {
                    Button("Add Node") {
                        addNode()
                    }
                    
                    Button("Generate Code") {
                        generateGraphCode()
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func addNode() {
        let newNode = GraphNode(
            id: "node\(nodes.count + 1)",
            position: CGPoint(x: 100, y: 100)
        )
        nodes.append(newNode)
    }
    
    private func generateGraphCode() {
        // Generate Swift code for the current graph
        let code = """
        let graph = AgentGraph(startNode: "\(nodes.first?.id ?? "start")", outputKey: "result", debug: false) {
            \(nodes.map { "Node.context(\"\($0.id)\") { context in /* ... */ }" }.joined(separator: "\n    "))
        }
        """
        
        // Copy to clipboard or show in a text view
        #if os(macOS)
        NSPasteboard.general.setString(code, forType: .string)
        #endif
    }
}

struct GraphNode: Identifiable {
    let id: String
    var position: CGPoint
}
```

## Performance Optimization

For large graphs, optimize your SwiftUI views:

```swift
struct OptimizedGraphView: View {
    let graph: AgentGraph
    @State private var viewData: GraphViewData?
    
    var body: some View {
        Group {
            if let data = viewData {
                LazyVStack {
                    ForEach(data.levels, id: \.self) { level in
                        LazyHStack {
                            ForEach(level.nodes, id: \.self) { node in
                                NodeView(node: node)
                            }
                        }
                    }
                }
            } else {
                ProgressView("Loading graph...")
            }
        }
        .task {
            await loadGraphData()
        }
    }
    
    private func loadGraphData() async {
        // Process graph data in background
        let data = await withTaskGroup(of: GraphViewData.self) { group in
            group.addTask {
                return processGraphForVisualization(graph)
            }
            
            return await group.first(where: { _ in true }) ?? GraphViewData.empty
        }
        
        viewData = data
    }
}
```

## Integration with Existing UI Frameworks

### UIKit Integration (iOS)

```swift
import UIKit
import SwiftUI

class GraphViewController: UIViewController {
    let graph: AgentGraph
    
    init(graph: AgentGraph) {
        self.graph = graph
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Embed SwiftUI view
        let graphView = graph.graphView()
        let hostingController = UIHostingController(rootView: graphView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }
}
```

### AppKit Integration (macOS)

```swift
import Cocoa
import SwiftUI

class GraphWindowController: NSWindowController {
    let graph: AgentGraph
    
    init(graph: AgentGraph) {
        self.graph = graph
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        window.center()
        window.title = "Graph Debug View"
        
        // Set SwiftUI content
        let graphView = graph.graphView()
        let hostingView = NSHostingView(rootView: graphView)
        window.contentView = hostingView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

## What You've Learned

✅ How to use instant SwiftUI extension methods  
✅ How to build complete debug applications  
✅ How to embed graph views in existing apps  
✅ How to manage multiple graphs in one application  
✅ How to create custom visualizations  
✅ How to build interactive graph editors  
✅ How to optimize performance for large graphs  
✅ How to integrate with UIKit and AppKit  

## Next Steps

- Learn <doc:BuildingComplexWorkflows> for advanced graph patterns
- Explore <doc:LiveDebugging> for real-time monitoring
- Try <doc:CLIDebugging> for command-line workflows