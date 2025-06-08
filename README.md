# LiteSwiftGraph

A lightweight, modular Swift library for building and executing agent graphs with declarative syntax and optional debugging capabilities.

## 🎯 Why LiteSwiftGraph?

LiteSwiftGraph solves the problem of building complex, conditional workflows in Swift with a clean, declarative API. Whether you're building AI agents, data processing pipelines, or state machines, LiteSwiftGraph provides:

- **🚀 Zero Dependencies** - Pure Swift with no external requirements
- **⚡ Async-First** - Built for modern Swift concurrency 
- **🎨 Declarative DSL** - Clean, readable graph definitions
- **🔧 Modular Design** - Use only what you need
- **🔍 Rich Debugging** - Optional visualization and monitoring tools

## 🏗️ Architecture

LiteSwiftGraph follows a clean, modular architecture:

### **LiteSwiftGraph** (Core Library)
The essential graph execution engine with no UI dependencies:
```swift
// Pure graph logic - works everywhere Swift runs
let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
    Node.context("start") { context in /* ... */ }
    Edge(from: "start", to: "process")
}

// Basic visualization always available
graph.printMermaidDiagram()
```

### **LiteSwiftGraphDebug** (Optional Debugging)
Advanced debugging and visualization components that extend your graphs:
```swift
// Rich debugging tools - import only when needed
import LiteSwiftGraphDebug

// Instant SwiftUI views - just like Mermaid diagrams!
graph.graphView()      // 🎯 Debug visualization
graph.liveView()       // 🚀 Live execution  
graph.structureView()  // 📊 Structure overview

// Traditional debugging tools
let console = GraphDebugConsole(graph: graph)
let renderer = GraphRenderer(graph: graph)
```

### **Ready-to-Run Examples**
- **LiteSwiftGraphExample** - Comprehensive usage demonstrations
- **LiteSwiftGraphCLI** - Interactive command-line interface  
- **LiteSwiftGraphUI** - Full SwiftUI application with live visualization

## 🚀 Quick Start

### Installation

Add LiteSwiftGraph to your project via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/LiteSwiftGraph.git", from: "1.0.0")
]
```

Choose your integration level:

```swift
// Minimal: Core graph execution only
.target(name: "MyApp", dependencies: ["LiteSwiftGraph"])

// Full: Core + debugging and visualization
.target(name: "MyApp", dependencies: ["LiteSwiftGraph", "LiteSwiftGraphDebug"])
```

### Your First Graph

```swift
import LiteSwiftGraph

// SAMPLE: Build a simple text processing pipeline
let sampleTextProcessor = AgentGraph(
    startNode: "sampleAnalyze", 
    outputKey: "result", 
    debug: false
) {
    Node.context("sampleAnalyze") { context in
        let text = context["input"] as! String
        let wordCount = text.split(separator: " ").count
        return [
            "text": text,
            "wordCount": wordCount,
            "needsExpansion": wordCount < 10
        ]
    }
    
    Node.context("sampleExpand") { context in
        let text = context["text"] as! String
        return ["result": "SAMPLE: Expanded: \(text) (with additional context)"]
    }
    
    Node.context("sampleSummarize") { context in
        let text = context["text"] as! String
        return ["result": "SAMPLE: Summary: \(text)"]
    }
    
    // Conditional routing based on analysis
    Edge(from: "sampleAnalyze", to: "sampleExpand", condition: { context in
        context["needsExpansion"] as? Bool == true
    })
    
    Edge(from: "sampleAnalyze", to: "sampleSummarize", condition: { context in
        context["needsExpansion"] as? Bool == false
    })
}

// Execute the sample graph
let result = try await sampleTextProcessor.run("Hello world")
print(result) // "SAMPLE: Expanded: Hello world (with additional context)"
```

## 💡 Core Concepts

### Nodes: The Processing Units

Nodes are where your logic lives. Each node transforms the context and passes it along:

```swift
// SAMPLE: Simple transformation node
Node.context("sampleProcess") { context in
    let input = context["data"] as! String
    return ["processed": input.uppercased()]
}

// SAMPLE: Async operations with error handling
Node.context("sampleFetchData") { context in
    let url = context["url"] as! String
    let data = try await URLSession.shared.data(from: URL(string: url)!)
    return ["response": String(data: data.0, encoding: .utf8)]
}
.retry(maxAttempts: 3, delay: 1.0)
.onFailure { error, context in
    return ["response": "SAMPLE: Fallback data due to: \(error.localizedDescription)"]
}
```

### Edges: The Decision Points

Edges define the flow between nodes with optional conditions:

```swift
// SAMPLE: Unconditional flow
Edge(from: "sampleStart", to: "sampleProcess")

// SAMPLE: Conditional branching
Edge(from: "sampleValidate", to: "sampleSuccess", condition: { context in
    context["isValid"] as? Bool == true
})

Edge(from: "sampleValidate", to: "sampleRetry", condition: { context in
    let attempts = context["attempts"] as? Int ?? 0
    return attempts < 3
})

