# Creating Your First Graph

Build your first LiteSwiftGraph workflow step by step.

## Overview

This tutorial walks you through creating a simple text processing workflow using LiteSwiftGraph. You'll learn the fundamental concepts of nodes, edges, and execution flow.

## Step 1: Set Up Your Project

First, add LiteSwiftGraph to your project via Swift Package Manager.

### Add the Package Dependency

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/LiteSwiftGraph.git", from: "1.0.0")
]
```

### Import the Library

```swift
import LiteSwiftGraph
```

## Step 2: Create Your First Graph

Let's build a simple text analyzer that processes user input and provides feedback.

```swift
let textAnalyzer = AgentGraph(
    startNode: "analyze", 
    outputKey: "feedback", 
    debug: true
) {
    // Your graph definition goes here
}
```

> Important: All three parameters are required:
> - `startNode`: Where execution begins
> - `outputKey`: The key to extract from the final result
> - `debug`: Whether to show execution logging

## Step 3: Add Processing Nodes

Nodes are where your logic lives. Each node takes a context and returns new data.

```swift
let textAnalyzer = AgentGraph(
    startNode: "analyze", 
    outputKey: "feedback", 
    debug: true
) {
    // Step 1: Analyze the input text
    Node.context("analyze") { context in
        let text = context["input"] as! String
        let wordCount = text.split(separator: " ").count
        let characterCount = text.count
        
        return [
            "originalText": text,
            "wordCount": wordCount,
            "characterCount": characterCount,
            "isShort": wordCount < 5
        ]
    }
    
    // Step 2: Generate feedback for short text
    Node.context("shortFeedback") { context in
        let text = context["originalText"] as! String
        return [
            "feedback": "Your text '\(text)' is quite brief. Consider adding more details."
        ]
    }
    
    // Step 3: Generate feedback for longer text
    Node.context("detailedFeedback") { context in
        let wordCount = context["wordCount"] as! Int
        let charCount = context["characterCount"] as! Int
        return [
            "feedback": "Great! Your text has \(wordCount) words and \(charCount) characters. Well structured!"
        ]
    }
}
```

## Step 4: Define the Flow with Edges

Edges connect your nodes and define the execution path.

```swift
let textAnalyzer = AgentGraph(
    startNode: "analyze", 
    outputKey: "feedback", 
    debug: true
) {
    // ... nodes from above ...
    
    // Define the flow
    Edge(from: "analyze", to: "shortFeedback", description: "short text", condition: { context in
        context["isShort"] as? Bool == true
    })
    
    Edge(from: "analyze", to: "detailedFeedback", description: "detailed text", condition: { context in
        context["isShort"] as? Bool == false
    })
}
```

## Step 5: Execute Your Graph

Now you can run your graph with any input:

```swift
// Execute with sample inputs
let shortResult = try await textAnalyzer.run("Hello world")
print(shortResult)
// Output: "Your text 'Hello world' is quite brief. Consider adding more details."

let longResult = try await textAnalyzer.run("This is a much longer text that contains several words and provides more detailed information")
print(longResult) 
// Output: "Great! Your text has 15 words and 98 characters. Well structured!"
```

## Step 6: Observe Debug Output

With `debug: true`, you'll see detailed execution logging:

```
🔍 DEBUG: Starting graph execution at node: analyze
🔍 DEBUG: Executing node: analyze
🔍 DEBUG: Node analyze result keys: originalText, wordCount, characterCount, isShort
🔍 DEBUG: Found 2 possible edges from node analyze
🔍 DEBUG: Condition satisfied for edge: analyze -> shortFeedback
🔍 DEBUG: Executing node: shortFeedback
🔍 DEBUG: Node shortFeedback result keys: feedback
🔍 DEBUG: End of workflow reached
```

## Complete Example

Here's the complete working example:

```swift
import LiteSwiftGraph

func createTextAnalyzer() -> AgentGraph {
    return AgentGraph(
        startNode: "analyze", 
        outputKey: "feedback", 
        debug: true
    ) {
        Node.context("analyze") { context in
            let text = context["input"] as! String
            let wordCount = text.split(separator: " ").count
            let characterCount = text.count
            
            return [
                "originalText": text,
                "wordCount": wordCount,
                "characterCount": characterCount,
                "isShort": wordCount < 5
            ]
        }
        
        Node.context("shortFeedback") { context in
            let text = context["originalText"] as! String
            return [
                "feedback": "Your text '\(text)' is quite brief. Consider adding more details."
            ]
        }
        
        Node.context("detailedFeedback") { context in
            let wordCount = context["wordCount"] as! Int
            let charCount = context["characterCount"] as! Int
            return [
                "feedback": "Great! Your text has \(wordCount) words and \(charCount) characters. Well structured!"
            ]
        }
        
        Edge(from: "analyze", to: "shortFeedback", description: "short text", condition: { context in
            context["isShort"] as? Bool == true
        })
        
        Edge(from: "analyze", to: "detailedFeedback", description: "detailed text", condition: { context in
            context["isShort"] as? Bool == false
        })
    }
}

// Usage
let analyzer = createTextAnalyzer()
let result = try await analyzer.run("Your input text here")
print(result)
```

## What You've Learned

✅ How to create an ``AgentGraph`` with required parameters  
✅ How to define processing ``Node``s that transform data  
✅ How to connect nodes with conditional ``Edge``s  
✅ How to execute your graph and handle results  
✅ How to use debug mode to understand execution flow  

## Next Steps

- Learn <doc:DebuggingYourGraph> to visualize and monitor your graphs
- Explore <doc:ErrorHandlingAndRetries> for robust production workflows
- Try <doc:BuildingComplexWorkflows> for advanced patterns