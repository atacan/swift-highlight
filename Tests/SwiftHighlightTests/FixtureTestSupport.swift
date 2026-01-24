import Foundation

/// Mirrors highlight.js fixture tests which trim leading/trailing whitespace.
func normalizeFixtureOutput(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}
