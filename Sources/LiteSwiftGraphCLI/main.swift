import Foundation
import LiteSwiftGraph
import LiteSwiftGraphDebug

// MARK: - CLI Application

func createSimpleWorkflow() -> AgentGraph {
    return AgentGraph(startNode: "start", outputKey: "result", debug: true) {
        Node.context("start") { context in
            print("📊 Starting process...")
            return [
                "input": context["input"] as! String,
                "stage": "initialized"
            ]
        }
        
        Node.context("analyze") { context in
            print("🔍 Analyzing input...")
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            let input = context["input"] as! String
            return [
                "analysis": "Input '\(input)' has \(input.count) characters",
                "stage": "analyzed"
            ]
        }
        
        Node.context("process") { context in
            print("⚙️ Processing...")
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            let analysis = context["analysis"] as! String
            return [
                "result": "Processed: \(analysis)",
                "stage": "completed"
            ]
        }
        
        Edge(from: "start", to: "analyze", description: "Initialize")
        Edge(from: "analyze", to: "process", description: "Process")
    }
}

func createConditionalWorkflow() -> AgentGraph {
    return AgentGraph(startNode: "start", outputKey: "result", debug: true) {
        Node.context("start") { context in
            let input = context["input"] as! String
            let isLong = input.count > 10
            print("📊 Input is \(isLong ? "long" : "short")")
            return [
                "input": input,
                "isLong": isLong
            ]
        }
        
        Node.context("shortPath") { context in
            print("🚀 Taking short path...")
            return [
                "result": "Quick processing for short input"
            ]
        }
        
        Node.context("longPath") { context in
            print("🔄 Taking detailed path...")
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            return [
                "result": "Thorough processing for long input"
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

func createRetryWorkflow() -> AgentGraph {
    return AgentGraph(startNode: "start", outputKey: "result", debug: true) {
        Node.context("start") { context in
            return [
                "input": context["input"] as! String,
                "attempts": 0
            ]
        }
        
        Node.context("unreliableService") { context in
            print("🌐 Calling unreliable service...")
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            // Simulate failure 60% of the time
            let shouldFail = Double.random(in: 0...1) < 0.6
            if shouldFail {
                print("❌ Service call failed, retrying...")
                throw NSError(domain: "ServiceError", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Service temporarily unavailable"
                ])
            }
            
            print("✅ Service call succeeded!")
            return [
                "serviceResult": "Service call successful!",
                "stage": "service_completed"
            ]
        }.retry(maxAttempts: 3, delay: 0.5)
         .onFailure { error, context in
            print("🔄 Using fallback strategy...")
            return [
                "result": "Fallback: Used cached data instead of live service",
                "stage": "fallback_used"
            ]
        }
        
        Node.context("processResult") { context in
            if let serviceResult = context["serviceResult"] as? String {
                return [
                    "result": "Success: \(serviceResult)",
                    "stage": "completed"
                ]
            } else {
                // Already handled by fallback
                return context
            }
        }
        
        Edge(from: "start", to: "unreliableService")
        Edge(from: "unreliableService", to: "processResult", condition: { context in
            context["serviceResult"] != nil
        })
    }
}

// MARK: - Interactive CLI

func showMenu() {
    print()
    print("Choose an example to run:")
    print("1. Simple Linear Workflow")
    print("2. Conditional Branching")
    print("3. Retry & Error Handling")
    print("4. View Graph Diagrams")
    print("5. Exit")
    print()
    print("Enter your choice (1-5): ", terminator: "")
}

func getUserInput() -> String? {
    return readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
}

func runWorkflow(_ graph: AgentGraph, with input: String) async {
    let startTime = Date()
    
    print("\n" + String(repeating: "=", count: 50))
    print("Executing workflow with input: '\(input)'")
    print(String(repeating: "=", count: 50))
    
    do {
        let result = try await graph.run(input)
        let executionTime = Date().timeIntervalSince(startTime)
        
        print("\n" + String(repeating: "✅", count: 20))
        print("EXECUTION SUCCESSFUL")
        print("Result: \(result)")
        print("Execution time: \(String(format: "%.2f", executionTime))s")
        print(String(repeating: "✅", count: 20))
    } catch {
        let executionTime = Date().timeIntervalSince(startTime)
        print("\n" + String(repeating: "❌", count: 20))
        print("EXECUTION FAILED")
        print("Error: \(error.localizedDescription)")
        print("Execution time: \(String(format: "%.2f", executionTime))s")
        print(String(repeating: "❌", count: 20))
    }
}

func showGraphDiagrams() {
    let workflows = [
        ("Simple Workflow", createSimpleWorkflow()),
        ("Conditional Workflow", createConditionalWorkflow()),
        ("Retry Workflow", createRetryWorkflow())
    ]
    
    for (name, graph) in workflows {
        print("\n" + String(repeating: "=", count: 40))
        print("\(name) - Mermaid Diagram")
        print(String(repeating: "=", count: 40))
        print(graph.generateMermaidDiagram())
        
        print("\n" + String(repeating: "-", count: 40))
        print("\(name) - ASCII Diagram")
        print(String(repeating: "-", count: 40))
        print(graph.generateASCIIDiagram())
    }
}

// MARK: - Main Program

@main
struct LiteSwiftGraphCLI {
    static func main() async {
        print("=== LiteSwiftGraph CLI Demo ===")
        print("A lightweight Swift library for building and executing agent graphs")
        print()
        
        var shouldContinue = true
        
        while shouldContinue {
            showMenu()
            
            guard let choice = getUserInput() else {
                print("Invalid input. Please try again.")
                continue
            }
            
            switch choice {
            case "1":
                print("\nEnter input text: ", terminator: "")
                let input = getUserInput() ?? "Hello from LiteSwiftGraph!"
                await runWorkflow(createSimpleWorkflow(), with: input)
                
            case "2":
                print("\nEnter input text (try both short and long): ", terminator: "")
                let input = getUserInput() ?? "Short"
                await runWorkflow(createConditionalWorkflow(), with: input)
                
            case "3":
                print("\nEnter input text: ", terminator: "")
                let input = getUserInput() ?? "Test retry mechanism"
                await runWorkflow(createRetryWorkflow(), with: input)
                
            case "4":
                showGraphDiagrams()
                
            case "5":
                shouldContinue = false
                print("\nThank you for using LiteSwiftGraph CLI!")
                
            default:
                print("Invalid choice. Please enter 1-5.")
            }
            
            if shouldContinue {
                print("\nPress Enter to continue...")
                _ = readLine()
            }
        }
    }
}