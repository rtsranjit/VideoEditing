# VideoEditingKit - Project Setup Guide

## 📋 Integration Checklist

### 1. **Add Package Dependency**

#### Method A: Local Package (Recommended for Development)
```
1. Open your project in Xcode
2. File → Add Package Dependencies
3. Click "Add Local..."
4. Navigate to: /Users/sveltetech/Desktop/VideoEditing
5. Click "Add Package"
6. Select target and click "Add Package"
```

#### Method B: Git Repository
```bash
# First, make VideoEditingKit a git repository
cd /Users/sveltetech/Desktop/VideoEditing
git init
git add .
git commit -m "Initial VideoEditingKit package"

# Optional: Push to remote repository
git remote add origin YOUR_GIT_URL
git push -u origin main
```

Then in Xcode:
```
1. File → Add Package Dependencies
2. Enter URL: YOUR_GIT_URL (or local path)
3. Select version/branch
4. Click "Add Package"
```

### 2. **Required Permissions (Info.plist)**

Add these permissions to your app's `Info.plist`:

```xml
<!-- Microphone for voice-over recording -->
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record voice-overs for videos.</string>

<!-- Photo Library for video access and saving -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to import and save videos.</string>

<!-- Camera for video recording (if needed) -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to record videos.</string>

<!-- Optional: Background audio -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### 3. **Minimum Deployment Targets**

Ensure your project targets match VideoEditingKit requirements:

```
iOS: 14.0+
macOS: 11.0+
tvOS: 14.0+
watchOS: 7.0+
Swift: 5.5+
```

### 4. **Basic Import & Usage**

```swift
import VideoEditingKit
import AVFoundation
import Photos

@available(iOS 14.0, *)
class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Basic usage
        let videoURL = // your video URL
        let editor = VideoEditingKit.shared.createVideoEditor(with: videoURL)
        present(editor, animated: true)
    }
}
```

## 🔧 Configuration Options

### 1. **User ID Configuration**
Set a custom user ID for draft management:

```swift
UserDefaults.standard.set("your_user_id", forKey: "userId")
```

### 2. **Draft Limit Configuration**
The default draft limit is 10. To check availability:

```swift
let canCreateDraft = VideoEditingKit.shared.checkDraftLimit()
if !canCreateDraft {
    // Handle draft limit reached
    print("Draft limit reached. Delete some drafts first.")
}
```

### 3. **File Management**
VideoEditingKit stores files in:
```
Documents/DraftVideo{uniqueId}/
```

To clean up old drafts:
```swift
// Get all drafts
let drafts = VideoEditingKit.shared.getDrafts()

// Delete specific draft
DraftManager.shared.deleteFromDocumentDirectory(uniqueId: "draft_id")
```

## 📱 Platform-Specific Considerations

### iOS App
- Add camera/microphone permissions
- Handle video picker presentation
- Save exported videos to Photos

### SwiftUI App
- Use UIViewControllerRepresentable wrappers
- Handle sheet presentations
- Manage state with @State variables

### macOS App
- Different file system permissions
- Alternative audio session configuration
- Different UI presentation styles

## 🚀 Quick Start Examples

### Simple Integration
```swift
// Create and present editor
let editor = VideoEditingKit.shared.createVideoEditor(with: videoURL)
present(editor, animated: true)
```

### With Completion Handling
```swift
let editor = VideoEditingKit.shared.createVideoEditor(with: videoURL)

// Handle export completion
editor.exportVideo(progressHandler: { progress in
    print("Progress: \(Int(progress * 100))%")
}) { result in
    switch result {
    case .success(let exportedURL):
        print("Video exported: \(exportedURL)")
    case .failure(let error):
        print("Export failed: \(error)")
    }
}
```

### Draft Management
```swift
// Save draft
let success = editor.saveDraft()

// Load drafts
let drafts = VideoEditingKit.shared.getDrafts()

// Present draft list
let draftController = DraftListController()
draftController.onDraftSelected = { draft in
    // Handle draft selection
}
present(draftController, animated: true)
```

## 🛠️ Troubleshooting

### Common Issues

1. **"Module not found"**
   - Ensure package is added to target
   - Clean build folder (Cmd+Shift+K)
   - Rebuild project

2. **Permissions not working**
   - Check Info.plist entries
   - Test on device (not simulator)
   - Request permissions before using features

3. **Audio recording fails**
   - Verify microphone permission
   - Check audio session configuration
   - Test with different audio formats

4. **Video export crashes**
   - Ensure sufficient storage space
   - Check video format compatibility
   - Verify output URL is valid

5. **Drafts not saving**
   - Check draft limit (max 10)
   - Verify file system permissions
   - Check available storage space

### Performance Tips

1. **Memory Management**
   - Don't hold strong references to editors
   - Clean up completed exports
   - Monitor memory usage during long sessions

2. **Storage Management**
   - Regularly clean old drafts
   - Compress videos when possible
   - Monitor available disk space

3. **Battery Optimization**
   - Pause video playback when not visible
   - Reduce preview quality during editing
   - Use background processing for exports

## 📚 Additional Resources

- [Advanced Integration Examples](Examples/Advanced-Custom-Integration.swift)
- [SwiftUI Integration](Examples/SwiftUI-Integration.swift) 
- [iOS App Integration](Examples/iOS-App-Integration.swift)
- [API Documentation](README.md)

## 🆘 Support

If you encounter issues:

1. Check this setup guide
2. Review example implementations
3. Check the main README.md
4. Create an issue with reproduction steps