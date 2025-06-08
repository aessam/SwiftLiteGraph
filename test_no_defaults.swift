import Foundation

// This should fail to compile if defaults are still present
func testNoDefaults() {
    // This should require all parameters
    let graph = AgentGraph(startNode: "start") { // Missing outputKey and debug - should fail
        Node.context("start") { $0 }
    }
}
EOF < /dev/null