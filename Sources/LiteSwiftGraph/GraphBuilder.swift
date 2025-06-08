import Foundation

// MARK: - Type Wrappers for DSL

public struct AnyNode {
    public let node: Any
    public let id: String
    
    public init<I, O>(_ node: Node<I, O>) {
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