#if canImport(SwiftUI)
import SwiftUI
import LiteSwiftGraph
import LiteSwiftGraphDebug

// MARK: - Simple SwiftUI Example

/// This example demonstrates the new extension methods for instant SwiftUI debugging
struct SimpleSwiftUIExample {
    
    /// Create a simple graph for demonstration
    static func createDemoGraph() -> AgentGraph {
        return AgentGraph(startNode: "start", outputKey: "result", debug: false) {
            Node.context("start") { context in
                let input = context["input"] as! String
                return [
                    "message": "Processing: \(input)",
                    "wordCount": input.split(separator: " ").count
                ]
            }
            
            Node.context("analyze") { context in
                let wordCount = context["wordCount"] as! Int
                return [
                    "analysis": wordCount > 3 ? "long message" : "short message",
                    "needsExpansion": wordCount <= 3
                ]
            }
            
            Node.context("expand") { context in
                let message = context["message"] as! String
                return ["result": "Expanded: \(message) (with additional context)"]
            }
            
            Node.context("summarize") { context in
                let message = context["message"] as! String
                return ["result": "Summary: \(message)"]
            }
            
            Edge(from: "start", to: "analyze")
            Edge(from: "analyze", to: "expand", description: "short", condition: { context in
                context["needsExpansion"] as? Bool == true
            })
            Edge(from: "analyze", to: "summarize", description: "long", condition: { context in
                context["needsExpansion"] as? Bool == false
            })
        }
    }
    
    /// Example SwiftUI app using the extension methods
    @MainActor
    struct DemoApp: App {
        let demoGraph = createDemoGraph()
        
        var body: some Scene {
            WindowGroup("Graph Debug View") {
                demoGraph.graphView()  // 🎯 Instant debug visualization
            }
            .defaultSize(width: 800, height: 600)
            
            WindowGroup("Live Execution") {
                demoGraph.liveView()   // 🚀 Live execution with controls
            }
            .defaultSize(width: 900, height: 700)
            
            WindowGroup("Structure View") {
                demoGraph.structureView()  // 📊 Compact structure view
            }
            .defaultSize(width: 400, height: 500)
        }
    }
    
    /// Example of embedding in existing views
    struct EmbeddedExample: View {
        let demoGraph = createDemoGraph()
        
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    Text("My Application")
                        .font(.title)
                    
                    Text("Here's my graph visualization:")
                        .font(.headline)
                    
                    // Embed debug view inline
                    demoGraph.graphView()
                        .frame(height: 300)
                        .border(Color.gray)
                    
                    Text("And here's the structure:")
                    
                    demoGraph.structureView()
                        .frame(height: 200)
                        .border(Color.gray)
                }
                .padding()
                .navigationTitle("Graph Demo")
            }
        }
    }
}

// MARK: - Usage Example

/*
 To use these new extension methods:
 
 1. Import both libraries:
    import LiteSwiftGraph
    import LiteSwiftGraphDebug
 
 2. Create your graph as usual:
    let myGraph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
        // Your nodes and edges
    }
 
 3. Get instant SwiftUI views:
    myGraph.graphView()      // Debug visualization
    myGraph.liveView()       // Live execution
    myGraph.structureView()  // Structure overview
 
 4. Use them in your SwiftUI apps:
    struct MyApp: App {
        var body: some Scene {
            WindowGroup {
                myGraph.graphView()
            }
        }
    }
 */

#endif