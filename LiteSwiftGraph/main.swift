import Foundation

// Define a proper type for the context passed between nodes
public typealias GraphContext = [String: Any]

// MARK: - Core Components

// Define core graph components
public struct Node<Input, Output> {
    let id: String
    let handler: (Input) async throws -> Output
    var retryConfig: RetryConfig?
    var timeoutSeconds: Double?
    var failureHandler: ((Error, Input) async -> Output)?
    
    public init(_ id: String, handler: @escaping (Input) async throws -> Output) {
        self.id = id
        self.handler = handler
    }
    
    public func timeout(seconds: Double) -> Self {
        var copy = self
        copy.timeoutSeconds = seconds
        return copy
    }
    
    public func retry(maxAttempts: Int, delay: Double = 1.0) -> Self {
        var copy = self
        copy.retryConfig = RetryConfig(maxAttempts: maxAttempts, delay: delay)
        return copy
    }
    
    public func onFailure(_ handler: @escaping (Error, Input) async -> Output) -> Self {
        var copy = self
        copy.failureHandler = handler
        return copy
    }
}

public struct Edge {
    let fromNode: String
    let toNode: String
    let condition: ((GraphContext) -> Bool)?
    let description: String
    
    public init(from: String, to: String, description: String = "", condition: ((GraphContext) -> Bool)? = nil) {
        self.fromNode = from
        self.toNode = to
        self.condition = condition
        self.description = description
    }
}

public struct RetryConfig {
    let maxAttempts: Int
    let delay: Double
}

// MARK: - Type Wrappers for DSL

// Type-erased node for DSL
public struct AnyNode {
    let node: Any
    let id: String
    
    init<I, O>(_ node: Node<I, O>) {
        self.node = node
        self.id = node.id
    }
}

// MARK: - Graph Builder DSL

@resultBuilder
public struct GraphBuilder {
    public static func buildBlock(_ components: Any...) -> [Any] {
        return components
    }
    
    public static func buildExpression<I, O>(_ node: Node<I, O>) -> AnyNode {
        return AnyNode(node)
    }
    
    public static func buildExpression(_ edge: Edge) -> Edge {
        return edge
    }
}

// MARK: - Error Types

enum GraphError: Error {
    case timeout
    case invalidWorkflow
    case unknownError
    case nodeNotFound(String)
    case invalidNodeType(String)
    case outputKeyMissing(String)
}

// MARK: - Graph Implementation

public class AgentGraph {
    private var nodes: [String: Any] = [:]
    private var edges: [Edge] = []
    private var startNodeId: String
    private var finalOutputKey: String
    private var debugMode: Bool
    
    public init(startNode: String = "start", outputKey: String = "finalAnswer", debug: Bool = false, @GraphBuilder _ builder: () -> [Any]) {
        self.startNodeId = startNode
        self.finalOutputKey = outputKey
        self.debugMode = debug
        
        let components = builder()
        
        // Extract nodes and edges
        for component in components {
            if let anyNode = component as? AnyNode {
                nodes[anyNode.id] = anyNode.node
            } else if let edge = component as? Edge {
                edges.append(edge)
            }
        }
    }
    
    // MARK: - Visualization Methods
    
    // Generate Mermaid diagram representation
    public func generateMermaidDiagram() -> String {
        var diagram = "graph TD;\n"
        
        // Add all nodes
        for nodeId in nodes.keys {
            let shape = nodeId == startNodeId ? "([Start])" : "[\"\(nodeId)\"]"
            diagram += "    \(nodeId)\(shape);\n"
        }
        
        // Add all edges
        for edge in edges {
            let edgeStyle = edge.condition != nil ? "-.->|\"" : "-->|\""
            let edgeLabel = edge.description.isEmpty ? "flow" : edge.description
            diagram += "    \(edge.fromNode) \(edgeStyle)\(edgeLabel)\"| \(edge.toNode);\n"
        }
        
        return diagram
    }
    
