import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 14.0, *)
public class VideoEditingKit {
    public static let shared = VideoEditingKit()
    
    private init() {}
    
    #if canImport(UIKit)
    public func createVideoEditor(with videoURL: URL, uniqueId: String? = nil) -> VideoEditingController {
        let editor = VideoEditingController(videoURL: videoURL, uniqueId: uniqueId ?? UUID().uuidString)
        return editor
    }
    #endif
    
    public func getDrafts() -> [VideoEditingState]? {
        return DraftManager.shared.getDraftsArray()
    }
    
    public func checkDraftLimit() -> Bool {
        return DraftManager.shared.checkLimitOfDrafts()
    }
}

#if canImport(UIKit)
public extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

public extension UIButton {
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            let colorImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.setBackgroundImage(colorImage, for: forState)
        }
    }
}
#endif

public extension FileManager {
    func removeItemIfExisted(_ url: URL) {
        if fileExists(atPath: url.path) {
            try? removeItem(at: url)
        }
    }
}

public extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}