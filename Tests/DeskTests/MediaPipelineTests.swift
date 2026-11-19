import Foundation
import Testing
@testable import Desk

@MainActor
struct MediaPipelineTests {
    private func makeVideo(in directory: URL, name: String, codec: String) throws -> URL {
        let input = directory.appendingPathComponent(name)
        let process = Process()
        process.executableURL = try #require(FFmpegConverter.ffmpegURL)
        process.arguments = ["-y", "-loglevel", "error", "-f", "lavfi", "-i", "testsrc=d=1:s=32x32",
                             "-c:v", codec, input.path]
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
        return input
    }

    @Test(.enabled(if: FFmpegConverter.ffmpegURL != nil))
    func failedRemuxReturnsNilAndLeavesNoOutput() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let raw = try makeVideo(in: directory, name: "raw.avi", codec: "rawvideo")
        #expect(await FFmpegConverter.shared.remuxIfNeeded(raw) == nil)
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.hasPrefix("study-") }
        #expect(leftovers.isEmpty)
        let valid = try makeVideo(in: directory, name: "valid.mp4", codec: "mpeg4")
        let output = try #require(await FFmpegConverter.shared.remuxIfNeeded(valid))
        #expect(try Data(contentsOf: output).count > 0)
    }
}