    // Generate Mermaid diagram with execution path highlighted
    public func generateMermaidDiagramWithPath(_ executionPath: [String]) -> String {
        var diagram = "graph TD;\n"
        
        // Define a style for the execution path
        diagram += "    classDef executedNode fill:#FF6666,stroke:#990000,color:white,stroke-width:2px;\n"
        diagram += "    classDef executedEdge stroke:#FF0000,stroke-width:2px;\n"
        
        // Add all nodes
        for nodeId in nodes.keys {
            let shape = nodeId == startNodeId ? "([Start])" : "[\"\(nodeId)\"]"
            diagram += "    \(nodeId)\(shape);\n"
        }
        
        // Add all edges
        for edge in edges {
            let edgeStyle = edge.condition != nil ? "-.->|\"" : "-->|\""
            let edgeLabel = edge.description.isEmpty ? "flow" : edge.description
            
            // Create a unique ID for the edge
//            let edgeId = "edge_\(edge.fromNode)_\(edge.toNode)"
            diagram += "    \(edge.fromNode) \(edgeStyle)\(edgeLabel)\"| \(edge.toNode);\n"
        }
        
        // Apply class to executed nodes
        if !executionPath.isEmpty {
            diagram += "    class " + executionPath.joined(separator: ",") + " executedNode;\n"
        }
        
        // Generate IDs for executed edges and apply class
        if executionPath.count > 1 {
            var executedEdgeIDs: [String] = []
            for i in 0..<(executionPath.count - 1) {
                let fromNode = executionPath[i]
                let toNode = executionPath[i + 1]
                
                // Find all edges between these nodes
                let relevantEdges = edges.filter { $0.fromNode == fromNode && $0.toNode == toNode }
                
                // Add edge IDs to the list
                for _ in relevantEdges {
                    let edgeId = "edge_\(fromNode)_\(toNode)"
                    executedEdgeIDs.append(edgeId)
                }
            }
            
            // Apply class to edges if any were found
            if !executedEdgeIDs.isEmpty {
                diagram += "    linkStyle " + executedEdgeIDs.indices.map { String($0) }.joined(separator: ",") + " stroke:#FF0000,stroke-width:2px;\n"
            }
        }
        
        return diagram
    }
    
    // Print Mermaid diagram to console
    public func printMermaidDiagram() {
        print("=== Graph Visualization (Mermaid) ===")
        print(generateMermaidDiagram())
        print("=====================================")
    }
    
    // Print Mermaid diagram with execution path highlighted
    public func printMermaidDiagramWithPath(_ executionPath: [String]) {
        print("=== Graph Execution Path (Mermaid) ===")
        print(generateMermaidDiagramWithPath(executionPath))
        print("======================================")
    }
    
    public func run(_ input: Any) async throws -> Any {
        guard nodes[startNodeId] != nil else {
            throw GraphError.nodeNotFound(startNodeId)
        }
        
        var context: GraphContext = ["input": input]
        var currentNodeId = startNodeId
        var executionPath: [String] = []
        
        logDebug("Starting graph execution at node: \(currentNodeId)")
        
        while true {
            guard let nodeAny = nodes[currentNodeId] else {
                throw GraphError.nodeNotFound(currentNodeId)
            }
            
            // Add to execution path
            executionPath.append(currentNodeId)
            logDebug("Executing node: \(currentNodeId)")
            
            // Execute current node
            if let node = nodeAny as? Node<GraphContext, GraphContext> {
                do {
                    let nodeResult = try await executeNode(node, with: context)
                    logDebug("Node \(currentNodeId) result keys: \(nodeResult.keys.joined(separator: ", "))")
                    
                    // Merge results into context
                    for (key, value) in nodeResult {
                        context[key] = value
                    }
                    
                    // Find next node based on edges and conditions
                    if let nextNodeId = findNextNode(from: currentNodeId, context: context) {
                        logDebug("Moving to next node: \(nextNodeId)")
                        currentNodeId = nextNodeId
                        
                        // Check for cycles
                        if executionPath.filter({ $0 == currentNodeId }).count > 3 {
                            logDebug("Possible infinite loop detected, breaking cycle")
                            throw GraphError.invalidWorkflow
                        }
                    } else {
                        // End of workflow, return final result
                        logDebug("End of workflow reached")
                        
                        // Print execution path diagram before returning
                        if debugMode {
                            printMermaidDiagramWithPath(executionPath)
                        }
                        
                        if let finalOutput = context[finalOutputKey] {
                            return finalOutput
                        } else {
                            throw GraphError.outputKeyMissing(finalOutputKey)
                        }
                    }
                } catch {
                    logDebug("Error in node \(currentNodeId): \(error)")
                    if let failureHandler = node.failureHandler {
                        let fallbackResult = await failureHandler(error, context)
                        for (key, value) in fallbackResult {
                            context[key] = value
                            logDebug("Added fallback result for key: \(key)")
                        }
                        
                        // Find next node after failure handling
                        if let nextNodeId = findNextNode(from: currentNodeId, context: context) {
                            logDebug("Moving to next node after failure: \(nextNodeId)")
                            currentNodeId = nextNodeId
                        } else {
                            // End of workflow after failure
                            logDebug("End of workflow reached after failure")
                            
                            // Print execution path diagram before returning
                            if debugMode {
                                printMermaidDiagramWithPath(executionPath)
                            }
                            
                            if let finalOutput = context[finalOutputKey] {
                                return finalOutput
                            } else {
                                throw GraphError.outputKeyMissing(finalOutputKey)
                            }
                        }
                    } else {
                        // Print execution path diagram before throwing
                        if debugMode {
                            printMermaidDiagramWithPath(executionPath)
                        }
                        
                        throw error
                    }
                }
            } else {
                throw GraphError.invalidNodeType(currentNodeId)
            }
        }
    }
    
