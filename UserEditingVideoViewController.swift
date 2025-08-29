//
//  UserEditingVideoViewController.swift
//  sesiosnativeapp
//
//  Created by Ranjit Singh on 23/08/23.
//  Copyright © 2023 rtsranjit. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit
import CoreGraphics
import AssetsLibrary

class UserEditingVideoViewController: UIViewController {
    
    private lazy var currentPlayerTime: CMTime = .zero {
        didSet {
            
            if let duration = player?.currentItem?.duration {
                let currentTime = CMTimeGetSeconds(currentPlayerTime)
                let totalDuration = CMTimeGetSeconds(duration)
                let progress = Float(currentTime / totalDuration)
                self.adjustMusicProgressView.progress = progress
            }
            
            // Iterate through subviews to find UITextView with specific tags and hide them if needed
            for subview in self.canvasImageView.subviews {
                if let textView = subview as? UITextView {
                    let textViewTag = textView.tag
                    // Check if the tag exists in rangeDict and if it does, get its corresponding TextViewStateDuration
                    if let textViewDuration = self.rangeDict[textViewTag] {
                        // Calculate the end time of the text view based on its begin time and duration
                        let textViewEndTime = textViewDuration.beginTime + textViewDuration.duration
                        
                        // Check if the current progress time is within the range of the text view
                        if CMTimeGetSeconds(currentPlayerTime) >= textViewDuration.beginTime && CMTimeGetSeconds(currentPlayerTime) <= textViewEndTime {
                            // Hide the text view if it's within the specified duration
                            textView.isHidden = false
                        } else {
                            // Show the text view if it's not within the specified duration
                            textView.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    private lazy var textPadding: CGFloat = 15
    
    private lazy var songID = 0
    private lazy var songURLString = ""
    private lazy var song_title = ""
    private lazy var songURLTEMP:URL? = nil
    internal var audioPlayer:AVAudioPlayer? = nil
    
    lazy var adjustedMusicDuration: Double? = nil
    
    private lazy var adjustMusicView: UIView = {
        let musicView = UIView()
        musicView.layer.borderWidth = 5
        musicView.layer.masksToBounds = true
        musicView.layer.cornerRadius = 5
        
        return musicView
    }()
    private lazy var adjustMusicProgressView: UIProgressView = {
        let musicProgressView = UIProgressView(frame: CGRect(x: 0, y: 21, width: 200, height: 10))
        musicProgressView.progress = 0.0
        musicProgressView.progressTintColor = hexStringToUIColor(hex: "#454545")
        musicProgressView.trackTintColor = .white
        musicProgressView.transform = CGAffineTransform(scaleX: 1.0, y: 12.0)
        
        return musicProgressView
    }()
    private lazy var adjustMusicScrollView: UIScrollView = {
        let musicScrollView = UIScrollView()
        
        return musicScrollView
    }()
    
    var isAdjustingMusic = false {
        didSet {
            if isAdjustingMusic {
                self.pauseMedia()
            } else {
                self.audioPlayer?.currentTime = adjustedMusicDuration ?? 0
                self.player.seek(to: .zero)
                self.playMedia()
            }
        }
    }
    var adjustedMusic: Bool = false {
        didSet {
            if adjustedMusic {
                
                //pauseMedia()
                
                self.undoBtn.setTitle(NSLocalizedString("Discard", comment: ""), for: .normal)
                self.undoBtn.isHidden = false
                
                self.addedTextViews.isHidden = true
                
                self.backBtn.isHidden = true
                self.textBtn.isHidden = true
                self.drawBtn.isHidden = true
                self.voiceOverBtn.isHidden = true
                self.musicListBtn.isHidden = true
                self.volumeBtn.isHidden = true
                self.nextBtn.isHidden = true
                
                self.doneBtn.isHidden = false
                self.colorAndFontPickerView.isHidden = true
                
                self.adjustMusicView.isHidden = false
                self.adjustMusicScrollView.isHidden = false
                
                for subViews in canvasImageView.subviews {
                    if let textView = subViews as? UITextView {
                        textView.isUserInteractionEnabled = false
                    }
                }
            } else {
                
                playMedia()
                
                self.undoBtn.setTitle(NSLocalizedString("Undo", comment: ""), for: .normal)
                self.undoBtn.isHidden = true
                
                self.addedTextViews.isHidden = false
                
                self.backBtn.isHidden = false
                self.textBtn.isHidden = false
                self.drawBtn.isHidden = false
                self.voiceOverBtn.isHidden = false
                self.musicListBtn.isHidden = false
                self.volumeBtn.isHidden = false
                self.nextBtn.isHidden = false
                
                self.doneBtn.isHidden = true
                self.undoBtn.isHidden = true
                self.colorAndFontPickerView.isHidden = true
                
                self.adjustMusicView.isHidden = true
                self.adjustMusicScrollView.isHidden = true
                
                for subViews in canvasImageView.subviews {
                    if let textView = subViews as? UITextView {
                        textView.isUserInteractionEnabled = true
                    }
                }
            }
        }
    }
    
    let topSafeAreaHeight = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0.0
    let bottomSafeAreaHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0.0
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var playerItem :AVPlayerItem!
    var playerVolume: Float = 1.0
    
    let backBtn = UIButton()
    
    let nextBtn = UIButton()
    
    var progressAlert:Float = 0.0
    
    //Draw Functionality
    let drawBtn = UIButton()
    var drawColor: UIColor = UIColor.white
    
    let videoFilePath:URL? = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("video.mp4"))
    
    var isDrawing: Bool = false {
        didSet {
            if isDrawing {
                
                pauseMedia()
                
                self.addedTextViews.isHidden = true
                
                self.backBtn.isHidden = true
                self.textBtn.isHidden = true
                self.drawBtn.isHidden = true
                self.voiceOverBtn.isHidden = true
                self.musicListBtn.isHidden = true
                self.volumeBtn.isHidden = true
                self.nextBtn.isHidden = true
                
                self.doneBtn.isHidden = false
                self.colorAndFontPickerView.isHidden = false
                
                for subViews in canvasImageView.subviews {
                    if let textView = subViews as? UITextView {
                        textView.isUserInteractionEnabled = false
                    }
                }
            } else {
                
                playMedia()
                
                self.addedTextViews.isHidden = false
                
                self.backBtn.isHidden = false
                self.textBtn.isHidden = false
                self.drawBtn.isHidden = false
                self.voiceOverBtn.isHidden = false
                self.musicListBtn.isHidden = false
                self.volumeBtn.isHidden = false
                self.nextBtn.isHidden = false
                
                self.doneBtn.isHidden = true
                self.undoBtn.isHidden = true
                self.colorAndFontPickerView.isHidden = true
                
                for subViews in canvasImageView.subviews {
                    if let textView = subViews as? UITextView {
                        textView.isUserInteractionEnabled = true
                    }
                }
            }
        }
    }
    
    var isMagnifyingGlassActive = false
    
    var swiped = false
    var lastPoint: CGPoint!
    
    //Text Functionality
    let textBtn = UIButton()
    var textColor: UIColor = UIColor.white
    
    let textEditingStack = UIStackView()
    let textAlignmentBtn = UIButton()
    let textStyleBtn = UIButton()
    let textBackgroundBtn = UIButton()
    
    private lazy var frameContainerView = UIView(frame: CGRect(x: 100/2, y: appHeight-100.0, width: appWidth-100, height: 60))
    private lazy var rangeSlider = TrimmerRangeSlider(frame: CGRect(x: 100/2, y: appHeight-100.0, width: appWidth-100, height: 60))
    var rangeDict: [Int:TextViewStateDuration] = [:]
    private lazy var addedTextViews: UIScrollView = {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: view.frame.height-bottomSafeAreaHeight-75-50, width: appWidth, height: 40))
        scrollView.isUserInteractionEnabled = true
        scrollView.isScrollEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    // Create a slider
    let textFontSlider = CustomSlider()
    
    var lastPanPoint: CGPoint?
    var imageViewToPan: UIImageView?
    let deleteBtn = UIButton()
    
    private lazy var animator: NVActivityIndicatorView = {
        let animator = NVActivityIndicatorView(frame: appLoaderframe, type: loadingImageType(), color: appLoadingImageColor, padding: CGFloat(0))
        animator.center = view.center
        self.view.addSubview(animator)
        return animator
    }()
    
    /**
     Array of Colors that will show while drawing or typing
     */
    public var colors  : [UIColor] = []
    
    let colorsCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), collectionViewLayout: UICollectionViewLayout())
    let fontCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), collectionViewLayout: UICollectionViewLayout())
    var colorsCollectionViewDelegate: ColorsCollectionViewDelegate!
    var fontCollectionViewDelegate: FontDelegate!
    let colorAndFontPickerView = UIView()
    
    var lastTextViewTransform: CGAffineTransform?
    var lastTextViewTransCenter: CGPoint?
    var lastTextViewFont:UIFont?
    
    var activeTextView: CustomPaddingTextView?
    let canvasImageView = UIImageView()
    
    var isTextEditing: Bool = false {
        didSet {
            if isTextEditing {
                
                pauseMedia()
                
                self.textFontSlider.isHidden = false
                
                self.addedTextViews.isHidden = true
                
                self.backBtn.isHidden = true
                self.textBtn.isHidden = true
                self.drawBtn.isHidden = true
                self.voiceOverBtn.isHidden = true
                self.musicListBtn.isHidden = true
                self.volumeBtn.isHidden = true
                self.nextBtn.isHidden = true
                
                self.doneBtn.isHidden = false
                self.colorAndFontPickerView.isHidden = false
                
                self.textAlignmentBtn.setImage(UIImage(systemName: self.textAlignmentBtn.tag==0 ? "text.alignleft" : self.textAlignmentBtn.tag==1 ? "text.aligncenter" : "text.alignright")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
                
                self.textEditingStack.isHidden = false
                self.frameContainerView.isHidden = true
            } else {
                
                playMedia()
                
                self.textFontSlider.isHidden = true
                
                self.addedTextViews.isHidden = false
                
                self.backBtn.isHidden = false
                self.textBtn.isHidden = false
                self.drawBtn.isHidden = false
                self.voiceOverBtn.isHidden = false
                self.musicListBtn.isHidden = false
                self.volumeBtn.isHidden = false
                self.nextBtn.isHidden = false
                
                self.doneBtn.isHidden = true
                self.colorAndFontPickerView.isHidden = true
                
                self.textEditingStack.isHidden = true
                
                self.deleteBtn.isHidden = true
            }
        }
    }
    
    var isTextMoving: Bool = false {
        didSet {
            if isTextMoving {
                
                pauseMedia()
                
                self.addedTextViews.isHidden = true
                
                self.doneBtn.isHidden = true
                self.backBtn.isHidden = true
                self.textBtn.isHidden = true
                self.drawBtn.isHidden = true
                self.voiceOverBtn.isHidden = true
                self.musicListBtn.isHidden = true
                self.volumeBtn.isHidden = true
                self.nextBtn.isHidden = true
                self.colorAndFontPickerView.isHidden = true
                
                self.deleteBtn.isHidden = false
                
                self.textEditingStack.isHidden = true
                self.frameContainerView.isHidden = true
            } else {
                
                playMedia()
                
                self.addedTextViews.isHidden = false
                
                self.backBtn.isHidden = false
                self.textBtn.isHidden = false
                self.drawBtn.isHidden = false
                self.voiceOverBtn.isHidden = false
                self.musicListBtn.isHidden = false
                self.volumeBtn.isHidden = false
                self.nextBtn.isHidden = false
                
                self.deleteBtn.isHidden = true
            }
        }
    }
    
    var isTextSelected: Bool = false {
        didSet {
            if isTextSelected {
                
                pauseMedia()
                
                self.addedTextViews.isHidden = true
                
                self.doneBtn.isHidden = false
                self.backBtn.isHidden = true
                self.textBtn.isHidden = true
                self.drawBtn.isHidden = true
                self.voiceOverBtn.isHidden = true
                self.musicListBtn.isHidden = true
                self.volumeBtn.isHidden = true
                self.nextBtn.isHidden = true
                self.colorAndFontPickerView.isHidden = true
                
                self.deleteBtn.isHidden = true
                
                self.textEditingStack.isHidden = true
                
                self.frameContainerView.isHidden = false
            } else {
                
                playMedia()
                
                self.addedTextViews.isHidden = false
                
                self.doneBtn.isHidden = true
                self.backBtn.isHidden = false
                self.textBtn.isHidden = false
                self.drawBtn.isHidden = false
                self.voiceOverBtn.isHidden = false
                self.musicListBtn.isHidden = false
                self.volumeBtn.isHidden = false
                self.nextBtn.isHidden = false
                
                self.deleteBtn.isHidden = true
                
                self.frameContainerView.isHidden = true
            }
        }
    }
    
    private lazy var pointsDrawnArray: [[[DrawnPoints]]] = []
    private lazy var currentDrawnPoint: Int = 0
    
    let doneBtn = UIButton()
    
    let undoBtn = UIButton()
    
    let volumeBtn = UIButton()
    
    let musicListBtn = UIButton()
    
    //Voice Over functionality
    let voiceOverBtn = UIButton()
    
    let voiceOverVC = VoiceOverViewController()
    var voiceOverAudioVolume: Float = 1.0
    
    var videoURL: URL
    
    var videoAsset:AVAsset
    
    var uniqueId: String
    
    lazy var siteAudioURL: URL? = nil
    
    var draftVideos = false
    
    // This is an initializer
    init(videoURL: URL, uniqueId: String = UUID().uuidString) {
        self.videoURL = videoURL
        
        self.videoAsset = AVAsset(url: videoURL)
        
        self.uniqueId = uniqueId
        
        // Call the superclass's designated initializer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        if draftVideos {
            self.loadStateFromUserDefaults(uniqueId: uniqueId)
        }
        if trimmedVideoURL == nil {
            trimmedVideoURL = videoURL
        }
        
//        let tabBarHeight = self.tabBarController?.tabBar.frame.size.height ?? 0
//        self.view.frame.size.height -= tabBarHeight
        
        view.backgroundColor = .black
        
        // Define the URL of your video file
        //        if let videoAsset = createAVAssetFromData() {
        
        playerItem = AVPlayerItem(asset: videoAsset)
        
        // Create an AVPlayer with the video URL
        player = AVPlayer(playerItem: playerItem)
        player.volume = playerVolume
        
        // Create an AVPlayerLayer to display the video
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        player.actionAtItemEnd = .none
        
        // Set the frame to fit inside the safe area insets
        if let safeAreaInsets = view.superview?.safeAreaInsets {
            let topInset = safeAreaInsets.top
            let leftInset = safeAreaInsets.left
            let rightInset = safeAreaInsets.right
            let bottomInset = safeAreaInsets.bottom
            
            playerLayer.frame = CGRect(
                x: view.bounds.origin.x + leftInset,
                y: view.bounds.origin.y + topInset,
                width: view.bounds.width - (leftInset + rightInset),
                height: view.bounds.height - (topInset + bottomInset)
            )
        } else {
            // Set the frame and position of the playerLayer
            //                playerLayer.frame = view.bounds
            playerLayer.frame = CGRect(x: 0, y: 0, width: appWidth, height: view.frame.height-bottomSafeAreaHeight-75)
            //                playerLayer.frame.size.height = view.bounds.height-(bottomSafeAreaHeight-75)
        }
        
        // Add the playerLayer to your view's layer
        view.layer.addSublayer(playerLayer)
        
        // Add observer to monitor playback time
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            // Update progress slider based on current playback time
            
            self?.currentPlayerTime = time
        }

