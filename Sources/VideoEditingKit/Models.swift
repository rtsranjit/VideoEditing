import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

public struct VideoEditingState: Codable {
    public let videoTag: String
    public let createdTime: Date
    public let videoURL: String
    public let canvasImage: String?
    public let canvasFrame: String
    public let textViewsData: [TextViewState]
    public let videoThumbnail: [String]?
    public let rangeDict: [Int: TextViewStateDuration]?
    public let voiceOverModel: [AudioModel]?
    public let pointsDrawnArray: [[[DrawnPoint]]]
    public let siteAudioURL: String?
    public var adjustedMusicDuration: Double?
    public var videoAudioVolume: Double
    public var voiceOverAudioVolume: Double
    public var siteAudioVolume: Double
    
    public init(videoTag: String, createdTime: Date = Date(), videoURL: String, canvasImage: String? = nil, canvasFrame: String, textViewsData: [TextViewState] = [], videoThumbnail: [String]? = nil, rangeDict: [Int: TextViewStateDuration]? = nil, voiceOverModel: [AudioModel]? = nil, pointsDrawnArray: [[[DrawnPoint]]] = [], siteAudioURL: String? = nil, adjustedMusicDuration: Double? = nil, videoAudioVolume: Double = 1.0, voiceOverAudioVolume: Double = 1.0, siteAudioVolume: Double = 1.0) {
        self.videoTag = videoTag
        self.createdTime = createdTime
        self.videoURL = videoURL
        self.canvasImage = canvasImage
        self.canvasFrame = canvasFrame
        self.textViewsData = textViewsData
        self.videoThumbnail = videoThumbnail
        self.rangeDict = rangeDict
        self.voiceOverModel = voiceOverModel
        self.pointsDrawnArray = pointsDrawnArray
        self.siteAudioURL = siteAudioURL
        self.adjustedMusicDuration = adjustedMusicDuration
        self.videoAudioVolume = videoAudioVolume
        self.voiceOverAudioVolume = voiceOverAudioVolume
        self.siteAudioVolume = siteAudioVolume
    }
}

public struct DrawnPoint: Codable {
    public let x: CGFloat
    public let y: CGFloat
    public let color: String
    
    public init(x: CGFloat, y: CGFloat, color: String) {
        self.x = x
        self.y = y
        self.color = color
    }
    
    public static let example = DrawnPoint(x: 0, y: 0, color: "#ffffff")
}

public struct TextViewState: Codable {
    public let text: String?
    public let attributedText: Data?
    public let frame: String
    public let bounds: String
    public let center: String
    public let transform: String
    #if canImport(UIKit)
    public let textAlignment: NSTextAlignment.RawValue
    #else
    public let textAlignment: Int
    #endif
    public let contentSize: String
    public let tag: Int
    public let backgroundColorString: String
    public let fontURLString: String?
    
    #if canImport(UIKit)
    public init(text: String?, attributedText: Data?, frame: String, bounds: String, center: String, transform: String, textAlignment: NSTextAlignment.RawValue, contentSize: String, tag: Int, backgroundColorString: String, fontURLString: String?) {
        self.text = text
        self.attributedText = attributedText
        self.frame = frame
        self.bounds = bounds
        self.center = center
        self.transform = transform
        self.textAlignment = textAlignment
        self.contentSize = contentSize
        self.tag = tag
        self.backgroundColorString = backgroundColorString
        self.fontURLString = fontURLString
    }
    #else
    public init(text: String?, attributedText: Data?, frame: String, bounds: String, center: String, transform: String, textAlignment: Int, contentSize: String, tag: Int, backgroundColorString: String, fontURLString: String?) {
        self.text = text
        self.attributedText = attributedText
        self.frame = frame
        self.bounds = bounds
        self.center = center
        self.transform = transform
        self.textAlignment = textAlignment
        self.contentSize = contentSize
        self.tag = tag
        self.backgroundColorString = backgroundColorString
        self.fontURLString = fontURLString
    }
    #endif
}

public struct TextViewStateDuration: Codable {
    public let beginTime: Double
    public let duration: Double
    
    public init(beginTime: Double, duration: Double) {
        self.beginTime = beginTime
        self.duration = duration
    }
}

public struct AudioModel: Codable {
    public let startTime: Double
    public var endTime: Double
    public let audioPath: String
    
    public init(startTime: Double, endTime: Double, audioPath: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.audioPath = audioPath
    }
}