import UniformTypeIdentifiers
import XCTest
@testable import JustPlay

final class SupportedAudioTypesTests: XCTestCase {
    func testSupportedExtensionsIncludeRequiredFormats() {
        XCTAssertEqual(Set(SupportedAudioTypes.supportedExtensions), Set(["wav", "mp3", "m4a", "aiff", "caf"]))
    }

    func testAllUTTypesResolveFromRequiredExtensions() {
        let resolvedTypes = SupportedAudioTypes.all
        let resolvedIdentifiers = Set(resolvedTypes.map(\.identifier))
        let expectedIdentifiers = Set(
            SupportedAudioTypes.supportedExtensions.compactMap { extensionName in
                UTType(filenameExtension: extensionName)?.identifier
            }
        )

        XCTAssertEqual(resolvedIdentifiers, expectedIdentifiers)
    }
}
