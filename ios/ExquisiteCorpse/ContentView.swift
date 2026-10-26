import LinkPresentation
import SwiftData
import SwiftUI
import UIKit

let colors: [UInt32] = [0x1A1A1A, 0xEE0028, 0xFF7A00, 0xFFD900, 0x00B053, 0x0057D9, 0x6A1FB0, 0x8B5E34, 0xF0157F, 0xFFFFFF]
let sizes: [CGFloat] = [3, 8, 18]
let penGlyphs = ["penF8", "penF7", "penF3"]
let penScale: [CGFloat] = [0.5, 0.66, 0.84]

enum Screen {
    case landing, transition, drawing, reveal, gallery, detail, howTo
}

struct ContentView: View {
    @State private var screen = Screen.landing
    @State private var turn = 0
    @State private var game = 0
    @State private var sections: [CGImage?] = [nil, nil, nil]
    @State private var composite: UIImage?
    @State private var savedImage: UIImage?
    @State private var confirmDone = false
    @State private var confirmHome = false
    @State private var undoFlash = 0
    @State private var selectedDrawing: Drawing?
    @State private var confirmDelete = false

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Drawing.createdAt, order: .reverse) private var drawings: [Drawing]

    @State private var tool = Tool.pen
    @State private var colorHex = colors[0]
    @State private var size = sizes[1]
    @State private var canvas = CanvasController()

    var body: some View {
        GeometryReader { geo in
            let lg = geo.size.width >= 768
            ZStack {
                Color.white.ignoresSafeArea()
                switch screen {
                case .landing: landing(lg)
                case .transition: transition(lg)
                case .drawing: drawing(lg, height: geo.size.height)
                case .reveal: reveal(lg, height: geo.size.height)
                case .gallery: gallery(lg)
                case .detail: detail(lg, height: geo.size.height)
                case .howTo: howTo(lg)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    // line weight for every hand-drawn outline, in points
    private func lineWidth(_ lg: Bool) -> CGFloat { lg ? 3 : 2.5 }

    // MARK: landing

    private func landing(_ lg: Bool) -> some View {
        let s: CGFloat = lg ? 58 : 42
        return ZStack {
            landingTitle(lg)
            VStack {
                Spacer()
                HStack {
                    IconButton(glyph: "gallery", size: s) { screen = .gallery }
                    Spacer()
                    IconButton(glyph: "info", size: s) { screen = .howTo }
                }
                .padding(.horizontal, lg ? 32 : 22)
                .padding(.bottom, lg ? 28 : 12)
            }
        }
    }

    private func landingTitle(_ lg: Bool) -> some View {
        VStack(spacing: lg ? 44 : 32) {
            Squiggle(index: 0, lineWidth: lineWidth(lg))
                .frame(width: lg ? 300 : 200, height: lg ? 80 : 60)
            Title(lines: ["exquisite", "sketch"], size: lg ? 68 : 48)
            Squiggle(index: 1, lineWidth: lineWidth(lg))
                .frame(width: lg ? 300 : 200, height: lg ? 80 : 60)
            Button("play", action: startNewGame)
                .buttonStyle(SketchButtonStyle(width: lg ? 260 : 200, height: lg ? 66 : 56, fontSize: lg ? 28 : 22))
        }
    }

    // MARK: pass the device

    private func transition(_ lg: Bool) -> some View {
        let labels = ["the head", "the body", "the legs"]
        return VStack(spacing: lg ? 28 : 20) {
            VerticalSquiggle(lineWidth: lineWidth(lg))
                .frame(width: lg ? 80 : 60, height: lg ? 280 : 200)
            Title(lines: ["pass the device"], size: lg ? 48 : 36)
            Text("next player draws " + labels[turn])
                .font(mono(lg ? 24 : 19))
                .foregroundStyle(Color(hex: 0x888888))
                .multilineTextAlignment(.center)
            Button("ready", action: startTurn)
                .buttonStyle(SketchButtonStyle(width: lg ? 240 : 180, height: lg ? 62 : 52, fontSize: lg ? 24 : 22))
        }
        .padding(.horizontal, lg ? 24 : 16)
    }

    // MARK: drawing

    private func drawing(_ lg: Bool, height: CGFloat) -> some View {
        let labels = ["draw the head", "draw the body", "draw the legs"]
        let s: CGFloat = lg ? 58 : 42
        let gap: CGFloat = lg ? 20 : 16
        let row = s * 5 + gap * 4
        let lw = lineWidth(lg)
        let color = RGB(hex: colorHex)

        return VStack(spacing: 0) {
            Text(labels[turn])
                .font(mono(lg ? 28 : 20))
                .foregroundStyle(ink)
                .padding(.top, lg ? 26 : 24)
                .padding(.bottom, lg ? 26 : 22)

            DrawingCanvas(
                controller: canvas,
                guide: guideImage(),
                tool: tool,
                color: color,
                size: size,
                onTouch: { confirmDone = false }
            )
            .id("\(game)-\(turn)")
            .aspectRatio(canvasW / canvasH, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(ink, lineWidth: 2))
            .frame(maxWidth: lg ? 680 : 440, maxHeight: height * (lg ? 0.5 : 0.4))
            .padding(.horizontal, lg ? 32 : 20)

            VStack(spacing: lg ? 26 : 22) {
                // colors, two rows of five
                VStack(spacing: gap) {
                    ForEach(0..<2, id: \.self) { r in
                        HStack(spacing: gap) {
                            ForEach(r * 5..<r * 5 + 5, id: \.self) { i in
                                swatch(i, size: s, lineWidth: lw)
                            }
                        }
                    }
                }

                // pens, fill, undo
                HStack(spacing: gap) {
                    ForEach(0..<sizes.count, id: \.self) { i in
                        ToolBox(size: s, lineWidth: lw, selected: size == sizes[i] && tool != .fill, action: {
                            confirmDone = false
                            size = sizes[i]
                            if tool == .fill { tool = colorHex == 0xFFFFFF ? .eraser : .pen }
                        }) {
                            let px = (s * penScale[i]).rounded()
                            Glyph(name: penGlyphs[i]).frame(width: px, height: px)
                        }
                    }
                    ToolBox(size: s, lineWidth: lw, selected: tool == .fill, action: {
                        confirmDone = false
                        tool = tool == .fill ? (colorHex == 0xFFFFFF ? .eraser : .pen) : .fill
                    }) {
                        let px = (s * 0.79).rounded()
                        Glyph(name: "fill2").frame(width: px, height: px)
                    }
                    ToolBox(size: s, lineWidth: lw, selected: false, flash: undoFlash > 0, action: undo) {
                        let px = (s * 0.74).rounded()
                        Glyph(name: "undo19").frame(width: px, height: px)
                    }
                }

                Button(confirmDone ? "sure?" : "done", action: handleDone)
                    .buttonStyle(SketchButtonStyle(width: row, height: lg ? 60 : 50, fontSize: lg ? 22 : 18))
            }
            .padding(.horizontal, lg ? 24 : 16)
            .padding(.top, lg ? 24 : 20)
            .padding(.bottom, lg ? 28 : 24)
            .frame(maxHeight: .infinity)
        }
    }

    private func swatch(_ i: Int, size s: CGFloat, lineWidth lw: CGFloat) -> some View {
        let c = colors[i]
        let isWhite = c == 0xFFFFFF
        let selected = isWhite
            ? (tool == .eraser || (tool == .fill && colorHex == c))
            : (tool != .eraser && colorHex == c)
        return Swatch(
            color: Color(hex: c), circle: "circ\(i + 1)", size: s, lineWidth: lw,
            isWhite: isWhite, selected: selected
        ) {
            confirmDone = false
            if isWhite && tool != .fill {
                tool = .eraser
                return
            }
            colorHex = c
            if tool == .eraser { tool = .pen }
        }
    }

    // MARK: reveal

    private func reveal(_ lg: Bool, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            Title(lines: ["behold!"], size: lg ? 46 : 34)

            if let composite {
                Image(uiImage: composite)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(ink, lineWidth: 2))
                    .frame(maxWidth: lg ? 440 : 300, maxHeight: max(100, height - (lg ? 235 : 195)))
                    .padding(.top, lg ? 26 : 22)
            }

            HStack(spacing: lg ? 14 : 10) {
                let style = SketchButtonStyle(width: nil, height: lg ? 52 : 42, fontSize: lg ? 18 : 14)
                if savedImage != nil {
                    Button("save") {
                        confirmHome = false
                        share()
                    }
                    .buttonStyle(style)
                }
                Button {
                    if !confirmHome {
                        confirmHome = true
                    } else {
                        confirmHome = false
                        screen = .landing
                    }
                } label: {
                    // always as wide as "sure?" so the button doesn't change size
                    ZStack {
                        Text("sure?").hidden()
                        Text(confirmHome ? "sure?" : "home")
                    }
                }
                .buttonStyle(style)
            }
            .padding(.top, lg ? 30 : 24)

            Spacer(minLength: 16)
        }
        .padding(.top, lg ? 30 : 28)
        .padding(.horizontal, lg ? 24 : 16)
    }

    // MARK: gallery

    private func gallery(_ lg: Bool) -> some View {
        VStack(spacing: 0) {
            BackHeader(title: "gallery", lg: lg) { screen = .landing }
            if drawings.isEmpty {
                Spacer()
                VStack(spacing: lg ? 34 : 26) {
                    Text("nothing here yet.")
                        .font(mono(lg ? 20 : 16))
                        .foregroundStyle(Color(hex: 0x888888))
                    Button("play", action: startNewGame)
                        .buttonStyle(SketchButtonStyle(width: lg ? 260 : 200, height: lg ? 66 : 56, fontSize: lg ? 28 : 22))
                }
                Spacer()
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: lg ? 18 : 12), count: lg ? 4 : 3),
                        spacing: lg ? 18 : 12
                    ) {
                        ForEach(drawings) { drawing in
                            GalleryThumb(drawing: drawing)
                                .onTapGesture {
                                    selectedDrawing = drawing
                                    confirmDelete = false
                                    screen = .detail
                                }
                        }
                    }
                    .padding(.horizontal, screenMargin(lg))
                    .padding(.bottom, 24)
                }
            }
        }
    }

    // one drawing from the gallery: date, the drawing, save and delete
    @ViewBuilder
    private func detail(_ lg: Bool, height: CGFloat) -> some View {
        if let drawing = selectedDrawing {
            VStack(spacing: 0) {
                BackHeader(title: drawing.dateLabel, lg: lg) {
                    confirmDelete = false
                    screen = .gallery
                }
                if let image = drawing.image {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(ink, lineWidth: 2))
                        .frame(maxWidth: lg ? 440 : 300, maxHeight: max(100, height - (lg ? 250 : 210)))
                        .padding(.horizontal, screenMargin(lg))
                }
                HStack(spacing: lg ? 14 : 10) {
                    let style = SketchButtonStyle(width: nil, height: lg ? 52 : 42, fontSize: lg ? 18 : 14)
                    Button("save") {
                        confirmDelete = false
                        if let image = drawing.image, let framed = padded(image) {
                            share(framed, date: drawing.createdAt)
                        }
                    }
                    .buttonStyle(style)
                    Button {
                        if !confirmDelete {
                            confirmDelete = true
                        } else {
                            confirmDelete = false
                            selectedDrawing = nil
                            modelContext.delete(drawing)
                            try? modelContext.save()
                            screen = .gallery
                        }
                    } label: {
                        // always as wide as "delete" so the button doesn't change size
                        ZStack {
                            Text("delete").hidden()
                            Text(confirmDelete ? "sure?" : "delete")
                        }
                    }
                    .buttonStyle(style)
                }
                .padding(.top, lg ? 30 : 24)
                Spacer(minLength: 16)
            }
        } else {
            gallery(lg)
        }
    }

    // MARK: how to play

    private func howTo(_ lg: Bool) -> some View {
        let steps = [
            "3 players, one device.",
            "first player draws a head. don’t let anyone see. draw to the bottom edge.",
            "when done, pass the device. next player draws the body. they can see the bottom edge to connect.",
            "repeat for the last player who draws the legs.",
            "behold your exquisite creature! drawings save to a gallery.",
        ]
        let content = VStack(spacing: lg ? 40 : 34) {
            ForEach(steps.indices, id: \.self) { i in
                HowToStep(number: i + 1, text: steps[i], lg: lg)
            }
            Button("play", action: startNewGame)
                .buttonStyle(SketchButtonStyle(width: lg ? 260 : 200, height: lg ? 66 : 56, fontSize: lg ? 28 : 22))
                .padding(.top, lg ? 30 : 26)
        }
        .frame(maxWidth: lg ? 560 : CGFloat.infinity)
        .padding(.horizontal, screenMargin(lg))
        .padding(.bottom, 24)

        return VStack(spacing: 0) {
            BackHeader(title: "how to play", lg: lg) { screen = .landing }
            // stays put when it fits; only scrolls on small screens or with large text
            ViewThatFits(in: .vertical) {
                content
                ScrollView { content }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: game flow

    private func startNewGame() {
        turn = 0
        game += 1
        sections = [nil, nil, nil]
        composite = nil
        savedImage = nil
        startTurn()
    }

    private func startTurn() {
        tool = .pen
        colorHex = colors[0]
        size = sizes[1]
        confirmDone = false
        screen = .drawing
    }

    private func undo() {
        confirmDone = false
        canvas.undo()
        undoFlash += 1
        Task {
            try? await Task.sleep(for: .milliseconds(160))
            undoFlash -= 1
        }
    }

    private func handleDone() {
        if !confirmDone {
            confirmDone = true
            return
        }
        confirmDone = false
        sections[turn] = canvas.snapshot()
        if turn < 2 {
            turn += 1
            screen = .transition
        } else {
            let finished = buildComposite()
            composite = finished
            savedImage = padded(finished)
            saveToGallery(finished)
            confirmHome = false
            screen = .reveal
        }
    }

    // bottom strip of the previous player's drawing
    private func guideImage() -> CGImage? {
        guard turn > 0, let prev = sections[turn - 1] else { return nil }
        let px = CGFloat(pixelScale)
        return prev.cropping(to: CGRect(x: 0, y: (canvasH - guideH) * px, width: canvasW * px, height: guideH * px))
    }

    // the three sections stacked, each overlapping the one above by the guide strip
    private func buildComposite() -> UIImage {
        let px = CGFloat(pixelScale)
        let size = CGSize(width: canvasW * px, height: (canvasH * 3 - guideH * 2) * px)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            for (i, section) in sections.enumerated() {
                guard let section else { continue }
                let y = CGFloat(i) * (canvasH - guideH) * px
                UIImage(cgImage: section).draw(in: CGRect(x: 0, y: y, width: canvasW * px, height: canvasH * px))
            }
        }
    }

    // write the drawing to a PNG file and open the share sheet with it,
    // so "Save Image" puts the PNG in Photos and other apps get a real .png
    private func share() {
        if let savedImage { share(savedImage, date: Date()) }
    }

    private func share(_ image: UIImage, date: Date) {
        guard let data = image.pngData() else { return }
        // e.g. sketch-april-3-2026-0434pm.png
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM-d-yyyy-hhmma"
        let name = "sketch-" + formatter.string(from: date).lowercased() + ".png"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return
        }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let window = scene.keyWindow ?? scene.windows.first,
              var top = window.rootViewController else { return }
        while let presented = top.presentedViewController { top = presented }

        let item = DrawingShareItem(url: url, image: image)
        let sheet = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        // on iPad the share sheet is a popover and needs something to point at
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.maxY - 80, width: 0, height: 0)
            popover.permittedArrowDirections = .down
        }
        top.present(sheet, animated: true)
    }

    // every finished round goes into the gallery
    private func saveToGallery(_ image: UIImage) {
        let drawing = Drawing(
            imageData: image.pngData(),
            thumbnailData: makeThumbnail(image).pngData()
        )
        modelContext.insert(drawing)
        try? modelContext.save()
    }

    // the drawing with a white margin, for the share sheet
    private func padded(_ composite: UIImage) -> UIImage? {
        let pad = 50 * CGFloat(pixelScale)
        let size = CGSize(width: composite.size.width + pad * 2, height: composite.size.height + pad * 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            composite.draw(at: CGPoint(x: pad, y: pad))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Drawing.self, inMemory: true)
}

// the PNG handed to the share sheet, titled with the app name:
// it heads the share sheet and becomes the subject line in Mail
nonisolated final class DrawingShareItem: NSObject, UIActivityItemSource {
    let url: URL
    let image: UIImage

    init(url: URL, image: UIImage) {
        self.url = url
        self.image = image
    }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any {
        url
    }

    func activityViewController(_ controller: UIActivityViewController, itemForActivityType type: UIActivity.ActivityType?) -> Any? {
        url
    }

    func activityViewController(_ controller: UIActivityViewController, subjectForActivityType type: UIActivity.ActivityType?) -> String {
        "Exquisite Sketch"
    }

    func activityViewControllerLinkMetadata(_ controller: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Exquisite Sketch"
        metadata.iconProvider = NSItemProvider(object: image)
        return metadata
    }
}
