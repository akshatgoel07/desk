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

    @Test func groupDragMovesEveryCardWithoutRelayout() throws {
        let (canvas, window, records) = try canvas(notes: 40)
        defer { window.contentView = nil }
        canvas.select(Set(records.map(\.id)))
        let moved = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0.frame.offsetBy(dx: 37, dy: -11)) })
        canvas.previewFrames(moved)
        for view in canvas.itemViews {
            #expect(view.frame == moved[view.id])
            #expect(!view.needsLayout)
        }
        #expect(canvas.notes.allSatisfy { $0.frame == moved[$0.id] })
        let union = moved.values.reduce(CGRect.null) { $0.union($1) }
        let outline = try #require(canvas.overlayLayer.path).boundingBoxOfPath
        let expected = canvas.viewRect(fromCanvas: union).insetBy(dx: -1, dy: -1)
        #expect(abs(outline.minX - expected.minX) < 0.001)
        #expect(abs(outline.maxY - expected.maxY) < 0.001)
    }

    @Test func externalFrameChangesStillReachTheModelAndResizeRelayouts() throws {
        let (canvas, window, records) = try canvas(notes: 3)
        defer { window.contentView = nil }
        let view = try #require(canvas.itemViews.first { $0.id == records[1].id })
        view.frame = view.frame.offsetBy(dx: 12, dy: 8)
        #expect(canvas.notes.first { $0.id == records[1].id }?.frame == view.frame)
        #expect(!view.needsLayout)
        view.frame.size = CGSize(width: 180, height: 220)
        #expect(view.needsLayout)
        #expect(canvas.notes.first { $0.id == records[1].id }?.frame.size == CGSize(width: 180, height: 220))
    }

    @Test func outlineFollowsPanAndZoom() throws {
        let (canvas, window, records) = try canvas(notes: 12)
        defer { window.contentView = nil }
        canvas.select([records[5].id])
        canvas.setViewport(Viewport(scale: 2, translation: CGPoint(x: -40, y: 25)))
        let outline = try #require(canvas.overlayLayer.path).boundingBoxOfPath
        let expected = canvas.viewRect(fromCanvas: records[5].frame).insetBy(dx: -1, dy: -1)
        #expect(abs(outline.minX - expected.minX) < 0.001)
        #expect(abs(outline.width - expected.width) < 0.001)
        #expect(canvas.accessibilityValue() as? String == "Note 5")
    }
}
