import XCTest
@testable import Strand

final class TestBundleAssemblerTests: XCTestCase {

    func testReScrubsEveryFileIncludingRawCapture() {
        // A serial that never went through the append(log:) sink, e.g. embedded in raw-capture console text.
        let rawWithSerial = "{\"console\":\"connected to WHOOP 4C1594026 ok\"}"
        let entries = [
            FileExport.BundleEntry(name: "report.txt", data: Data("clean line".utf8)),
            FileExport.BundleEntry(name: "raw-capture.jsonl", data: Data(rawWithSerial.utf8)),
        ]
        let scrubbed = TestBundleAssembler.redactEntries(entries)
        let raw = scrubbed.first { $0.name == "raw-capture.jsonl" }!
        let text = String(data: raw.data, encoding: .utf8)!
        XCTAssertFalse(text.contains("4C1594026"), "the injected serial must be scrubbed")
        XCTAssertTrue(text.contains("WHOOP <serial>"))
    }

    func testMetaJsonIsNotMangledButStillPasses() {
        // meta.json has no PII shapes, so it should pass through byte-identical.
        let json = Data("{\"schema\":1,\"redaction\":\"v2\"}".utf8)
        let scrubbed = TestBundleAssembler.redactEntries([FileExport.BundleEntry(name: "meta.json", data: json)])
        XCTAssertEqual(scrubbed.first!.data, json)
    }

    func testStampsRedactionV2() {
        XCTAssertEqual(TestBundleAssembler.redactionVersion, "v2")
    }
}
