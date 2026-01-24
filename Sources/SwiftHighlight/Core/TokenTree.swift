import Foundation

/// A node in the token tree representing parsed code structure.
public enum TokenNode: Sendable, Hashable {
    /// Plain text content
    case text(String)
    /// A scoped node containing children with semantic meaning
    case scope(ScopeNode)
}

/// A scope node containing children with optional scope and language.
/// Scopes represent semantic categories like "keyword", "string", "comment", etc.
public struct ScopeNode: Sendable, Hashable {
    /// The scope name (e.g., "keyword", "string", "comment")
    public let scope: String?
    /// The language name for sub-language embedding
    public let language: String?
    /// Child nodes
    public let children: [TokenNode]

    public init(scope: String? = nil, language: String? = nil, children: [TokenNode] = []) {
        self.scope = scope
        self.language = language
        self.children = children
    }
}

/// A wrapper for the token tree root with associated language.
/// Use this for custom rendering of highlighted code.
public struct TokenTree: Sendable, Hashable {
    /// The root node of the token tree
    public let root: ScopeNode
    /// The language used for highlighting
    public let language: String

    public init(root: ScopeNode, language: String) {
        self.root = root
        self.language = language
    }
}

// MARK: - Internal Builder

/// Internal mutable node used during tree construction
private final class MutableScopeNode {
    var scope: String?
    var language: String?
    var children: [MutableTokenNode] = []

    init(scope: String? = nil, language: String? = nil) {
        self.scope = scope
        self.language = language
    }

    /// Converts to immutable ScopeNode
    func freeze() -> ScopeNode {
        ScopeNode(
            scope: scope,
            language: language,
            children: children.map { $0.freeze() }
        )
    }
}

/// Internal mutable token node used during tree construction
private enum MutableTokenNode {
    case text(String)
    case scope(MutableScopeNode)

    func freeze() -> TokenNode {
        switch self {
        case .text(let s):
            return .text(s)
        case .scope(let node):
            return .scope(node.freeze())
        }
    }
}

/// Token tree emitter - builds a tree structure during parsing
internal final class TokenTreeEmitter {
    private var rootNode = MutableScopeNode()
    private var stack: [MutableScopeNode] = []
    private let options: HighlightOptions

    var root: ScopeNode { rootNode.freeze() }

    init(options: HighlightOptions) {
        self.options = options
        stack = [rootNode]
    }

    private var top: MutableScopeNode {
        stack.last ?? rootNode
    }

    /// Adds text to the current node
    func addText(_ text: String) {
        guard !text.isEmpty else { return }
        top.children.append(.text(text))
    }

    /// Opens a new scope
    func openNode(_ scope: String) {
        let node = MutableScopeNode(scope: scope)
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

    /// Closes the current node (discards return value externally)
    func closeNode() {
        guard stack.count > 1 else { return }
        _ = stack.removeLast()
    }

    /// Internal version that returns the node
    @discardableResult
    private func closeNodeInternal() -> MutableScopeNode? {
        guard stack.count > 1 else { return nil }
        return stack.removeLast()
    }

    /// Closes all open nodes
    func closeAllNodes() {
        while stack.count > 1 {
            closeNode()
        }
    }

    /// Adds a sublanguage result
    func addSublanguage(_ emitter: TokenTreeEmitter, name: String?) {
        let node = MutableScopeNode(scope: name.map { "language:\($0)" })
        node.children = emitter.rootNode.children
        top.children.append(.scope(node))
    }

    /// Adds a sublanguage token tree
    func addSublanguage(_ tree: TokenTree, name: String?) {
        let node = MutableScopeNode(scope: name.map { "language:\($0)" })
        node.children = tree.root.children.map { thaw($0) }
        top.children.append(.scope(node))
    }

    /// Finalizes the tree
    func finalize() {
        closeAllNodes()
    }

    private func thaw(_ node: TokenNode) -> MutableTokenNode {
        switch node {
        case .text(let text):
            return .text(text)
        case .scope(let scopeNode):
            let child = MutableScopeNode(scope: scopeNode.scope, language: scopeNode.language)
            child.children = scopeNode.children.map { thaw($0) }
            return .scope(child)
        }
    }

    /// Renders the tree to HTML using the public HTMLRenderer
    func toHTML() -> String {
        let tree = TokenTree(root: rootNode.freeze(), language: "")
        let renderer = HTMLRenderer(theme: HTMLTheme(classPrefix: options.classPrefix))
        return renderer.render(tree)
    }
}
