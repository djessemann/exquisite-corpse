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

// a small underlined word used as a link, at the app's smallest type size (13pt)
struct TextLink: View {
    let title: String
    let lg: Bool
    let action: () -> Void

    var body: some View {
        Text(title)
            .font(mono(lg ? 16 : 13))
            .underline()
            .foregroundStyle(ink)
            // a bigger tap target than the word itself
            .padding(12)
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

// a step on the how to play screen: a small picture, then the number and words beside it
struct HowToStep: View {
    let number: Int
    let text: String
    let image: String
    let tall: Bool
    let lg: Bool

    var body: some View {
        let column: CGFloat = lg ? 170 : 115
        HStack(spacing: lg ? 22 : 16) {
            Image(uiImage: UIImage(named: image) ?? UIImage())
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: tall ? column * 0.48 : column)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(ink, lineWidth: 1.5))
                .frame(width: column)
            // hanging number: wrapped lines line up with the words, not the number
            HStack(alignment: .firstTextBaseline, spacing: lg ? 10 : 8) {
                Text("\(number).")
                    .frame(width: lg ? 24 : 18, alignment: .leading)
                Text(text)
                    .lineSpacing(lg ? 4 : 3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(mono(lg ? 17 : 13))
            .foregroundStyle(ink)
            Spacer(minLength: 0)
        }
        .frame(minHeight: lg ? 118 : 80)
    }
}
