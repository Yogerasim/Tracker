import UIKit
enum CollectionItem {
    case emoji(String)
    case color(UIColor)
}
enum CollectionData {
    static let emojis: [CollectionItem] = [
        .emoji("😀"), .emoji("😎"), .emoji("🥳"),
        .emoji("🤓"), .emoji("🤖"), .emoji("👾"),
        .emoji("🐶"), .emoji("🐱"), .emoji("🦊"),
        .emoji("🐻"), .emoji("🐼"), .emoji("🐨"),
        .emoji("🍎"), .emoji("🍕"), .emoji("🍔"),
        .emoji("🍩"), .emoji("🍪"), .emoji("🍫"),
    ]
    static let colors: [CollectionItem] = [
        .color(.systemRed), .color(.systemBlue), .color(.systemGreen),
        .color(.systemYellow), .color(.systemOrange), .color(.systemPurple),
        .color(.systemPink), .color(.brown), .color(.cyan), .color(.systemRed), .color(.systemBlue), .color(.systemGreen),
    ]
}
