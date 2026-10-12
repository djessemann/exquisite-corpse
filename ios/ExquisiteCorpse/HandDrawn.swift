import SwiftUI

let ink = Color(hex: 0x1A1A1A)

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// Space Mono, bundled with the app
func mono(_ size: CGFloat) -> Font {
    .custom("SpaceMono-Regular", size: size)
}

// MARK: - SVG path parsing (only M, L, C and Z are used by the traced glyphs)

enum SVGPath {
    static func parse(_ d: String) -> Path {
        var path = Path()
        var tokens: [String] = []
        var current = ""
        for ch in d {
            if ch.isLetter {
                if !current.isEmpty { tokens.append(current); current = "" }
                tokens.append(String(ch))
            } else if ch == " " || ch == "," {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else if ch == "-" && !current.isEmpty {
                tokens.append(current)
                current = "-"
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { tokens.append(current) }

        var i = 0
        var command = "M"
        func num() -> CGFloat {
            let v = Double(tokens[i]) ?? 0
            i += 1
            return CGFloat(v)
        }
        while i < tokens.count {
            if let first = tokens[i].first, first.isLetter {
                command = tokens[i]
                i += 1
                if command == "Z" || command == "z" {
                    path.closeSubpath()
                    continue
                }
            }
            switch command {
            case "M":
                path.move(to: CGPoint(x: num(), y: num()))
                command = "L"
            case "L":
                path.addLine(to: CGPoint(x: num(), y: num()))
            case "C":
                let c1 = CGPoint(x: num(), y: num())
                let c2 = CGPoint(x: num(), y: num())
                let p = CGPoint(x: num(), y: num())
                path.addCurve(to: p, control1: c1, control2: c2)
            default:
                i += 1
            }
        }
        return path
    }
}

// a path drawn in a fixed viewBox, scaled to whatever frame it is given
struct ViewBoxShape: Shape {
    let path: Path
    let viewBox: CGRect
    var stretch = false

    nonisolated func path(in rect: CGRect) -> Path {
        var sx = rect.width / viewBox.width
        var sy = rect.height / viewBox.height
        if !stretch {
            let s = min(sx, sy)
            sx = s
            sy = s
        }
        let dx = rect.midX - viewBox.midX * sx
        let dy = rect.midY - viewBox.midY * sy
        let t = CGAffineTransform(a: sx, b: 0, c: 0, d: sy, tx: dx, ty: dy)
        return path.applying(t)
    }
}

// parsed once and reused
@MainActor
enum GlyphCache {
    static var paths: [String: Path] = [:]

    static func path(_ name: String) -> Path {
        if let p = paths[name] { return p }
        let p = SVGPath.parse(Glyphs.all[name]?.path ?? "")
        paths[name] = p
        return p
    }
}

// one hand-drawn glyph. Outline glyphs keep their line weight in screen points.
struct Glyph: View {
    let name: String
    var color: Color = ink
    var filled = false
    var stretch = false
    var lineWidth: CGFloat = 2.5

    var body: some View {
        let g = Glyphs.all[name]!
        let shape = ViewBoxShape(
            path: GlyphCache.path(name),
            viewBox: CGRect(x: 0, y: 0, width: g.width, height: g.height),
            stretch: stretch
        )
        if g.filled || filled {
            shape.fill(color)
        } else {
            shape.stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
    }
}

struct Squiggle: View {
    var index = 0
    var lineWidth: CGFloat

    var body: some View {
        ViewBoxShape(
            path: SVGPath.parse(Glyphs.squiggles[index]),
            viewBox: CGRect(x: -4, y: -6, width: 208, height: 72)
        )
        .stroke(ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
}

struct VerticalSquiggle: View {
    var lineWidth: CGFloat

    var body: some View {
        ViewBoxShape(
            path: SVGPath.parse(Glyphs.verticalSquiggle),
            viewBox: CGRect(x: -6, y: -4, width: 72, height: 208)
        )
        .stroke(ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
}

// a color swatch: the color filled into its own uneven circle; the selected one gets a matching outline
struct Swatch: View {
    let color: Color
    let circle: String
    let size: CGFloat
    let lineWidth: CGFloat
    let isWhite: Bool
    let selected: Bool
    let action: () -> Void

    var body: some View {
        ZStack {
            Glyph(name: circle, color: color, filled: true, stretch: true)
                .padding(2)
            if isWhite {
                Glyph(name: circle, color: Color(hex: 0xCCCCCC), stretch: true, lineWidth: lineWidth * 0.6)
                    .padding(2)
            }
            if selected {
                Glyph(name: circle, stretch: true, lineWidth: lineWidth)
                    .padding(-1)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

// a tool: only the selected one gets a hand-drawn box; a flashing one shows the same box briefly
struct ToolBox<Content: View>: View {
    let size: CGFloat
    let lineWidth: CGFloat
    let selected: Bool
    var flash = false
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            if selected || flash {
                Glyph(name: "frameL3", stretch: true, lineWidth: lineWidth)
                    .padding(-4)
            }
            content
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

// square bordered button that inverts while pressed
struct SketchButtonStyle: ButtonStyle {
    var width: CGFloat?
    var height: CGFloat
    var fontSize: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(mono(fontSize))
            .lineLimit(1)
            .padding(.horizontal, 16)
            .frame(width: width, height: height)
            .foregroundStyle(configuration.isPressed ? .white : ink)
            .background(configuration.isPressed ? ink : .white)
            .overlay(Rectangle().stroke(ink, lineWidth: 2))
            .contentShape(Rectangle())
    }
}

// one line per entry, set tighter than the font's own line height
struct Title: View {
    let lines: [String]
    let size: CGFloat

    var body: some View {
        VStack(spacing: -size * 0.38) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(mono(size))
                    .foregroundStyle(ink)
                    .fixedSize()
            }
        }
    }
}
