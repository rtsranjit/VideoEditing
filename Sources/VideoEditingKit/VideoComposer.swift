import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit

@available(iOS 14.0, *)
public class VideoComposer {
    
    public static let shared = VideoComposer()
    
    private init() {}
    
    public func composeVideo(
        asset: AVAsset,
        canvasImage: UIImage?,
        textViews: [UITextView],
        rangeDict: [Int: TextViewStateDuration],
        voiceOverAudio: [AudioModel],
        siteAudio: (url: URL, adjustedDuration: Double)?,
        videoAudioVolume: Float,
        voiceOverAudioVolume: Float,
        siteAudioVolume: Float,
        outputURL: URL,
        uniqueId: String,
        progressHandler: @escaping (Float) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        
        guard let clipVideoTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(VideoCompositionError.noVideoTrack))
            return
        }
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
        let videoTransform = clipVideoTrack.preferredTransform
        transformer.setTransform(videoTransform, at: .zero)
        transformer.setOpacity(0.0, at: asset.duration)
        
        let isVideoAssetPortrait = videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 ||
            videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0
        let naturalSize = isVideoAssetPortrait ? CGSize(width: clipVideoTrack.naturalSize.height, height: clipVideoTrack.naturalSize.width) : clipVideoTrack.naturalSize
        
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: naturalSize)
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: naturalSize)
        parentLayer.addSublayer(videoLayer)
        
        if let canvasImage = canvasImage {
            let watermarkLayer = CALayer()
            watermarkLayer.contents = canvasImage.cgImage
            watermarkLayer.frame = CGRect(origin: .zero, size: naturalSize)
            parentLayer.addSublayer(watermarkLayer)
        }
        
        for textView in textViews {
            textView.isHidden = false
            let uiView = UIView(frame: textView.superview?.frame ?? CGRect.zero)
            uiView.addSubview(textView)
            let image = uiView.asImage()
            textView.superview?.addSubview(textView)
            
            let textLayer = CALayer()
            textLayer.contents = image.cgImage
            
            if let rangeDictValues = rangeDict[textView.tag] {
                textLayer.beginTime = rangeDictValues.beginTime
                textLayer.duration = rangeDictValues.duration
            }
            
            textLayer.frame = CGRect(origin: .zero, size: naturalSize)
            parentLayer.addSublayer(textLayer)
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = naturalSize
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(asset.duration.seconds))
        videoComposition.renderScale = 1.0
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayers: [videoLayer], in: parentLayer)
        
        let mixComposition = AVMutableComposition()
        guard let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
            completion(.failure(VideoCompositionError.failedToCreateTrack))
            return
        }
        
        let audioMix = AVMutableAudioMix()
        var audioMixParam: [AVMutableAudioMixInputParameters] = []
        
        do {
            try videoCompositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: clipVideoTrack, at: .zero)
            
            if let audioTrack = asset.tracks(withMediaType: .audio).first {
                guard let audioFromVideoCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID()) else {
                    completion(.failure(VideoCompositionError.failedToCreateTrack))
                    return
                }
                try audioFromVideoCompositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)
                
                let videoParam = AVMutableAudioMixInputParameters(track: audioTrack)
                videoParam.trackID = audioFromVideoCompositionTrack.trackID
                videoParam.setVolume(videoAudioVolume, at: .zero)
                audioMixParam.append(videoParam)
            }
        } catch {
            completion(.failure(error))
            return
        }
        
        for audioModel in voiceOverAudio {
            if let url = DraftManager.shared.loadFileFromDocumentDirectory(uniqueId: uniqueId, fileName: audioModel.audioPath) {
                let audioAsset = AVURLAsset(url: url)
                let startTime = CMTime(seconds: audioModel.startTime, preferredTimescale: audioAsset.duration.timescale)
                
                guard let audioModelCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { continue }
                
                if let audioTrack = audioAsset.tracks(withMediaType: .audio).first {
                    let videoDuration = asset.duration
                    let audioDuration = min(audioAsset.duration, videoDuration)
                    do {
                        try audioModelCompositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: audioDuration), of: audioTrack, at: startTime)
                        
                        let audioParam = AVMutableAudioMixInputParameters(track: audioTrack)
                        audioParam.trackID = audioModelCompositionTrack.trackID
                        audioParam.setVolume(voiceOverAudioVolume, at: .zero)
                        audioMixParam.append(audioParam)
                    } catch {
                        print("Error adding voice-over audio: \(error)")
                    }
                }
            }
        }
        
        if let siteAudio = siteAudio {
            let audioAsset = AVURLAsset(url: siteAudio.url)
            let startAudioURLTime = CMTime(seconds: siteAudio.adjustedDuration, preferredTimescale: CMTimeScale(asset.duration.seconds))
            
            guard let audioModelCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
                completion(.failure(VideoCompositionError.failedToCreateTrack))
                return
            }
            
            if let audioTrack = audioAsset.tracks(withMediaType: .audio).first {
                let videoDuration = asset.duration
                let audioDuration = min(audioAsset.duration, videoDuration)
                do {
                    try audioModelCompositionTrack.insertTimeRange(CMTimeRangeMake(start: startAudioURLTime, duration: audioDuration), of: audioTrack, at: .zero)
                    
                    let audioParam = AVMutableAudioMixInputParameters(track: audioTrack)
                    audioParam.trackID = audioModelCompositionTrack.trackID
                    audioParam.setVolume(siteAudioVolume, at: .zero)
                    audioMixParam.append(audioParam)
                } catch {
                    print("Error adding site audio: \(error)")
                }
            }
        }
        
        audioMix.inputParameters = audioMixParam
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
        layerInstruction.setTransform(videoTransform, at: .zero)
        layerInstruction.setOpacity(0.0, at: asset.duration)
        
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(VideoCompositionError.failedToCreateExporter))
            return
        }
        
        exporter.outputFileType = .mov
        exporter.outputURL = outputURL
        exporter.videoComposition = videoComposition
        exporter.audioMix = audioMix
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progressHandler(exporter.progress)
            if exporter.progress >= 1.0 {
                timer.invalidate()
            }
        }
        
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                timer.invalidate()
                
                guard exporter.status == .completed, let outputURL = exporter.outputURL else {
                    if let error = exporter.error {
                        completion(.failure(error))
                    } else {
                        completion(.failure(VideoCompositionError.exportFailed))
                    }
                    return
                }
                
                completion(.success(outputURL))
            }
        }
    }
}
#endif

public enum VideoCompositionError: Error {
    case noVideoTrack
    case failedToCreateTrack
    case failedToCreateExporter
    case exportFailed
    
    public var localizedDescription: String {
        switch self {
        case .noVideoTrack:
            return "No video track found in the asset"
        case .failedToCreateTrack:
            return "Failed to create composition track"
        case .failedToCreateExporter:
            return "Failed to create export session"
        case .exportFailed:
            return "Video export failed"
        }
    }
}