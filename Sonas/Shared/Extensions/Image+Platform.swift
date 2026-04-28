#if os(macOS)
    import AppKit

    public typealias PlatformImage = NSImage
#else
    import UIKit

    public typealias PlatformImage = UIImage
#endif

public extension PlatformImage {
    #if os(macOS)
        func pngData() -> Data? {
            guard let tiffRepresentation,
                  let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
            return bitmapImage.representation(using: .png, properties: [:])
        }
    #endif
}
