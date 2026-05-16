import UniformTypeIdentifiers

enum SupportedAudioTypes {
    static let supportedExtensions = ["wav", "mp3", "m4a", "aiff", "caf"]

    static let all: [UTType] = supportedExtensions.compactMap {
        UTType(filenameExtension: $0)
    }

    static let extensionsDescription = supportedExtensions.joined(separator: ", ")
}
