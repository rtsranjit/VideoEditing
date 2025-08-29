//
//  DraftVideoManager.swift
//  sesiosnativeapp
//
//  Created by Ranjit Singh on 29/03/24.
//  Copyright © 2024 rtsranjit. All rights reserved.
//

import Foundation

class DraftVideoManager {
    
    static let shared = DraftVideoManager()
    
    private init() {
        
    }
    
    func getDraftsArray() -> [UserEditingVideoState]? {
        guard let savedArrayData = UserDefaults.standard.data(forKey: "\(loggedinUserId)UserEditingVideoDictionary"),
              let userEditingVideoDictionary = try? JSONDecoder().decode([String: UserEditingVideoState].self, from: savedArrayData) else {
            // Handle case when userEditingVideoDictionary is empty, not found in UserDefaults, or index is out of bounds
            return nil
        }
        
        // Extract values from the dictionary
        let draftsArray = userEditingVideoDictionary.values.sorted { $0.createdTime < $1.createdTime }
        
        // Reverse the array to get the latest drafts first
//        draftsArray.reverse()
        
        return draftsArray
    }


    func checkLimitOfDrafts() -> Bool {
        if let savedArrayData = UserDefaults.standard.data(forKey: "\(loggedinUserId)UserEditingVideoDictionary"),
           let userEditingVideoDictionary = try? JSONDecoder().decode([String: UserEditingVideoState].self, from: savedArrayData) {
            return userEditingVideoDictionary.count < 10 // LIMIT 10
        }
        return true
    }

//    func getCurrentIndex() -> Int {
//        var count = 0
//        if let savedArrayData = UserDefaults.standard.data(forKey: "\(loggedinUserId)UserEditingVideoDictionary"),
//           let userEditingVideoDictionary = try? JSONDecoder().decode([String: UserEditingVideoState].self, from: savedArrayData) {
//            count = userEditingVideoDictionary.keys.max() ?? 0
//            count += 1
//        }
//        return count
//    }
    
    func getFilePath(uniqueId: String, fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return nil
        }
        
        // Create a folder within the documents directory if it doesn't exist
        var folderPath: URL!
        folderPath = documentsDirectory.appendingPathComponent("DraftVideo\(uniqueId)", isDirectory: true)
        // Check if the directory already exists
        if !FileManager.default.fileExists(atPath: folderPath.path) {
            // Create a folder within the documents directory if it doesn't exist
            do {
                try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating folder: \(error)")
            }
        } else {
            print("Directory already exists at: \(folderPath.path)")
        }
        
