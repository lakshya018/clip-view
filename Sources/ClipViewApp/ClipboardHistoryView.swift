import AppKit
import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var manager: ClipboardManager
    @ObservedObject private var preferences = AppPreferences.shared
    var onClear: () -> Void
    @State private var copiedID: UUID?
    @State private var searchText = ""
    @State private var selectedFilter: ClipboardFilter = .all
    @State private var showingSettings = false
    @State private var selectedItemID: UUID?
    @State private var pinLimitWarning: String?

    private var filteredItems: [ClipboardItem] {
        manager.filteredItems(searchText: searchText, filter: selectedFilter)
    }

    private var emptyMessage: String {
        if !searchText.isEmpty || selectedFilter != .all {
            return "No matching clips"
        }
        return "Your clipboard history will appear here"
    }

    var body: some View {
        ZStack {
            // Main content - dims when settings is open
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    HStack(alignment: .top, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ThemeColors.accent)

                            VStack(alignment: .leading, spacing: 1) {
                                Text("ClipView")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Clipboard manager")
                                    .font(.system(size: 10))
                                    .foregroundColor(ThemeColors.textSecondary)
                            }
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: onClear) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .regular))
                            }
                            .buttonStyle(.plain)
                            .controlSize(.small)
                            .hoverEffect(style: .gray)
                            .help("Clear history")

                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 13, weight: .regular))
                            }
                            .buttonStyle(.plain)
                            .controlSize(.small)
                            .hoverEffect(style: .gray)
                            .help("Settings")
                        }
                        .padding(.top, 2)
                    }

                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12))
                                .foregroundColor(ThemeColors.textSecondary)
                                .help("Search clips")

                            TextField("Search", text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))

                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(ThemeColors.textSecondary)
                                }
                                .buttonStyle(.plain)
                                .help("Clear search")
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(ThemeColors.inputBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(ThemeColors.borderMedium, lineWidth: 1.2)
                                )
                        )

                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(ClipboardFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .fixedSize()
                    }
                }
                .padding(12)
                .padding(.horizontal, 10)
                .padding(.top, 10)

                if filteredItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 24))
                            .foregroundColor(ThemeColors.textSecondary)
                        Text(emptyMessage)
                            .font(.system(size: 13))
                            .foregroundColor(ThemeColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(filteredItems) { item in
                                ClipboardRowView(
                                    item: item,
                                    copiedID: $copiedID,
                                    isSelected: item.id == selectedItemID,
                                    onDelete: {
                                        manager.removeItem(item)
                                    },
                                    onPin: {
                                        let pinned = manager.togglePin(for: item)
                                        if !pinned {
                                            pinLimitWarning = "You can pin up to 5 items"
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                pinLimitWarning = nil
                                            }
                                        }
                                    },
                                    onCopy: {
                                        copyItem(item)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 6)
                        .padding(.bottom, 10)
                    }
                }
            }
            .opacity(showingSettings ? 0.35 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: showingSettings)

            // Toasts - always full opacity, unaffected by settings dim
            VStack {
                Spacer()
                if copiedID != nil {
                    Text("Copied!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ThemeColors.textOnAccent)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(ThemeColors.toastBackground)
                        .cornerRadius(12)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: copiedID)
                }
                if let warning = pinLimitWarning {
                    Text(warning)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ThemeColors.textOnAccent)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(ThemeColors.warningBackground)
                        .cornerRadius(10)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: pinLimitWarning)
                }
            }
            .padding(.bottom, 32)

            // Settings dialog - always full opacity on top
            if showingSettings {
                ThemeColors.scrimOverlay
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingSettings = false
                    }

                SettingsView(preferences: preferences) {
                    showingSettings = false
                }
                .frame(maxWidth: 260)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .frame(width: 338, height: 520)
        .focusable()
        .focusEffectDisabled()
        .background(ThemeColors.backgroundSecondary)
        .onAppear {
            if let selectedItemID, !filteredItems.contains(where: { $0.id == selectedItemID }) {
                self.selectedItemID = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            if let selectedItemID, !filteredItems.contains(where: { $0.id == selectedItemID }) {
                self.selectedItemID = nil
            }
        }
    }

    private var selectedItem: ClipboardItem? {
        filteredItems.first(where: { $0.id == selectedItemID }) ?? filteredItems.first
    }

    private func copyItem(_ item: ClipboardItem) {
        if let text = item.contentText {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        } else if let image = item.contentImage {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([image])
        }
        selectedItemID = item.id
        copiedID = item.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            copiedID = nil
        }
    }

    private func moveSelection(by offset: Int) {
        guard !filteredItems.isEmpty else { return }
        let currentIndex = filteredItems.firstIndex(where: { $0.id == selectedItemID }) ?? 0
        let nextIndex = max(0, min(filteredItems.count - 1, currentIndex + offset))
        selectedItemID = filteredItems[nextIndex].id
    }
}

struct ClipboardRowView: View {
    @Environment(\.colorScheme) var colorScheme
    let item: ClipboardItem
    @Binding var copiedID: UUID?
    var isSelected: Bool = false
    var onDelete: (() -> Void)? = nil
    var onPin: (() -> Void)? = nil
    var onCopy: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            onCopy?()
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 6) {
                    Spacer()

                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                            .foregroundColor(ThemeColors.accent)
                    }
                }

                if let image = item.contentImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 128)
                        .cornerRadius(8)
                } else if let text = item.contentText {
                    Text(text)
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                        .truncationMode(.tail)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? ThemeColors.selectedLight : (colorScheme == .dark ? ThemeColors.hoverLight : ThemeColors.hoverDark))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? ThemeColors.selectedBorderLight : ThemeColors.borderLight, lineWidth: 1)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .hoverEffect(style: .accent)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            if let onPin = onPin {
                Button(action: onPin) {
                    Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
                }
            }
        }
    }
}

extension View {
    func hoverEffect(style: HoverHighlight.Style) -> some View {
        modifier(HoverHighlight(style: style))
    }
}

struct SettingsView: View {
    @ObservedObject var preferences: AppPreferences
    var onClose: () -> Void

    let historyOptions = [20, 40, 60, 80, 100]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings")
                .font(.system(size: 17, weight: .semibold))
                .padding(.bottom, 4)

            Text("Customize your clipboard history preferences.")
                .font(.system(size: 12))
                .foregroundColor(ThemeColors.textSecondary)
                .padding(.bottom, 24)

            Text("History Size")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ThemeColors.textSecondary)
                .padding(.bottom, 8)

            Picker("Items", selection: $preferences.historyLimit) {
                ForEach(historyOptions, id: \.self) { value in
                    Text("\(value) items").tag(value)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .fixedSize()

            Spacer()

            HStack {
                Spacer()
                Button("Done", action: onClose)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 280, height: 210)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ThemeColors.backgroundElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ThemeColors.borderMedium, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: ThemeColors.shadow, radius: 24, x: 0, y: 10)
    }
}

struct HoverHighlight: ViewModifier {
    enum Style { case accent, gray }
    @State private var isHovered = false
    var style: Style

    func body(content: Content) -> some View {
        content
            .background(isHovered ? (style == .gray ? ThemeColors.hoverGray : ThemeColors.hoverAccent) : ThemeColors.clear)
            .cornerRadius(8)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}