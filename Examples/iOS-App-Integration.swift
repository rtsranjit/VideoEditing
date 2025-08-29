// iOS App Integration Example
// Add this to your iOS app's ViewController

import UIKit
import VideoEditingKit
import AVFoundation
import Photos

@available(iOS 14.0, *)
class MainViewController: UIViewController {
    
    @IBOutlet weak var selectVideoButton: UIButton!
    @IBOutlet weak var viewDraftsButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestPermissions()
    }
    
    private func setupUI() {
        selectVideoButton.layer.cornerRadius = 10
        viewDraftsButton.layer.cornerRadius = 10
        
        // Check draft availability
        let draftCount = VideoEditingKit.shared.getDrafts()?.count ?? 0
        statusLabel.text = "Drafts available: \(draftCount)"
    }
    
    private func requestPermissions() {
        // Request microphone permission for voice-over
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            print("Microphone permission: \(granted)")
        }
        
        // Request photo library permission for video access
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            print("Photo library permission: \(status)")
        }
    }
    
    @IBAction func selectVideoTapped(_ sender: UIButton) {
        presentVideoPicker()
    }
    
    @IBAction func viewDraftsTapped(_ sender: UIButton) {
        presentDraftList()
    }
    
    // MARK: - Video Selection
    private func presentVideoPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    // MARK: - Draft Management
    private func presentDraftList() {
        let draftController = DraftListController()
        draftController.onDraftSelected = { [weak self] draft in
            self?.resumeEditingFromDraft(draft)
        }
        
        let navController = UINavigationController(rootViewController: draftController)
        present(navController, animated: true)
    }
    
    private func resumeEditingFromDraft(_ draft: VideoEditingState) {
        guard let videoURL = DraftManager.shared.loadFileFromDocumentDirectory(
            uniqueId: draft.videoTag,
            fileName: draft.videoURL
        ) else {
            showAlert("Failed to load draft video")
            return
        }
        
        startVideoEditing(with: videoURL, uniqueId: draft.videoTag, isDraft: true)
    }
    
    // MARK: - Video Editing
    private func startVideoEditing(with videoURL: URL, uniqueId: String? = nil, isDraft: Bool = false) {
        let editor = VideoEditingKit.shared.createVideoEditor(
            with: videoURL, 
            uniqueId: uniqueId
        )
        
        editor.isDraftVideo = isDraft
        editor.modalPresentationStyle = .fullScreen
        
        // Add custom completion handler
        editor.onVideoExported = { [weak self] exportURL in
            self?.handleVideoExport(exportURL)
        }
        
        editor.onDraftSaved = { [weak self] success in
            self?.handleDraftSaved(success)
        }
        
        present(editor, animated: true)
    }
    
    private func handleVideoExport(_ exportURL: URL) {
        // Save to photo library
        UISaveVideoAtPathToSavedPhotosAlbum(exportURL.path, self, 
            #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            if let error = error {
                self.showAlert("Failed to save video: \(error.localizedDescription)")
            } else {
                self.showAlert("Video saved to Photos!")
            }
        }
    }
    
    private func handleDraftSaved(_ success: Bool) {
        DispatchQueue.main.async {
            let message = success ? "Draft saved successfully!" : "Failed to save draft"
            self.showAlert(message)
            
            // Update draft count
            let draftCount = VideoEditingKit.shared.getDrafts()?.count ?? 0
            self.statusLabel.text = "Drafts available: \(draftCount)"
        }
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "VideoEditingKit", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true) {
            guard let videoURL = info[.mediaURL] as? URL else {
                self.showAlert("Failed to get video URL")
                return
            }
            
            // Check if we can create more drafts
            if !VideoEditingKit.shared.checkDraftLimit() {
                self.showAlert("Draft limit reached (10 max). Please delete some drafts first.")
                return
            }
            
            self.startVideoEditing(with: videoURL)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}