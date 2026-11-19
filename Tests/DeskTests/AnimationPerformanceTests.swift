import AppKit
import Testing
@testable import Desk

@MainActor
struct AnimationPerformanceTests {
    private func canvas(notes count: Int) throws -> (CanvasView, NSWindow, [NoteRecord]) {
        _ = NSApplication.shared
        let store = NoteStore(inMemory: true)
        let records = (0..<count).map { index in
            NoteRecord(id: UUID(), text: "Note \(index)",
                       frame: CGRect(x: index % 10 * 160, y: index / 10 * 220, width: 140, height: 200), order: index)
        }
        for record in records { try store.insert(record).get() }
        let canvas = CanvasView(store: store)
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 800, height: 600),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = canvas
        canvas.loadNotes()
        canvas.layoutSubtreeIfNeeded()
        return (canvas, window, records)
    }

    @Test func thumbnailBucketsCoverTheNeededPixelsAndStopAtTheSourceSize() {
        let source = CGSize(width: 1600, height: 1200)
        for needed in stride(from: 1.0, through: 1600.0, by: 7.0) {
            let pixels = CanvasItemView.thumbnailPixels(needed: needed, source: source)
            #expect(CGFloat(pixels) >= needed)
            #expect(pixels <= 1600)
            #expect(pixels == 1600 || pixels.nonzeroBitCount == 1)
        }
        #expect(CanvasItemView.thumbnailPixels(needed: 5000, source: source) == 1600)
        #expect(CanvasItemView.thumbnailPixels(needed: 300, source: source)
            == CanvasItemView.thumbnailPixels(needed: 500, source: source))
    }
}
