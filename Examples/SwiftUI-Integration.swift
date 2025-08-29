// SwiftUI Integration Example
// Add this to your SwiftUI app

import SwiftUI
import VideoEditingKit
import AVFoundation

@available(iOS 14.0, *)
struct ContentView: View {
    @State private var showingVideoPicker = false
    @State private var showingDraftList = false
    @State private var showingVideoEditor = false
    @State private var selectedVideoURL: URL?
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var draftCount = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                
                Image(systemName: "video.badge.plus")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("VideoEditingKit Demo")
                    .font(.largeTitle)
                    .bold()
                
                Text("Drafts available: \(draftCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    Button("Select Video to Edit") {
                        checkPermissionsAndShowPicker()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("View Saved Drafts") {
                        showingDraftList = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(draftCount == 0)
                    
                    Button("Create Sample Video") {
                        createSampleVideoForTesting()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Video Editor")
            .onAppear {
                updateDraftCount()
            }
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPicker { url in
                selectedVideoURL = url
                showingVideoEditor = true
            }
        }
        .sheet(isPresented: $showingDraftList) {
            DraftListView { draft in
                resumeEditingFromDraft(draft)
            }
        }
        .fullScreenCover(isPresented: $showingVideoEditor) {
            if let videoURL = selectedVideoURL {
                VideoEditorWrapper(videoURL: videoURL) { success in
                    handleEditingCompletion(success)
                }
            }
        }
        .alert("VideoEditingKit", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func checkPermissionsAndShowPicker() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    showingVideoPicker = true
                } else {
                    showAlert("Microphone permission is required for voice-over recording")
                }
            }
        }
    }
    
    private func resumeEditingFromDraft(_ draft: VideoEditingState) {
        guard let videoURL = DraftManager.shared.loadFileFromDocumentDirectory(
            uniqueId: draft.videoTag,
            fileName: draft.videoURL
        ) else {
            showAlert("Failed to load draft video")
            return
        }
        
        selectedVideoURL = videoURL
        showingVideoEditor = true
    }
    
    private func handleEditingCompletion(_ success: Bool) {
        updateDraftCount()
        if success {
            showAlert("Video editing completed successfully!")
        }
    }
    
    private func updateDraftCount() {
        draftCount = VideoEditingKit.shared.getDrafts()?.count ?? 0
    }
    
    private func createSampleVideoForTesting() {
        // This would create a simple test video programmatically
        showAlert("Sample video creation not implemented in this demo")
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - SwiftUI Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - UIKit Wrappers for SwiftUI
@available(iOS 14.0, *)
struct VideoEditorWrapper: UIViewControllerRepresentable {
    let videoURL: URL
    let onCompletion: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> VideoEditingController {
        let editor = VideoEditingKit.shared.createVideoEditor(with: videoURL)
        editor.onVideoExported = { _ in
            onCompletion(true)
        }
        return editor
    }
    
    func updateUIViewController(_ uiViewController: VideoEditingController, context: Context) {
        // No updates needed
    }
}

struct VideoPicker: UIViewControllerRepresentable {
    let onVideoSelected: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.onVideoSelected(videoURL)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct DraftListView: UIViewControllerRepresentable {
    let onDraftSelected: (VideoEditingState) -> Void
    
    func makeUIViewController(context: Context) -> DraftListController {
        let controller = DraftListController()
        controller.onDraftSelected = onDraftSelected
        return controller
    }
    
    func updateUIViewController(_ uiViewController: DraftListController, context: Context) {
        // No updates needed
    }
}

// MARK: - App Entry Point
@main
struct VideoEditingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}