// SAMPLE: Descriptive edges for better visualization
Edge(from: "sampleAnalyze", to: "sampleDeepProcess", description: "complex data", condition: { context in
    (context["complexity"] as? Int ?? 0) > 5
})
```

### Context: The Data Flow

Context is a simple dictionary that flows through your graph:

```swift
// SAMPLE: Input flows through the graph
let result = try await sampleGraph.run([
    "userInput": "Process this text",
    "settings": ["language": "en", "model": "advanced"]
])

// SAMPLE: Each node can read and modify context
Node.context("sampleTranslate") { context in
    let text = context["userInput"] as! String
    let settings = context["settings"] as! [String: String]
    
    // Transform and return new data
    return [
        "originalText": text,
        "translatedText": "SAMPLE: Translated '\(text)' to \(settings["language"]!)",
        "processingTime": Date().timeIntervalSince1970
    ]
}
```

## 🔧 Advanced Features

### Error Handling & Resilience

```swift
// SAMPLE: Unreliable service with comprehensive error handling
Node.context("sampleUnreliableAPI") { context in
    // Simulate flaky service for demonstration
    if Int.random(in: 1...10) <= 3 { 
        throw NSError(domain: "SampleError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sample API failure"]) 
    }
    return ["data": "SAMPLE: API Response"]
}
.retry(maxAttempts: 5, delay: 0.5)  // Exponential backoff
.timeout(seconds: 10.0)             // Prevent hanging
.onFailure { error, context in      // Graceful degradation
    return ["data": "SAMPLE: Cached fallback data"]
}
```

### Complex Conditional Logic

```swift
// SAMPLE: Complex AI workflow with conditional routing
let sampleAIWorkflow = AgentGraph(startNode: "sampleInput", outputKey: "response", debug: true) {
    Node.context("sampleInput") { context in
        let query = context["query"] as! String
        // SAMPLE: Simulate complexity analysis
        let complexity = query.count > 20 ? 5 : 2
        return [
            "query": query,
            "complexity": complexity,
            "category": "sample"
        ]
    }
    
    Node.context("sampleSimpleResponse") { context in
        return ["response": "SAMPLE: Simple answer for: \(context["query"]!)"]
    }
    
    Node.context("sampleResearchPhase") { context in
        // SAMPLE: Multi-step research simulation
        let query = context["query"] as! String
        let sources = ["SAMPLE: Source 1 for \(query)", "SAMPLE: Source 2 for \(query)"]
        return ["sources": sources, "needsSynthesis": true]
    }
    
    Node.context("sampleSynthesize") { context in
        let sources = context["sources"] as! [String]
        let synthesis = "SAMPLE: Synthesized response from \(sources.count) sources"
        return ["response": synthesis]
    }
    
    // Route based on complexity
    Edge(from: "sampleInput", to: "sampleSimpleResponse", condition: { context in
        (context["complexity"] as? Int ?? 0) < 3
    })
    
    Edge(from: "sampleInput", to: "sampleResearchPhase", condition: { context in
        (context["complexity"] as? Int ?? 0) >= 3
    })
    
    Edge(from: "sampleResearchPhase", to: "sampleSynthesize")
}
```

## 🔍 How to Debug Your Graph

LiteSwiftGraph provides comprehensive debugging tools to help you understand exactly what's happening in your graph execution.

### Step 1: Enable Built-in Debug Logging

The easiest way to debug your graph is to enable the built-in debug mode:

```swift
// Enable debug logging by setting debug: true
let yourGraph = AgentGraph(startNode: "yourStartNode", outputKey: "yourOutput", debug: true) {
    // Your actual nodes and edges (not samples!)
    Node.context("yourStartNode") { context in
        // Your actual logic here
        return ["yourData": "yourValue"]
    }
    
    Node.context("yourProcessNode") { context in
        // Your actual processing logic
        return ["yourOutput": "yourResult"]
    }
    
    Edge(from: "yourStartNode", to: "yourProcessNode")
}

// When you run your graph, you'll see detailed debug output:
let result = try await yourGraph.run("your input")

// Debug output will show:
// 🔍 DEBUG: Starting graph execution at node: yourStartNode
// 🔍 DEBUG: Executing node: yourStartNode  
// 🔍 DEBUG: Node yourStartNode result keys: yourData
// 🔍 DEBUG: Found 1 possible edges from node yourStartNode
// 🔍 DEBUG: Taking unconditional edge: yourStartNode -> yourProcessNode
// 🔍 DEBUG: Executing node: yourProcessNode
// 🔍 DEBUG: Node yourProcessNode result keys: yourOutput
// 🔍 DEBUG: End of workflow reached
```

### Step 2: Visualize Your Graph Structure

Generate diagrams of your actual graph to understand the flow:

### Mermaid Diagrams (Always Available)

```swift
// Generate diagrams of YOUR actual graph (not samples)
yourGraph.printMermaidDiagram()

// Output for your graph:
// graph TD;
//     yourStartNode([Start]);
//     yourProcessNode["yourProcessNode"];
//     yourStartNode -->|"flow"| yourProcessNode;

