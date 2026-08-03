import AppKit
import CryptoKit
import SwiftUI

class ClipboardItem: Identifiable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case contentText
        case contentImageData
        case timestamp
        case isPinned
    }

    let id: UUID
    let type: String
    let contentText: String?
    let contentImageData: Data?
    let timestamp: Date
    var isPinned: Bool
    let normalizedText: String?
    private let imageFingerprint: String?
    private var cachedImage: NSImage?

    init(text: String) {
        self.id = UUID()
        self.type = "text"
        self.contentText = text
        self.contentImageData = nil
        self.timestamp = Date()
        self.isPinned = false
        self.normalizedText = text.lowercased()
        self.imageFingerprint = nil
    }

    init(imageData: Data) {
        self.id = UUID()
        self.type = "image"
        self.contentText = nil
        self.contentImageData = imageData
        self.timestamp = Date()
        self.isPinned = false
        self.normalizedText = nil
        self.imageFingerprint = Self.makeImageFingerprint(from: imageData)
    }

    var contentImage: NSImage? {
        guard cachedImage == nil, let data = contentImageData else { return cachedImage }
        cachedImage = NSImage(data: data)
        return cachedImage
    }

    private static func makeImageFingerprint(from data: Data) -> String {
        SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        contentText = try container.decodeIfPresent(String.self, forKey: .contentText)
        contentImageData = try container.decodeIfPresent(Data.self, forKey: .contentImageData)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        normalizedText = contentText?.lowercased()
        imageFingerprint = contentImageData.map(Self.makeImageFingerprint(from:))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(contentText, forKey: .contentText)
        try container.encodeIfPresent(contentImageData, forKey: .contentImageData)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isPinned, forKey: .isPinned)
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        guard lhs.type == rhs.type else { return false }

        if lhs.type == "text" {
            return lhs.contentText == rhs.contentText
        } else if lhs.type == "image" {
            return lhs.imageFingerprint == rhs.imageFingerprint
        }
        return false
    }
}
