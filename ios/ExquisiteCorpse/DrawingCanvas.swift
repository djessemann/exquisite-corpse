import SwiftUI
import UIKit

// the drawing surface, in canvas units (same as the web version)
let canvasW: CGFloat = 600
let canvasH: CGFloat = 420
// strip of the previous player's drawing shown at the top of the next turn
let guideH: CGFloat = 25
// bitmap pixels per canvas unit, so lines stay sharp on Retina screens
let pixelScale = 2

let fillTolerance = 48

enum Tool {
    case pen, eraser, fill
}

struct RGB: Equatable {
    let r: UInt8
    let g: UInt8
    let b: UInt8

    init(hex: UInt32) {
        r = UInt8((hex >> 16) & 0xFF)
        g = UInt8((hex >> 8) & 0xFF)
        b = UInt8(hex & 0xFF)
    }

    var cgColor: CGColor {
        CGColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }

    static let white = RGB(hex: 0xFFFFFF)
}

enum Mark {
    case stroke(points: [CGPoint], color: RGB, size: CGFloat)
    case fill(at: CGPoint, color: RGB)
}

// lets the drawing screen ask the canvas for undo and the finished image
@MainActor
final class CanvasController {
    weak var view: CanvasView?

    func undo() { view?.undo() }
    func snapshot() -> CGImage? { view?.snapshot() }
}

struct DrawingCanvas: UIViewRepresentable {
    let controller: CanvasController
    let guide: CGImage?
    let tool: Tool
    let color: RGB
    let size: CGFloat
    let onTouch: () -> Void

    func makeUIView(context: Context) -> CanvasView {
        let v = CanvasView(guide: guide)
        controller.view = v
        return v
    }

    func updateUIView(_ v: CanvasView, context: Context) {
        v.tool = tool
        v.color = color
        v.size = size
        v.onTouch = onTouch
    }
}

final class CanvasView: UIView {
    var tool: Tool = .pen
    var color = RGB(hex: 0x1A1A1A)
    var size: CGFloat = 8
    var onTouch: () -> Void = {}

    private let guide: CGImage?
    private let bitmap: CGContext
    private let pw = Int(canvasW) * pixelScale
    private let ph = Int(canvasH) * pixelScale
    private var marks: [Mark] = []
    private var activeTouch: UITouch?
    private var currentPoints: [CGPoint] = []