// Copy to Mermaid Live Editor or documentation
let yourDiagramCode = yourGraph.generateMermaidDiagram()
```

### Step 3: Advanced Debugging (Optional)

For deeper inspection, import the debug library:

### Advanced Debugging Tools

```swift
import LiteSwiftGraphDebug

// Real-time execution monitoring for YOUR graph
let console = GraphDebugConsole(graph: yourGraph)

// ASCII visualization of YOUR graph
let renderer = GraphRenderer(graph: yourGraph)
print(renderer.renderASCII())
//
// Output shows YOUR actual graph structure:
// Graph Structure:
// ===============
// [START] yourStartNode
//   ---> yourProcessNode
// [NODE] yourProcessNode  

// Interactive step-by-step debugging of YOUR graph
let interactiveConsole = InteractiveDebugConsole(graph: yourGraph)
interactiveConsole.enableStepMode()
// Pauses at each of YOUR nodes for inspection
```

### Step 4: Instant SwiftUI Views (New!)

Just like Mermaid diagrams, you can instantly get SwiftUI debug views:

```swift
import SwiftUI
import LiteSwiftGraph
import LiteSwiftGraphDebug

// Your actual graph
let yourGraph = AgentGraph(startNode: "yourStart", outputKey: "result", debug: false) {
    // Your nodes and edges...
}

// Instant debug views - just like .generateMermaidDiagram()!
struct YourDebugApp: App {
    var body: some Scene {
        WindowGroup("Debug View") {
            yourGraph.graphView()  // 🎯 Instant debug visualization
        }
        
        WindowGroup("Live Execution") {  
            yourGraph.liveView()   // 🚀 Live execution with controls
        }
        
        WindowGroup("Structure") {
            yourGraph.structureView()  // 📊 Compact structure view
        }
    }
}

// Or embed in your existing views:
struct YourContentView: View {
    var body: some View {
        VStack {
            Text("Your App")
            
            // Embed debug view anywhere
            yourGraph.graphView()
                .frame(height: 300)
            
            // Or show structure inline
            yourGraph.structureView()
        }
    }
}
```

### Advanced SwiftUI Integration

For full control, use the traditional approach:

```swift
@main
struct MyGraphApp: App {
    @StateObject private var viewModel = GraphViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()  // Full-featured graph IDE
                .environmentObject(viewModel)
        }
    }
}
```

## 📱 Try the Examples

Experience LiteSwiftGraph in action:

```bash
# Clone and explore
git clone https://github.com/yourusername/LiteSwiftGraph.git
cd LiteSwiftGraph

# Interactive examples with full debugging
swift run LiteSwiftGraphExample

# Command-line interface for testing
swift run LiteSwiftGraphCLI

# Beautiful SwiftUI app (macOS)
swift run LiteSwiftGraphUI

# Run the test suite
swift test
```

## 🎨 Use Cases

LiteSwiftGraph excels in scenarios requiring conditional logic and complex flows:

### AI Agent Workflows
```swift
// SAMPLE: Multi-step AI reasoning pattern
startNode: "understand" → "research" → "synthesize" → "validate" → "respond"
```

### Data Processing Pipelines  
```swift
// SAMPLE: ETL with conditional transforms
startNode: "extract" → "validate" → "transform" → "enrich" → "load"
```

### User Onboarding Flows
```swift
// SAMPLE: Adaptive onboarding based on user type
startNode: "identify" → ["basicSetup", "advancedSetup", "enterpriseSetup"] → "complete"
```

### API Orchestration
```swift
// SAMPLE: Service calls with fallbacks and retries
startNode: "auth" → "primaryAPI" → "fallbackAPI" → "cache" → "respond"
```

## ⚡ Performance & Testing

LiteSwiftGraph is built for production use:

- **🔥 Fast Execution** - Minimal overhead, optimized for async/await
- **📏 Small Footprint** - Core library is <50KB compiled
- **🧪 Well Tested** - Comprehensive test suite covering all scenarios
- **🔒 Memory Safe** - No retain cycles or memory leaks
- **⚖️ Thread Safe** - Concurrent execution support

```bash
# Run performance tests
swift test --filter Performance

# Memory leak detection
swift test --sanitize=address
```

## 📋 Requirements

- **Swift 6.1+** (for modern concurrency)
- **iOS 17+ / macOS 14+ / Linux** (Core library)
- **Xcode 15+** (for SwiftUI components)

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Setup

```bash
git clone https://github.com/yourusername/LiteSwiftGraph.git
cd LiteSwiftGraph
swift build        # Build all targets
swift test          # Run tests
swift run LiteSwiftGraphExample  # Try examples
```

## 📄 License

LiteSwiftGraph is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## 🙋 Support

- **📖 Documentation**: Check out our [examples](Sources/LiteSwiftGraphExample/)
- **🐛 Issues**: Report bugs on [GitHub Issues](https://github.com/yourusername/LiteSwiftGraph/issues)
- **💡 Discussions**: Join our [GitHub Discussions](https://github.com/yourusername/LiteSwiftGraph/discussions)
- **🚀 Feature Requests**: We love hearing your ideas!

---

**Made with ❤️ for the Swift community**

*LiteSwiftGraph • Lightweight • Powerful • Swift*