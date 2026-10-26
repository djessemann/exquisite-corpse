import SwiftData
import SwiftUI
import UIKit

// One finished round. Saved automatically on the behold screen.
// With the iCloud capability on, SwiftData syncs these through the user's own iCloud;
// without it they stay on the device. CloudKit needs every property to be optional
// or have a default, so nothing here is required.
@Model
final class Drawing {
    var createdAt: Date = Date()
    // the full drawing as PNG, stored outside the database file
    @Attribute(.externalStorage) var imageData: Data?
    // a small PNG for the gallery grid
    @Attribute(.externalStorage) var thumbnailData: Data?

    init(createdAt: Date = Date(), imageData: Data?, thumbnailData: Data?) {
        self.createdAt = createdAt
        self.imageData = imageData
        self.thumbnailData = thumbnailData
    }

    var image: UIImage? { imageData.flatMap(UIImage.init(data:)) }
    var thumbnail: UIImage? { thumbnailData.flatMap(UIImage.init(data:)) ?? image }

    // e.g. "oct 15, 2026"
    var dateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: createdAt).lowercased()
    }
}

// the same image scaled down, for the gallery grid
func makeThumbnail(_ image: UIImage, width: CGFloat = 240) -> UIImage {
    let scale = width / image.size.width
    let size = CGSize(width: width, height: (image.size.height * scale).rounded())
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
        image.draw(in: CGRect(origin: .zero, size: size))
    }
}

// MARK: - pieces shared by the new screens

// a hand-drawn icon with no frame, sized like the fill icon in a tool button
struct IconButton: View {
    let glyph: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        let px = (size * 0.79).rounded()
        Glyph(name: glyph)
            .frame(width: px, height: px)
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }
}

// Screen header, spaced like the "draw the head" title on the game screen:
// 24pt above the title, 22pt below it, 20pt side margins, 20pt type.
// The back chevron sits on the left margin, on the same line as the title.
struct BackHeader: View {
    let title: String
    let lg: Bool
    let back: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(mono(lg ? 28 : 20))
                .foregroundStyle(ink)
                .lineLimit(1)
                .padding(.horizontal, lg ? 40 : 30)
            HStack {
                Glyph(name: "back")
                    .frame(width: lg ? 17 : 14, height: lg ? 29 : 24)
                    // a bigger tap target without moving anything
                    .contentShape(Rectangle().inset(by: -14))
                    .onTapGesture(perform: back)
                Spacer()
            }
        }
        .padding(.horizontal, screenMargin(lg))
        .padding(.top, lg ? 26 : 24)
        .padding(.bottom, lg ? 26 : 22)
    }
}

// side margin used by the game screen and every screen with a header
func screenMargin(_ lg: Bool) -> CGFloat { lg ? 32 : 20 }

// one drawing in the gallery grid
struct GalleryThumb: View {
    let drawing: Drawing

    var body: some View {
        Color.white
            .aspectRatio(canvasW / (canvasH * 3 - guideH * 2), contentMode: .fit)
            .overlay {
                if let image = drawing.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(ink, lineWidth: 2))
    }
}

// a numbered step on the how to play screen
struct HowToStep: View {
    let number: Int
    let text: String
    let lg: Bool

    var body: some View {
        HStack(alignment: .top, spacing: lg ? 18 : 14) {
            Text("\(number)")
                .font(mono(lg ? 16 : 13))
                .foregroundStyle(ink)
                .frame(width: lg ? 34 : 28, height: lg ? 34 : 28)
                .overlay(Circle().stroke(ink, lineWidth: 2))
            Text(text)
                .font(mono(lg ? 18 : 14))
                .foregroundStyle(ink)
                .lineSpacing(lg ? 5 : 4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, lg ? 5 : 3)
            Spacer(minLength: 0)
        }
    }
}