    private func executeNode(_ node: Node<GraphContext, GraphContext>, with context: GraphContext) async throws -> GraphContext {
        if let timeout = node.timeoutSeconds {
            return try await withTimeout(seconds: timeout) {
                try await self.executeWithRetry(node, context: context)
            }
        } else {
            return try await executeWithRetry(node, context: context)
        }
    }
    
    private func executeWithRetry(_ node: Node<GraphContext, GraphContext>, context: GraphContext) async throws -> GraphContext {
        if let retryConfig = node.retryConfig {
            var lastError: Error?
            for attempt in 1...retryConfig.maxAttempts {
                do {
                    logDebug("Executing node \(node.id) - attempt \(attempt)/\(retryConfig.maxAttempts)")
                    return try await node.handler(context)
                } catch {
                    lastError = error
                    logDebug("Node \(node.id) failed with error: \(error), attempt \(attempt)/\(retryConfig.maxAttempts)")
                    if attempt < retryConfig.maxAttempts {
                        try await Task.sleep(nanoseconds: UInt64(retryConfig.delay * 1_000_000_000))
                    }
                }
            }
            throw lastError ?? GraphError.unknownError
        } else {
            return try await node.handler(context)
        }
    }
    
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let task = Task {
                do {
                    let result = try await operation()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            Task {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                task.cancel()
                continuation.resume(throwing: GraphError.timeout)
            }
        }
    }
    
    private func findNextNode(from currentNodeId: String, context: GraphContext) -> String? {
        let possibleEdges = edges.filter { $0.fromNode == currentNodeId }
        logDebug("Found \(possibleEdges.count) possible edges from node \(currentNodeId)")
        
        for edge in possibleEdges {
            if let condition = edge.condition {
                logDebug("Evaluating condition for edge to \(edge.toNode)")
                if condition(context) {
                    logDebug("Condition satisfied for edge: \(currentNodeId) -> \(edge.toNode)")
                    return edge.toNode
                } else {
                    logDebug("Condition failed for edge: \(currentNodeId) -> \(edge.toNode)")
                }
            } else {
                logDebug("Taking unconditional edge: \(currentNodeId) -> \(edge.toNode)")
                return edge.toNode
            }
        }
        
        logDebug("No valid edges found from node \(currentNodeId)")
        return nil
    }
    
    private func logDebug(_ message: String) {
        if debugMode {
            print("🔍 DEBUG: \(message)")
        }
    }
}

// MARK: - Sample Usage

// Create a convenience extension for creating context nodes
extension Node where Input == GraphContext, Output == GraphContext {
    public static func context(_ id: String, handler: @escaping (GraphContext) async throws -> GraphContext) -> Node {
        return Node(id, handler: handler)
    }
}

