import Foundation

// MARK: - Graph Errors

public enum GraphError: Error {
    case timeout
    case invalidWorkflow
    case unknownError
    case nodeNotFound(String)
    case invalidNodeType(String)
    case outputKeyMissing(String)
}