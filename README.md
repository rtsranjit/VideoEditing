# VideoEditingKit

A comprehensive Swift Package Manager library for video editing on iOS, macOS, tvOS, and watchOS. Built from production-ready video editing components, VideoEditingKit provides a complete solution for integrating video editing capabilities into your apps.

## Features

- ✅ **Video Composition & Export** - Professional video composition with overlays, text, and audio mixing
- ✅ **Audio Recording & Voice-Over** - Real-time audio recording with voice-over capabilities
- ✅ **Text & Drawing Overlays** - Add text views and drawing annotations to videos
- ✅ **Draft Management** - Save and restore video editing sessions
- ✅ **Multi-Track Audio** - Support for original video audio, voice-over, and background music
- ✅ **Volume Controls** - Individual volume controls for each audio track
- ✅ **File Management** - Comprehensive file handling for video drafts and assets
- ✅ **Modern Swift** - Built with modern Swift patterns and async/await support

## Requirements

- iOS 14.0+ / macOS 11.0+ / tvOS 14.0+ / watchOS 7.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

### Swift Package Manager

Add VideoEditingKit to your project using Swift Package Manager:

1. In Xcode, select **File > Add Packages**
2. Enter the repository URL: `https://github.com/yourusername/VideoEditingKit`
3. Select the version you want to use
4. Click **Add Package**

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/VideoEditingKit", from: "1.0.0")
]
```

## Quick Start

### Basic Video Editing

```swift
import VideoEditingKit
import AVFoundation

// Create a video editor
let videoURL = Bundle.main.url(forResource: "sample", withExtension: "mp4")!
let editor = VideoEditingKit.shared.createVideoEditor(with: videoURL)

// Present the editor
present(editor, animated: true)

// Export the edited video
editor.exportVideo(progressHandler: { progress in
    print("Export progress: \(progress)")
}) { result in
    switch result {
    case .success(let exportedURL):
        print("Video exported to: \(exportedURL)")
    case .failure(let error):
        print("Export failed: \(error)")
    }
}
```

### Working with Drafts

```swift
// Check available draft slots
if VideoEditingKit.shared.checkDraftLimit() {
    // Save current editing session
    let success = editor.saveDraft()
    print("Draft saved: \(success)")
}

// Load existing drafts
if let drafts = VideoEditingKit.shared.getDrafts() {
    let draftController = DraftListController()
    draftController.onDraftSelected = { draft in
        // Resume editing from draft
        print("Selected draft: \(draft.videoTag)")
    }
    present(draftController, animated: true)
}
```

### Audio Recording

```swift
// Start recording voice-over
let currentTime = CMTimeGetSeconds(editor.player.currentTime())
editor.audioRecorder.startRecording(at: currentTime, uniqueId: editor.uniqueId) { result in
    switch result {
    case .success(let fileName):
        print("Recording started, file: \(fileName)")
    case .failure(let error):
        print("Failed to start recording: \(error)")
    }
}

// Stop recording
editor.audioRecorder.stopRecording(at: endTime)

// Play recorded audio
editor.audioRecorder.playAudio(fileName: "userAudio0.m4a", uniqueId: editor.uniqueId)
```

### Custom Video Composition

```swift
import AVFoundation

