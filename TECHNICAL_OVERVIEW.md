# LiteSwiftGraph Technical Overview

## Project Architecture

LiteSwiftGraph follows a clean modular architecture with clear separation of concerns:

```
LiteSwiftGraph/
├── Sources/
│   ├── LiteSwiftGraph/           # Core graph logic (pure)
│   ├── LiteSwiftGraphDebug/      # UI/Debug components (optional)
│   ├── LiteSwiftGraphCLI/        # Command-line application
│   ├── LiteSwiftGraphUI/         # SwiftUI application
│   └── LiteSwiftGraphExample/    # Example usage
└── Tests/
    └── LiteSwiftGraphTests/      # Unit tests
```

## Core Library (LiteSwiftGraph)

**Purpose**: Pure graph execution logic with no UI dependencies
**Platform Support**: All platforms (macOS, iOS, tvOS, watchOS, visionOS)

### Key Files:
- `GraphCore.swift` - Core execution engine
- `GraphBuilder.swift` - DSL for graph construction using @resultBuilder
- `GraphExecutor.swift` - Main `AgentGraph` class with required parameters
- `GraphError.swift` - Error handling types
- `GraphExtensions.swift` - Mermaid diagram generation
- `GraphObserver.swift` - Observer pattern for execution monitoring
- `LiteSwiftGraph.swift` - Public API exports

### Critical Design Decisions:

1. **No Default Parameters**: `AgentGraph` initializer requires all parameters to force explicit configuration:
   ```swift
   public init(startNode: String, outputKey: String, debug: Bool, @GraphBuilder _ builder: () -> [Any])
   ```

2. **DSL Pattern**: Uses Swift's `@resultBuilder` for declarative graph construction:
   ```swift
   let graph = AgentGraph(startNode: "start", outputKey: "result", debug: false) {
       Node.context("start") { context in ... }
       Edge(from: "start", to: "next")
   }
   ```

3. **Observer Pattern**: Execution monitoring through `GraphExecutionObserver` protocol

## Debug Library (LiteSwiftGraphDebug)

**Purpose**: UI components and debugging tools
**Dependencies**: LiteSwiftGraph (core library)
**Platform Support**: Primarily macOS/iOS for SwiftUI components

### Key Files:
- `GraphDebugConsole.swift` - Real-time execution monitoring
- `GraphRenderer.swift` - ASCII visualization and debug coordination
- `UI/` directory:
  - `ContentView.swift` - Main SwiftUI debug interface
  - `GraphViewModel.swift` - State management for UI
  - `ModernGraphView.swift` - Modern SwiftUI graph visualization
- `GraphExecutorExtensions.swift` - Extension methods for instant SwiftUI views

### Extension Methods Pattern:
```swift
// Just like .generateMermaidDiagram(), users get instant SwiftUI views:
graph.graphView()      // Debug visualization
graph.liveView()       // Live execution with controls
graph.structureView()  // Compact structure overview
```

## Applications

### CLI Application (LiteSwiftGraphCLI)
- Interactive command-line debugging
- Perfect for testing graph logic
- Uses both core and debug libraries

### UI Application (LiteSwiftGraphUI)
- Full visual debugging environment
- Live graph visualization
- Interactive execution with real-time node highlighting
- Multiple example workflows

### Example Application (LiteSwiftGraphExample)
- Demonstrates proper library usage
- Shows integration patterns
- Educational reference implementation

## Swift Package Manager Configuration

### Package.swift Structure:
```swift
let package = Package(
    name: "LiteSwiftGraph",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1)],
    products: [
        .library(name: "LiteSwiftGraph", targets: ["LiteSwiftGraph"]),
        .library(name: "LiteSwiftGraphDebug", targets: ["LiteSwiftGraphDebug"]),
        .executable(name: "LiteSwiftGraphCLI", targets: ["LiteSwiftGraphCLI"]),
        .executable(name: "LiteSwiftGraphUI", targets: ["LiteSwiftGraphUI"]),
        .executable(name: "LiteSwiftGraphExample", targets: ["LiteSwiftGraphExample"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        .target(name: "LiteSwiftGraph"),
        .target(name: "LiteSwiftGraphDebug", dependencies: ["LiteSwiftGraph"]),
        .executableTarget(name: "LiteSwiftGraphExample", dependencies: ["LiteSwiftGraph", "LiteSwiftGraphDebug"]),
        .executableTarget(name: "LiteSwiftGraphCLI", dependencies: ["LiteSwiftGraph", "LiteSwiftGraphDebug"]),
        .executableTarget(name: "LiteSwiftGraphUI", dependencies: ["LiteSwiftGraph", "LiteSwiftGraphDebug"]),
        .testTarget(name: "LiteSwiftGraphTests", dependencies: ["LiteSwiftGraph"])
    ]
)
```

### Key Points:
- `products` must come before `dependencies` in Package.swift
- Core library has no dependencies
- Debug library depends only on core
- All executables use both libraries
- Tests only test the core library