        return folderPath.appendingPathComponent(fileName)
    }
    
    func saveFileToDocumentDirectory(uniqueId: String, fileName: String, image: UIImage? = nil, file: URL? = nil, completion: @escaping (URL?, Error?) -> Void) {

        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            let error = NSError(domain: "YourDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
            completion(nil, error)
            return
        }
        
        var folderPath: URL!
        folderPath = documentsDirectory.appendingPathComponent("DraftVideo\(uniqueId)", isDirectory: true)
        // Check if the directory already exists
        if !FileManager.default.fileExists(atPath: folderPath.path) {
            // Create a folder within the documents directory if it doesn't exist
            do {
                try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating folder: \(error)")
                completion(nil, error)
                return
            }
        }
        
        let fileURL = folderPath.appendingPathComponent(fileName)
        
        if let videoURL = file {
            // Load video data asynchronously using URLSession
            URLSession.shared.dataTask(with: videoURL) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error loading video data:", error?.localizedDescription ?? "Unknown error")
                    completion(nil, error)
                    return
                }
                
                do {
                    // Write the video data to the file at the specified URL
                    try data.write(to: fileURL, options: .atomic)
                    print("Video saved successfully at:", fileURL)
                    completion(fileURL, nil)
                } catch {
                    completion(nil, error)
                }
            }.resume()
        } else {
            // Handle image saving
            guard let imageData = image?.pngData() else {
                print("Unable to get PNG representation of image")
                return
            }
            
            do {
                try imageData.write(to: fileURL)
                completion(fileURL, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    func loadFileFromDocumentDirectory(uniqueId: String, fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return nil
        }
        
        let folderPath = documentsDirectory.appendingPathComponent("DraftVideo\(uniqueId)", isDirectory: true)
        let fileURL = folderPath.appendingPathComponent(fileName)
        
        return fileURL
    }
    
    func checkFileExistInDocumentDirectory(uniqueId: String, fileName: String) -> URL? {
        
        // Check for empty fileName
        guard !fileName.isEmpty else {
            // You might want to handle this case differently, like throwing an error or logging it.
            print("File name is empty")
            return nil
        }
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return nil
        }
        
        let folderPath = documentsDirectory.appendingPathComponent("DraftVideo\(uniqueId)", isDirectory: true)
        let fileURL = folderPath.appendingPathComponent(fileName)
        
        // Check if the file exists at the constructed URL
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        } else {
            print("File does not exist at: \(fileURL.path)")
            return nil
        }
    }
    
    func deleteFromDocumentDirectory(uniqueId: String, fileName: String? = nil) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }
        
        let folderPath = documentsDirectory.appendingPathComponent("DraftVideo\(uniqueId)", isDirectory: true)
        
        if let fileName = fileName {
            let filePath = folderPath.appendingPathComponent(fileName)
            do {
                try FileManager.default.removeItem(at: filePath)
                print("Filepath \(filePath) deleted successfully")
            } catch {
                print("Error deleting Filepath:", error)
            }
            return
        }
        
        do {
            try FileManager.default.removeItem(at: folderPath)
            print("Directory \(folderPath) deleted successfully")
        } catch {
            print("Error deleting directory:", error)
        }
        
        let key = "\(loggedinUserId)UserEditingVideoDictionary"
        
        guard let savedArrayData = UserDefaults.standard.data(forKey: key),
              var userEditingVideoDictionary = try? JSONDecoder().decode([String: UserEditingVideoState].self, from: savedArrayData),
              !userEditingVideoDictionary.isEmpty else {
            // Handle case when UserEditingVideoDictionary is empty, not found in UserDefaults, or index is out of bounds
            return
        }

        if userEditingVideoDictionary.count == 1 {
            // Remove the entire dictionary from UserDefaults
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            // Remove the last element from the dictionary
            userEditingVideoDictionary.removeValue(forKey: uniqueId)
            
            // Save the updated UserEditingVideoDictionary to UserDefaults
            if let encodedData = try? JSONEncoder().encode(userEditingVideoDictionary) {
                UserDefaults.standard.set(encodedData, forKey: key)
            }
        }
        
        // Synchronize UserDefaults to save changes immediately
        UserDefaults.standard.synchronize()
    }
    
    func deleteFile(filePath: URL) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: filePath.path) else {
            print("File does not exist at path: \(filePath)")
            return
        }
        
        do {
            try fileManager.removeItem(at: filePath)
            print("File deleted successfully: \(filePath)")
        } catch {
            print("Error deleting file at path \(filePath): \(error)")
        }
    }
    
    func editVideoLayer(userEditingVC: UserEditingVideoViewController, currentView: UIViewController, completion: @escaping (URL) -> Void) {
        
        // Delete existing file if present
        if let videoFilePath = userEditingVC.videoFilePath {
            self.deleteFile(filePath: videoFilePath)
        }
        
        let asset = userEditingVC.videoAsset
        guard let clipVideoTrack = asset.tracks(withMediaType: .video).first else {
            print("Failed to get video track.")
            return
        }
        
        // Setup video transformation
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
        let videoTransform = clipVideoTrack.preferredTransform
        transformer.setTransform(videoTransform, at: .zero)
        transformer.setOpacity(0.0, at: asset.duration)
        
        // Determine natural size and orientation of the video
        let isVideoAssetPortrait = videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 ||
            videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0
        let naturalSize = isVideoAssetPortrait ? CGSize(width: clipVideoTrack.naturalSize.height, height: clipVideoTrack.naturalSize.width) : clipVideoTrack.naturalSize
        
        // Setup video composition
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: naturalSize)
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: naturalSize)
        parentLayer.addSublayer(videoLayer)
        
        let watermarkLayer = CALayer()
        watermarkLayer.contents = userEditingVC.canvasImageView.image?.cgImage
        watermarkLayer.frame = CGRect(origin: .zero, size: naturalSize)
        parentLayer.addSublayer(watermarkLayer)
        
        for subview in userEditingVC.canvasImageView.subviews {
            if let textView = subview as? UITextView {
                textView.isHidden = false
            }
        }
        
        for subview in userEditingVC.canvasImageView.subviews {
            if let textView = subview as? UITextView {
                
                let uiView = UIView(frame: userEditingVC.canvasImageView.frame)
                uiView.addSubview(textView)
                let image = uiView.asImage()
                userEditingVC.canvasImageView.addSubview(textView)
                
                let watermarkLayer = CALayer()
                watermarkLayer.contents = image.cgImage
                
                if let rangeDictValues = userEditingVC.rangeDict[textView.tag] {
                    watermarkLayer.beginTime = rangeDictValues.beginTime
                    watermarkLayer.duration = rangeDictValues.duration
                }
                
                watermarkLayer.frame = CGRect(origin: .zero, size: naturalSize)
                
                parentLayer.addSublayer(watermarkLayer)
            }
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = naturalSize
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(userEditingVC.videoAsset.duration.seconds))
        videoComposition.renderScale = 1.0
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayers: [videoLayer], in: parentLayer)
        
        let mixComposition = AVMutableComposition()
        guard let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        
        //Extract audio from the video and the music
        let audioMix: AVMutableAudioMix = AVMutableAudioMix()
        var audioMixParam: [AVMutableAudioMixInputParameters] = []
        
        // Original Video audio
        do {
            try videoCompositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: userEditingVC.videoAsset.duration), of: clipVideoTrack, at: .zero)
