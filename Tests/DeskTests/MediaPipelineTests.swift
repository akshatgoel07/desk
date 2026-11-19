import Foundation
import Testing
@testable import Desk

private func location(_ tool: String) -> URL? {
    ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"].map { URL(fileURLWithPath: $0).appendingPathComponent(tool) }
        .first { FileManager.default.isExecutableFile(atPath: $0.path) }
}

@MainActor
struct MediaPipelineTests {
    private func makeVideo(in directory: URL, name: String, codec: String) throws -> URL {
        let input = directory.appendingPathComponent(name)
        let process = Process()
        let ffmpeg: URL = try #require(location("ffmpeg"))
        process.executableURL = ffmpeg
        process.arguments = ["-y", "-loglevel", "error", "-f", "lavfi", "-i", "testsrc=d=1:s=32x32",
                             "-c:v", codec, input.path]
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
        return input
    }

    @Test(.enabled(if: location("ffmpeg") != nil))
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

    @Test(.enabled(if: location("ffmpeg") != nil && location("ffprobe") != nil))
    func probeReadsOutputLargerThanThePipeBuffer() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = try makeVideo(in: directory, name: "source.mp4", codec: "mpeg4")
        let many = directory.appendingPathComponent("many.mkv")
        let process = Process()
        let ffmpeg: URL = try #require(location("ffmpeg"))
        process.executableURL = ffmpeg
        process.arguments = ["-y", "-loglevel", "error", "-i", source.path]
            + Array(repeating: ["-map", "0:v"], count: 40).flatMap { $0 } + ["-c", "copy", many.path]
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
        let result = await FFmpegConverter.shared.probe(many)
        #expect(result.tracks == 40)
    }
}
