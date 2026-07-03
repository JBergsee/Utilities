


import SwiftUI
import UIKit

// There's no systemGroupedBackground color in SwiftUI, but the UIKit color can be used.
// This is a shortcut to improve semantics in calling code.
public extension Color {
    static let systemGroupedBackground = Color(.systemGroupedBackground)
}
