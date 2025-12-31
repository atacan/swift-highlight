import Foundation

/// A pattern that can be used for regex matching.
/// Can be created from a string literal or an NSRegularExpression.
public enum RegexPattern: Sendable {
    case string(String)
    case regex(NSRegularExpression)

    /// Returns the source string representation of the pattern
    public var source: String {
        switch self {
        case .string(let str):
            return str
        case .regex(let regex):
            return regex.pattern
        }
    }

    /// Creates a compiled regex from this pattern
    public func compile(
        caseInsensitive: Bool = false,
        unicode: Bool = false
    ) throws -> NSRegularExpression {
        switch self {
        case .string(let pattern):
            var options: NSRegularExpression.Options = []
            if caseInsensitive {
                options.insert(.caseInsensitive)
            }
            return try NSRegularExpression(pattern: pattern, options: options)
        case .regex(let regex):
            return regex
        }
    }
}

extension RegexPattern: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension RegexPattern: ExpressibleByStringInterpolation {}

extension RegexPattern: CustomStringConvertible {
    public var description: String {
        source
    }
}
