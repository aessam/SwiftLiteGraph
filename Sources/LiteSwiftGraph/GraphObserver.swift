import Foundation

// MARK: - Execution Observer Protocol

public protocol GraphExecutionObserver: AnyObject {
    func graphExecutionStarted(initialContext: GraphContext)
    func nodeExecutionStarted(nodeId: String, context: GraphContext)
    func nodeExecutionCompleted(nodeId: String, result: GraphContext)
    func nodeExecutionFailed(nodeId: String, error: Error)
    func graphExecutionCompleted(finalContext: GraphContext, executionPath: [String])
}

// MARK: - Default Implementation

public extension GraphExecutionObserver {
    func graphExecutionStarted(initialContext: GraphContext) {}
    func nodeExecutionStarted(nodeId: String, context: GraphContext) {}
    func nodeExecutionCompleted(nodeId: String, result: GraphContext) {}
    func nodeExecutionFailed(nodeId: String, error: Error) {}
    func graphExecutionCompleted(finalContext: GraphContext, executionPath: [String]) {}
}