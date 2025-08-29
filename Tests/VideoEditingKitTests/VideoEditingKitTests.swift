import XCTest
@testable import VideoEditingKit
import AVFoundation

@available(iOS 14.0, *)
final class VideoEditingKitTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Clean up any existing test data
        UserDefaults.standard.removeObject(forKey: "testUserVideoEditingDictionary")
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        UserDefaults.standard.removeObject(forKey: "testUserVideoEditingDictionary")
    }
    
    func testVideoEditingKitSharedInstance() throws {
        let kit1 = VideoEditingKit.shared
        let kit2 = VideoEditingKit.shared
        
        XCTAssertTrue(kit1 === kit2, "VideoEditingKit should be a singleton")
    }
    
    func testDraftManagerSingleton() throws {
        let manager1 = DraftManager.shared
        let manager2 = DraftManager.shared
        
        XCTAssertTrue(manager1 === manager2, "DraftManager should be a singleton")
    }
    
    func testDraftLimit() throws {
        let manager = DraftManager.shared
        let hasSpace = manager.checkLimitOfDrafts()
        
        XCTAssertTrue(hasSpace, "Should have space for drafts initially")
    }
    
    func testVideoEditingStateModel() throws {
        let state = VideoEditingState(
            videoTag: "test123",
            videoURL: "test.mp4",
            canvasFrame: "{{0,0},{100,100}}"
        )
        
        XCTAssertEqual(state.videoTag, "test123")
        XCTAssertEqual(state.videoURL, "test.mp4")
        XCTAssertEqual(state.videoAudioVolume, 1.0)
        XCTAssertEqual(state.voiceOverAudioVolume, 1.0)
        XCTAssertEqual(state.siteAudioVolume, 1.0)
    }
    
    func testAudioModel() throws {
        let audio = AudioModel(startTime: 5.0, endTime: 10.0, audioPath: "audio.m4a")
        
        XCTAssertEqual(audio.startTime, 5.0)
        XCTAssertEqual(audio.endTime, 10.0)
        XCTAssertEqual(audio.audioPath, "audio.m4a")
    }
    
    func testDrawnPoint() throws {
        let point = DrawnPoint(x: 100, y: 200, color: "#FF0000")
        
        XCTAssertEqual(point.x, 100)
        XCTAssertEqual(point.y, 200)
        XCTAssertEqual(point.color, "#FF0000")
    }
    
    func testTextViewStateDuration() throws {
        let duration = TextViewStateDuration(beginTime: 2.0, duration: 5.0)
        
        XCTAssertEqual(duration.beginTime, 2.0)
        XCTAssertEqual(duration.duration, 5.0)
    }
    
    func testFilePathGeneration() throws {
        let manager = DraftManager.shared
        let filePath = manager.getFilePath(uniqueId: "test123", fileName: "test.mp4")
        
        XCTAssertNotNil(filePath)
        XCTAssertTrue(filePath?.absoluteString.contains("DraftVideotest123") == true)
        XCTAssertTrue(filePath?.absoluteString.contains("test.mp4") == true)
    }
    
    func testEmptyDraftsArray() throws {
        let manager = DraftManager.shared
        let drafts = manager.getDraftsArray()
        
        // Should be nil when no drafts exist
        XCTAssertNil(drafts)
    }
    
    func testVideoCompositionErrorDescriptions() throws {
        let noVideoTrackError = VideoCompositionError.noVideoTrack
        let failedTrackError = VideoCompositionError.failedToCreateTrack
        let failedExporterError = VideoCompositionError.failedToCreateExporter
        let exportFailedError = VideoCompositionError.exportFailed
        
        XCTAssertFalse(noVideoTrackError.localizedDescription.isEmpty)
        XCTAssertFalse(failedTrackError.localizedDescription.isEmpty)
        XCTAssertFalse(failedExporterError.localizedDescription.isEmpty)
        XCTAssertFalse(exportFailedError.localizedDescription.isEmpty)
    }
    
    func testAudioRecordingErrorDescriptions() throws {
        let filePathError = AudioRecordingError.failedToCreateFilePath
        let recordingError = AudioRecordingError.recordingInProgress
        let noRecordingError = AudioRecordingError.noActiveRecording
        
        XCTAssertFalse(filePathError.localizedDescription.isEmpty)
        XCTAssertFalse(recordingError.localizedDescription.isEmpty)
        XCTAssertFalse(noRecordingError.localizedDescription.isEmpty)
    }
    
    func testDraftManagerErrorDescriptions() throws {
        let documentsError = DraftManagerError.documentsDirectoryNotFound
        let dataError = DraftManagerError.dataLoadFailed
        let imageError = DraftManagerError.imageConversionFailed
        let noDataError = DraftManagerError.noDataProvided
        
        XCTAssertFalse(documentsError.localizedDescription.isEmpty)
        XCTAssertFalse(dataError.localizedDescription.isEmpty)
        XCTAssertFalse(imageError.localizedDescription.isEmpty)
        XCTAssertFalse(noDataError.localizedDescription.isEmpty)
    }
    
    func testUIColorHexString() throws {
        let redColor = UIColor.red
        let hexString = redColor.hexString
        
        XCTAssertEqual(hexString, "#FF0000")
    }
    
    func testFileManagerRemoveIfExists() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.txt")
        
        // Create a test file
        try "test content".write(to: tempURL, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))
        
        // Remove it using our extension
        FileManager.default.removeItemIfExisted(tempURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempURL.path))
        
        // Should not crash when file doesn't exist
        FileManager.default.removeItemIfExisted(tempURL)
    }
}