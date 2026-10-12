import SwiftUI
import UIKit

let colors: [UInt32] = [0x1A1A1A, 0xEE0028, 0xFF7A00, 0xFFD900, 0x00B053, 0x0057D9, 0x6A1FB0, 0x8B5E34, 0xF0157F, 0xFFFFFF]
let sizes: [CGFloat] = [3, 8, 18]
let penGlyphs = ["penF8", "penF7", "penF3"]
let penScale: [CGFloat] = [0.5, 0.66, 0.84]

enum Screen {
    case landing, transition, drawing, reveal
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
                }
            }
        }
        .preferredColorScheme(.light)
    }

    // line weight for every hand-drawn outline, in points
    private func lineWidth(_ lg: Bool) -> CGFloat { lg ? 3 : 2.5 }

    // MARK: landing

    private func landing(_ lg: Bool) -> some View {
        VStack(spacing: lg ? 44 : 32) {
            Squiggle(index: 0, lineWidth: lineWidth(lg))
                .frame(width: lg ? 300 : 200, height: lg ? 80 : 60)
            Title(lines: ["exquisite", "corpse"], size: lg ? 68 : 48)
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
                if let savedImage {
                    let image = Image(uiImage: savedImage)
                    ShareLink(item: image, preview: SharePreview("Exquisite Corpse", image: image)) {
                        Text("save")
                    }
                    .buttonStyle(style)
                    .simultaneousGesture(TapGesture().onEnded { confirmHome = false })
                }
                Button(confirmHome ? "sure?" : "home") {
                    if !confirmHome {
                        confirmHome = true
                    } else {
                        confirmHome = false
                        screen = .landing
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
            composite = buildComposite()
            savedImage = paddedForSaving()
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

    // the composite with a white margin, for the share sheet
    private func paddedForSaving() -> UIImage? {
        guard let composite else { return nil }
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
}
