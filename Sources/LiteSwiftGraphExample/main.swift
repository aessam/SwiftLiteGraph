import Foundation
import LiteSwiftGraph
import LiteSwiftGraphDebug

// Example: Create a simple research agent
func createSimpleResearchAgent() -> AgentGraph {
    return AgentGraph(startNode: "start", outputKey: "finalAnswer", debug: true) {
        // Start node - initialize the workflow
        Node.context("start") { input in
            print("🚀 Starting research workflow...")
            return [
                "query": input["input"] as! String,
                "stage": "initialized"
            ]
        }
        
        // Query analysis node
        Node.context("analyze") { context in
            let query = context["query"] as! String
            print("🔍 Analyzing query: \(query)")
            
            // Simulate analysis
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            let queryType = query.contains("how") ? "procedural" :
                          query.contains("what") ? "factual" : "general"
            
            return [
                "query": query,
                "queryType": queryType,
                "stage": "analyzed"
            ]
        }.timeout(seconds: 2.0)
        
        // Search node with retry
        Node.context("search") { context in
            print("🌐 Searching for information...")
            
            // Simulate search that might fail
            let shouldFail = Int.random(in: 1...3) == 1
            if shouldFail {
                throw NSError(domain: "SearchError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Search API temporarily unavailable"])
            }
            
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            return [
                "searchResults": [
                    "Result 1: Important finding",
                    "Result 2: Supporting evidence",
                    "Result 3: Additional context"
                ],
                "stage": "searched"
            ]
        }.retry(maxAttempts: 3, delay: 0.5)
         .onFailure { error, context in
            print("⚠️  Search failed, using fallback...")
            return [
                "searchResults": ["Fallback: Limited results available"],
                "stage": "searched_with_fallback"
            ]
        }
        
        // Process results
        Node.context("process") { context in
            print("⚙️  Processing results...")
            let results = context["searchResults"] as? [String] ?? []
            
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            let summary = "Found \(results.count) results for your query"
            return [
                "summary": summary,
                "stage": "processed"
            ]
        }
        
        // Generate final answer
        Node.context("answer") { context in
            print("✍️  Generating final answer...")
            
            let query = context["query"] as! String
            let summary = context["summary"] as! String
            let results = context["searchResults"] as? [String] ?? []
            
            let answer = """
            Query: \(query)
            
            \(summary)
            
            Key Findings:
            \(results.map { "• \($0)" }.joined(separator: "\n"))
            
            This is a demonstration of the LiteSwiftGraph execution engine.
            """
            
            return [
                "finalAnswer": answer,
                "stage": "completed"
            ]
        }
        
        // Define edges
        Edge(from: "start", to: "analyze")
        Edge(from: "analyze", to: "search")
        Edge(from: "search", to: "process")
        Edge(from: "process", to: "answer")
    }
}

// Example with conditional branching
func createBranchingAgent() -> AgentGraph {
    return AgentGraph(startNode: "start", outputKey: "result", debug: false) {
        Node.context("start") { context in
            let value = context["input"] as! Int
            return [
                "value": value,
                "isEven": value % 2 == 0
            ]
        }
        
        Node.context("evenPath") { context in
            let value = context["value"] as! Int
            return ["result": "Even number: \(value * 2)"]
        }
        
        Node.context("oddPath") { context in
            let value = context["value"] as! Int
            return ["result": "Odd number: \(value + 1)"]
        }
        
        Edge(from: "start", to: "evenPath", description: "if even", condition: { context in
            context["isEven"] as? Bool == true
        })
        
        Edge(from: "start", to: "oddPath", description: "if odd", condition: { context in
            context["isEven"] as? Bool == false
        })
    }
}

// Main execution
//@main
struct LiteSwiftGraphExample {
    static func main() async throws {
        print("=== LiteSwiftGraph Example ===\n")
        
        // Example 1: Simple Research Agent
        print("1. Running Simple Research Agent")
        print("================================\n")
        
        let researchAgent = createSimpleResearchAgent()
        
        // Show the graph structure
        researchAgent.printMermaidDiagram()
        
        // Create debug console
        let debugConsole = GraphDebugConsole(graph: researchAgent)
        
        // Run the agent
        do {
            let result = try await researchAgent.run("What is quantum computing?")
            print("\n=== FINAL RESULT ===")
            print(result)
        } catch {
            print("\n❌ Error: \(error)")
        }
        
        // Example 2: Branching Agent with Visual Debugging
        print("\n\n2. Running Branching Agent with Visual Debug")
        print("============================================\n")
        
        let branchingAgent = createBranchingAgent()
        
        // Create debug coordinator for combined visualization
        let coordinator = GraphDebugCoordinator(graph: branchingAgent)
        
        // Test with even number
        print("\nTesting with even number (42):")
        let evenResult = try await branchingAgent.run(42)
        print("Result: \(evenResult)")
        
        // Test with odd number
        print("\nTesting with odd number (17):")
        let oddResult = try await branchingAgent.run(17)
        print("Result: \(oddResult)")
        
        // Example 3: Interactive Step-by-Step Debugging
        print("\n\n3. Interactive Step-by-Step Example")
        print("===================================\n")
        
        let stepAgent = AgentGraph(startNode: "step1", outputKey: "final", debug: false) {
            Node.context("step1") { _ in
                print("   Executing step 1...")
                return ["data": "Step 1 complete"]
            }
            
            Node.context("step2") { context in
                print("   Executing step 2...")
                return ["data": (context["data"] as! String) + " -> Step 2 complete"]
            }
            
            Node.context("step3") { context in
                print("   Executing step 3...")
                return ["final": (context["data"] as! String) + " -> Step 3 complete"]
            }
            
            Edge(from: "step1", to: "step2")
            Edge(from: "step2", to: "step3")
        }
        
        // ASCII visualization
        print("Graph Structure:")
        let renderer = GraphRenderer(graph: stepAgent)
        print(renderer.renderASCII())
        
        print("\nExecuting with step mode enabled...")
        print("(In a real interactive session, you would press ENTER to step through)")
        
        let interactiveConsole = InteractiveDebugConsole(graph: stepAgent)
        // Note: In a real terminal app, you could enable step mode:
        // interactiveConsole.enableStepMode()
        
        let stepResult = try await stepAgent.run("start")
        print("\nFinal result: \(stepResult)")
        
        print("\n\n4. SwiftUI Extension Methods Demo")
        print("=================================\n")
        
        let demoGraph = AgentGraph(startNode: "demoStart", outputKey: "demoResult", debug: false) {
            Node.context("demoStart") { context in
                return ["data": "Demo: \(context["input"]!)"]
            }
            
            Node.context("demoProcess") { context in
                return ["demoResult": "Demo processed: \(context["data"]!)"]
            }
            
            Edge(from: "demoStart", to: "demoProcess")
        }
        
        print("With LiteSwiftGraphDebug imported, your graphs get instant SwiftUI extension methods:")
        print("• demoGraph.graphView()      - Debug visualization")
        print("• demoGraph.liveView()       - Live execution with controls")
        print("• demoGraph.structureView()  - Compact structure view")
        print("")
        print("Just like how you can call:")
        print("• demoGraph.printMermaidDiagram()")
        print("")
        print("You can now get SwiftUI views instantly!")
        print("")
        print("Check SimpleSwiftUIExample.swift for complete SwiftUI app examples.")
        
        print("\n\n=== Example Complete ===")
    }
}
