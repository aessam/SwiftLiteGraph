import Foundation

// MARK: - Node Extensions

extension Node where Input == GraphContext, Output == GraphContext {
    public static func context(_ id: String, handler: @escaping (GraphContext) async throws -> GraphContext) -> Node {
        return Node(id, handler: handler)
    }
}