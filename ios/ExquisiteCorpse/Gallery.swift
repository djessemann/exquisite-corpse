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

// a glyph in a hand-drawn circle, the same size and line weight as a color swatch
struct IconCircle: View {
    let glyph: String
    let circle: String
    let size: CGFloat
    let lineWidth: CGFloat
    var scale: CGFloat = 0.6
    let action: () -> Void

    var body: some View {
        let inner = (size - 4) * scale
        ZStack {
            Glyph(name: circle, stretch: true, lineWidth: lineWidth)
                .padding(2)
            Glyph(name: glyph)
                .frame(width: inner, height: inner)
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

// hand-drawn back chevron on the left, title centered in the same row
struct BackHeader: View {
    let title: String
    let lg: Bool
    let back: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(mono(lg ? 26 : 20))
                .foregroundStyle(ink)
                .lineLimit(1)
            HStack {
                Glyph(name: "back")
                    .frame(width: lg ? 19 : 15, height: lg ? 32 : 26)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: back)
                Spacer()
            }
        }
        .frame(height: 44)
        .padding(.horizontal, lg ? 18 : 6)
        .padding(.top, lg ? 12 : 6)
    }
}

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
