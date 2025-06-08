import Foundation

// MARK: - Graph Executor

public final class AgentGraph: @unchecked Sendable {
    private var nodes: [String: Any] = [:]
    private var edges: [Edge] = []
    private var startNodeId: String
    private var finalOutputKey: String
    private var debugMode: Bool
    private var observers: [GraphExecutionObserver] = []
    
    public init(startNode: String, outputKey: String, debug: Bool, @GraphBuilder _ builder: () -> [Any]) {
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
    
    // MARK: - Observer Management
    
    public func addObserver(_ observer: GraphExecutionObserver) {
        observers.append(observer)
    }
    
    public func removeObserver(_ observer: GraphExecutionObserver) {
        observers.removeAll { $0 === observer }
    }
    
    // MARK: - Execution
    
    nonisolated public func run(_ input: Any) async throws -> Any {
        guard nodes[startNodeId] != nil else {
            throw GraphError.nodeNotFound(startNodeId)
        }
        
        var context: GraphContext = ["input": input]
        var currentNodeId = startNodeId
        var executionPath: [String] = []
        
        logDebug("Starting graph execution at node: \(currentNodeId)")
        notifyObservers { $0.graphExecutionStarted(initialContext: context) }
        
        while true {
            guard let nodeAny = nodes[currentNodeId] else {
                throw GraphError.nodeNotFound(currentNodeId)
            }
            
            // Add to execution path
            executionPath.append(currentNodeId)
            logDebug("Executing node: \(currentNodeId)")
            notifyObservers { $0.nodeExecutionStarted(nodeId: currentNodeId, context: context) }
            
            // Execute current node
            if let node = nodeAny as? Node<GraphContext, GraphContext> {
                do {
                    let nodeResult = try await executeNode(node, with: context)
                    logDebug("Node \(currentNodeId) result keys: \(nodeResult.keys.joined(separator: ", "))")
                    
                    // Merge results into context
                    for (key, value) in nodeResult {
                        context[key] = value
                    }
                    
                    notifyObservers { $0.nodeExecutionCompleted(nodeId: currentNodeId, result: nodeResult) }
                    
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
                        notifyObservers { $0.graphExecutionCompleted(finalContext: context, executionPath: executionPath) }
                        
                        if let finalOutput = context[finalOutputKey] {
                            return finalOutput
                        } else {
                            throw GraphError.outputKeyMissing(finalOutputKey)
                        }
                    }
                } catch {
                    logDebug("Error in node \(currentNodeId): \(error)")
                    notifyObservers { $0.nodeExecutionFailed(nodeId: currentNodeId, error: error) }
                    
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
                            notifyObservers { $0.graphExecutionCompleted(finalContext: context, executionPath: executionPath) }
                            
                            if let finalOutput = context[finalOutputKey] {
                                return finalOutput
                            } else {
                                throw GraphError.outputKeyMissing(finalOutputKey)
                            }
                        }
                    } else {
                        notifyObservers { $0.graphExecutionCompleted(finalContext: context, executionPath: executionPath) }
                        throw error
                    }
                }
            } else {
                throw GraphError.invalidNodeType(currentNodeId)
            }
        }
    }
    
    private func executeNode(_ node: Node<GraphContext, GraphContext>, with context: GraphContext) async throws -> GraphContext {
        // For now, we'll skip timeout implementation to avoid concurrency issues
        // This can be improved in future versions
        return try await executeWithRetry(node, context: context)
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
    
    private func notifyObservers(_ block: (GraphExecutionObserver) -> Void) {
        for observer in observers {
            block(observer)
        }
    }
    
    // MARK: - Graph Info
    
    public func getNodes() -> [String] {
        return Array(nodes.keys)
    }
    
    public func getEdges() -> [Edge] {
        return edges
    }
    
    public func getStartNodeId() -> String {
        return startNodeId
    }
}