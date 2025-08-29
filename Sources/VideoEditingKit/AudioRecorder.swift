import Foundation
import AVFoundation

@available(iOS 14.0, *)
public class AudioRecorder: ObservableObject {
    
    private var audioRecorder: AVAudioRecorder?
    public var audioPlayer: AVPlayer?
    
    @Published public var isRecording = false
    @Published public var audioArray: [AudioModel] = []
    
    private let audioSettings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
    ]
    
    public init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(iOS) || os(tvOS) || os(watchOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        #endif
    }
    
    public func startRecording(at startTime: Double, uniqueId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let fileName = "userAudio\(audioArray.count).m4a"
        
        guard let filePath = DraftManager.shared.getFilePath(uniqueId: uniqueId, fileName: fileName) else {
            completion(.failure(AudioRecordingError.failedToCreateFilePath))
            return
        }
        
        FileManager.default.removeItemIfExisted(filePath)
        
        do {
            audioRecorder = try AVAudioRecorder(url: filePath, settings: audioSettings)
            audioRecorder?.record()
            isRecording = true
            
            audioArray.append(AudioModel(startTime: startTime, endTime: 0, audioPath: fileName))
            completion(.success(fileName))
        } catch {
            completion(.failure(error))
        }
    }
    
    public func stopRecording(at endTime: Double) {
        audioRecorder?.stop()
        isRecording = false
        
        if var lastAudio = audioArray.last {
            audioArray.removeLast()
            lastAudio.endTime = endTime
            audioArray.append(lastAudio)
        }
    }
    
    public func playAudio(fileName: String, uniqueId: String, volume: Float = 1.0) {
        guard let url = DraftManager.shared.loadFileFromDocumentDirectory(uniqueId: uniqueId, fileName: fileName) else {
            print("Audio file not found")
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        audioPlayer = AVPlayer(playerItem: playerItem)
        audioPlayer?.volume = volume
        audioPlayer?.play()
    }
    
    public func stopAudio() {
        audioPlayer?.pause()
    }
    
    public func discardLatestClip(uniqueId: String) -> Bool {
        guard let lastAudio = audioArray.last else { return false }
        
        DraftManager.shared.deleteFromDocumentDirectory(uniqueId: uniqueId, fileName: lastAudio.audioPath)
        audioArray.removeLast()
        return true
    }
    
    public func clearAllAudio() {
        audioArray.removeAll()
        audioPlayer = nil
    }
}

public enum AudioRecordingError: Error {
    case failedToCreateFilePath
    case recordingInProgress
    case noActiveRecording
    
    public var localizedDescription: String {
        switch self {
        case .failedToCreateFilePath:
            return "Failed to create file path for audio recording"
        case .recordingInProgress:
            return "Recording is already in progress"
        case .noActiveRecording:
            return "No active recording found"
        }
    }
}