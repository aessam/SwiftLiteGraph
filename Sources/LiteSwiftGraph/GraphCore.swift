import Foundation

// MARK: - Core Types

public typealias GraphContext = [String: Any]

// MARK: - Node

public struct Node<Input, Output> {
    public let id: String
    public let handler: (Input) async throws -> Output
    public var retryConfig: RetryConfig?
    public var timeoutSeconds: Double?
    public var failureHandler: ((Error, Input) async -> Output)?
    
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

// MARK: - Edge

public struct Edge {
    public let fromNode: String
    public let toNode: String
    public let condition: ((GraphContext) -> Bool)?
    public let description: String
    
    public init(from: String, to: String, description: String = "", condition: ((GraphContext) -> Bool)? = nil) {
        self.fromNode = from
        self.toNode = to
        self.condition = condition
        self.description = description
    }
}

// MARK: - RetryConfig

public struct RetryConfig {
    public let maxAttempts: Int
    public let delay: Double
    
    public init(maxAttempts: Int, delay: Double) {
        self.maxAttempts = maxAttempts
        self.delay = delay
    }
}