// Sample usage with a complex multi-stage research workflow
func createComplexResearchAgent() -> AgentGraph {
    return AgentGraph(startNode: "start", outputKey: "finalAnswer", debug: true) {
        // DEFINE NODES
        
        // Start node - initialize the workflow
        Node.context("start") { input in
            print("Initializing research workflow...")
            return [
                "query": input["input"] as! String,
                "stage": "initialized",
                "timestamp": Date()
            ]
        }
        
        // Query understanding - analyze what's being asked
        Node.context("queryAnalysis") { context in
            print("Analyzing query: \(context["query"] as! String)")
            
            let query = context["query"] as! String
            // Extract key terms
            let keyTerms = query.components(separatedBy: " ")
                .filter { $0.count > 3 }
                .map { $0.lowercased() }
            
            // Identify query type
            let queryType = query.contains("how") ? "procedural" :
                          query.contains("why") ? "explanatory" :
                          query.contains("when") ? "temporal" :
                          query.contains("what") ? "factual" : "general"
            
            return [
                "query": query,
                "queryType": queryType,
                "keyTerms": keyTerms,
                "stage": "queryAnalyzed",
                "requiresExternalData": true
            ]
        }
        
        // Primary search node - search for information
        Node.context("primarySearch") { context in
            print("Performing primary search for: \(context["keyTerms"] as! [String])")
            
            // Simulate search delay
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Mock search results
            let searchResults = [
                "Found information about quantum computing advancements",
                "Recent breakthroughs in quantum error correction",
                "New quantum algorithms developed in 2024"
            ]
            
            // Determine if results are sufficient or need refinement
            let resultsQuality = Double.random(in: 0...1)
            let needsRefinement = resultsQuality < 0.7
            
            return [
                "primaryResults": searchResults,
                "resultsQuality": resultsQuality,
                "needsRefinement": needsRefinement,
                "stage": "primarySearchCompleted",
                "searchTimestamp": Date()
            ]
        }
        
        // Search refinement node - improve search results if needed
        Node.context("searchRefinement") { context in
            print("Refining search based on initial results...")
            
            let keyTerms = context["keyTerms"] as! [String]
            let primaryResults = context["primaryResults"] as! [String]
            
            // Extract additional terms from primary results
            let additionalTerms = ["quantum", "research", "algorithm"]
            
            // Combine terms for refined search
            let refinedTerms = Array(Set(keyTerms + additionalTerms))
            
            print("Refined search terms: \(refinedTerms)")
            
            // Simulate refined search
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            let refinedResults = [
                "Latest quantum computing hardware developments",
                "Quantum supremacy achievements in 2023-2024",
                "Commercial applications of quantum computing",
                "Quantum computing research funding trends"
            ]
            
            // Combine with original results
            var allResults = primaryResults
            allResults.append(contentsOf: refinedResults)
            
            return [
                "allResults": allResults,
                "refinedTerms": refinedTerms,
                "stage": "searchRefined"
            ]
        }
        
        // Information extraction - extract relevant details
        Node.context("informationExtraction") { context in
            print("Extracting information from search results...")
            
            // Get results from either primary or refined search
            let results = context["allResults"] as? [String] ?? context["primaryResults"] as! [String]
            
            // Mock extracted information
            let extractedInformation = [
                "fact1": "Quantum error correction improved by 45% in 2024",
                "fact2": "IBM unveiled 1000+ qubit quantum computer",
                "fact3": "Quantum machine learning shows 30% performance boost",
                "fact4": "New quantum algorithms for optimization problems",
                "fact5": "Quantum cloud services expanded to more industries"
            ]
            
            return [
                "extractedInformation": extractedInformation,
                "dataPoints": extractedInformation.count,
                "stage": "informationExtracted"
            ]
        }
        
        // Source evaluation - assess credibility and relevance
        Node.context("sourceEvaluation") { context in
            print("Evaluating sources...")
            
            // Mock source evaluation
            let sourceCredibility = 0.85
            let sourceRelevance = 0.9
            let sourceFreshness = 0.95
            
            let sourceScore = (sourceCredibility + sourceRelevance + sourceFreshness) / 3.0
            
            return [
                "sourceCredibility": sourceCredibility,
                "sourceRelevance": sourceRelevance,
                "sourceFreshness": sourceFreshness,
                "sourceScore": sourceScore,
                "stage": "sourcesEvaluated"
            ]
        }
        
        // Additional context lookup - get supplementary information
        Node.context("contextLookup") { context in
            print("Looking up additional context...")
            
            // Mock context information
            let additionalContext = [
                "field": "Quantum computing is a rapidly evolving field",
                "history": "Major breakthroughs started in 2019 with quantum supremacy",
                "challenges": "Quantum decoherence remains a significant challenge",
                "future": "Commercial applications expected to expand by 2027"
            ]
            
            return [
                "additionalContext": additionalContext,
                "stage": "contextAdded"
            ]
        }
        
        // Generate response draft
        Node.context("responseDraft") { context in
            print("Generating response draft...")
            
            let query = context["query"] as! String
            let extractedInfo = context["extractedInformation"] as! [String: String]
            let additionalContext = context["additionalContext"] as? [String: String] ?? [:]
            
            // Generate a draft response
            let draft = """
            Draft response to: \(query)
            
            Key findings:
            - \(extractedInfo["fact1"] ?? "")
            - \(extractedInfo["fact2"] ?? "")
            - \(extractedInfo["fact3"] ?? "")
            
            Additional context:
            - \(additionalContext["field"] ?? "")
            - \(additionalContext["challenges"] ?? "")
            """
            
            return [
                "responseDraft": draft,
                "draftQuality": 0.75,
                "stage": "draftGenerated"
            ]
        }
        
        // Response refinement
        Node.context("responseRefinement") { context in
            print("Refining response...")
            
            let draft = context["responseDraft"] as! String
            let draftQuality = context["draftQuality"] as! Double
            
            // Simulate refinement
            let refinementNeeded = draftQuality < 0.8
            
            var refinedResponse = draft
            if refinementNeeded {
                // Add more details
                refinedResponse += """
                
                Further insights:
                - Quantum computing research funding increased by 30% globally
                - Several startups have emerged focusing on specialized quantum hardware
                - Major cloud providers now offer quantum computing services
                """
            }
            
            return [
                "refinedResponse": refinedResponse,
                "stage": "responseRefined"
            ]
        }
        
        // Final response formatting
        Node.context("finalFormatting") { context in
            print("Formatting final response...")
            
            let response = context["refinedResponse"] as! String
            let query = context["query"] as! String
            
            // Create nicely formatted final answer
            let finalAnswer = """
            Based on comprehensive research on "\(query)", here is what I found:
            
            \(response)
            
            CONCLUSION:
            Quantum computing is advancing rapidly with improvements in both hardware capabilities and algorithm development. Error correction, increased qubit counts, and practical applications are the main areas of progress.
            """
            
            return [
                "finalAnswer": finalAnswer,
                "stage": "completed",
                "completionTimestamp": Date()
            ]
        }
        
        // Error handling node
        Node.context("errorHandling") { context in
            print("Handling error in workflow...")
            
            let query = context["query"] as? String ?? "unknown query"
            let stage = context["stage"] as? String ?? "unknown stage"
            let error = context["error"] as? String ?? "An unknown error occurred"
            
            let errorResponse = """
            I encountered an issue while researching "\(query)".
            
            The process failed during the "\(stage)" stage with the following error:
            \(error)
            
            I can retry the search with a different approach if you'd like.
            """
            
            return [
                "finalAnswer": errorResponse,
                "stage": "error"
            ]
        }
        
        // DEFINE EDGES
        
        // Main flow
        Edge(from: "start", to: "queryAnalysis", description: "Initialize")
        Edge(from: "queryAnalysis", to: "primarySearch", description: "Search")
        
        // Conditional flow based on search quality
        Edge(from: "primarySearch", to: "searchRefinement", description: "Needs refinement", condition: { context in
            return context["needsRefinement"] as? Bool == true
        })
        Edge(from: "primarySearch", to: "informationExtraction", description: "Good results", condition: { context in
            return context["needsRefinement"] as? Bool == false
        })
        
        // Continue flow after refinement
        Edge(from: "searchRefinement", to: "informationExtraction", description: "Process refined results")
        
        // Fork for parallel processing
        Edge(from: "informationExtraction", to: "sourceEvaluation", description: "Evaluate sources")
        Edge(from: "informationExtraction", to: "contextLookup", description: "Add context")
        
        // Join back for response generation - fixed conditions
        Edge(from: "sourceEvaluation", to: "responseDraft", description: "Wait for context", condition: { context in
            // Only proceed when both source evaluation and context lookup are done
            return context["additionalContext"] != nil
        })
        Edge(from: "contextLookup", to: "responseDraft", description: "Wait for sources", condition: { context in
            // Only proceed when both source evaluation and context lookup are done
            return context["sourceScore"] != nil
        })
        
        // Fallback edges in case one path takes too long
        Edge(from: "sourceEvaluation", to: "contextLookup", description: "Get context if missing")
        Edge(from: "contextLookup", to: "sourceEvaluation", description: "Get sources if missing")
        
        // Final stages
        Edge(from: "responseDraft", to: "responseRefinement", description: "Refine")
        Edge(from: "responseRefinement", to: "finalFormatting", description: "Format")
        
        // Error handling edges
        Edge(from: "primarySearch", to: "errorHandling", description: "Search error", condition: { context in
            return context["error"] != nil
        })
        Edge(from: "informationExtraction", to: "errorHandling", description: "Extraction error", condition: { context in
            return context["error"] != nil
        })
    }
}

// Run the complex research agent
func runComplexAgent() async throws {
    let agent = createComplexResearchAgent()
    
    print("\n=== COMPLEX RESEARCH AGENT ===\n")
    
    // Print the graph visualization
    agent.printMermaidDiagram()
    
    print("\n=== EXECUTING WORKFLOW ===\n")
    
    // Run the agent
    let result = try await agent.run("What are the latest advancements in quantum computing?")
    
    print("\n=== FINAL RESULT ===\n")
    print(result)
}

// Execute
try await runComplexAgent()
