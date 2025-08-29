import UIKit
import VideoEditingKit
import AVFoundation

@available(iOS 14.0, *)
class ExampleViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let startEditingButton = UIButton(type: .system)
        startEditingButton.setTitle("Start Video Editing", for: .normal)
        startEditingButton.backgroundColor = .systemBlue
        startEditingButton.setTitleColor(.white, for: .normal)
        startEditingButton.layer.cornerRadius = 10
        startEditingButton.addTarget(self, action: #selector(startEditingTapped), for: .touchUpInside)
        
        let viewDraftsButton = UIButton(type: .system)
        viewDraftsButton.setTitle("View Drafts", for: .normal)
        viewDraftsButton.backgroundColor = .systemGreen
        viewDraftsButton.setTitleColor(.white, for: .normal)
        viewDraftsButton.layer.cornerRadius = 10
        viewDraftsButton.addTarget(self, action: #selector(viewDraftsTapped), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [startEditingButton, viewDraftsButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            startEditingButton.heightAnchor.constraint(equalToConstant: 50),
            viewDraftsButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func startEditingTapped() {
        // In a real app, you would get this from photo picker or camera
        guard let sampleVideoURL = createSampleVideoURL() else {
            showAlert(message: "No sample video available")
            return
        }
        
        let editor = VideoEditingKit.shared.createVideoEditor(with: sampleVideoURL)
        
        // Configure editor if needed
        editor.modalPresentationStyle = .fullScreen
        
        present(editor, animated: true) {
            print("Video editor presented")
        }
    }
    
    @objc private func viewDraftsTapped() {
        let draftController = DraftListController()
        
        draftController.onDraftSelected = { [weak self] draft in
            self?.resumeEditing(from: draft)
        }
        
        present(UINavigationController(rootViewController: draftController), animated: true)
    }
    
    private func resumeEditing(from draft: VideoEditingState) {
        // Load the video URL from the draft
        guard let videoURL = DraftManager.shared.loadFileFromDocumentDirectory(
            uniqueId: draft.videoTag,
            fileName: draft.videoURL
        ) else {
            showAlert(message: "Could not load draft video")
            return
        }
        
        let editor = VideoEditingKit.shared.createVideoEditor(with: videoURL, uniqueId: draft.videoTag)
        editor.isDraftVideo = true
        
        // You could restore more state here from the draft object
        // editor.rangeDict = draft.rangeDict ?? [:]
        // editor.pointsDrawnArray = draft.pointsDrawnArray
        
        present(editor, animated: true)
    }
    
    private func createSampleVideoURL() -> URL? {
        // This is just for example - in a real app you'd use a real video
        // You could create a sample video programmatically or use one from bundle
        return Bundle.main.url(forResource: "sample_video", withExtension: "mp4")
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Example of custom video editing workflow
@available(iOS 14.0, *)
extension ExampleViewController {
    
    func customVideoEditingWorkflow() {
        // Example of a complete video editing workflow
        
        // 1. Create editor with video
        guard let videoURL = createSampleVideoURL() else { return }
        let editor = VideoEditingKit.shared.createVideoEditor(with: videoURL)
        
        // 2. Configure audio recording
        let audioRecorder = editor.audioRecorder
        
        // 3. Start recording at specific time
        audioRecorder.startRecording(at: 5.0, uniqueId: editor.uniqueId) { result in
            switch result {
            case .success(let fileName):
                print("Recording started: \(fileName)")
                
                // Stop recording after 3 seconds (in real app, user would control this)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    audioRecorder.stopRecording(at: 8.0)
                    print("Recording stopped")
                }
                
            case .failure(let error):
                print("Recording failed: \(error)")
            }
        }
        
        // 4. Export when ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            editor.exportVideo(progressHandler: { progress in
                print("Export progress: \(Int(progress * 100))%")
            }) { result in
                switch result {
                case .success(let exportedURL):
                    print("Video exported successfully to: \(exportedURL)")
                    
                    // 5. Save draft if needed
                    let draftSaved = editor.saveDraft()
                    print("Draft saved: \(draftSaved)")
                    
                case .failure(let error):
                    print("Export failed: \(error)")
                }
            }
        }
    }
    
    func demonstrateFileManagement() {
        let manager = DraftManager.shared
        let uniqueId = "demo_session"
        
        // Save an image
        let sampleImage = UIImage(systemName: "star.fill") ?? UIImage()
        manager.saveFileToDocumentDirectory(
            uniqueId: uniqueId,
            fileName: "overlay.png",
            image: sampleImage
        ) { result in
            switch result {
            case .success(let url):
                print("Image saved at: \(url)")
                
                // Check if file exists
                if let existingURL = manager.checkFileExistInDocumentDirectory(
                    uniqueId: uniqueId,
                    fileName: "overlay.png"
                ) {
                    print("File confirmed to exist at: \(existingURL)")
                }
                
            case .failure(let error):
                print("Failed to save image: \(error)")
            }
        }
    }
}