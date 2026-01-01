import Foundation

/// Protocol for rendering token trees to various output formats.
/// Implement this protocol to create custom renderers for formats not provided by the library.
public protocol TokenRenderer {
    /// The output type produced by this renderer (e.g., String, AttributedString)
    associatedtype Output

    /// The theme type used by this renderer
    associatedtype Theme: HighlightTheme

    /// The theme configuration
    var theme: Theme { get }

    /// Renders a token tree to the output format
    func render(_ tree: TokenTree) -> Output
}

/// A simple theme that returns no styles (useful for renderers that don't need theming).
public struct EmptyTheme: HighlightTheme {
    public init() {}

    public func style(for scope: String) -> ScopeStyle? {
        nil
    }
}
