//
//  VoiceOverViewController.swift
//  sesiosnativeapp
//
//  Created by Apple on 08/09/23.
//  Copyright © 2023 SocialEngineSolutions. All rights reserved.
//

import Foundation

struct AudioModel: Codable {
    let startTime: Double
    var endTime: Double
    let audioPath: String
}

class VoiceOverViewController: UIViewController {
    
    weak var userEditingVC: UserEditingVideoViewController?
    
    init() {
        super.init(nibName: nil, bundle: nil) // Call designated initializer of UIViewController
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let imageLayerSuperView = UIView()
    
    let videoImageLayer = UIImageView()
    let movingView = UIView()
    
    let recordButton = UIButton()
    
    let discardButton = UIButton()
    
//    let muteVideoBtn = UIButton() //Remove video original sound
    
    let playButton = UIButton()
    let doneButton = UIButton()
    
    var arrayOfLayers: [CALayer] = []
    
    var currentAudioPath: String = ""
    var audioPlayer: AVPlayer?
    var audioArray:[AudioModel] = [] {
        didSet {
            discardButton.isHidden = audioArray.count>0 ? false : true
        }
    }
    
    var isRecording = false {
        didSet {
            if isRecording {
                userEditingVC?.playMedia(muteSiteAudio: true)
                self.startRecording()
                recordButton.setImage(UIImage(systemName: "stop.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 76, weight: .thin, scale: .large)), for: UIControl.State())
                recordButton.imageView?.tintColor = navigationColor
                recordButton.backgroundColor = .clear
                movingView.isUserInteractionEnabled = false
                
            } else {
                userEditingVC?.pauseMedia()
                self.stopRecording()
                recordButton.setImage(UIImage(systemName: "circle.inset.filled", withConfiguration: UIImage.SymbolConfiguration(pointSize: 76, weight: .thin, scale: .large)), for: UIControl.State())
                recordButton.imageView?.tintColor = .gray
                recordButton.backgroundColor = .clear
                movingView.isUserInteractionEnabled = true
                
            }
        }
    }
    
    var movingViewXOrigin: Double = 0.0 {
        didSet {
            movingView.frame.origin.x = movingViewXOrigin-(movingView.frame.width/2.0)
            if (movingView.frame.origin.x+(movingView.frame.width/2.0))==videoImageLayer.frame.width {
                recordButton.isUserInteractionEnabled = false
                recordButton.alpha = 0.5
            } else {
                recordButton.isUserInteractionEnabled = true
                recordButton.alpha = 1.0
            }
        }
    }
    var isMovingPointer = true
    
    var audioRecorder: AVAudioRecorder?
    lazy var audioSettings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
    ]
    
    var caLayerForAudio = CALayer()
    
    var audioCheck = false //Stop audio from playing first time
    
    var timeObserver: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeViews()
        
        if audioPlayer == nil {
            setAudioFunctionality()
        }
        
        setDefaultAudio(category: .playAndRecord)
        
        if let currentTimeCMTime = userEditingVC?.player?.currentTime() {
            movingViewXOrigin = setXPosition(progress: CMTimeGetSeconds(currentTimeCMTime))
        }
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        if player?.isPlaying ?? false {
            playButton.setImage(UIImage(systemName: "pause.fill"), for: UIControl.State())
        } else {
            playButton.setImage(UIImage(systemName: "play.fill"), for: UIControl.State())
        }
        recordButton.setImage(UIImage(systemName: "circle.inset.filled", withConfiguration: UIImage.SymbolConfiguration(pointSize: 76, weight: .thin, scale: .large)), for: UIControl.State())
        recordButton.imageView?.tintColor = .gray
        recordButton.backgroundColor = .clear
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.isRecording = false
        userEditingVC?.playMedia()
    }
    
    func updateOverlayFrames(_ frame: CGRect) -> Bool {
        var checkCondition = true
        for caLayer in arrayOfLayers {
            if overlaysOverlap(frame, otherFrame: caLayer.frame) {
                checkCondition = false
                break
            }
        }
        return checkCondition
    }
    
    func overlaysOverlap(_ frame1: CGRect, otherFrame frame2: CGRect) -> Bool {
        return frame1.intersects(frame2)
    }
    
    func initializeViews() {
        
        let transparentView = UIView(frame: CGRect(x: 0, y: 0, width: appWidth, height: appHeight-356))
        let gesture = UITapGestureRecognizer(target: self, action: #selector(closeButtonTapped))
        transparentView.addGestureRecognizer(gesture)
        view.addSubview(transparentView)
        
        // Set up your pop-up view's content here
        let popUpView = UIView(frame: CGRect(x: 0, y: appHeight-356, width: appWidth, height: 356))
        popUpView.backgroundColor = UIColor.white
        popUpView.layer.cornerRadius = 10
        popUpView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        popUpView.isUserInteractionEnabled = true
        
        let voiceOverText = UILabel(frame: CGRect(x: 0, y: 0, width: appWidth, height: 40))
        voiceOverText.textAlignment = .center
        voiceOverText.text = NSLocalizedString("Voice Over", comment: "")
        voiceOverText.font = UIFont(name: boldFont, size: 16)
        popUpView.addSubview(voiceOverText)
        
        imageLayerSuperView.frame = CGRect(x: 10, y: 50, width: appWidth-20, height: 50)
        imageLayerSuperView.isUserInteractionEnabled = true
        popUpView.addSubview(imageLayerSuperView)
        
        videoImageLayer.frame = CGRect(x: 0, y: 0, width: imageLayerSuperView.frame.width, height: imageLayerSuperView.frame.height)
        videoImageLayer.layer.cornerRadius = 5.0
        videoImageLayer.layer.masksToBounds = true
        videoImageLayer.isUserInteractionEnabled = true
        imageLayerSuperView.addSubview(videoImageLayer)
        
        //If changing x Position then also change the condition in touchesBegan & touchesMoved functions.
        movingView.frame = CGRect(x: 0, y: -2, width: 6, height: imageLayerSuperView.frame.height+4)
        movingView.layer.cornerRadius = 3.0
        movingView.layer.masksToBounds = true
        movingView.backgroundColor = navigationColor
        movingView.isUserInteractionEnabled = true
        imageLayerSuperView.addSubview(movingView)
        
        let infoText = UILabel(frame: CGRect(x: 0, y: 110, width: appWidth, height: 30))
        infoText.textAlignment = .center
        infoText.textColor = UIColor(red: 0.167, green: 0.167, blue: 0.167, alpha: 1)
        infoText.text = NSLocalizedString("Tap or hold to record audio over the video", comment: "")
        infoText.font = UIFont(name: fontName, size: 15)
        popUpView.addSubview(infoText)
        
        recordButton.frame = CGRect(x: (appWidth-76)/2, y: 150, width: 76, height: 76)
        recordButton.layer.masksToBounds = true
        recordButton.layer.cornerRadius = recordButton.frame.height/2
        recordButton.setImage(UIImage(systemName: "circle.inset.filled", withConfiguration: UIImage.SymbolConfiguration(pointSize: 76, weight: .thin, scale: .large)), for: UIControl.State())
        recordButton.imageView?.tintColor = .gray
        recordButton.backgroundColor = .clear
        recordButton.addTarget(self, action: #selector(startVoiceRecording), for: .touchUpInside)
        // Create a UILongPressGestureRecognizer
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        recordButton.addGestureRecognizer(longPressGesture)
        popUpView.addSubview(recordButton)
        
//        muteVideoBtn.frame = CGRect(x: appWidth-31-36, y: 170, width: 36, height: 36)
//        muteVideoBtn.setImage(UIImage(systemName: "speaker.fill"), for: UIControl.State())
//        muteVideoBtn.addTarget(self, action: #selector(muteBtnTapped(_:)), for: .touchUpInside)
//        muteVideoBtn.tintColor = UIColor(red: 0.54, green: 0.54, blue: 0.55, alpha: 1)
//        popUpView.addSubview(muteVideoBtn)
        
        discardButton.frame = CGRect(x: 31, y: 170, width: 36, height: 36)
        discardButton.setImage(UIImage(named: "discardButton"), for: UIControl.State())
        discardButton.addTarget(self, action: #selector(discardBtnTapped), for: .touchUpInside)
        discardButton.isHidden = audioArray.count>0 ? false : true
        popUpView.addSubview(discardButton)
        
        let bottomSafeAreaHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0.0
        
        let bottomView = UIView(frame: CGRect(x: 0, y: popUpView.frame.height-60-bottomSafeAreaHeight, width: appWidth, height: 60+bottomSafeAreaHeight))
        bottomView.backgroundColor = UIColor(red: 0.887, green: 0.887, blue: 0.887, alpha: 1)
        popUpView.addSubview(bottomView)
        
        playButton.frame = CGRect(x: 15, y: 9, width: 42, height: 42)
        playButton.setImage(UIImage(systemName: "play.fill"), for: UIControl.State())
        playButton.imageView?.contentMode = .scaleAspectFit
        playButton.isSelected = true
        playButton.imageView?.tintColor = UIColor(red: 0.31, green: 0.31, blue: 0.31, alpha: 1)
        playButton.setBackgroundColor(color: .white, forState: UIControl.State())
        playButton.layer.cornerRadius = playButton.frame.height/2
        playButton.layer.masksToBounds = true
        playButton.addTarget(self, action: #selector(self.playButtonTapped), for: .touchUpInside)
        bottomView.addSubview(playButton)
        
        doneButton.frame = CGRect(x: appWidth-57, y: 9, width: 42, height: 42)
        doneButton.setImage(UIImage(systemName: "checkmark"), for: UIControl.State())
        doneButton.imageView?.tintColor = UIColor(red: 0.31, green: 0.31, blue: 0.31, alpha: 1)
        doneButton.imageView?.contentMode = .scaleAspectFit
        doneButton.setBackgroundColor(color: .white, forState: UIControl.State())
        doneButton.layer.cornerRadius = doneButton.frame.height/2
        doneButton.layer.masksToBounds = true
        doneButton.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
        bottomView.addSubview(doneButton)
        
        view.addSubview(popUpView)
        
        createImageFrames()
        
        if arrayOfLayers.count == 0 {
            addCALayers()
        }
    }
    
    func setAudioFunctionality() {
        timeObserver = userEditingVC?.player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1/(userEditingVC?.videoAsset.duration.seconds ?? 0), preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil, using: { [self] time in
            let lastXValue = movingViewXOrigin
            if isMovingPointer {
                movingViewXOrigin = setXPosition(progress: CMTimeGetSeconds(time))
                
                for audioModel in audioArray {
                    
                    //                        print("PlayerTime: \(CMTimeGetSeconds(time))")
                    //                        print("StartTime: \(audioModel.startTime)")
                    
                    let timeInSeconds = CMTimeGetSeconds(time)
                    if audioModel.endTime != 0,
                       (timeInSeconds >= audioModel.startTime && timeInSeconds <= audioModel.endTime),
                       !(audioPlayer?.isPlaying ?? false) {
                        
                        audioPlayer = nil
                        
                        if audioCheck == false,
                           let url = DraftVideoManager.shared.checkFileExistInDocumentDirectory(uniqueId: userEditingVC?.uniqueId ?? "", fileName: audioModel.audioPath) {
                            // Create an AVPlayerItem from the audio URL
                            let playerItem = AVPlayerItem(url: url)
                            
                            audioPlayer = AVPlayer(playerItem: playerItem)
                            audioPlayer?.volume = userEditingVC?.voiceOverAudioVolume ?? 1.0
                            
                            if (userEditingVC?.player?.isPlaying ?? false) {
                                userEditingVC?.playMedia()
                            }
                            self.currentAudioPath = audioModel.audioPath
                        }
                    } else if self.currentAudioPath == audioModel.audioPath,
                              timeInSeconds>audioModel.endTime,
                              !(audioPlayer?.isPlaying ?? true) {
                        self.userEditingVC?.pauseMedia()
                    }
                }
                
            }
            if isRecording {
                movingViewXOrigin = setXPosition(progress: CMTimeGetSeconds(time))
                caLayerForAudio.frame.size.width += (movingViewXOrigin-lastXValue)
            }
        })
    }
    
    func addCALayers() {
        for audioModel in audioArray {
            
            let thumbtimeSeconds  = CMTimeGetSeconds(userEditingVC?.videoAsset.duration ?? CMTime())
            let totalTime = videoImageLayer.frame.origin.x+videoImageLayer.frame.width
            let xOrigin = (audioModel.startTime*totalTime)/thumbtimeSeconds
            let width = (audioModel.endTime*totalTime)/thumbtimeSeconds
            
            caLayerForAudio = CALayer()
            caLayerForAudio.frame = CGRect(x: xOrigin, y: 0, width: width-xOrigin, height: movingView.frame.height)
            caLayerForAudio.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
            self.arrayOfLayers.append(self.caLayerForAudio)
            self.videoImageLayer.layer.addSublayer(self.caLayerForAudio)
        }
    }
    
    //MARK: CreatingFrameImages
    func createImageFrames()
    {
        //creating assets
        let assetImgGenerate : AVAssetImageGenerator    = AVAssetImageGenerator(asset: userEditingVC?.videoAsset ?? AVAsset())
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter    = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore   = CMTime.zero;
        
        assetImgGenerate.appliesPreferredTrackTransform = true
        let thumbTime: CMTime = userEditingVC?.videoAsset.duration ?? CMTime()
        let thumbtimeSeconds  = Int(CMTimeGetSeconds(thumbTime))
        let maxLength         = "\(thumbtimeSeconds)" as NSString
        
        let thumbAvg  = thumbtimeSeconds/10
        var startTime = 1
        var startXPosition:CGFloat = 0.0
        
        //loop for 6 number of frames
        for _ in 0...9
        {
            
            let imageButton = UIButton()
            let xPositionForEach = CGFloat(self.videoImageLayer.frame.width)/10
            imageButton.frame = CGRect(x: CGFloat(startXPosition), y: CGFloat(0), width: xPositionForEach, height: CGFloat(self.videoImageLayer.frame.height))
            do {
                let time:CMTime = CMTimeMakeWithSeconds(Float64(startTime),preferredTimescale: Int32(maxLength.length))
                let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: img)
                imageButton.setImage(image, for: .normal)
            }
            catch let error as NSError {
                print("Image generation failed with error: \(error.localizedDescription)")
            }
            
            startXPosition = startXPosition + xPositionForEach
            startTime = startTime + thumbAvg
            imageButton.isUserInteractionEnabled = false
            videoImageLayer.addSubview(imageButton)
        }
    }
    
    @objc func playButtonTapped(_ sender: UIButton) {
        if isRecording { return }
        if sender.isSelected {
            isMovingPointer = true
            userEditingVC?.playMedia()
            sender.setImage(UIImage(systemName: "pause.fill"), for: UIControl.State())
        } else {
            isMovingPointer = false
            userEditingVC?.pauseMedia()
            sender.setImage(UIImage(systemName: "play.fill"), for: UIControl.State())
        }
        sender.isSelected = !sender.isSelected
    }
    
    @objc func closeButtonTapped() {
        // Close the pop-up view
        dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, self.movingView.isUserInteractionEnabled {
            if videoImageLayer == touch.view {
                isMovingPointer = false
                var location = touch.location(in: videoImageLayer)
                setTime(xPosition: &location.x)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, self.movingView.isUserInteractionEnabled {
            if videoImageLayer == touch.view {
                var location = touch.location(in: videoImageLayer)
                setTime(xPosition: &location.x)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, self.movingView.isUserInteractionEnabled {
            if videoImageLayer == touch.view {
                isMovingPointer = playButton.isSelected ? true : false
                var location = touch.location(in: videoImageLayer)
                setTime(xPosition: &location.x)
            }
        }
    }
    
    func setTime(xPosition: inout CGFloat) {
        
        if xPosition<0 {
            xPosition = 0
        } else if xPosition>videoImageLayer.frame.width {
            xPosition = videoImageLayer.frame.width
        }
//        movingViewXOrigin = xPosition
        
        let thumbTime: CMTime = userEditingVC?.videoAsset.duration ?? CMTime()
        let thumbtimeSeconds  = Int(CMTimeGetSeconds(thumbTime))
        
        let totalTime = videoImageLayer.frame.origin.x+videoImageLayer.frame.width
        let second = xPosition/(totalTime/CGFloat(thumbtimeSeconds))
        
        userEditingVC?.player.seek(to: CMTime(seconds: second, preferredTimescale: userEditingVC?.videoAsset.duration.timescale ?? CMTimeScale())) // Video Player
        userEditingVC?.audioPlayer?.currentTime = (userEditingVC?.adjustedMusicDuration ?? 0) + second // Site Audio Player 
        
        movingViewXOrigin = setXPosition(progress: second)
    }
    
    func setXPosition(progress: CGFloat) -> (CGFloat) {
        
        let thumbTime: CMTime = userEditingVC?.videoAsset.duration ?? CMTime()
        let thumbtimeSeconds  = Int(CMTimeGetSeconds(thumbTime))
        
        let totalTime = videoImageLayer.frame.origin.x+videoImageLayer.frame.width
        
        let xPosition = progress*(totalTime/CGFloat(thumbtimeSeconds))
        
        if xPosition>totalTime {
            if isRecording {
                isRecording = false
                isMovingPointer = false
                stopRecording()
                userEditingVC?.pauseMedia()
            }
            return totalTime
        }
        
        return xPosition
    }
    
    @objc func startVoiceRecording(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            isRecording = true
        } else {
            if isRecording {
                isRecording = false
            }
        }
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // Long press started
            isRecording = true
        } else if gesture.state == .ended {
            // Long press ended
            if isRecording {
                isRecording = false
            }
        }
    }
    
    @objc func muteBtnTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.setImage(UIImage(systemName: sender.isSelected ? "speaker.slash.fill" : "speaker.fill"), for: UIControl.State())
    }
    
    @objc func discardBtnTapped() {
        // Create an alert controller
        let alertController = UIAlertController(title: NSLocalizedString("Discard latest clip?", comment: ""), message: NSLocalizedString("If you continue, you'll lose the latest voiceover clip you recorded.", comment: ""), preferredStyle: .alert)
        
        // Create OK action
        let okAction = UIAlertAction(title: NSLocalizedString("Discard", comment: ""), style: .destructive) { (_) in
            // Handle OK button tap
            print("OK Button Tapped")
            
            self.userEditingVC?.pauseMedia()
            self.audioPlayer = nil
            
            self.arrayOfLayers.last?.removeFromSuperlayer()
            self.arrayOfLayers.removeLast()
            DraftVideoManager.shared.deleteFromDocumentDirectory(uniqueId: self.userEditingVC?.uniqueId ?? "", fileName: self.audioArray.last?.audioPath)
            self.audioArray.removeLast()
        }
        
        // Create Cancel action
        let cancelAction = UIAlertAction(title: NSLocalizedString("Keep", comment: ""), style: .cancel) { (_) in
            // Handle Cancel button tap (if needed)
            print("Cancel Button Tapped")
        }
        
        // Add actions to the alert controller
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }
    
}

extension VoiceOverViewController {
    
    func startRecording() {
        
        if let currentItem = self.userEditingVC?.player.currentItem {
            let currentTime = CMTimeGetSeconds(currentItem.currentTime())
            movingViewXOrigin = setXPosition(progress: currentTime)
        }
        
        let xOrigin = movingViewXOrigin
        
        caLayerForAudio = CALayer()
        caLayerForAudio.frame = CGRect(x: xOrigin, y: 0, width: 0, height: movingView.frame.height)
        caLayerForAudio.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
        self.arrayOfLayers.append(self.caLayerForAudio)
        self.videoImageLayer.layer.addSublayer(self.caLayerForAudio)
        
//        let path = NSTemporaryDirectory().appending("userEditedAudio\(audioArray.count).m4a")
//        let filePath = URL(fileURLWithPath: path)

        let fileName = "userAudio\(audioArray.count).m4a"
        if let filePath = DraftVideoManager.shared.getFilePath(uniqueId: userEditingVC?.uniqueId ?? "", fileName: fileName) {
            
            // Remove file if existed
            FileManager.default.removeItemIfExisted(filePath)
            
            do {
                audioRecorder = try AVAudioRecorder(url: filePath, settings: audioSettings)
                audioRecorder?.record()
                
                let thumbTime: CMTime = userEditingVC?.videoAsset.duration ?? CMTime()
                let thumbtimeSeconds  = CMTimeGetSeconds(thumbTime)//Int(CMTimeGetSeconds(thumbTime))
                let totalTime = videoImageLayer.frame.origin.x+videoImageLayer.frame.width
                let second = (xOrigin*thumbtimeSeconds)/totalTime
                
                audioArray.append(AudioModel(startTime: second, endTime: 0, audioPath: fileName))
            } catch {
                print("Error starting recording: \(error.localizedDescription)")
            }
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        if let startTime = audioArray.last?.startTime,
           let audioPath = audioArray.last?.audioPath {
            
            audioArray.removeLast()
            
            let thumbTime: CMTime = userEditingVC?.videoAsset.duration ?? CMTime()
            let thumbtimeSeconds  = CMTimeGetSeconds(thumbTime)//Int(CMTimeGetSeconds(thumbTime))
            let totalTime = videoImageLayer.frame.origin.x+videoImageLayer.frame.width
            let second = (movingViewXOrigin*thumbtimeSeconds)/totalTime
            
            audioArray.append(AudioModel(startTime: startTime, endTime: second, audioPath: audioPath))
            
            audioCheck=true
            // Schedule a closure to set audioCheck to false after two seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.audioCheck = false
            }
        }
    }
    
}
