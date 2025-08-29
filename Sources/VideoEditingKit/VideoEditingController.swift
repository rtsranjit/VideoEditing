import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit

@available(iOS 14.0, *)
public class VideoEditingController: UIViewController {
    
    public var videoAsset: AVAsset!
    public var player: AVPlayer!
    public var playerLayer: AVPlayerLayer!
    
    public var canvasImageView: UIImageView!
    public var uniqueId: String
    public var videoFilePath: URL?
    
    public var audioRecorder: AudioRecorder!
    public var rangeDict: [Int: TextViewStateDuration] = [:]
    public var pointsDrawnArray: [[[DrawnPoint]]] = []
    
    public var playerVolume: Float = 1.0
    public var voiceOverAudioVolume: Float = 1.0
    public var audioPlayer: AVAudioPlayer?
    public var adjustedMusicDuration: Double?
    public var siteAudioURL: URL?
    
    public var isDraftVideo = false
    
    private var timeObserver: Any?
    
    public init(videoURL: URL, uniqueId: String) {
        self.uniqueId = uniqueId
        super.init(nibName: nil, bundle: nil)
        
        self.videoAsset = AVAsset(url: videoURL)
        self.player = AVPlayer(url: videoURL)
        self.audioRecorder = AudioRecorder()
        
        setupVideoFilePath()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVideoFilePath() {
        let fileName = "EditedVideo_\(uniqueId).mov"
        videoFilePath = DraftManager.shared.getFilePath(uniqueId: uniqueId, fileName: fileName)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupVideoPlayer()
        setupGestures()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)
        
        canvasImageView = UIImageView()
        canvasImageView.backgroundColor = .clear
        canvasImageView.isUserInteractionEnabled = true
        view.addSubview(canvasImageView)
    }
    
    private func setupVideoPlayer() {
        player.volume = playerVolume
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] time in
            self?.handleTimeUpdate(time)
        }
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCanvasTap(_:)))
        canvasImageView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCanvasPan(_:)))
        canvasImageView.addGestureRecognizer(panGesture)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = view.bounds
        canvasImageView.frame = view.bounds
    }
    
    private func handleTimeUpdate(_ time: CMTime) {
        let currentTime = CMTimeGetSeconds(time)
        
        for audioModel in audioRecorder.audioArray {
            let timeInSeconds = currentTime
            if audioModel.endTime != 0,
               (timeInSeconds >= audioModel.startTime && timeInSeconds <= audioModel.endTime),
               audioRecorder.audioPlayer == nil {
                
                audioRecorder.playAudio(fileName: audioModel.audioPath, uniqueId: uniqueId, volume: voiceOverAudioVolume)
            }
        }
    }
    
    @objc private func handleCanvasTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: canvasImageView)
        addTextView(at: location)
    }
    
    @objc private func handleCanvasPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: canvasImageView)
        
        switch gesture.state {
        case .began:
            startDrawing(at: location)
        case .changed:
            continueDrawing(to: location)
        case .ended, .cancelled:
            endDrawing()
        default:
            break
        }
    }
    
    private func addTextView(at point: CGPoint) {
        let textView = UITextView()
        textView.frame = CGRect(x: point.x - 50, y: point.y - 25, width: 100, height: 50)
        textView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        textView.layer.cornerRadius = 5
        textView.text = "Add text"
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textAlignment = .center
        textView.tag = canvasImageView.subviews.count
        textView.isEditable = true
        textView.isScrollEnabled = false
        
        canvasImageView.addSubview(textView)
        textView.becomeFirstResponder()
    }
    
    private func startDrawing(at point: CGPoint) {
        
    }
    
    private func continueDrawing(to point: CGPoint) {
        
    }
    
    private func endDrawing() {
        
    }
    
    public func playMedia(muteSiteAudio: Bool = false) {
        player.play()
        
        if !muteSiteAudio {
            audioPlayer?.play()
        }
    }
    
    public func pauseMedia() {
        player.pause()
        audioPlayer?.pause()
        audioRecorder.stopAudio()
    }
    
    public func exportVideo(progressHandler: @escaping (Float) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let outputURL = videoFilePath else {
            completion(.failure(VideoEditingError.noOutputURL))
            return
        }
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        let textViews = canvasImageView.subviews.compactMap { $0 as? UITextView }
        let siteAudio: (url: URL, adjustedDuration: Double)? = {
            if let url = siteAudioURL, let duration = adjustedMusicDuration {
                return (url, duration)
            }
            return nil
        }()
        
        VideoComposer.shared.composeVideo(
            asset: videoAsset,
            canvasImage: canvasImageView.image,
            textViews: textViews,
            rangeDict: rangeDict,
            voiceOverAudio: audioRecorder.audioArray,
            siteAudio: siteAudio,
            videoAudioVolume: playerVolume,
            voiceOverAudioVolume: voiceOverAudioVolume,
            siteAudioVolume: audioPlayer?.volume ?? 1.0,
            outputURL: outputURL,
            uniqueId: uniqueId,
            progressHandler: progressHandler,
            completion: completion
        )
    }
    
    public func saveDraft() -> Bool {
        let canvasFrame = NSCoder.string(for: canvasImageView.frame)
        let textViewsData = canvasImageView.subviews.compactMap { subview -> TextViewState? in
            guard let textView = subview as? UITextView else { return nil }
            
            return TextViewState(
                text: textView.text,
                attributedText: try? NSKeyedArchiver.archivedData(withRootObject: textView.attributedText, requiringSecureCoding: false),
                frame: NSCoder.string(for: textView.frame),
                bounds: NSCoder.string(for: textView.bounds),
                center: NSCoder.string(for: textView.center),
                transform: NSCoder.string(for: textView.transform),
                textAlignment: textView.textAlignment.rawValue,
                contentSize: NSCoder.string(for: textView.contentSize),
                tag: textView.tag,
                backgroundColorString: textView.backgroundColor?.hexString ?? "#FFFFFF",
                fontURLString: nil
            )
        }
        
        let draft = VideoEditingState(
            videoTag: uniqueId,
            videoURL: (videoAsset as? AVURLAsset)?.url.lastPathComponent ?? "",
            canvasFrame: canvasFrame,
            textViewsData: textViewsData,
            rangeDict: rangeDict,
            voiceOverModel: audioRecorder.audioArray,
            pointsDrawnArray: pointsDrawnArray,
            siteAudioURL: siteAudioURL?.lastPathComponent,
            adjustedMusicDuration: adjustedMusicDuration,
            videoAudioVolume: Double(playerVolume),
            voiceOverAudioVolume: Double(voiceOverAudioVolume),
            siteAudioVolume: Double(audioPlayer?.volume ?? 1.0)
        )
        
        return DraftManager.shared.saveDraft(draft)
    }
    
    deinit {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }
}

public enum VideoEditingError: Error {
    case noOutputURL
    case exportFailed
    
    public var localizedDescription: String {
        switch self {
        case .noOutputURL:
            return "No output URL specified for video export"
        case .exportFailed:
            return "Video export failed"
        }
    }
}

extension UIColor {
    var hexString: String {
        let components = self.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        
        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
    }
}
#endif