import XCTest
@testable import maestro

final class LoggerColorTests: XCTestCase {
    private func captureOutput(_ block: () -> Void) -> String {
        let pipe = Pipe()
        let original = dup(STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        block()
        fflush(stdout)
        pipe.fileHandleForWriting.closeFile()
        dup2(original, STDOUT_FILENO)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    func testLinesAreIndividuallyColored() {
        let logger = Logger(pusher: nil)
        let output = captureOutput {
            logger.log("first\nsecond")
        }
        let lines = output.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
        XCTAssertTrue(lines.allSatisfy { $0.hasPrefix("\u{001B}[36m") && $0.hasSuffix("\u{001B}[0m") })
    }
}