    init(guide: CGImage?) {
        self.guide = guide
        bitmap = CGContext(
            data: nil,
            width: Int(canvasW) * pixelScale,
            height: Int(canvasH) * pixelScale,
            bitsPerComponent: 8,
            bytesPerRow: Int(canvasW) * pixelScale * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        )!
        // draw in canvas units with y pointing down
        bitmap.translateBy(x: 0, y: CGFloat(Int(canvasH) * pixelScale))
        bitmap.scaleBy(x: CGFloat(pixelScale), y: -CGFloat(pixelScale))
        bitmap.setLineCap(.round)
        bitmap.setLineJoin(.round)
        super.init(frame: .zero)
        backgroundColor = .white
        isMultipleTouchEnabled = false
        layer.contentsGravity = .resize
        layer.magnificationFilter = .linear
        layer.minificationFilter = .trilinear
        redrawAll()
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: rendering

    private func present() {
        layer.contents = bitmap.makeImage()
    }

    private func redrawAll() {
        bitmap.setFillColor(RGB.white.cgColor)
        bitmap.fill(CGRect(x: 0, y: 0, width: canvasW, height: canvasH))
        if let guide {
            UIGraphicsPushContext(bitmap)
            UIImage(cgImage: guide).draw(in: CGRect(x: 0, y: 0, width: canvasW, height: guideH))
            UIGraphicsPopContext()
        }
        for mark in marks {
            switch mark {
            case let .stroke(points, color, size):
                drawStroke(points, color: color, size: size)
            case let .fill(at, color):
                _ = fillRegion(at: at, color: color)
            }
        }
        present()
    }

    private func drawStroke(_ points: [CGPoint], color: RGB, size: CGFloat) {
        guard points.count >= 2 else { return }
        bitmap.setStrokeColor(color.cgColor)
        bitmap.setLineWidth(size)
        bitmap.beginPath()
        bitmap.move(to: points[0])
        for p in points.dropFirst() { bitmap.addLine(to: p) }
        bitmap.strokePath()
    }

    // scanline flood fill of everything close in color to the tapped pixel
    private func fillRegion(at point: CGPoint, color: RGB) -> Bool {
        let px = Int((point.x * CGFloat(pixelScale)).rounded())
        let py = Int((point.y * CGFloat(pixelScale)).rounded())
        guard px >= 0, py >= 0, px < pw, py < ph, let raw = bitmap.data else { return false }
        let d = raw.bindMemory(to: UInt8.self, capacity: pw * ph * 4)
        let start = (py * pw + px) * 4
        let tr = Int(d[start]), tg = Int(d[start + 1]), tb = Int(d[start + 2])
        if tr == Int(color.r) && tg == Int(color.g) && tb == Int(color.b) { return false }
        let tol2 = fillTolerance * fillTolerance * 3

        @inline(__always) func match(_ i: Int) -> Bool {
            let o = i * 4
            let dr = Int(d[o]) - tr, dg = Int(d[o + 1]) - tg, db = Int(d[o + 2]) - tb
            return dr * dr + dg * dg + db * db <= tol2
        }

        let seen = UnsafeMutablePointer<Bool>.allocate(capacity: pw * ph)
        seen.initialize(repeating: false, count: pw * ph)
        defer { seen.deallocate() }
        var stack = [py * pw + px]
        while let idx = stack.popLast() {
            let cy = idx / pw
            let cx = idx - cy * pw
            var xL = cx
            while xL >= 0 && match(cy * pw + xL) { xL -= 1 }
            xL += 1
            var xR = cx
            while xR < pw && match(cy * pw + xR) { xR += 1 }
            xR -= 1
            if xL > xR { continue }
            for x in xL...xR {
                let pi = cy * pw + x
                if seen[pi] { continue }
                seen[pi] = true
                let o = pi * 4
                d[o] = color.r; d[o + 1] = color.g; d[o + 2] = color.b; d[o + 3] = 255
                if cy > 0 {
                    let up = pi - pw
                    if !seen[up] && match(up) { stack.append(up) }
                }
                if cy < ph - 1 {
                    let dn = pi + pw
                    if !seen[dn] && match(dn) { stack.append(dn) }
                }
            }
        }
        return true
    }

    // MARK: actions

    func undo() {
        guard !marks.isEmpty else { return }
        marks.removeLast()
        redrawAll()
    }

    func snapshot() -> CGImage? {
        bitmap.makeImage()
    }

    // MARK: touches (one finger at a time; a second touch is ignored)

    private func canvasPoint(_ touch: UITouch) -> CGPoint {
        let p = touch.location(in: self)
        guard bounds.width > 0, bounds.height > 0 else { return .zero }
        return CGPoint(x: p.x * canvasW / bounds.width, y: p.y * canvasH / bounds.height)
    }

    private var strokeColor: RGB { tool == .eraser ? .white : color }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        onTouch()
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch
        let p = canvasPoint(touch)
        if tool == .fill {
            if fillRegion(at: p, color: color) {
                marks.append(.fill(at: p, color: color))
                present()
            }
            return
        }
        currentPoints = [p]
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch), tool != .fill, !currentPoints.isEmpty else { return }
        let samples = event?.coalescedTouches(for: touch) ?? [touch]
        var last = currentPoints[currentPoints.count - 1]
        bitmap.setStrokeColor(strokeColor.cgColor)
        bitmap.setLineWidth(size)
        bitmap.beginPath()
        bitmap.move(to: last)
        for s in samples {
            let p = canvasPoint(s)
            if p == last { continue }
            bitmap.addLine(to: p)
            currentPoints.append(p)
            last = p
        }
        bitmap.strokePath()
        present()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches)
    }

    private func finish(_ touches: Set<UITouch>) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        activeTouch = nil
        if currentPoints.count >= 2 {
            marks.append(.stroke(points: currentPoints, color: strokeColor, size: size))
        }
        currentPoints = []
    }
}
