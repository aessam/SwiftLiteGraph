#if canImport(SwiftUI)
import SwiftUI
import LiteSwiftGraph

// MARK: - Modern Graph Canvas View

public struct ModernGraphCanvasView: View {
    @EnvironmentObject var viewModel: GraphViewModel
    @State private var hoveredNode: String? = nil
    @State private var dragOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    
    private let nodeSize: CGSize = CGSize(width: 140, height: 70)
    private let canvasSize: CGSize = CGSize(width: 900, height: 600)
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(NSColor.controlBackgroundColor),
                        Color(NSColor.controlBackgroundColor).opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Grid pattern overlay
                GridPattern()
                    .opacity(0.05)
                
                // Graph content
                Canvas { context, size in
                    // Draw edges first (behind nodes)
                    for edge in viewModel.edges {
                        if let fromPos = nodePosition(for: edge.fromNode),
                           let toPos = nodePosition(for: edge.toNode) {
                            drawModernEdge(
                                context: context,
                                from: fromPos,
                                to: toPos,
                                edge: edge,
                                isExecuted: isEdgeExecuted(edge)
                            )
                        }
                    }
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                
                // Nodes layer
                ForEach(viewModel.allNodes, id: \.self) { nodeId in
                    if let position = nodePosition(for: nodeId) {
                        ModernNodeView(
                            nodeId: nodeId,
                            isExecuted: viewModel.executedNodes.contains(nodeId),
                            isCurrent: viewModel.currentNode == nodeId,
                            isStart: nodeId == viewModel.allNodes.first,
                            isHovered: hoveredNode == nodeId
                        )
                        .position(position)
                        .onHover { isHovered in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                hoveredNode = isHovered ? nodeId : nil
                            }
                        }
                    }
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .scaleEffect(scale)
            .offset(dragOffset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = value
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func nodePosition(for nodeId: String) -> CGPoint? {
        guard let index = viewModel.allNodes.firstIndex(of: nodeId) else { return nil }
        
        // Improved layout algorithm with better spacing
        let totalNodes = viewModel.allNodes.count
        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        
        // Special positioning for common patterns
        switch totalNodes {
        case 1:
            return CGPoint(x: centerX, y: centerY)
        case 2:
            let spacing: CGFloat = 250
            let x = centerX + (index == 0 ? -spacing/2 : spacing/2)
            return CGPoint(x: x, y: centerY)
        case 3:
            if index == 0 {
                return CGPoint(x: centerX, y: 100)
            } else {
                let x = centerX + (index == 1 ? -150 : 150)
                return CGPoint(x: x, y: centerY + 100)
            }
        default:
            // Hierarchical layout for complex graphs
            let levels = calculateNodeLevels()
            let level = levels[nodeId] ?? 0
            let nodesAtLevel = viewModel.allNodes.filter { levels[$0] == level }
            let indexAtLevel = nodesAtLevel.firstIndex(of: nodeId) ?? 0
            
            let levelHeight = canvasSize.height / CGFloat(levels.values.max() ?? 1 + 2)
            let y = levelHeight * CGFloat(level + 1)
            
            let levelWidth = canvasSize.width - 200
            let nodeSpacing = levelWidth / CGFloat(nodesAtLevel.count + 1)
            let x = 100 + nodeSpacing * CGFloat(indexAtLevel + 1)
            
            return CGPoint(x: x, y: y)
        }
    }
    
    private func calculateNodeLevels() -> [String: Int] {
        var levels: [String: Int] = [:]
        var visited: Set<String> = []
        
        // BFS to assign levels
        if let startNode = viewModel.allNodes.first {
            var queue: [(node: String, level: Int)] = [(startNode, 0)]
            
            while !queue.isEmpty {
                let (node, level) = queue.removeFirst()
                if visited.contains(node) { continue }
                
                visited.insert(node)
                levels[node] = level
                
                // Find connected nodes
                let connectedNodes = viewModel.edges
                    .filter { $0.fromNode == node }
                    .map { $0.toNode }
                
                for nextNode in connectedNodes {
                    if !visited.contains(nextNode) {
                        queue.append((nextNode, level + 1))
                    }
                }
            }
        }
        
        // Assign remaining nodes
        for node in viewModel.allNodes where levels[node] == nil {
            levels[node] = 0
        }
        
        return levels
    }
    
    private func isEdgeExecuted(_ edge: LiteSwiftGraph.Edge) -> Bool {
        return viewModel.executedNodes.contains(edge.fromNode) &&
               viewModel.executedNodes.contains(edge.toNode)
    }
    
    private func drawModernEdge(context: GraphicsContext, from: CGPoint, to: CGPoint, edge: LiteSwiftGraph.Edge, isExecuted: Bool) {
        // Calculate edge endpoints at node boundaries
        let angle = atan2(to.y - from.y, to.x - from.x)
        let nodeWidth: CGFloat = 140
        let nodeHeight: CGFloat = 70
        
        // Calculate intersection points with node rectangles
        let fromEdge = calculateNodeEdgePoint(center: from, angle: angle, width: nodeWidth, height: nodeHeight, isOutgoing: true)
        let toEdge = calculateNodeEdgePoint(center: to, angle: angle + .pi, width: nodeWidth, height: nodeHeight, isOutgoing: false)
        
        var path = Path()
        
        // Smart curve calculation that avoids inappropriate loops
        let deltaX = toEdge.x - fromEdge.x
        let deltaY = toEdge.y - fromEdge.y
        let distance = hypot(deltaX, deltaY)
        
        // Only use curves for longer connections or when nodes are at similar heights
        let shouldUseCurve = distance > 150 || abs(deltaY) < 50
        
        if shouldUseCurve && distance > 100 {
            // Calculate intelligent control points
            let midX = (fromEdge.x + toEdge.x) / 2
            let midY = (fromEdge.y + toEdge.y) / 2
            let curvature = min(distance * 0.15, 40)
            
            // Determine curve direction based on relative positions
            let curveOffset: CGFloat
            if abs(deltaX) > abs(deltaY) {
                // Horizontal-ish connection: curve up or down based on vertical space
                curveOffset = deltaY > 0 ? -curvature : curvature
            } else {
                // Vertical-ish connection: curve left or right based on horizontal space
                curveOffset = deltaX > 0 ? curvature : -curvature
            }
            
            let controlPoint1 = CGPoint(
                x: fromEdge.x + deltaX * 0.3,
                y: fromEdge.y + (abs(deltaX) > abs(deltaY) ? curveOffset : deltaY * 0.3)
            )
            let controlPoint2 = CGPoint(
                x: toEdge.x - deltaX * 0.3,
                y: toEdge.y - (abs(deltaX) > abs(deltaY) ? curveOffset : deltaY * 0.3)
            )
            
            path.move(to: fromEdge)
            path.addCurve(to: toEdge, control1: controlPoint1, control2: controlPoint2)
        } else {
            // Use straight line for short distances or direct vertical/horizontal connections
            path.move(to: fromEdge)
            path.addLine(to: toEdge)
        }
        
        // Draw edge with modern styling
        let edgeColor = isExecuted ? Color.green : Color(NSColor.tertiaryLabelColor).opacity(0.5)
        let strokeStyle = StrokeStyle(
            lineWidth: isExecuted ? 3 : 2,
            lineCap: .round,
            lineJoin: .round,
            dash: edge.condition != nil ? [8, 4] : []
        )
        
        if isExecuted {
            // Add glow effect for executed edges
            context.stroke(
                path,
                with: .color(edgeColor.opacity(0.3)),
                style: StrokeStyle(lineWidth: 8, lineCap: .round)
            )
        }
        
        context.stroke(path, with: .color(edgeColor), style: strokeStyle)
        
        // Draw arrow head
        drawArrowHead(context: context, from: fromEdge, to: toEdge, isExecuted: isExecuted)
        
        // Draw edge label if present
        if !edge.description.isEmpty {
            let midX = (fromEdge.x + toEdge.x) / 2
            let midY = (fromEdge.y + toEdge.y) / 2
            let labelRect = CGRect(
                x: midX - 60,
                y: midY - 15,
                width: 120,
                height: 30
            )
            
            context.draw(
                Text(edge.description)
                    .font(.caption)
                    .foregroundColor(isExecuted ? .primary : .secondary),
                in: labelRect
            )
        }
    }
    
    private func drawArrowHead(context: GraphicsContext, from: CGPoint, to: CGPoint, isExecuted: Bool) {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 15
        let arrowAngle: CGFloat = .pi / 6
        
        // Arrow tip is already at the edge of the node
        let arrowTip = to
        
        var arrowPath = Path()
        let arrowLeft = CGPoint(
            x: arrowTip.x - arrowLength * cos(angle - arrowAngle),
            y: arrowTip.y - arrowLength * sin(angle - arrowAngle)
        )
        let arrowRight = CGPoint(
            x: arrowTip.x - arrowLength * cos(angle + arrowAngle),
            y: arrowTip.y - arrowLength * sin(angle + arrowAngle)
        )
        
        arrowPath.move(to: arrowLeft)
        arrowPath.addLine(to: arrowTip)
        arrowPath.addLine(to: arrowRight)
        arrowPath.closeSubpath()
        
        let arrowColor = isExecuted ? Color.green : Color(NSColor.tertiaryLabelColor).opacity(0.5)
        context.fill(arrowPath, with: .color(arrowColor))
    }
    
    private func calculateNodeEdgePoint(center: CGPoint, angle: CGFloat, width: CGFloat, height: CGFloat, isOutgoing: Bool) -> CGPoint {
        // Calculate the intersection point of a line from the center at the given angle
        // with the rounded rectangle boundary
        let halfWidth = width / 2
        let halfHeight = height / 2
        
        // Normalize angle to [0, 2π)
        var normalizedAngle = angle
        while normalizedAngle < 0 { normalizedAngle += 2 * .pi }
        while normalizedAngle >= 2 * .pi { normalizedAngle -= 2 * .pi }
        
        // Calculate intersection with rectangle edges
        let dx = cos(normalizedAngle)
        let dy = sin(normalizedAngle)
        
        var intersectionX: CGFloat
        var intersectionY: CGFloat
        
        // Check which edge the line intersects
        if abs(dx) * halfHeight > abs(dy) * halfWidth {
            // Intersects left or right edge
            intersectionX = dx > 0 ? halfWidth : -halfWidth
            intersectionY = dy * halfWidth / abs(dx)
        } else {
            // Intersects top or bottom edge
            intersectionX = dx * halfHeight / abs(dy)
            intersectionY = dy > 0 ? halfHeight : -halfHeight
        }
        
        // For rounded corners, adjust the point slightly inward
        let adjustmentFactor: CGFloat = 0.85 // Slight inset to account for corner radius
        let finalX = center.x + intersectionX * adjustmentFactor
        let finalY = center.y + intersectionY * adjustmentFactor
        
        return CGPoint(x: finalX, y: finalY)
    }
}

// MARK: - Modern Node View

struct ModernNodeView: View {
    let nodeId: String
    let isExecuted: Bool
    let isCurrent: Bool
    let isStart: Bool
    let isHovered: Bool
    
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Glow effect for current node
            if isCurrent {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(0.4),
                                Color.yellow.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            }
            
            // Main node container
            RoundedRectangle(cornerRadius: 16)
                .fill(nodeBackgroundGradient)
                .frame(width: 140, height: 70)
                .shadow(
                    color: shadowColor,
                    radius: isHovered ? 12 : 8,
                    x: 0,
                    y: isHovered ? 6 : 4
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(nodeBorderGradient, lineWidth: isCurrent ? 3 : 2)
                )
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.spring(response: 0.3), value: isHovered)
            
            // Node content
            VStack(spacing: 4) {
                if isStart {
                    Label("START", systemImage: "play.circle.fill")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                Text(nodeId)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(isCurrent ? .bold : .medium)
                    .foregroundColor(textColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            
            // Status indicator
            if isExecuted && !isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                    .background(Circle().fill(Color(NSColor.controlBackgroundColor)))
                    .offset(x: 55, y: -25)
            }
            
            if isCurrent {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 20, height: 20)
                            .opacity(0.3)
                            .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                    )
                    .offset(x: 55, y: -25)
            }
        }
        .onAppear {
            if isCurrent {
                pulseAnimation = true
            }
        }
    }
    
    private var nodeBackgroundGradient: LinearGradient {
        let colors: [Color]
        
        if isCurrent {
            colors = [
                Color.yellow.opacity(0.3),
                Color.yellow.opacity(0.2)
            ]
        } else if isExecuted {
            colors = [
                Color.green.opacity(0.25),
                Color.green.opacity(0.15)
            ]
        } else {
            colors = [
                Color(NSColor.controlColor),
                Color(NSColor.controlColor).opacity(0.8)
            ]
        }
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var nodeBorderGradient: LinearGradient {
        let colors: [Color]
        
        if isCurrent {
            colors = [Color.orange, Color.yellow]
        } else if isExecuted {
            colors = [Color.green, Color.green.opacity(0.8)]
        } else {
            colors = [
                Color(NSColor.separatorColor),
                Color(NSColor.separatorColor).opacity(0.5)
            ]
        }
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var shadowColor: Color {
        if isCurrent {
            return Color.yellow.opacity(0.3)
        } else if isExecuted {
            return Color.green.opacity(0.2)
        } else {
            return Color.black.opacity(0.1)
        }
    }
    
    private var textColor: Color {
        if isCurrent {
            return .primary
        } else if isExecuted {
            return .primary
        } else {
            return .secondary
        }
    }
}

// MARK: - Grid Pattern

struct GridPattern: View {
    var body: some View {
        Canvas { context, size in
            let gridSize: CGFloat = 20
            
            // Vertical lines
            for x in stride(from: 0, to: size.width, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(
                    path,
                    with: .color(Color(NSColor.separatorColor).opacity(0.5)),
                    lineWidth: 0.5
                )
            }
            
            // Horizontal lines
            for y in stride(from: 0, to: size.height, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(
                    path,
                    with: .color(Color(NSColor.separatorColor).opacity(0.5)),
                    lineWidth: 0.5
                )
            }
        }
    }
}

#endif