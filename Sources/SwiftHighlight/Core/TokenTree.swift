import Foundation

/// A node in the token tree representing parsed code structure.
public enum TokenNode: Sendable {
    /// Plain text content
    case text(String)
    /// A scoped node containing children with semantic meaning
    case scope(ScopeNode)
}

/// A scope node containing children with optional scope and language.
/// Scopes represent semantic categories like "keyword", "string", "comment", etc.
public final class ScopeNode: @unchecked Sendable {
    /// The scope name (e.g., "keyword", "string", "comment")
    public internal(set) var scope: String?
    /// The language name for sub-language embedding
    public internal(set) var language: String?
    /// Child nodes
    public internal(set) var children: [TokenNode] = []

    public init(scope: String? = nil, language: String? = nil, children: [TokenNode] = []) {
        self.scope = scope
        self.language = language
        self.children = children
    }
}

/// A wrapper for the token tree root with associated language.
/// Use this for custom rendering of highlighted code.
public struct TokenTree: Sendable {
    /// The root node of the token tree
    public let root: ScopeNode
    /// The language used for highlighting
    public let language: String

    public init(root: ScopeNode, language: String) {
        self.root = root
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

    /// Renders the tree to HTML using the public HTMLRenderer
    func toHTML() -> String {
        let tree = TokenTree(root: rootNode, language: "")
        let renderer = HTMLRenderer(theme: HTMLTheme(classPrefix: options.classPrefix))
        return renderer.render(tree)
    }
}