// Create custom composition
VideoComposer.shared.composeVideo(
    asset: videoAsset,
    canvasImage: overlayImage,
    textViews: textOverlays,
    rangeDict: textTimings,
    voiceOverAudio: voiceRecordings,
    siteAudio: (backgroundMusicURL, adjustedStartTime),
    videoAudioVolume: 0.8,
    voiceOverAudioVolume: 1.0,
    siteAudioVolume: 0.6,
    outputURL: exportURL,
    uniqueId: "unique_session_id",
    progressHandler: { progress in
        // Update progress UI
    },
    completion: { result in
        // Handle completion
    }
)
```

## Architecture

VideoEditingKit is organized into several key components:

### Core Components

- **VideoEditingKit**: Main interface and entry point
- **VideoEditingController**: Primary video editing view controller
- **VideoComposer**: Video composition and export engine
- **AudioRecorder**: Audio recording and playback management
- **DraftManager**: Draft persistence and file management
- **DraftListController**: UI for browsing saved drafts

### Data Models

- **VideoEditingState**: Complete state of a video editing session
- **AudioModel**: Audio clip metadata (start time, end time, file path)
- **TextViewState**: Text overlay state and positioning
- **DrawnPoint**: Drawing annotation data

## Advanced Usage

### Custom Text Overlays with Timing

```swift
// Add text overlay with specific timing
let textState = TextViewState(
    text: "Welcome to my video",
    attributedText: nil,
    frame: NSStringFromCGRect(CGRect(x: 50, y: 100, width: 200, height: 50)),
    bounds: NSStringFromCGRect(CGRect(x: 0, y: 0, width: 200, height: 50)),
    center: NSStringFromCGPoint(CGPoint(x: 150, y: 125)),
    transform: NSStringFromCGAffineTransform(.identity),
    textAlignment: NSTextAlignment.center.rawValue,
    contentSize: NSStringFromCGSize(CGSize(width: 200, height: 50)),
    tag: 1,
    backgroundColorString: "#FFFFFF",
    fontURLString: nil
)

// Set text display timing
editor.rangeDict[1] = TextViewStateDuration(beginTime: 2.0, duration: 5.0)
```

### Volume Control

```swift
// Control individual audio track volumes
editor.playerVolume = 0.8        // Original video audio
editor.voiceOverAudioVolume = 1.0 // Voice-over audio
editor.audioPlayer?.volume = 0.6  // Background music
```

### File Management

```swift
// Save custom files
DraftManager.shared.saveFileToDocumentDirectory(
    uniqueId: "session_id",
    fileName: "custom_overlay.png",
    image: overlayImage
) { result in
    switch result {
    case .success(let url):
        print("File saved at: \(url)")
    case .failure(let error):
        print("Save failed: \(error)")
    }
}

// Check if file exists
if let fileURL = DraftManager.shared.checkFileExistInDocumentDirectory(
    uniqueId: "session_id",
    fileName: "custom_overlay.png"
) {
    print("File exists at: \(fileURL)")
}
```

## Error Handling

VideoEditingKit provides comprehensive error handling:

```swift
// Video composition errors
public enum VideoCompositionError: Error {
    case noVideoTrack
    case failedToCreateTrack
    case failedToCreateExporter
    case exportFailed
}

// Audio recording errors
public enum AudioRecordingError: Error {
    case failedToCreateFilePath
    case recordingInProgress
    case noActiveRecording
}

// Draft management errors
public enum DraftManagerError: Error {
    case documentsDirectoryNotFound
    case dataLoadFailed
    case imageConversionFailed
    case noDataProvided
}
```

## Performance Considerations

- **Memory Management**: VideoEditingKit automatically manages AVFoundation resources
- **File Cleanup**: Draft files are automatically organized and can be cleaned up when no longer needed
- **Background Processing**: Video export runs asynchronously with progress callbacks
- **Draft Limits**: Default limit of 10 drafts per user to prevent storage bloat

## Permissions

Your app will need the following permissions:

```xml
<!-- Info.plist -->
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record voice-overs for videos.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save edited videos.</string>
```

## Example Project

Check out the included example project for complete implementation examples and best practices.

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License

VideoEditingKit is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Support

- 📚 [Documentation](https://github.com/yourusername/VideoEditingKit/wiki)
- 🐛 [Issue Tracker](https://github.com/yourusername/VideoEditingKit/issues)
- 💬 [Discussions](https://github.com/yourusername/VideoEditingKit/discussions)

## Changelog

### v1.0.0
- Initial release
- Core video editing functionality
- Audio recording and voice-over support
- Draft management system
- Text and drawing overlays
- Multi-track audio mixing
- iOS 14+ support