## Documentation System

### DocC Setup:
- Swift-DocC plugin configured for automatic documentation generation
- `.spi.yml` configured for Swift Package Index auto-documentation
- Three comprehensive tutorials in `Documentation.docc/`:
  - `CreatingYourFirstGraph.md` - Basic usage tutorial
  - `DebuggingYourGraph.md` - Comprehensive debugging guide
  - `SwiftUIIntegration.md` - Visual application building

### Generate Documentation:
```bash
swift package generate-documentation --target LiteSwiftGraph
swift package --disable-sandbox preview-documentation --target LiteSwiftGraph
```

## Common Issues and Solutions

### 1. SwiftUI Edge Type Conflicts
**Problem**: SwiftUI has its own `Edge` type causing ambiguity
**Solution**: Use fully qualified types in UI code:
```swift
// In UI files, use:
let edges: [LiteSwiftGraph.Edge] = graph.getEdges()
```

### 2. Missing Imports After File Moves
**Problem**: Files moved between modules missing imports
**Solution**: Add proper imports:
```swift
import LiteSwiftGraph        // For core types
import LiteSwiftGraphDebug   // For UI components
```

### 3. Sendable Protocol Errors
**Problem**: Async execution with non-Sendable types
**Solution**: Use proper MainActor isolation and Task.detached:
```swift
Task.detached {
    // Background work
    await MainActor.run {
        // UI updates
    }
}
```

### 4. Test Compilation After Removing Defaults
**Problem**: Tests fail after removing default parameters
**Solution**: Use sed to update all test files:
```bash
find Tests -name "*.swift" -exec sed -i '' 's/AgentGraph(/AgentGraph(startNode: "start", outputKey: "result", debug: false, /g' {} \;
```

## Development Workflow

### 1. Core Development
- Work in `Sources/LiteSwiftGraph/` for pure graph logic
- No UI dependencies allowed
- All platforms must be supported
- Run tests: `swift test`

### 2. UI/Debug Development
- Work in `Sources/LiteSwiftGraphDebug/` for visual components
- Can depend on core library
- Focus on macOS/iOS SwiftUI
- Test with UI application: `swift run LiteSwiftGraphUI`

### 3. Integration Testing
- Use CLI application: `swift run LiteSwiftGraphCLI`
- Use example application: `swift run LiteSwiftGraphExample`
- Verify both core and debug libraries work together

### 4. Documentation Updates
- Update tutorials in `Documentation.docc/`
- Regenerate docs: `swift package generate-documentation --target LiteSwiftGraph`
- Update README.md for any API changes

## API Design Principles

### 1. Explicit Configuration
- No default parameters in critical APIs
- Users must explicitly define all graph parameters
- Clear error messages for missing configuration

### 2. Consistent Patterns
- Extension methods follow same pattern as existing methods
- `.graphView()` parallels `.generateMermaidDiagram()`
- All debug methods return SwiftUI views for consistency

### 3. Clean Separation
- Core library is pure Swift with no UI dependencies
- Debug library provides optional UI enhancements
- Applications demonstrate usage patterns

### 4. Observable Execution
- Observer pattern for monitoring execution
- Real-time updates for debugging
- Clear execution path tracking

## Performance Considerations

### 1. Lazy Loading
- UI components use lazy loading for large graphs
- Background processing for graph analysis
- Efficient memory usage patterns

### 2. Async Execution
- All graph execution is async/await
- Proper task management and cancellation
- MainActor isolation for UI updates

### 3. Cycle Detection
- Built-in infinite loop prevention
- Execution path tracking
- Clear error reporting for cycles

## Testing Strategy

### 1. Unit Tests
- Core library functionality in `Tests/LiteSwiftGraphTests/`
- Test graph execution, error handling, and edge conditions
- No UI testing in core tests

### 2. Integration Testing
- Use example applications for integration testing
- Manual testing of UI components through applications
- Documentation examples should be tested

### 3. Documentation Testing
- Ensure all code examples in documentation compile
- Tutorial examples should be runnable
- API documentation should be complete

## Future Maintenance Notes

### 1. Adding New Features
- Add core logic to `LiteSwiftGraph`
- Add UI components to `LiteSwiftGraphDebug`
- Update documentation and examples
- Maintain clean separation of concerns

### 2. Breaking Changes
- Follow semantic versioning
- Update all dependent code
- Provide migration guides
- Test all applications and examples

### 3. Platform Support
- Core library supports all Swift platforms
- UI components focus on SwiftUI-supported platforms
- Consider platform-specific optimizations

### 4. Dependencies
- Minimize external dependencies
- Core library should remain dependency-free
- Document any new dependencies clearly

## Git History Reference

Key commits in the refactoring:
- Initial separation of UI from core logic
- Removal of default parameters from AgentGraph
- Addition of SwiftUI extension methods
- DocC documentation setup
- README improvements with clear examples

This technical overview should help future developers understand the architecture, common issues, and development patterns used in LiteSwiftGraph.