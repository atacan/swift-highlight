import Foundation

/// A node in the token tree
internal enum TokenNode {
    case text(String)
    case scope(ScopeNode)
}

/// A scope node containing children
internal final class ScopeNode {
    var scope: String?
    var language: String?
    var children: [TokenNode] = []

    init(scope: String? = nil, language: String? = nil) {
        self.scope = scope
        self.language = language
    }
}

/// Token tree emitter - builds a tree structure during parsing
internal final class TokenTreeEmitter {
    private var rootNode = ScopeNode()
    private var stack: [ScopeNode] = []
    private let options: HighlightOptions

    var root: ScopeNode { rootNode }

    init(options: HighlightOptions) {
        self.options = options
        stack = [rootNode]
    }

    private var top: ScopeNode {
        stack.last ?? rootNode
    }

    /// Adds text to the current node
    func addText(_ text: String) {
        guard !text.isEmpty else { return }
        top.children.append(.text(text))
    }

    /// Opens a new scope
    func openNode(_ scope: String) {
        let node = ScopeNode(scope: scope)
        top.children.append(.scope(node))
        stack.append(node)
    }

    /// Starts a new scope (alias for openNode)
    func startScope(_ scope: String) {
        openNode(scope)
    }

    /// Ends the current scope
    func endScope() {
        closeNode()
    }

    /// Closes the current node
    @discardableResult
    func closeNode() -> ScopeNode? {
        guard stack.count > 1 else { return nil }
        return stack.removeLast()
    }

    /// Closes all open nodes
    func closeAllNodes() {
        while stack.count > 1 {
            _ = closeNode()
        }
    }

    /// Adds a sublanguage result
    func addSublanguage(_ emitter: TokenTreeEmitter, name: String?) {
        let node = emitter.root
        if let name = name {
            node.scope = "language:\(name)"
        }
        top.children.append(.scope(node))
    }

    /// Finalizes the tree
    func finalize() {
        closeAllNodes()
    }

    /// Renders the tree to HTML
    func toHTML() -> String {
        let renderer = HTMLRenderer(options: options)
        return renderer.render(rootNode)
    }
}

/// Renders a token tree to HTML
internal struct HTMLRenderer {
    private let options: HighlightOptions

    init(options: HighlightOptions) {
        self.options = options
    }

    func render(_ node: ScopeNode) -> String {
        var buffer = ""
        renderNode(.scope(node), to: &buffer, isRoot: true)
        return buffer
    }

    private func renderNode(_ node: TokenNode, to buffer: inout String, isRoot: Bool = false) {
        switch node {
        case .text(let text):
            buffer += Utils.escapeHTML(text)
        case .scope(let scopeNode):
            let hasScope = scopeNode.scope != nil && !isRoot
            // Skip empty scope nodes (e.g., empty params)
            if hasScope && scopeNode.children.isEmpty {
                return
            }
            if hasScope {
                let className = scopeToCSSClass(scopeNode.scope!)
                buffer += "<span class=\"\(className)\">"
            }
            for child in scopeNode.children {
                renderNode(child, to: &buffer)
            }
            if hasScope {
                buffer += "</span>"
            }
        }
    }

    private func scopeToCSSClass(_ name: String) -> String {
        // Sub-language scope
        if name.hasPrefix("language:") {
            return name.replacingOccurrences(of: "language:", with: "language-")
        }

        // Tiered scope: comment.line
        if name.contains(".") {
            let pieces = name.split(separator: ".")
            var result = ["\(options.classPrefix)\(pieces[0])"]
            for (i, piece) in pieces.dropFirst().enumerated() {
                result.append("\(piece)\(String(repeating: "_", count: i + 1))")
            }
            return result.joined(separator: " ")
        }

        // Simple scope
        return "\(options.classPrefix)\(name)"
    }
}