//            if !userEditingVC.muteBtn.isSelected {
                if let audioTrack = userEditingVC.videoAsset.tracks(withMediaType: .audio).first {
                    guard let audioFromVideoCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID()) else { return }
                    try audioFromVideoCompositionTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: userEditingVC.videoAsset.duration), of: audioTrack, at: .zero)
//                    audioFromVideoCompositionTrack.preferredVolume = userEditingVC.player.volume
                    
                    let videoParam: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters(track: audioTrack)
                    videoParam.trackID = audioFromVideoCompositionTrack.trackID
                    
                    //Set final volume of the audio record and the music
                    videoParam.setVolume(userEditingVC.playerVolume, at: .zero)
                    
                    //Add setting
                    audioMixParam.append(videoParam)
                    
                } else {
                    print("No audio track found in the video asset.")
                }
//            }
        } catch {
            print("Error: \(error)")
        }
        
        //Voice over audio
        if userEditingVC.voiceOverVC.audioArray.count > 0 {
            for audioModel in userEditingVC.voiceOverVC.audioArray {
                if let url = DraftVideoManager.shared.loadFileFromDocumentDirectory(uniqueId: userEditingVC.uniqueId, fileName: audioModel.audioPath) {
                    let audioAsset = AVURLAsset(url: url)
                    let startTime = CMTime(seconds: audioModel.startTime, preferredTimescale: audioAsset.duration.timescale)
                    
                    guard let audioModelCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
                    
                    if let audioTrack = audioAsset.tracks(withMediaType: .audio).first {
                        let videoDuration = asset.duration
                        let audioDuration = min(audioAsset.duration, videoDuration)//Audio asset duration should never be greater than video asset duration
                        do {
                            try audioModelCompositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: audioDuration), of: audioTrack, at: startTime)
//                            audioModelCompositionTrack.preferredVolume = userEditingVC.voiceOverVC.audioPlayer?.volume ?? 1.0
                            
                            let videoParam: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters(track: audioTrack)
                            videoParam.trackID = audioModelCompositionTrack.trackID
                            
                            //Set final volume of the audio record and the music
                            videoParam.setVolume(userEditingVC.voiceOverAudioVolume, at: .zero)
                            
                            //Add setting
                            audioMixParam.append(videoParam)
                            
                        } catch {
                            print("Error: \(error)")
                        }
                    } else {
                        print("Error: Audio track not found")
                    }
                }
            }
        }
        
        //Site Audio
        if let adjustedMusicDuration = userEditingVC.adjustedMusicDuration {

            if let url = DraftVideoManager.shared.loadFileFromDocumentDirectory(uniqueId: userEditingVC.uniqueId, fileName: userEditingVC.siteAudioURL?.lastPathComponent ?? "") {
                let audioAsset = AVURLAsset(url: url)
                let startAudioURLTime = CMTime(seconds: adjustedMusicDuration, preferredTimescale: CMTimeScale(userEditingVC.videoAsset.duration.seconds))
                //let startTime: CMTime = CMTime(seconds: userEditingVC.adjustedMusicDuration ?? 0, preferredTimescale: CMTimeScale(userEditingVC.videoAsset.duration.seconds))
                
                guard let audioModelCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
                
                if let audioTrack = audioAsset.tracks(withMediaType: .audio).first {
                    let videoDuration = asset.duration
                    let audioDuration = min(audioAsset.duration, videoDuration)//Audio asset duration should never be greater than video asset duration
                    do {
                        try audioModelCompositionTrack.insertTimeRange(CMTimeRangeMake(start: startAudioURLTime, duration: audioDuration), of: audioTrack, at: .zero)
//                        audioModelCompositionTrack.preferredVolume = userEditingVC.audioPlayer?.volume ?? 1.0
                        
                        let videoParam: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters(track: audioTrack)
                        videoParam.trackID = audioModelCompositionTrack.trackID
                        
                        //Set final volume of the audio record and the music
                        videoParam.setVolume(userEditingVC.audioPlayer?.volume ?? 1.0, at: .zero)
                        
                        //Add setting
                        audioMixParam.append(videoParam)
                        
                    } catch {
                        print("Error: \(error)")
                    }
                } else {
                    print("Error: Audio track not found")
                }
            }
        }
        
        //Add parameter
        audioMix.inputParameters = audioMixParam
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: userEditingVC.videoAsset.duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
        layerInstruction.setTransform(videoTransform, at: .zero)
        layerInstruction.setOpacity(0.0, at: asset.duration)
        
        instruction.layerInstructions = [layerInstruction]

        videoComposition.instructions = [instruction]
        
        // Export
        let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputFileType = .mov
        exporter?.outputURL = userEditingVC.videoFilePath
        exporter?.videoComposition = videoComposition
        exporter?.audioMix = audioMix
        
        // Show progress
        let alertView = UIAlertController(title: NSLocalizedString("Preparing...", comment: ""), message: "\n\n", preferredStyle: .alert)
        let margin:CGFloat = 8.0
        let rect = CGRect(x: margin, y: 72.0, width: alertView.view.frame.width-(margin * 2.0) , height: 2.0)
        let progressView = UIProgressView(frame: rect)
        progressView.progress = 0.0
        progressView.tintColor = .systemBlue
        alertView.view.addSubview(progressView)
        currentView.present(alertView, animated: true, completion: nil)
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            
            if progressView.frame.width == (appWidth-(margin * 2.0)) {
                progressView.frame.size.width = alertView.view.frame.width-(margin * 2.0)
            }
            progressView.progress = exporter?.progress ?? 0.0
            
            print(progressView.progress)
            
            if progressView.progress == 1.0 {
                alertView.dismiss(animated: true)
                timer.invalidate()
            }
        }
        // Add a cancel action
        alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            // Handle cancellation if needed
            exporter?.cancelExport()
            timer.invalidate()
            progressView.progress = 0.0
        }))
        
        exporter?.exportAsynchronously {
            DispatchQueue.main.async {
                
                guard let exporter = exporter, exporter.status == .completed, let outputURL = exporter.outputURL else {
                    if let error = exporter?.error {
                        print("Export failed with error: \(error)")
                    }
                    alertView.dismiss(animated: true)
                    timer.invalidate()
                    if exporter?.status == .failed || exporter?.status == .unknown {
                        currentView.view.makeToast(NSLocalizedString("Something went wrong.", comment: ""))
                    }
                    return
                }
                
                completion(outputURL)
            }
        }
    }
    
}
