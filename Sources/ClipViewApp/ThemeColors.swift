import SwiftUI
import AppKit

struct ThemeColors {
    // MARK: - Backgrounds
    // Resolves NSColor values against dark appearance since the popover is forced dark.
    static let backgroundPrimary = Color(NSColor.windowBackgroundColor)
    static let backgroundSecondary = Color(NSColor.controlBackgroundColor)

    // Elevated surface (e.g. settings dialog) - sits above the main app background
    static let backgroundElevated = Color(NSColor.underPageBackgroundColor)

    // Text input background
    static let inputBackground = Color(NSColor.textBackgroundColor)

    // MARK: - Borders
    static let borderLight = Color.secondary.opacity(0.16)
    static let borderMedium = Color.secondary.opacity(0.2)

    // MARK: - Foreground / Text
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textOnAccent = Color.white
    static let accent = Color.accentColor

    // MARK: - Hover and selection states
    static let hoverLight = Color.white.opacity(0.07)
    static let hoverDark = Color.black.opacity(0.07)
    static let hoverGray = Color.gray.opacity(0.18)
    static let hoverAccent = Color.accentColor.opacity(0.2)
    static let selectedLight = Color.accentColor.opacity(0.16)
    static let selectedBorderLight = Color.accentColor.opacity(0.35)

    // MARK: - Overlays
    static let clear = Color.clear
    static let scrimOverlay = Color.black.opacity(0.18)
    static let toastBackground = Color.black.opacity(0.9)
    static let warningBackground = Color.black.opacity(0.85)
    static let shadow = Color.black.opacity(0.25)

    // MARK: - Materials
    // Vibrancy material used for the main popover surface, matching native
    // macOS menu bar extras (Control Center, Wi-Fi, Volume, etc.).
    static let popoverMaterial: NSVisualEffectView.Material = .menu
    // Slightly more prominent material to differentiate the settings dialog.
    static let elevatedMaterial: NSVisualEffectView.Material = .hudWindow
}

/// A SwiftUI wrapper around `NSVisualEffectView` that reproduces the
/// translucent, blurred vibrancy used by native macOS toolbar popovers.
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var isEmphasized: Bool = false

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = isEmphasized
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
        nsView.isEmphasized = isEmphasized
    }
}