        self.view.addSubview(canvasImageView)
        canvasImageView.isUserInteractionEnabled = true
        let tapped = UITapGestureRecognizer(target: self, action: #selector(self.canvasImageViewTapped))
        canvasImageView.addGestureRecognizer(tapped)
        
        backBtn.setImage(UIImage(systemName: "chevron.left"), for: UIControl.State())
        backBtn.imageView?.tintColor = .white
        backBtn.frame = CGRect(x: 10, y: topSafeAreaHeight+15, width: 40, height: 40)
        backBtn.tintColor = UIColor.black.withAlphaComponent(0.3)
        backBtn.setBackgroundColor(color: UIColor.black.withAlphaComponent(0.3), forState: UIControl.State())
        backBtn.setTitleColor(.white, for: .normal)
        backBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        backBtn.layer.masksToBounds = true
        backBtn.layer.cornerRadius = backBtn.frame.height/2
        backBtn.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backBtn.isUserInteractionEnabled = true
        
        view.addSubview(backBtn)
        
        undoBtn.setTitle(NSLocalizedString("Undo", comment: ""), for: .normal)
        undoBtn.isHidden = true
        undoBtn.contentHorizontalAlignment = .leading
        undoBtn.frame = CGRect(x: 10, y: topSafeAreaHeight+10, width: 80, height: 40)
        undoBtn.tintColor = UIColor.clear
        undoBtn.setBackgroundColor(color: UIColor.clear, forState: UIControl.State())
        undoBtn.layer.shadowColor = UIColor.black.cgColor
        undoBtn.layer.shadowRadius = 6.0
        undoBtn.layer.shadowOpacity = 1.0
        undoBtn.layer.shadowOffset = CGSize(width: 0, height: 0)
        undoBtn.setTitleColor(.white, for: .normal)
        undoBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        undoBtn.layer.masksToBounds = true
        undoBtn.layer.cornerRadius = undoBtn.frame.height/2
        undoBtn.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        undoBtn.isUserInteractionEnabled = true
        
        view.addSubview(undoBtn)
        
        textBtn.setImage(UIImage(systemName: "textformat")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
        textBtn.imageView?.contentMode = .scaleAspectFit
        textBtn.frame = CGRect(x: appWidth-50, y: topSafeAreaHeight+15, width: 40, height: 40)
        textBtn.tintColor = UIColor.black.withAlphaComponent(0.3)
        textBtn.setBackgroundColor(color: UIColor.black.withAlphaComponent(0.3), forState: UIControl.State())
        textBtn.setTitleColor(.white, for: .normal)
        textBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        textBtn.layer.masksToBounds = true
        textBtn.layer.cornerRadius = backBtn.frame.height/2
        textBtn.addTarget(self, action: #selector(textButtonTapped), for: .touchUpInside)
        textBtn.isUserInteractionEnabled = true
        
        view.addSubview(textBtn)
        
        textEditingStack.frame = CGRect(x: 110, y: topSafeAreaHeight+10, width: appWidth-220, height: 40)
        textEditingStack.isHidden = true
        textEditingStack.alignment = .center
        view.addSubview(textEditingStack)
        
        textAlignmentBtn.setImage(UIImage(systemName: "text.aligncenter")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
        textAlignmentBtn.tag = 1
        textAlignmentBtn.imageView?.contentMode = .scaleAspectFit
        textAlignmentBtn.frame = CGRect(x: textEditingStack.bounds.midX - 30 - (30/2) - 10, y: 0, width: 30, height: 30)
        textAlignmentBtn.tintColor = UIColor.black.withAlphaComponent(0.3)
        textAlignmentBtn.setBackgroundColor(color: UIColor.black.withAlphaComponent(0.3), forState: UIControl.State())
        textAlignmentBtn.layer.masksToBounds = true
        textAlignmentBtn.layer.cornerRadius = textAlignmentBtn.frame.height/2
        textAlignmentBtn.addTarget(self, action: #selector(changeTextAlignment(_:)), for: .touchUpInside)
        textAlignmentBtn.isUserInteractionEnabled = true
        textEditingStack.addSubview(textAlignmentBtn)
        
        if #available(iOS 17.0, *) {
            textStyleBtn.setImage(UIImage(systemName: "lightspectrum.horizontal", withConfiguration: UIImage.SymbolConfiguration(pointSize: 38, weight: .regular, scale: .medium))?.withRenderingMode(.alwaysOriginal), for: UIControl.State())
        } else {
            textStyleBtn.setImage(UIImage(systemName: "paintpalette.fill")?.withRenderingMode(.alwaysOriginal), for: UIControl.State())
        }
        textStyleBtn.imageView?.contentMode = .scaleAspectFit
        textStyleBtn.frame = CGRect(x: textAlignmentBtn.frame.origin.x + textAlignmentBtn.frame.width + 10, y: 0, width: 30, height: 30)
        textStyleBtn.tintColor = UIColor.black.withAlphaComponent(0.3)
        textStyleBtn.setBackgroundColor(color: UIColor.black.withAlphaComponent(0.3), forState: UIControl.State())
        textStyleBtn.layer.masksToBounds = true
        textStyleBtn.layer.cornerRadius = textAlignmentBtn.frame.height/2
        textStyleBtn.addTarget(self, action: #selector(changeTextStyle(_:)), for: .touchUpInside)
        textStyleBtn.isUserInteractionEnabled = true
        textEditingStack.addSubview(textStyleBtn)
        
        textBackgroundBtn.setImage(UIImage(systemName: "textformat")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
        textBackgroundBtn.imageView?.contentMode = .scaleAspectFit
        textBackgroundBtn.frame = CGRect(x: textStyleBtn.frame.origin.x + textStyleBtn.frame.width + 10, y: 0, width: 30, height: 30)
        textBackgroundBtn.tintColor = UIColor.clear
        textBackgroundBtn.setBackgroundColor(color: UIColor.clear, forState: UIControl.State())
        textBackgroundBtn.layer.borderColor = UIColor.white.cgColor
        textBackgroundBtn.layer.borderWidth = 1.5
        textBackgroundBtn.layer.masksToBounds = true
        textBackgroundBtn.layer.cornerRadius = 5
        textBackgroundBtn.addTarget(self, action: #selector(changeTextBackground(_:)), for: .touchUpInside)
        textBackgroundBtn.isUserInteractionEnabled = true
        textEditingStack.addSubview(textBackgroundBtn)
        
        drawBtn.setImage(UIImage(systemName: "scribble")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
        drawBtn.imageView?.contentMode = .scaleAspectFit
        drawBtn.frame = CGRect(x: appWidth-100, y: topSafeAreaHeight+15, width: 40, height: 40)
        drawBtn.tintColor = UIColor.black.withAlphaComponent(0.3)
        drawBtn.setBackgroundColor(color: UIColor.black.withAlphaComponent(0.3), forState: UIControl.State())
        drawBtn.setTitleColor(.white, for: .normal)
        drawBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        drawBtn.layer.masksToBounds = true
        drawBtn.layer.cornerRadius = backBtn.frame.height/2
        drawBtn.addTarget(self, action: #selector(drawButtonTapped), for: .touchUpInside)
        drawBtn.isUserInteractionEnabled = true
        
        view.addSubview(drawBtn)
        
        musicListBtn.setImage(UIImage(systemName: "music.note.list")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
        musicListBtn.imageView?.contentMode = .scaleAspectFit
        musicListBtn.frame = CGRect(x: appWidth-150, y: topSafeAreaHeight+15, width: 40, height: 40)
        musicListBtn.tintColor = UIColor.black.withAlphaComponent(0.3)
        musicListBtn.setBackgroundColor(color: UIColor.black.withAlphaComponent(0.3), forState: UIControl.State())
        musicListBtn.setTitleColor(.white, for: .normal)
        musicListBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        musicListBtn.layer.masksToBounds = true
        musicListBtn.layer.cornerRadius = backBtn.frame.height/2
        musicListBtn.addTarget(self, action: #selector(openMusicView), for: .touchUpInside)
        musicListBtn.isUserInteractionEnabled = true
        
        view.addSubview(musicListBtn)
        
        voiceOverBtn.setImage(UIImage(systemName: "mic")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
        voiceOverBtn.imageView?.contentMode = .scaleAspectFit
//        voiceOverBtn.isHidden = true
//        voiceOverBtn.layer.opacity = 0.0
        voiceOverBtn.frame = CGRect(x: appWidth-200, y: topSafeAreaHeight+15, width: 40, height: 40)
        voiceOverBtn.tintColor = UIColor.black.withAlphaComponent(0.3)
        voiceOverBtn.setBackgroundColor(color: UIColor.black.withAlphaComponent(0.3), forState: UIControl.State())
        voiceOverBtn.setTitleColor(.white, for: .normal)
        voiceOverBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        voiceOverBtn.layer.masksToBounds = true
        voiceOverBtn.layer.cornerRadius = backBtn.frame.height/2
        voiceOverBtn.addTarget(self, action: #selector(voiceOverButtonTapped), for: .touchUpInside)
        voiceOverBtn.isUserInteractionEnabled = true
        
        view.addSubview(voiceOverBtn)
        
        volumeBtn.setImage(UIImage(systemName: "slider.horizontal.3")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
        volumeBtn.imageView?.contentMode = .scaleAspectFit
        volumeBtn.frame = CGRect(x: appWidth-250, y: topSafeAreaHeight+15, width: 40, height: 40)
        volumeBtn.tintColor = UIColor.black.withAlphaComponent(0.3)
        volumeBtn.setBackgroundColor(color: UIColor.black.withAlphaComponent(0.3), forState: UIControl.State())
        volumeBtn.setTitleColor(.white, for: .normal)
        volumeBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        volumeBtn.layer.masksToBounds = true
        volumeBtn.layer.cornerRadius = backBtn.frame.height/2
        volumeBtn.addTarget(self, action: #selector(volumeSettingsTapped), for: .touchUpInside)
        volumeBtn.isUserInteractionEnabled = true
        
        view.addSubview(volumeBtn)
        
        doneBtn.setTitle(NSLocalizedString("Done", comment: ""), for: .normal)
        doneBtn.isHidden = true
        doneBtn.frame = CGRect(x: appWidth-90, y: topSafeAreaHeight+10, width: 80, height: 40)
        doneBtn.contentHorizontalAlignment = .right
        doneBtn.tintColor = UIColor.clear
        doneBtn.setBackgroundColor(color: UIColor.clear, forState: UIControl.State())
        doneBtn.layer.shadowColor = UIColor.black.cgColor
        doneBtn.layer.shadowRadius = 6.0
        doneBtn.layer.shadowOpacity = 1.0
        doneBtn.layer.shadowOffset = CGSize(width: 0, height: 0)
        doneBtn.setTitleColor(.white, for: .normal)
        doneBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        doneBtn.layer.masksToBounds = true
        doneBtn.layer.cornerRadius = doneBtn.frame.height/2
        doneBtn.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        doneBtn.isUserInteractionEnabled = true
        
        view.addSubview(doneBtn)
        
        nextBtn.setTitle(NSLocalizedString("Next", comment: ""), for: .normal)
        nextBtn.frame = CGRect(x: (appWidth-100)/2, y: view.frame.height-bottomSafeAreaHeight-55, width: 100, height: 40)
        nextBtn.setBackgroundColor(color: buttonBackgroundColor, forState: UIControl.State())
        nextBtn.setTitleColor(.white, for: .normal)
        nextBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        nextBtn.layer.masksToBounds = true
        nextBtn.layer.cornerRadius = nextBtn.frame.height/2
        nextBtn.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        nextBtn.isUserInteractionEnabled = true
        
        view.addSubview(nextBtn)
        
        deleteBtn.setImage(UIImage(systemName: "trash")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
        deleteBtn.imageView?.contentMode = .scaleAspectFit
        deleteBtn.frame = CGRect(x: (appWidth-40)/2, y: view.frame.height-bottomSafeAreaHeight-50, width: 40, height: 40)
        deleteBtn.tintColor = UIColor.black.withAlphaComponent(0.3)
        deleteBtn.setBackgroundColor(color: UIColor.black.withAlphaComponent(0.3), forState: UIControl.State())
        deleteBtn.setTitleColor(.white, for: .normal)
        deleteBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        deleteBtn.layer.masksToBounds = true
        deleteBtn.layer.cornerRadius = backBtn.frame.height/2
        deleteBtn.isUserInteractionEnabled = true
        deleteBtn.isHidden = true
        
        view.addSubview(deleteBtn)
        
        voiceOverVC.userEditingVC = self
        
        if rangeDict.count>0 {
            self.frameContainerView.isHidden = true
            self.createRangeSlider()
            self.isTextSelected = false
        }
        
        if draftVideos {
            createColorAndFontPickerView(onlyColor: true)
            self.colorAndFontPickerView.isHidden = true
        }
        
        // Add observer for player item's end time
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        configureSliderView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        playMedia()
        colorAndFontPickerView.isHidden = true
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        self.extendedLayoutIncludesOpaqueBars = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.pauseMedia()
        self.navigationController?.navigationBar.isHidden = false
//        if let avasset = self.videoAsset as? AVURLAsset {
//            self.deleteFile(filePath: avasset.url)
//        }
//        if let videoFilePath = self.videoFilePath {
//            self.deleteFile(filePath: videoFilePath)
//        }
    }
    
    deinit {
        print("UserEditingVideoViewController deallocated")
    }
    
    @objc func playerDidFinishPlaying(notification: Notification) {
        // Seek to time zero when player finishes playing
        self.player?.seek(to: CMTime.zero)
        self.voiceOverVC.audioPlayer?.seek(to: .zero)
        self.audioPlayer?.currentTime = adjustedMusicDuration ?? 0
    }

    internal func playMedia(muteSiteAudio: Bool = false) {
        player.play()
        if muteSiteAudio {
            player.isMuted = true
            audioPlayer?.pause()
        } else {
            player.isMuted = false
            audioPlayer?.play()
        }
        voiceOverVC.audioPlayer?.play()
    }
    
    internal func pauseMedia() {
        player.pause()
        audioPlayer?.pause()
        voiceOverVC.audioPlayer?.pause()
    }
    
    @objc func backButtonTapped() {
        if videoIsEdited() || self.draftVideos {
            // Create your alert as usual
            let alertView = UIAlertController(title: NSLocalizedString("Discard Media?", comment: ""), message: NSLocalizedString("If you go back now, you will lose any changes that you've made.", comment: ""), preferredStyle: .alert)
            
            alertView.addAction(UIAlertAction(title: NSLocalizedString("Discard", comment: ""), style: .destructive, handler: { _ in
                //Remove all Audio files
                if !self.draftVideos {
                    for audioModel in self.voiceOverVC.audioArray {
                        DraftVideoManager.shared.deleteFromDocumentDirectory(uniqueId: self.uniqueId, fileName: audioModel.audioPath)
                    }
                }
                if let siteAudioURL = self.siteAudioURL,
                   siteAudioURL.lastPathComponent.contains("SiteMusicAudio") {
                    DraftVideoManager.shared.deleteFromDocumentDirectory(uniqueId: self.uniqueId, fileName: siteAudioURL.lastPathComponent)
                }
                self.goBack()
            }))
            
            alertView.addAction(UIAlertAction(title: NSLocalizedString("Save draft", comment: ""), style: .default, handler: { [weak self] _ in
                
                self?.animator.startAnimating()
                self?.view.isUserInteractionEnabled = false
                
                self?.saveStateToUserDefaults({ error in
                    
                    self?.animator.stopAnimating()
                    self?.view.isUserInteractionEnabled = true
                    
                    guard let error else {
                        
                        self?.goBack()
                        return
                    }
                    
                    print(error)
                    self?.view.makeToast(NSLocalizedString("Error while saving", comment: ""))
                    
                })
            }))

            // Add a cancel action
            alertView.addAction(UIAlertAction(title: NSLocalizedString("Continue editing", comment: ""), style: .default, handler: { _ in
                // Handle cancellation if needed
            }))

            // Show it to your users
            self.present(alertView, animated: true, completion: nil)
        } else {
            goBack()
        }
    }
    
    func goBack() {
        
        if let observer = voiceOverVC.timeObserver {
            self.player.removeTimeObserver(observer)
        }
        
        playSound(sound: "back")
        for controller in self.navigationController!.viewControllers as Array {
            if self.navigationController?.containsViewController(ofKind: CameraViewViewController.self) == true {
                if controller.isKind(of: CameraViewViewController.self) {
                    self.navigationController!.popToViewController(controller, animated: true)
                }
            } else if self.navigationController?.containsViewController(ofKind: VideoTabBarViewController.self) == true {
                if controller.isKind(of: VideoTabBarViewController.self) {
                    self.navigationController!.popToViewController(controller, animated: true)
                }
            }else {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
    }
    
    @objc func canvasImageViewTapped() {
        if self.isTextEditing {
            doneButtonTapped()
        }
    }
    
    @objc func doneButtonTapped() {
        // Handle the done button tap action here
        self.isDrawing = false
        self.isTextEditing = false
        self.isTextSelected = false
        self.adjustedMusic = false
        
        view.endEditing(true)
    }
    
    @objc func nextButtonTapped() {
        if !videoIsEdited() && !volumeBtn.isSelected { //If No changes done.
            let newVC = CreateVideoViewController()
            newVC.isFromTickVideo = true
            newVC.videoURL = self.videoURL
            newVC.song_id = 0
            self.navigationController?.pushViewController(newVC, animated: true)
            return
        }
        
        let newVC = CreateVideoViewController()
        newVC.isFromTickVideo = true
        newVC.song_id = 0
        newVC.userEditingVC = self
        self.navigationController?.pushViewController(newVC, animated: true)
        return
        
//        self.editVideoLayer()
    }
    
    @objc func drawButtonTapped() {
        
        if canvasImageView.image != nil {
            self.undoBtn.isHidden = false
        }
        
        createColorAndFontPickerView(onlyColor: true)
        
        canvasImageView.frame = playerLayer.bounds // Adjust size as needed
        canvasImageView.isUserInteractionEnabled = true
        
        isDrawing = true
    }
    
    @objc func changeTextAlignment(_ sender: UIButton) {
        sender.tag = sender.tag == 3 ? 0 : sender.tag+1
        
        sender.setImage(UIImage(systemName: sender.tag == 0 ? "text.alignleft" : sender.tag == 1 ? "text.aligncenter" : sender.tag == 2 ? "text.alignright" : "text.justify")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: .normal)
        activeTextView?.textAlignment = sender.tag == 0 ? .left : sender.tag == 1 ? .center : sender.tag == 2 ? .right : .justified
        
        activeTextView?.setNeedsDisplay()
    }
    
    @objc func changeTextStyle(_ sender: UIButton) {
        sender.tag = sender.tag == 0 ? 1 : 0 //: sender.tag == 1 ? 2 : 0
        
        if sender.tag == 2 {
//            textFontSlider.value = Float(activeTextView?.font?.pointSize ?? 30.0) // Initial value
//            if #available(iOS 17.0, *) {
//                sender.setImage(UIImage(systemName: "character.magnify")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
//            } else {
//                sender.setImage(UIImage(systemName: "textformat.size")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
//            }
//            textFontSlider.isHidden = false
//            colorsCollectionView.isHidden = true
//            fontCollectionView.isHidden = true
        } else if sender.tag == 1 {
            sender.setImage(UIImage(systemName: "character")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
//            textFontSlider.isHidden = true
            colorsCollectionView.isHidden = true
            fontCollectionView.isHidden = false
        } else {
            if #available(iOS 17.0, *) {
                sender.setImage(UIImage(systemName: "lightspectrum.horizontal", withConfiguration: UIImage.SymbolConfiguration(pointSize: 38, weight: .regular, scale: .medium))?.withRenderingMode(.alwaysOriginal), for: UIControl.State())
            } else {
                sender.setImage(UIImage(systemName: "paintpalette.fill")?.withRenderingMode(.alwaysOriginal), for: UIControl.State())
            }
//            textFontSlider.isHidden = true
            colorsCollectionView.isHidden = false
            fontCollectionView.isHidden = true
        }
    }

    @objc func changeTextBackground(_ sender: UIButton) {
        sender.tag = sender.tag == 5 ? 0 : sender.tag+1
        
        if (sender.tag==1 && activeTextView?.textColor == .black) || (sender.tag==3 && activeTextView?.textColor == .white) {
            sender.tag += 1
        }
        
        sender.tintColor = sender.tag==0 ? .clear : UIColor.black.withAlphaComponent(0.3)
        sender.setBackgroundColor(color: sender.tag==0 ? .clear : UIColor.black.withAlphaComponent(0.3), forState: UIControl.State())
        
        self.setAttributedText()
    }
    
    func setAttributedText() {
                
        let textColor = activeTextView?.textColor ?? textColor
        let tag = textBackgroundBtn.tag
        
        let bwColor: UIColor = textColor == .white ? .black.withAlphaComponent(0.3) : .white.withAlphaComponent(0.3)
//        let uiColor: UIColor = textBackgroundBtn.tag==1 ? bwColor : textBackgroundBtn.tag==2 ? textColor.withAlphaComponent(0.3) : .clear
        let uiColor: UIColor = tag==1 ? .black : tag==2 ? .black.withAlphaComponent(0.3) : tag==3 ? .white : tag==4 ? .white.withAlphaComponent(0.3) : .clear

        activeTextView?.customBackgroundColor = uiColor

        // Create an attributed string
        let attributedString = NSMutableAttributedString(attributedString: activeTextView?.attributedText ?? NSAttributedString(string: ""))
        
        let range = NSRange(location: 0, length: attributedString.length) // Adjust the range as needed

        // Set the background color for the entire text view
//        attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: uiColor, range: range)

        // Set the shadow color
        let shadow = NSShadow()
        shadow.shadowColor = textBackgroundBtn.tag==5 ? bwColor : UIColor.clear // Change to your desired shadow color
        shadow.shadowOffset = CGSize(width: 1.0, height: 1.0) // Change to your desired shadow offset
        shadow.shadowBlurRadius = 0.0 // Change to your desired shadow blur radius
        attributedString.addAttribute(NSAttributedString.Key.shadow, value: shadow, range: NSRange(location: 0, length: attributedString.length))
        
        // Set the attributed text to the text view
        activeTextView?.attributedText = attributedString
        
        activeTextView?.setNeedsDisplay() // Updates Draw Rect Method of UITextView
    }
    
    @objc func textButtonTapped() {
        
        var count = 1
        for subViews in canvasImageView.subviews {
            if let _ = subViews as? UITextView {
                count += 1
            }
        }
        
        self.textAlignmentBtn.setImage(UIImage(systemName: "text.aligncenter")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
        if #available(iOS 17.0, *) {
            textStyleBtn.setImage(UIImage(systemName: "lightspectrum.horizontal", withConfiguration: UIImage.SymbolConfiguration(pointSize: 38, weight: .regular, scale: .medium))?.withRenderingMode(.alwaysOriginal), for: UIControl.State())
        } else {
            textStyleBtn.setImage(UIImage(systemName: "paintpalette.fill")?.withRenderingMode(.alwaysOriginal), for: UIControl.State())
        }
        
        self.isTextEditing = true
        
        createColorAndFontPickerView(onlyColor: true)
        
        let textView = CustomPaddingTextView(frame: CGRect(x: textPadding, y: 120, width: appWidth-(textPadding*2), height: 50))
        textView.textAlignment = .center
        textView.font = UIFont(name: "Helvetica", size: isIpad ? 30 : 26)
        textView.textColor = textColor
        textView.layer.shadowColor = UIColor.black.cgColor
        textView.layer.shadowOffset = CGSize(width: 1.0, height: 0.0)
        textView.layer.shadowOpacity = 0.2
        textView.layer.shadowRadius = 1.0
        textView.layer.backgroundColor = UIColor.clear.cgColor
        textView.backgroundColor = .clear
        textView.autocorrectionType = .default
        textView.isScrollEnabled = false
        textView.delegate = self
        textView.tag = count
        self.canvasImageView.addSubview(textView)
        canvasImageView.frame = playerLayer.bounds // Adjust size as needed
        canvasImageView.isUserInteractionEnabled = true
        addGestures(view: textView)
        textView.becomeFirstResponder()
        
        setAttributedText()
        
    }
    
    func addGestures(view: UIView) {
        //Gestures
        view.isUserInteractionEnabled = true
        
        let panGesture = UIPanGestureRecognizer(target: self,
                                                action: #selector(self.panGesture))
//        panGesture.minimumNumberOfTouches = 1
//        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self,
                                                    action: #selector(self.pinchGesture))
        pinchGesture.delegate = self
        view.addGestureRecognizer(pinchGesture)
        
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self,
                                                                    action:#selector(self.rotationGesture) )
        rotationGestureRecognizer.delegate = self
        rotationGestureRecognizer.delegate = self
        view.addGestureRecognizer(rotationGestureRecognizer)
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(PhotoEditorViewController.tapGesture))
//        view.addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGesture))
        view.addGestureRecognizer(longPressGesture)
        
    }
    
    func createColorAndFontPickerView(onlyColor: Bool = false, onlyFont: Bool = false) {
        
//        configureSliderView()
        configureColorsCollectionView()
        configureFontsCollectionView()
        
//        textFontSlider.isHidden = true
        colorsCollectionView.isHidden = onlyFont ? true : false
        fontCollectionView.isHidden = onlyColor ? true : false
        
//        let tabBarHeight = self.tabBarController?.tabBar.frame.size.height ?? 0
        colorAndFontPickerView.frame = CGRect(x: 0, y: view.frame.height-bottomSafeAreaHeight-45, width: appWidth, height: 45)
        colorAndFontPickerView.isHidden = false
        
        colorsCollectionView.frame = CGRect(x: 0, y: 0, width: appWidth, height: 30)
        fontCollectionView.frame = CGRect(x: 0, y: 0, width: appWidth, height: 45)
        
//        colorAndFontPickerView.addSubview(textFontSlider)
        colorAndFontPickerView.addSubview(colorsCollectionView)
        colorAndFontPickerView.addSubview(fontCollectionView)
        
        view.addSubview(colorAndFontPickerView)
    }
    
    @objc func keyboardWillChangeFrame(_ notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
//            let tabBarHeight = self.tabBarController?.tabBar.frame.size.height ?? 0
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.colorAndFontPickerView.frame.origin.y = view.frame.height-bottomSafeAreaHeight-45
            } else {
                self.colorAndFontPickerView.isHidden = false
                self.colorAndFontPickerView.frame.origin.y = UIScreen.main.bounds.size.height-(endFrame?.size.height ?? 0.0)-45
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    private func newOverlayLayer(textFrame: CGRect, text: String, textFont: UIFont, textColor: CGColor) -> CATextLayer {
        
        let textLayer = CATextLayer()
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
        textLayer.font = textFont
        textLayer.frame = textFrame
        textLayer.string = text
        textLayer.foregroundColor = textColor
        
        return textLayer
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
    
    func videoIsEdited() -> Bool {
        if voiceOverVC.audioArray.count > 0 { // Voice Over if Added.
            return true
        }
        if canvasImageView.subviews.count > 0 {
            for subViews in canvasImageView.subviews { // Text layer if Added.
                if let _ = subViews as? UITextView {
                    return true
                }
            }
        } else if canvasImageView.image != nil { // Canvas Drawn
            return true
        } else if adjustedMusicDuration != nil { // Site Audio Added
            return true
        } else if player.volume < 1.0 || (voiceOverVC.audioPlayer?.volume ?? 1.0) < 1.0 || (audioPlayer?.volume ?? 1.0) < 1.0 {
            return true
        }
        return false
    }
    
    func editVideoLayer() {
        
        DraftVideoManager.shared.editVideoLayer(userEditingVC: self, currentView: self, completion: { url in
            self.navigationController?.pushViewController(UserEditingVideoViewController(videoURL: url), animated: true)

//            //Remove all Audio files
//            for audioModel in self.voiceOverVC.audioArray {
//                FileManager.default.removeItemIfExisted(audioModel.audioPath)
//            }
//
//            let newVC = CreateVideoViewController()
//            newVC.isFromTickVideo = true
//            newVC.videoURL = url
//            newVC.song_id = 0
//            self.navigationController?.pushViewController(newVC, animated: true)
        })
    }
}

extension UserEditingVideoViewController {
    fileprivate func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        switch [transform.a, transform.b, transform.c, transform.d] {
        case [0.0, 1.0, -1.0, 0.0]:
            assetOrientation = .up
            isPortrait = true
            
        case [0.0, -1.0, 1.0, 0.0]:
            assetOrientation = .down
            isPortrait = true
            
        case [1.0, 0.0, 0.0, 1.0]:
            assetOrientation = .right
            
        case [-1.0, 0.0, 0.0, -1.0]:
            assetOrientation = .left
            
        case [0.0, 1.0, 1.0, 0.0]:
            assetOrientation = .upMirrored
            isPortrait = true
            
        case [0.0, -1.0, -1.0, 0.0]:
            assetOrientation = .downMirrored
            isPortrait = true
            
        case [-1.0, 0.0, 0.0, 1.0]:
            assetOrientation = .rightMirrored
            
        case [1.0, 0.0, 0.0, -1.0]:
            assetOrientation = .leftMirrored
            
        default:
            break
        }
        return (assetOrientation, isPortrait)
    }
    
    fileprivate func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset, standardSize:CGSize, atTime: CMTime) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform: transform)
        
        var aspectFillRatio:CGFloat = 1
        if assetTrack.naturalSize.height < assetTrack.naturalSize.width {
            aspectFillRatio = standardSize.height / assetTrack.naturalSize.height
        } else {
            aspectFillRatio = standardSize.width / assetTrack.naturalSize.width
        }
        
        if assetInfo.isPortrait {
            let scaleFactor = CGAffineTransform(scaleX: aspectFillRatio, y: aspectFillRatio)
            
            let posX = standardSize.width/2 - (assetTrack.naturalSize.height * aspectFillRatio)/2
            let posY = standardSize.height/2 - (assetTrack.naturalSize.width * aspectFillRatio)/2
            let moveFactor = CGAffineTransform(translationX: posX, y: posY)
            
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(moveFactor), at: atTime)
            
        } else {
            let scaleFactor = CGAffineTransform(scaleX: aspectFillRatio, y: aspectFillRatio)
            
            let posX = standardSize.width/2 - (assetTrack.naturalSize.width * aspectFillRatio)/2
            let posY = standardSize.height/2 - (assetTrack.naturalSize.height * aspectFillRatio)/2
            let moveFactor = CGAffineTransform(translationX: posX, y: posY)
            
            let concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(moveFactor)
            
            //            if assetInfo.orientation == .down {
            //                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
            //                concat = fixUpsideDown.concatenating(scaleFactor).concatenating(moveFactor)
            //            }
            
            instruction.setTransform(concat, at: atTime)
        }
        return instruction
    }
}

extension UserEditingVideoViewController: ColorDelegate, FontStyleDelegate {
    
    @objc func sliderTouchDown() {
        
        UIView.animate(withDuration: 0.3) {
            self.textFontSlider.frame.origin.x = 5
        }
        
    }
    
    @objc func sliderTouchInsideOutside() {
        
        UIView.animate(withDuration: 0.3) {
            self.textFontSlider.frame.origin.x = -12.5
        }
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        // Handle slider value change
        print("Slider value: \(sender.value)")
        
        activeTextView?.font = activeTextView?.font?.withSize(CGFloat(sender.value))
        
        let sizeToFit = activeTextView?.sizeThatFits(CGSize(width: activeTextView?.frame.width ?? (UIScreen.main.bounds.size.width-(textPadding*2)),
                                                     height:CGFloat.greatestFiniteMagnitude))
        activeTextView?.bounds.size = CGSize(width: activeTextView?.frame.width ?? (UIScreen.main.bounds.size.width-(textPadding*2)),
                                             height: sizeToFit?.height ?? UIScreen.main.bounds.size.height)
        
        activeTextView?.setNeedsDisplay()
    }
    
    func configureSliderView() {
        textFontSlider.frame = CGRect(x: 100, y: 0, width: 200, height: 25)
        textFontSlider.isHidden = true
        
        // Set slider properties
        textFontSlider.minimumValue = 10 // Minimum value
        textFontSlider.maximumValue = 60 // Maximum value
        textFontSlider.value = Float(activeTextView?.font?.pointSize ?? 30.0) // Initial value
        textFontSlider.isContinuous = true // Continuous value update
        
        textFontSlider.minimumTrackTintColor = .clear
        textFontSlider.maximumTrackTintColor = .clear
        
        textFontSlider.tintColor = .white.withAlphaComponent(0.5)
        
        textFontSlider.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)
        textFontSlider.addTarget(self, action: #selector(sliderTouchInsideOutside), for: .touchUpInside)
        textFontSlider.addTarget(self, action: #selector(sliderTouchInsideOutside), for: .touchUpOutside)
        
        // Add an action for value change
        textFontSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        textFontSlider.transform = CGAffineTransformMakeRotation(.pi * 1.5)
        
        textFontSlider.frame.origin = CGPoint(x: 5, y: 80)
        
        UIView.animate(withDuration: 0.3) {
            self.textFontSlider.frame.origin.x = -12.5
        }
        
        self.view.addSubview(textFontSlider)
    }
    
    func configureColorsCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 30, height: 30)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        colorsCollectionView.collectionViewLayout = layout
        colorsCollectionView.backgroundColor = .clear
        colorsCollectionView.showsHorizontalScrollIndicator = false
        colorsCollectionView.showsVerticalScrollIndicator = false
        colorsCollectionViewDelegate = ColorsCollectionViewDelegate()
        colorsCollectionViewDelegate.colorDelegate = self
        if !colors.isEmpty {
            colorsCollectionViewDelegate.colors = colors
        }
        colorsCollectionView.delegate = colorsCollectionViewDelegate
        colorsCollectionView.dataSource = colorsCollectionViewDelegate
        
        colorsCollectionView.register(
            UINib(nibName: "ColorCollectionViewCell", bundle: Bundle(for: ColorCollectionViewCell.self)),
            forCellWithReuseIdentifier: "ColorCollectionViewCell")
    }
    
    func configureFontsCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 45, height: 45)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 7
        layout.minimumLineSpacing = 7
        fontCollectionView.collectionViewLayout = layout
        fontCollectionView.backgroundColor = .clear
        fontCollectionViewDelegate = FontDelegate()
        fontCollectionViewDelegate.sendfontDelegate = self
        if !modelReference.isEmpty {
            fontCollectionViewDelegate.modelReference = modelReference
        }
        fontCollectionView.delegate = fontCollectionViewDelegate
        fontCollectionView.dataSource = fontCollectionViewDelegate
        
        fontCollectionView.register(
            UINib(nibName: "FontCell", bundle: Bundle(for: FontCell.self)),
            forCellWithReuseIdentifier: "FontCell")
    }
    
    func didSelectColor(color: UIColor) {
        if isDrawing {
            self.drawColor = color
        } else if let textView = activeTextView {
            // Get the selected range of text
            guard let selectedRange = textView.selectedTextRange, !selectedRange.isEmpty else {
                textView.textColor = color
                return
            }
            
            // Get the start and end positions of the selected range
            let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            let end = textView.offset(from: textView.beginningOfDocument, to: selectedRange.end)
            
            // Create an attributed string with the selected range
            let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
            attributedString.addAttribute(.foregroundColor, value: color, range: NSRange(location: start, length: end - start))
            
            // Apply the attributed string with color to the selected range
            textView.attributedText = attributedString
            
            // Update the text color property (optional)
            textColor = color
        }
    }
    
    func didSelectFont(selectfont: String, fontUrl: String) {
        if activeTextView != nil {
            print(fontUrl)
            activeTextView?.fontURLString = fontUrl
            self.loadFontOnTextView(fontUrl: fontUrl)
        }
    }
    
    func loadFontOnTextView(fontUrl: String, adjustBounds: Bool = true) {
        if let url = URL(string: fontUrl) {
            let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Failed to load font data:", error)
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                let dataProvider = CGDataProvider(data: data as CFData)
                guard let cgFont = CGFont(dataProvider!) else {
                    print("Failed to create CGFont")
                    return
                }
                
                var error: Unmanaged<CFError>?
                if !CTFontManagerRegisterGraphicsFont(cgFont, &error) {
                    if let fontName = cgFont.postScriptName as String? {
                        DispatchQueue.main.async {
                            self.activeTextView?.font = UIFont(name: fontName, size: self.activeTextView?.font?.pointSize ?? 30.0)!
                            self.lastTextViewFont = UIFont(name: fontName, size: self.activeTextView?.font?.pointSize ?? 30.0)!
                                                            
                            let sizeToFit = self.activeTextView?.sizeThatFits(CGSize(width: self.activeTextView?.frame.width ?? (UIScreen.main.bounds.size.width-(self.textPadding*2)),
                                                                         height:CGFloat.greatestFiniteMagnitude))

                            if adjustBounds {
                                self.activeTextView?.bounds.size = CGSize(width: self.activeTextView?.frame.width ?? (UIScreen.main.bounds.size.width-(self.textPadding*2)),
                                                                          height: sizeToFit?.height ?? UIScreen.main.bounds.size.height)
                            }
                            
                            self.activeTextView?.setNeedsDisplay()
                        }
                    } else {
                        print("Failed to get font name")
                    }
                } else {
                    print("Failed to register font")
                }
            }
            task.resume()
        } else {
            print("Invalid URL")
        }

    }
    
    override public func touchesBegan(_ touches: Set<UITouch>,
                                      with event: UIEvent?){
        if isDrawing {
            swiped = false
            self.undoBtn.isHidden = true
            self.doneBtn.isHidden = true
            if let touch = touches.first {
                lastPoint = touch.location(in: self.canvasImageView)
            }
        }
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDrawing {
            if canvasImageView.image != nil {
                self.undoBtn.isHidden = false
            }
            self.doneBtn.isHidden = false
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>,
                                      with event: UIEvent?){
        if isDrawing {
            // 6
            swiped = true
            if let touch = touches.first {
                let currentPoint = touch.location(in: canvasImageView)
                drawLineFrom(lastPoint, toPoint: currentPoint)

                if (self.currentDrawnPoint > pointsDrawnArray.count) || pointsDrawnArray.count == 0 {
                    // If currentDrawnPoint is greater than the count of pointsDrawnArray, append a new array
                    let points: [DrawnPoints] = [DrawnPoints(x: lastPoint.x, y: lastPoint.y, color: drawColor.toHexString()), DrawnPoints(x: currentPoint.x, y: currentPoint.y, color: drawColor.toHexString())]
                    pointsDrawnArray.append([points])
                    self.currentDrawnPoint = pointsDrawnArray.count
                    
                    self.doneBtn.isHidden = false
                    self.undoBtn.isHidden = false
                    
                } else if self.currentDrawnPoint > 0 && self.currentDrawnPoint <= pointsDrawnArray.count {
                    var drawnArray = pointsDrawnArray[self.currentDrawnPoint - 1]
                    let points: [DrawnPoints] = [DrawnPoints(x: lastPoint.x, y: lastPoint.y, color: drawColor.toHexString()), DrawnPoints(x: currentPoint.x, y: currentPoint.y, color: drawColor.toHexString())]
                    drawnArray.append(points)
                    pointsDrawnArray[self.currentDrawnPoint - 1] = drawnArray
                }
                                   
                self.doneBtn.isHidden = true
                self.undoBtn.isHidden = true
                // 7
                lastPoint = currentPoint
            }
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>,
                                      with event: UIEvent?){
        if isDrawing {
            self.doneBtn.isHidden = false
            self.undoBtn.isHidden = false
            if !swiped {
                // draw a single point
                drawLineFrom(lastPoint, toPoint: lastPoint)
                let points: [DrawnPoints] = [DrawnPoints(x: lastPoint.x, y: lastPoint.y, color: drawColor.toHexString()), DrawnPoints(x: lastPoint.x, y: lastPoint.y, color: drawColor.toHexString())]
                pointsDrawnArray.append([points])
            }
            currentDrawnPoint = pointsDrawnArray.count+1
        }
    }
    
    func drawLineFrom(_ fromPoint: CGPoint, toPoint: CGPoint, pointColor: CGColor? = nil) {
        autoreleasepool { // Used autoreleasepool for memory issue handling
            let canvasSize = canvasImageView.frame.integral.size
            UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0)
            if let context = UIGraphicsGetCurrentContext() {
                canvasImageView.image?.draw(in: CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height))
                context.move(to: CGPoint(x: fromPoint.x, y: fromPoint.y))
                context.addLine(to: CGPoint(x: toPoint.x, y: toPoint.y))
                context.setLineCap(CGLineCap.round)
                context.setLineWidth(5.0)
                context.setStrokeColor(pointColor ?? drawColor.cgColor)
                context.setBlendMode(CGBlendMode.normal)
                context.strokePath()
                canvasImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            }
            UIGraphicsEndImageContext()
        }
    }
    
//    @objc func clearButtonTapped() {
//        // Set the canvas image to the last saved state
//        canvasImageView.image = nil
//        self.undoBtn.isHidden = true
//    }
    
    @objc func undoButtonTapped() {
        
        if adjustedMusic { // Image Handle
            
            audioPlayer = nil
            adjustedMusicDuration = nil
            
            removeTextButtons(tag: 4161)
            
            //NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
            siteAudioURL = nil

            self.adjustMusicView.removeFromSuperview()
            self.adjustMusicScrollView.removeFromSuperview()
            
            adjustedMusic = false
            
        } else { // Drawn Canvase
            
            // Set the canvas image to the last saved state
            canvasImageView.image = nil
            
            guard pointsDrawnArray.count >= 1 else {
                return
            }
            // Remove an element from pointsDrawnArray
            pointsDrawnArray.remove(at: pointsDrawnArray.count - 1)
            self.currentDrawnPoint = pointsDrawnArray.count+1
            
            if pointsDrawnArray.count == 0 {
                self.undoBtn.isHidden = true
            }
            self.drawImageThroughPoints()
        }
    }
    
    func drawImageThroughPoints() {
        // Iterate through pointsDrawnArray to draw lines
        for index in pointsDrawnArray {
            for points in index {
                if let startPoint = points.first,
                   let endPoint = points.last {
                    drawLineFrom(CGPoint(x: startPoint.x, y: startPoint.y), toPoint: CGPoint(x: endPoint.x, y: endPoint.y), pointColor: hexStringToUIColor(hex: startPoint.color).cgColor)
                }
            }
        }
    }
}

extension UserEditingVideoViewController: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        isMagnifyingGlassActive = true
    }
    func textViewDidChange(_ textView: UITextView) {
        let rotation = atan2(textView.transform.b, textView.transform.a)
        if rotation == 0 {
            let oldFrame = textView.frame
            let sizeToFit = textView.sizeThatFits(CGSize(width: oldFrame.width, height:CGFloat.greatestFiniteMagnitude))
            textView.frame.size = CGSize(width: oldFrame.width, height: sizeToFit.height)
        }
        
        self.setAttributedText()
    }
    func textViewDidBeginEditing(_ textView: UITextView) {

        lastTextViewTransform =  textView.transform
        lastTextViewTransCenter = textView.center
        lastTextViewFont = textView.font ?? UIFont(name: "Helvetica", size: isIpad ? 30 : 26)
        if let customTextView = textView as? CustomPaddingTextView {
            activeTextView = customTextView
        }
        textView.superview?.bringSubviewToFront(textView)
        textView.setNeedsDisplay()
        //textView.font = UIFont(name: "Helvetica", size: 30)
        UIView.animate(withDuration: 0.3,
                       animations: {
            textView.transform = CGAffineTransform.identity
            textView.center = CGPoint(x: UIScreen.main.bounds.width / 2,
                                      y: 200)
            textView.setNeedsDisplay()
        }, completion: nil)
        
        self.isTextEditing = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        isMagnifyingGlassActive = false
        
        self.isTextEditing = false
        
        if textView.text.isEmpty {
            textView.removeFromSuperview()
            rangeDict.removeValue(forKey: textView.tag)
        } else {
            // Check if a UIButton with the same tag already exists
            if let existingButton = addedTextViews.subviews.compactMap({ $0 as? UIButton }).first(where: { $0.tag == textView.tag }) {
                
                // You can update its properties here if needed
                existingButton.setTitle(textView.text, for: .normal)
                
                let adjustedXOrigin = existingButton.frame.origin.x
                let buttonPreviousWidth = existingButton.frame.width
                
                existingButton.sizeToFit()
                existingButton.frame.size.width += 10
                existingButton.frame.size.height = 30
                
                // Adjust button width if it exceeds the maximum
                if existingButton.frame.width > 150 {
                    existingButton.frame.size.width = 150
                } else if existingButton.frame.width < 30 {
                    existingButton.frame.size.width = 30
                }
                existingButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
                
                let diffWidth = abs(buttonPreviousWidth-existingButton.frame.width)

                // Remove subviews with x origin greater than adjusted x origin
                for subview in addedTextViews.subviews {
                    if subview.frame.origin.x > adjustedXOrigin {
                        subview.frame.origin.x -=  diffWidth
                    }
                }

                // Adjust content size
                addedTextViews.contentSize = CGSize(width: max(addedTextViews.contentSize.width - diffWidth, appWidth), height: addedTextViews.frame.height)
                
            } else {
                self.addTextButtons(textView: textView)
            }
        }
        
        guard lastTextViewTransform != nil && lastTextViewTransCenter != nil && lastTextViewFont != nil
        else {
            return
        }
        //activeTextView = nil
        //textView.font = self.lastTextViewFont!
        UIView.animate(withDuration: 0.3,
                       animations: {
            textView.transform = self.lastTextViewTransform!
            textView.center = self.lastTextViewTransCenter!
            textView.setNeedsDisplay()
        }, completion: nil)
    }
    
    func addTextButtons(textView: UITextView) {
        
        var xOrigin: CGFloat = 0.0
        
        var uiButton: UIButton?
        
        if let buttonWithGreatestXOrigin = addedTextViews.subviews
            .compactMap({ $0 as? UIButton })
            .max(by: { $0.frame.origin.x < $1.frame.origin.x }) {
            if buttonWithGreatestXOrigin.frame.origin.x > 0 {
                // The UIButton subview with the greatest x origin that satisfies the threshold
                uiButton = buttonWithGreatestXOrigin
            }
        }

        if let lastSubview = uiButton {
            xOrigin = lastSubview.frame.origin.x + lastSubview.frame.width
        } else if xOrigin == 0 {
            self.view.addSubview(addedTextViews)
        }
        
        // A button with the same tag does not exist, create a new one
        let button = UIButton(type: .system)
        button.frame = CGRect(x: xOrigin + 10, y: 0, width: 80, height: 30)
        button.setTitle(textView.text, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.titleLabel?.numberOfLines = 1
        button.layer.cornerRadius = button.frame.height / 2
        button.layer.masksToBounds = true
        button.tintColor = UIColor.black.withAlphaComponent(0.3)
        button.setBackgroundColor(color: UIColor.black.withAlphaComponent(0.3), forState: UIControl.State())
        button.tag = textView.tag
        button.sizeToFit()
        button.frame.size.width += 10
        button.frame.size.height = 30
        
        button.addTarget(self, action: #selector(self.textViewTapped(_:)), for: .touchUpInside)
        
        // Adjust button width if it exceeds the maximum
        if button.frame.width > 150 {
            button.frame.size.width = 150
        } else if button.frame.width < 30 {
            button.frame.size.width = 30
        }
        button.titleEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        addedTextViews.addSubview(button)
        
        let contentWidth = xOrigin+10+button.frame.width
        addedTextViews.contentSize = CGSize(width: contentWidth>appWidth ? contentWidth : appWidth, height: addedTextViews.frame.height)
    }
    
    func removeTextButtons(tag: Int) {
        guard let buttonToRemove = addedTextViews.subviews.compactMap({ $0 as? UIButton }).first(where: { $0.tag == tag }) else {
            return // No button with the specified tag found
        }

        let adjustedXOrigin = buttonToRemove.frame.origin.x
        
        let buttonWidth = buttonToRemove.frame.width+10

        // Remove button
        buttonToRemove.removeFromSuperview()

        // Remove subviews with x origin greater than adjusted x origin
        for subview in addedTextViews.subviews {
            if subview.frame.origin.x > adjustedXOrigin {
                subview.frame.origin.x -=  buttonWidth
            }
        }

        // Adjust content size
        addedTextViews.contentSize = CGSize(width: max(addedTextViews.contentSize.width - buttonWidth, appWidth), height: addedTextViews.frame.height)
        
        // Remove addedTextViews if it contains no more subviews
        if addedTextViews.subviews.isEmpty {
            addedTextViews.removeFromSuperview()
        }
    }
}

extension UserEditingVideoViewController: UIGestureRecognizerDelegate {
    
    /**
     UIPanGestureRecognizer - Moving Objects
     Selecting transparent parts of the imageview won't move the object
     */
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        if let view = recognizer.view {
            if view is UIImageView {
                // Tap only on visible parts of the image
                if recognizer.state == .began {
                    for imageView in subImageViews(view: canvasImageView) {
                        let location = recognizer.location(in: imageView)
                        let alpha = imageView.alphaAtPoint(location)
                        if alpha > 0 {
                            imageViewToPan = imageView
                            break
                        }
                    }
                }
                if imageViewToPan != nil {
                    moveView(view: imageViewToPan!, recognizer: recognizer)
                }
            } else {
                if !isMagnifyingGlassActive {
                    moveView(view: view, recognizer: recognizer)
                }
            }
        }
    }
    
    /**
     UIPinchGestureRecognizer - Pinching Objects
     If it's a UITextView will make the font bigger so it doen't look pixlated
     */
    @objc func pinchGesture(_ recognizer: UIPinchGestureRecognizer) {
        self.view.endEditing(true)
        self.isTextMoving = true
        if let view = recognizer.view {
            if view is UITextView {
                let textView = view as! UITextView
//                let font = UIFont(name: textView.font!.fontName, size: textView.font!.pointSize * recognizer.scale)
//                textView.font = font
//                textFontSlider.value = Float(activeTextView?.font?.pointSize ?? 30.0) // Initial value
//                if recognizer.state == .ended {
//                    //let newTextFrame = calculateNewTextViewFrame(textView: textView)
//                    textView.bounds.size = textView.frame.size
//                }
                textView.transform = textView.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
                textView.setNeedsDisplay()
            } else {
                view.transform = view.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
                view.setNeedsDisplay()
            }
            recognizer.scale = 1
        }
        
        if recognizer.state == .ended {
            self.isTextMoving = false
        }
    }

    func calculateNewTextViewFrame(textView: UITextView) -> CGRect {
        // Here, you can calculate the new frame of the text view based on its content size, if needed.
        // For example:
//        let sizeToFit = textView.sizeThatFits(CGSize(width: oldFrame.width, height:CGFloat.greatestFiniteMagnitude))
//        textView.frame.size = CGSize(width: oldFrame.width, height: sizeToFit.height)
        let newSize = textView.sizeThatFits(CGSize(width: textView.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
        let newFrame = CGRect(origin: textView.frame.origin, size: CGSize(width: textView.bounds.size.width, height: newSize.height))
        return newFrame
    }
    
    /**
     UIRotationGestureRecognizer - Rotating Objects
     */
    @objc func rotationGesture(_ recognizer: UIRotationGestureRecognizer) {
        if let view = recognizer.view {
            view.transform = view.transform.rotated(by: recognizer.rotation)
            view.setNeedsDisplay()
            recognizer.rotation = 0
        }
    }
    
    /**
     UITapGestureRecognizer - Taping on Objects
     Will make scale scale Effect
     Selecting transparent parts of the imageview won't move the object
     */
    @objc func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if let view = recognizer.view {
            if view is UIImageView {
                //Tap only on visible parts on the image
                for imageView in subImageViews(view: canvasImageView) {
                    let location = recognizer.location(in: imageView)
                    let alpha = imageView.alphaAtPoint(location)
                    if alpha > 0 {
                        scaleEffect(view: imageView)
                        break
                    }
                }
            } else {
                scaleEffect(view: view)
            }
        }
    }
    
    @objc func longPressGesture(_ recognizer: UILongPressGestureRecognizer) {
        if let view = recognizer.view as? UITextView,
           !isTextMoving {
            showTextSelectedPortion(view)
        }
    }
    
    @objc func textViewTapped(_ sender: UIButton) {
        for subviews in self.canvasImageView.subviews {
            if let textview = subviews as? UITextView,
               sender.tag == textview.tag {
                showTextSelectedPortion(textview)
            }
        }
    }
    
    func showTextSelectedPortion(_ view: UITextView) {
        if let customTextView = view as? CustomPaddingTextView {
            activeTextView = customTextView
        }
        rangeSlider.lowerValue = 0
        rangeSlider.upperValue = 100
        if self.view.contains(frameContainerView) {
            rangeSliderSelectedPortion(tag: view.tag)
        } else {
            self.view.addSubview(frameContainerView)
            createRangeSlider()
        }
    }
    
    /*
     Support Multiple Gesture at the same time
     */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    @objc func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        //        if recognizer.state == .recognized {
        //            if !stickersVCIsVisible {
        //                addStickersViewController()
        //            }
        //        }
    }
    
    // to Override Control Center screen edge pan from bottom
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    /**
     Scale Effect
     */
    func scaleEffect(view: UIView) {
        view.superview?.bringSubviewToFront(view)
        
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
        let previouTransform =  view.transform
        UIView.animate(withDuration: 0.2,
                       animations: {
            view.transform = view.transform.scaledBy(x: 1.2, y: 1.2)
            view.setNeedsDisplay()
        },
                       completion: { _ in
            UIView.animate(withDuration: 0.2) {
                view.transform  = previouTransform
                view.setNeedsDisplay()
            }
        })
    }
    
    /**
     Moving Objects
     delete the view if it's inside the delete view
     Snap the view back if it's out of the canvas
     */
    
    func moveView(view: UIView, recognizer: UIPanGestureRecognizer)  {
        
        //hideToolbar(hide: true)
        //        if isTyping {
        //            colorPickerView.isHidden = true
        //        } else { // Sticker Moving
        //            collectioView?.isHidden = true
        //        }
        self.view.endEditing(true)
        self.isTextMoving = true
        view.superview?.bringSubviewToFront(view)
        let pointToSuperView = recognizer.location(in: self.view)
        
        view.center = CGPoint(x: view.center.x + recognizer.translation(in: canvasImageView).x,
                              y: view.center.y + recognizer.translation(in: canvasImageView).y)
        
        recognizer.setTranslation(CGPoint.zero, in: canvasImageView)
        
        if let previousPoint = lastPanPoint {
            //View is going into deleteBtn
            if deleteBtn.frame.contains(pointToSuperView) && !deleteBtn.frame.contains(previousPoint) {
                if #available(iOS 10.0, *) {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                }
                self.deleteBtn.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                UIView.animate(withDuration: 0.3, animations: {
                    view.transform = view.transform.scaledBy(x: 0.25, y: 0.25)
                    view.center = recognizer.location(in: self.canvasImageView)
                })
            }
            //View is going out of deleteBtn
            else if deleteBtn.frame.contains(previousPoint) && !deleteBtn.frame.contains(pointToSuperView) {
                //Scale to original Size
                UIView.animate(withDuration: 0.3, animations: {
                    // Restore the original size of deleteBtn
                    self.deleteBtn.transform = CGAffineTransform.identity
                    view.transform = view.transform.scaledBy(x: 4, y: 4)
                    view.center = recognizer.location(in: self.canvasImageView)
                })
            }
        }
        lastPanPoint = pointToSuperView
        
        if recognizer.state == .ended {
            imageViewToPan = nil
            lastPanPoint = nil
            //hideToolbar(hide: false)
            //            if isTyping {
            //                colorPickerView.isHidden = false
            //            } else { // Sticker Moving
            //                collectioView?.isHidden = false
            //            }
            self.isTextMoving = false
            let point = recognizer.location(in: self.view)
            
            if deleteBtn.frame.contains(point) { // Delete the view
                isTextEditing = false
                self.deleteBtn.transform = CGAffineTransform.identity
                view.removeFromSuperview()
                self.removeTextButtons(tag: view.tag)
                rangeDict.removeValue(forKey: view.tag)
                if #available(iOS 10.0, *) {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } else if !canvasImageView.bounds.contains(view.center) { //Snap the view back to canvasImageView
                UIView.animate(withDuration: 0.3, animations: {
                    view.center = self.canvasImageView.center
                })
                
            }
        }
    }
    
    func subImageViews(view: UIView) -> [UIImageView] {
        var imageviews: [UIImageView] = []
        for imageView in view.subviews {
            if imageView is UIImageView {
                imageviews.append(imageView as! UIImageView)
            }
        }
        return imageviews
    }
}

// MARK: AUDIO HANDLE

extension UserEditingVideoViewController: MyDataSendingDelegateProtocols {
    
    //Mute functionality
//    @objc func muteButtonTapped() {
//        muteBtn.isSelected = !muteBtn.isSelected
//        player.volume = muteBtn.isSelected ? 0.0 : 1.0
//        muteBtn.setImage(UIImage(systemName: muteBtn.isSelected ? "speaker.slash" : "speaker")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
//    }
    
    //Volume Settings functionality
    @objc func volumeSettingsTapped() {
//        pauseMedia()
        
        let userEditingVideoVolumeController = UserEditingVideoVolumeController()
        userEditingVideoVolumeController.userEditingVC = self
        userEditingVideoVolumeController.modalPresentationStyle = .overFullScreen
        self.present(userEditingVideoVolumeController, animated: true)
    }
    
    //Voice Over functionality
    @objc func voiceOverButtonTapped() {
        pauseMedia()
        
        voiceOverVC.userEditingVC = self
        voiceOverVC.modalPresentationStyle = .overFullScreen
        self.present(voiceOverVC, animated: true)
    }
    
    @objc func openMusicView() {
        let storyboard = UIStoryboard(name: kMain , bundle: nil)
        let newVC = storyboard.instantiateViewController(withIdentifier: "addmusicViewController") as? addmusicViewController
        self.songURLString = ""
        self.songID = 0
        self.definesPresentationContext = true
        newVC?.modalPresentationStyle = .formSheet
        newVC?.delegate = self
        newVC?.selectedVideoDuration = videoAsset.duration.seconds
        newVC?.userEditingVC = self
        self.present(newVC!, animated: true, completion: nil)
    }
    
    func sendDataToCameraViewController(song_id: Int, songUrl: String, title: String) {
        songID = song_id
        songURLString = songUrl
        song_title = title
        if songURLString != "" {
           downloadFileFromURL(url: songURLString)
        }
    }
    
    func downloadFileFromURL(url: String){
        if let url = URL(string: url) {
            self.animator.startAnimating()
            self.view.isUserInteractionEnabled = false
            DraftVideoManager.shared.saveFileToDocumentDirectory(uniqueId: self.uniqueId, fileName: "SiteMusicAudio.\(url.pathExtension)", file: url, completion: { url, _ in
                DispatchQueue.main.async {
                    self.animator.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                }
                
                guard let url else {
                    DispatchQueue.main.async {
                        self.view.makeToast(NSLocalizedString("Something went wrong.", comment: ""))
                    }
                    return
                }
                self.adjustedMusicDuration = 0
                self.siteAudioURL = url
                self.setAVAudioSettings(fromURL: url)
            })
        }
    }
    
    func setAVAudioSettings(fromURL optionalURL: URL?, adjustingMusic: Bool = true, preferredVolume: Float = 1.0) {
        if let downloadedURL = optionalURL {
            self.songURLTEMP = downloadedURL
            
            do {
                
                audioPlayer = try AVAudioPlayer(contentsOf: downloadedURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.numberOfLoops = 1
                audioPlayer?.volume = preferredVolume
//                audioPlayer?.delegate = self
                
                player.seek(to: .zero)
                playMedia()
                
                DispatchQueue.main.async {
                    if !self.view.subviews.contains(self.adjustMusicView) {
                        self.addAdjustMusicView() // Called only one time for view instance
                    } else {
                        self.adjustMusicScrollViewLayout()
                    }
                    self.adjustedMusic = adjustingMusic
                }

            } catch let error as NSError {
                //self.player = nil
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    self.view.makeToast(NSLocalizedString("Something went wrong.", comment: ""))
                }
            } catch {
                print("AVAudioPlayer init failed")
                DispatchQueue.main.async {
                    self.view.makeToast(NSLocalizedString("Something went wrong.", comment: ""))
                }
            }
        }
    }
    
    func checkBookFileExists(withLink link: String, completion: @escaping ((_ filePath: URL)->Void)){
        let urlString = link.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        if let url  = URL.init(string: urlString ?? ""){
            let fileManager = FileManager.default
            if let documentDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create: false){
                let filePath = documentDirectory.appendingPathComponent(url.lastPathComponent, isDirectory: false)
                do {
                    if try filePath.checkResourceIsReachable() {
                        print("file exist")
                        completion(filePath)
                    } else {
                        print("file doesnt exist")
                        downloadFile(withUrl: url, andFilePath: filePath, completion: completion)
                    }
                } catch {
                    print("file doesnt exist")
                    downloadFile(withUrl: url, andFilePath: filePath, completion: completion)
                }
            }else{
                 print("file doesnt exist")
            }
        }else{
                print("file doesnt exist")
        }
    }
    
    func downloadFile(withUrl url: URL, andFilePath filePath: URL, completion: @escaping ((_ filePath: URL)->Void)){
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try Data.init(contentsOf: url)
                try data.write(to: filePath, options: .atomic)
                print("saved at \(filePath.absoluteString)")
                DispatchQueue.main.async {
                    completion(filePath)
                }
            } catch {
                print("an error happened while downloading or saving the file")
            }
        }
    }
    
    func addAdjustMusicView() {
        
        // Add Notification Observer
//        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        let viewWidth = 200.0
        let lineColor = hexStringToUIColor(hex: "#cccccc")
        
        let xAxis = (Double(UIScreen.main.bounds.width) - viewWidth) / 2.0
        let bottomSafeAreaHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0.0
        let yAxis = Double(UIScreen.main.bounds.height) - 65.0 - bottomSafeAreaHeight
        
        adjustMusicView.addSubview(adjustMusicProgressView)
        
        adjustMusicView.frame = CGRect(x: xAxis, y: yAxis, width: viewWidth, height: 50)
        adjustMusicView.layer.borderColor = lineColor.cgColor
        self.view.addSubview(adjustMusicView)
        
        adjustMusicScrollView.frame = CGRect(x: 0, y: yAxis, width: Double(UIScreen.main.bounds.width), height: 50.0)
        adjustMusicScrollView.showsHorizontalScrollIndicator = false
        adjustMusicScrollView.contentInset = UIEdgeInsets(top: 0, left: CGFloat(xAxis), bottom: 0, right: CGFloat(xAxis))
        self.view.addSubview(adjustMusicScrollView)
        
        adjustMusicScrollView.delegate = self // Set scrollView's delegate to self
        
        self.adjustMusicScrollViewLayout()
        
        self.addMusicButton()
        
        adjustedMusicDuration = adjustedMusicDuration == nil ? 0 : adjustedMusicDuration
        audioPlayer?.currentTime = adjustedMusicDuration ?? 0
        adjustMusicScrollView.contentOffset.x = ((adjustedMusicDuration ?? 0)*200)/(CMTimeGetSeconds(self.videoAsset.duration))-xAxis
    }
    
    func adjustMusicScrollViewLayout() {
        
        for subviews in adjustMusicScrollView.subviews {
            subviews.removeFromSuperview()
        }
        
        let viewWidth = 200.0
        let lineColor = hexStringToUIColor(hex: "#cccccc")
        
        let videoAssetDuration = CMTimeGetSeconds(self.videoAsset.duration)
        let audioPlayerDuration = self.audioPlayer?.duration ?? 0
        
        adjustMusicScrollView.contentSize = CGSize(width: (viewWidth * audioPlayerDuration) / videoAssetDuration, height: 50.0)
    
        // Add vertical lines to the scrollView
        let lineSpacing: CGFloat = 3.0
        let lineHeightShort: CGFloat = 12.5
        let lineHeightLong: CGFloat = 25.0
        let numberOfLines = Int(adjustMusicScrollView.contentSize.width / (lineSpacing * 2))
        
        for i in 0...numberOfLines {
            let lineView = UIView()
            let height = i % 2 == 0 ? lineHeightShort : lineHeightLong
            lineView.frame = CGRect(x: CGFloat(i) * lineSpacing * 3, y: (adjustMusicScrollView.bounds.height - height) / 2.0, width: lineSpacing, height: height)
            lineView.backgroundColor = lineColor
            lineView.layer.cornerRadius = lineSpacing / 2.0 // Apply corner radius
            adjustMusicScrollView.addSubview(lineView)
        }
    }
    
    func addMusicButton() {
        
        for subviews in addedTextViews.subviews {
            if let subviews = subviews as? UIButton {
                subviews.frame.origin.x += 40
            }
        }
        
        var xOrigin: CGFloat = 0.0

        if let lastSubview = addedTextViews.subviews.last as? UIButton ?? addedTextViews.subviews.dropLast().last as? UIButton {
            xOrigin = lastSubview.frame.origin.x + lastSubview.frame.width
        } else if xOrigin == 0 {
            self.view.addSubview(addedTextViews)
        }
        
        // A button with the same tag does not exist, create a new one
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 10, y: 0, width: 30, height: 30)
        button.layer.cornerRadius = button.frame.height / 2
        button.layer.masksToBounds = true
        button.tag = 4161
        button.tintColor = UIColor.black.withAlphaComponent(0.3)
        button.setBackgroundColor(color: UIColor.black.withAlphaComponent(0.3), forState: UIControl.State())
        button.setImage(UIImage(systemName: "music.note")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
        button.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
//        button.sizeToFit()
//        button.frame.size.width += 10
//        button.frame.size.height = 30
        
        button.addTarget(self, action: #selector(self.musicBtnTapped), for: .touchUpInside)
        
        // Adjust button width if it exceeds the maximum
//        if button.frame.width > 150 {
//            button.frame.size.width = 150
//        }
        
        addedTextViews.addSubview(button)
        
        let contentWidth = 10+button.frame.width+addedTextViews.contentSize.width
        addedTextViews.contentSize = CGSize(width: contentWidth>appWidth ? contentWidth : appWidth, height: addedTextViews.frame.height)
    }
    
    @objc func musicBtnTapped() {
        adjustedMusic = true
    }
}

//extension UserEditingVideoViewController: AVAudioPlayerDelegate {
//    @objc func audioPlayerDidFinishPlaying(_ notification: Notification) {
//        
//        // Check if the finished player is the one you are observing
//        audioPlayer?.currentTime = adjustedMusicDuration ?? 0
//        
//        // Restart playback from the desired time
////        playMedia()
//    }
//}

//MARK: SCROLLVIEW DELEGATES
extension UserEditingVideoViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isAdjustingMusic = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Calculate the portion of scrollView that is scrolled
        let xAxis = (Double(UIScreen.main.bounds.width) - 200.0) / 2.0
        let x = Double(scrollView.contentOffset.x) + xAxis
        adjustedMusicDuration = (x * CMTimeGetSeconds(self.videoAsset.duration)) / 200.0
        print("Scrolled portion: \(adjustedMusicDuration ?? 0)")
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            // If deceleration is false, it means scrolling has completely stopped
            isAdjustingMusic = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isAdjustingMusic = false
    }
}

extension UserEditingVideoViewController {
    
    func rangeSliderSelectedPortion(tag: Int? = nil) {
        if let tag = tag,
           let beginTime = rangeDict[tag]?.beginTime,
           let duration = rangeDict[tag]?.duration {
            let totalDuration = videoAsset.duration.seconds
            
            let lVal = (beginTime*100)/totalDuration
            let uVal = lVal + ((duration*100)/totalDuration)
            
            rangeSlider.lowerValue = lVal
            rangeSlider.upperValue = uVal
        }
        isTextSelected = true
    }
    
    //Create range slider
    @objc func createRangeSlider()
    {
        isTextSelected = true
//        frameContainerView.layer.masksToBounds = true
//        frameContainerView.layer.cornerRadius = 5
        frameContainerView.backgroundColor = .systemYellow
        //Remove slider if already present
        let subViews = self.frameContainerView.subviews
        for subview in subViews{
            if subview.tag == 1000 {
                subview.removeFromSuperview()
            }
        }
        
        var xAxis = 15.0
        let images = createImageFramesUIImage()
        let imageWidth = (frameContainerView.frame.width-30)/CGFloat(images.count)
        for image in images {
            let imageView = UIImageView(frame: CGRect(x: xAxis, y: 5, width: imageWidth, height: frameContainerView.frame.height-10.0))
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            
            if images.first == image {
                imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                imageView.layer.cornerRadius = 5
            } else if images.last == image {
                imageView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                imageView.layer.cornerRadius = 5
            }
            
            self.frameContainerView.addSubview(imageView)
            
            xAxis += imageWidth
        }
        //Progress
//        let progressView = UIView(frame: CGRect(x: 0, y: -9, width: 4, height: frameContainerView.frame.height+18))
//        progressView.backgroundColor = .clear
//        progressView.layer.masksToBounds = true
//        progressView.layer.cornerRadius = progressView.frame.width/2
//        frameContainerView.addSubview(progressView)
//        player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1/30.0, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil, using: { time in
//            let duration = CMTimeGetSeconds(self.videoAsset.duration)
//            let progress = CGFloat((CMTimeGetSeconds(time) / duration))
//            if progress == 0 || progress == 1{
//                progressView.isHidden = true
//            } else {
//                progressView.isHidden = false
//                progressView.frame.origin.x = progress*(self.frameContainerView.frame.width-30)+15.0
//            }
//            
//            
////            for subview in self.canvasImageView.subviews {
////                if let textView = subview as? UITextView,
////                   (self.rangeDict[textView.tag] != nil) {
////                }
////            }
//            // Iterate through subviews to find UITextView with specific tags and hide them if needed
//            for subview in self.canvasImageView.subviews {
//                if let textView = subview as? UITextView {
//                    let textViewTag = textView.tag
//                    // Check if the tag exists in rangeDict and if it does, get its corresponding TextViewStateDuration
//                    if let textViewDuration = self.rangeDict[textViewTag] {
//                        // Calculate the end time of the text view based on its begin time and duration
//                        let textViewEndTime = textViewDuration.beginTime + textViewDuration.duration
//                        
//                        // Check if the current progress time is within the range of the text view
//                        if CMTimeGetSeconds(time) >= textViewDuration.beginTime && CMTimeGetSeconds(time) <= textViewEndTime {
//                            // Hide the text view if it's within the specified duration
//                            textView.isHidden = false
//                        } else {
//                            // Show the text view if it's not within the specified duration
//                            textView.isHidden = true
//                        }
//                    }
//                }
//            }
//        })
        
        rangeSlider = TrimmerRangeSlider(frame: frameContainerView.bounds)
        
        if let tag = activeTextView?.tag,
           let beginTime = rangeDict[tag]?.beginTime,
           let duration = rangeDict[tag]?.duration {
            
            let totalDuration = videoAsset.duration.seconds
            
            let lVal = (beginTime*100)/totalDuration
            let uVal = lVal + ((duration*100)/totalDuration)
            
            rangeSlider.lowerValue = lVal
            rangeSlider.upperValue = uVal
        }
        
        frameContainerView.addSubview(rangeSlider)
        
        frameContainerView.layer.masksToBounds = true
        frameContainerView.layer.cornerRadius = 5
        
        self.rangeSlider.tag = 1000
        
//        endTime = CGFloat(thumbtimeSeconds)
        
        //Range slider action
        rangeSlider.addTarget(self, action: #selector(self.rangeSliderValueChanged(_:)), for: .valueChanged)
        
        let time = DispatchTime.now() + Double(Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.rangeSlider.trackHighlightTintColor = UIColor.clear
            self.rangeSlider.curvaceousness = 1.0
        }
        
    }
    
    //MARK: rangeSlider Delegate
    @objc func rangeSliderValueChanged(_ rangeSlider: TrimmerRangeSlider) {
        
//        print(rangeSlider.lowerValue)
//        print(rangeSlider.upperValue)
        
        if let tag = self.activeTextView?.tag {
            let totalDuration = videoAsset.duration.seconds
            
            
            let beginTime = (rangeSlider.lowerValue/100)*totalDuration
            let duration = totalDuration*((rangeSlider.upperValue - rangeSlider.lowerValue)/100)
            
            rangeDict[tag] = TextViewStateDuration(beginTime: beginTime, duration: duration)
        }

        self.seekVideo(toPos: CGFloat((rangeSlider.lowerLayerSelected) ? rangeSlider.lowerValue : rangeSlider.upperValue))
    }
    //Seek video when slider
    func seekVideo(toPos pos: CGFloat) {
        let totalDuration = videoAsset.duration.seconds
        let beginTime = (pos/100)*totalDuration
        let time: CMTime = CMTimeMakeWithSeconds(Float64(beginTime), preferredTimescale: self.player.currentTime().timescale)
        self.player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
}

extension UserEditingVideoViewController {
    func createImageFramesUIImage() -> [UIImage] {
        
        var imageData: [UIImage] = []
        //creating assets
        let assetImgGenerate : AVAssetImageGenerator    = AVAssetImageGenerator(asset: videoAsset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter    = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore   = CMTime.zero;
        
        
        assetImgGenerate.appliesPreferredTrackTransform = true
        let thumbTime: CMTime = videoAsset.duration
        let thumbtimeSeconds  = Int(CMTimeGetSeconds(thumbTime))
        let maxLength         = "\(thumbtimeSeconds)" as NSString
        
        let thumbAvg  = thumbtimeSeconds/10
        var startTime = 0
        
        //loop for 6 number of frames
        for index in 0...9 {
            do {
                let time:CMTime = CMTimeMakeWithSeconds(Float64(startTime),preferredTimescale: Int32(maxLength.length))
                let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                imageData.append(UIImage(cgImage: img))
            }
            catch
                _ as NSError
            {
                print("Image generation failed with error (error)")
            }
            startTime += thumbAvg
        }
        return imageData
    }
    func createImageFrames() -> [String] {
        
        var imageData: [String] = []
        //creating assets
        let assetImgGenerate : AVAssetImageGenerator    = AVAssetImageGenerator(asset: videoAsset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter    = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore   = CMTime.zero;
        
        
        assetImgGenerate.appliesPreferredTrackTransform = true
        let thumbTime: CMTime = videoAsset.duration
        let thumbtimeSeconds  = Int(CMTimeGetSeconds(thumbTime))
        let maxLength         = "\(thumbtimeSeconds)" as NSString
        
        let thumbAvg  = thumbtimeSeconds/10
        var startTime = 0
        
        //loop for 6 number of frames
        for index in 0...9 {
            do {
                let time:CMTime = CMTimeMakeWithSeconds(Float64(startTime),preferredTimescale: Int32(maxLength.length))
                let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                
                DraftVideoManager.shared.saveFileToDocumentDirectory(uniqueId: self.uniqueId, fileName: "videoFrame\(index).png", image: UIImage(cgImage: img), completion: {_,_ in
                    imageData.append("videoFrame\(index).png")
                })
            }
            catch
                _ as NSError
            {
                print("Image generation failed with error (error)")
            }
            startTime += thumbAvg
        }
        return imageData
    }
}

// MARK: SAVE/LOAD DATA

extension UserEditingVideoViewController {
    
    func showDraftLimitAlert() {
        let alertView = UIAlertController(title: NSLocalizedString("Draft Limit", comment: ""), message: NSLocalizedString("Maximum limit is 10. Please delete any one video to save the draft.", comment: ""), preferredStyle: .alert)
        
        alertView.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .destructive, handler: { _ in
            let controller = DraftListViewController()
            controller.modalPresentationStyle = .formSheet
            self.present(controller, animated: true)
        }))

        // Add a cancel action
        alertView.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
            // Handle cancellation if needed
        }))

        // Show it to your users
        self.present(alertView, animated: true, completion: nil)
    }
    
    // Function to save the necessary data to UserDefaults
    func saveStateToUserDefaults(_ completion: @escaping (Error?)->Void) {
        
        let group = DispatchGroup()
        var errorOccurred: Error?
        
        // CHECK DRAFT LIMIT
        if !self.draftVideos { // IF NEW VIDEO
            guard DraftVideoManager.shared.checkLimitOfDrafts() else {
                self.showDraftLimitAlert()
                return
            }
        }
        
        if canvasImageView.subviews.count > 0  || canvasImageView.image != nil { // TEXT ADDED
            group.enter()
            DraftVideoManager.shared.saveFileToDocumentDirectory(uniqueId: self.uniqueId, fileName: "TextLayer.png", image: self.canvasImageView.asImage(), completion: { url, error in
                if let error = error {
                    errorOccurred = error
                }
                group.leave()
            })
        }
        
        let videoFileName = "Video.\(videoURL.pathExtension)"
        if DraftVideoManager.shared.checkFileExistInDocumentDirectory(uniqueId: uniqueId, fileName: videoFileName) == nil {
            group.enter()
            DraftVideoManager.shared.saveFileToDocumentDirectory(uniqueId: self.uniqueId, fileName: videoFileName, file: self.videoURL, completion: { _, error in
                if let error = error {
                    errorOccurred = error
                }
                group.leave()
            })
        }
        
        var userEditingVideoDictionary: [String: UserEditingVideoState] = [:]
        
        var imageFileName: String? = nil
        if let image = canvasImageView.image {
            imageFileName = "canvasImage.png"
            group.enter()
            DraftVideoManager.shared.saveFileToDocumentDirectory(uniqueId: self.uniqueId, fileName: "canvasImage.png", image: image, completion: { _, error in
                if let error = error {
                    errorOccurred = error
                }
                group.leave()
            })
        }
        
        var siteAudioFileName: String? = nil
        if let siteAudioURL = siteAudioURL {
            siteAudioFileName = "SiteMusic.\(siteAudioURL.pathExtension)"
            group.enter()
            DraftVideoManager.shared.saveFileToDocumentDirectory(uniqueId: self.uniqueId, fileName: siteAudioFileName ?? "", file: siteAudioURL, completion: { _, error in
                if let error = error {
                    errorOccurred = error
                }
                if siteAudioURL.lastPathComponent.contains("SiteMusicAudio") {
                    DraftVideoManager.shared.deleteFromDocumentDirectory(uniqueId: self.uniqueId, fileName: siteAudioURL.lastPathComponent)
                }
                group.leave()
            })
        }
        
        let stateData = UserEditingVideoState(
            videoTag: self.uniqueId,
            createdTime: Date(),
            videoURL: "Video.\(videoURL.pathExtension)",
//            textColor: textColor.toHexString(),
//            drawColor: drawColor.toHexString(),
            canvasImage: imageFileName,
            canvasFrame: NSCoder.string(for: canvasImageView.frame),
            textViewsData: getTextViewsData(),
            videoThumbnail: createImageFrames(), 
            rangeDict: rangeDict,
            voiceOverModel: voiceOverVC.audioArray,
            pointsDrawnArray: pointsDrawnArray,
            siteAudioURL: siteAudioFileName,
            adjustedMusicDuration: adjustedMusicDuration,
            videoAudioVolume: Double(self.player.volume),
            voiceOverAudioVolume: Double(self.voiceOverVC.audioPlayer?.volume ?? 1.0),
            siteAudioVolume: Double(self.audioPlayer?.volume ?? 1.0)
        )
        
        // Load the current userEditingVideoDictionary from UserDefaults
        if let savedArrayData = UserDefaults.standard.data(forKey: "\(loggedinUserId)UserEditingVideoDictionary"),
           let savedDict = try? JSONDecoder().decode([String: UserEditingVideoState].self, from: savedArrayData) {
            userEditingVideoDictionary = savedDict
        }

        userEditingVideoDictionary[self.uniqueId] = stateData
        
        // Save the updated userEditingVideoDictionary to UserDefaults
        if let encodedData = try? JSONEncoder().encode(userEditingVideoDictionary) {
            UserDefaults.standard.set(encodedData, forKey: "\(loggedinUserId)UserEditingVideoDictionary")
            UserDefaults.standard.synchronize()
        }
        
        // Notify completion when all tasks are finished
        group.notify(queue: .main) {
            if let error = errorOccurred {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    // Function to load the necessary data from UserDefaults
    func loadStateFromUserDefaults(uniqueId: String) {
        DispatchQueue.global().async {
            guard let savedArrayData = UserDefaults.standard.data(forKey: "\(loggedinUserId)UserEditingVideoDictionary"),
                  let savedDict = try? JSONDecoder().decode([String: UserEditingVideoState].self, from: savedArrayData),
                  !savedDict.isEmpty,
                  let userEditingVideoDictionary = savedDict[uniqueId] else {
                // Handle case when userEditingVideoDictionary is empty, not found in UserDefaults, or index is out of bounds
                DispatchQueue.main.async {
                    // Update UI to reflect error state, if needed
                }
                return
            }
            
            let stateData = userEditingVideoDictionary
            
            // Load canvasImageView's image from String
//            if let string = stateData.canvasImage,
//               let url = DraftVideoManager.shared.checkFileExistInDocumentDirectory(uniqueId: uniqueId, fileName: string) {
//                do {
//                    let canvasImageData = try Data(contentsOf: url)
//                    DispatchQueue.main.async {
//                        self.canvasImageView.image = UIImage(data: canvasImageData)
//                    }
//                } catch {
//                    print("Error loading image data:", error)
//                    // Handle the error appropriately, e.g., show an error message to the user
//                }
//            } else {
//                print("Error: Unable to load image from document directory")
//                // Handle the case where either the filename is missing or the file couldn't be loaded
//            }
            
            // Decode canvasImageView frame string into CGRect
            let canvasFrame = NSCoder.cgRect(for: stateData.canvasFrame)
            self.pointsDrawnArray = stateData.pointsDrawnArray
            self.currentDrawnPoint = self.pointsDrawnArray.count+1
            
            DispatchQueue.main.async {
                self.canvasImageView.frame = canvasFrame
                self.drawImageThroughPoints()
            }
            
            // Load UITextView content, frame, center, and transform
            for textViewData in stateData.textViewsData {
                DispatchQueue.main.async {
                    
                    let frame = NSCoder.cgRect(for: textViewData.frame)
                    let textView = CustomPaddingTextView(frame: frame)
                    
                    if let font = textViewData.fontURLString {
                        self.activeTextView = textView
                        textView.fontURLString = font
                        self.loadFontOnTextView(fontUrl: font, adjustBounds: false)
                    }
                    
                    textView.layer.backgroundColor = UIColor.clear.cgColor
                    textView.backgroundColor = .clear
                    textView.customBackgroundColor = hexStringToUIColor(hex: textViewData.backgroundColorString)
                    textView.autocorrectionType = .default
                    textView.isScrollEnabled = false
                    textView.delegate = self
                    textView.isUserInteractionEnabled = true
                    textView.tag = textViewData.tag
                    textView.text = textViewData.text
                    if let attributedTextData = textViewData.attributedText {
                        do {
                            let attributedText = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: attributedTextData)
                            textView.attributedText = attributedText
                        } catch {
                            print("Error unarchiving attributed text: \(error.localizedDescription)")
                        }
                    }
                    
                    // Set text alignment
                    if let textAlignment = NSTextAlignment(rawValue: textViewData.textAlignment) {
                        textView.textAlignment = textAlignment
                    }
                    
                    let transform = NSCoder.cgAffineTransform(for: textViewData.transform)
                    let center = NSCoder.cgPoint(for: textViewData.center)
                    let bounds = NSCoder.cgRect(for: textViewData.bounds)
                    
                    textView.transform = transform
                    textView.center = center
                    textView.bounds = bounds
                    
                    self.addGestures(view: textView)
                    self.canvasImageView.addSubview(textView)
                    
                    textView.setNeedsDisplay()
                    
                    self.isMagnifyingGlassActive = false
                }
            }
            
            if let rangeDict = stateData.rangeDict {
                self.rangeDict = rangeDict
            }
            
            self.playerVolume = Float(stateData.videoAudioVolume)
            self.player.volume = self.playerVolume
            
            if let audioArray = stateData.voiceOverModel,
               audioArray.count>0 {
                DispatchQueue.main.async {
                    self.voiceOverAudioVolume = Float(stateData.voiceOverAudioVolume)
                    self.voiceOverVC.audioArray = audioArray
                    self.voiceOverVC.setAudioFunctionality()
                    self.voiceOverVC.audioPlayer?.volume = Float(stateData.voiceOverAudioVolume)
                }
            }
            
            DispatchQueue.main.async {
                // Extract tags of subviews
                let subviewTags = self.canvasImageView.subviews.map({ $0.tag })
                
                // Sort the tags
                let sortedTags = subviewTags.sorted()
                
                // Iterate over sorted tags
                for tag in sortedTags {
                    // Find the subview with the current tag
                    if let subview = self.canvasImageView.subviews.first(where: { $0.tag == tag }) {
                        // Check if the subview is a UITextView
                        if let textView = subview as? UITextView {
                            // Call addTextButtons with the UITextView
                            self.addTextButtons(textView: textView)
                        }
                    }
                }
            }
            
            if let fileName = stateData.siteAudioURL {
                if let url = DraftVideoManager.shared.checkFileExistInDocumentDirectory(uniqueId: uniqueId, fileName: fileName) {
                    self.adjustedMusicDuration = stateData.adjustedMusicDuration
                    self.siteAudioURL = url
                    if self.adjustedMusicDuration != nil {
                        self.setAVAudioSettings(fromURL: url, adjustingMusic: false, preferredVolume: Float(stateData.siteAudioVolume))
                    }
                    self.audioPlayer?.volume = Float(stateData.siteAudioVolume)
                }
            }
        }
    }
    
    private func getTextViewsData() -> [TextViewState] {
        var textViewsData: [TextViewState] = []
        for subview in canvasImageView.subviews {
            if let textView = subview as? CustomPaddingTextView {
                var attributedTextData: Data?
                if let attributedText = textView.attributedText {
                    do {
                        attributedTextData = try NSKeyedArchiver.archivedData(withRootObject: attributedText, requiringSecureCoding: false)
                    } catch {
                        print("Error archiving attributed text: \(error.localizedDescription)")
                    }
                }

                let textViewData = TextViewState(
                    text: textView.text,
                    attributedText: attributedTextData,
                    frame: NSCoder.string(for: textView.frame),
                    bounds: NSCoder.string(for: textView.bounds),
                    center: NSCoder.string(for: textView.center), // Add center
                    transform: NSCoder.string(for: textView.transform), // Add transform
                    textAlignment: textView.textAlignment.rawValue,
                    contentSize: NSCoder.string(for: textView.contentSize), // Store content size as string
                    tag: textView.tag,
                    backgroundColorString: textView.customBackgroundColor.toHexString(),
                    fontURLString: textView.fontURLString
                )
                textViewsData.append(textViewData)
            }
        }
        return textViewsData
    }

}
