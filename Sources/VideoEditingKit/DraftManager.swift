import Foundation
import UIKit

@available(iOS 14.0, *)
public class DraftManager {
    
    public static let shared = DraftManager()
    
    private let maxDrafts = 10
    private var userId: String {
        return UserDefaults.standard.string(forKey: "userId") ?? "defaultUser"
    }
    
    private init() {}
    
    public func getDraftsArray() -> [VideoEditingState]? {
        guard let savedArrayData = UserDefaults.standard.data(forKey: "\(userId)VideoEditingDictionary"),
              let videoEditingDictionary = try? JSONDecoder().decode([String: VideoEditingState].self, from: savedArrayData) else {
            return nil
        }
        
        let draftsArray = videoEditingDictionary.values.sorted { $0.createdTime < $1.createdTime }
        return draftsArray
    }
    
    public func saveDraft(_ draft: VideoEditingState) -> Bool {
        guard checkLimitOfDrafts() else { return false }
        
        let key = "\(userId)VideoEditingDictionary"
        var draftsDict: [String: VideoEditingState] = [:]
        
        if let savedArrayData = UserDefaults.standard.data(forKey: key),
           let existingDict = try? JSONDecoder().decode([String: VideoEditingState].self, from: savedArrayData) {
            draftsDict = existingDict
        }
        
        draftsDict[draft.videoTag] = draft
        
        if let encodedData = try? JSONEncoder().encode(draftsDict) {
            UserDefaults.standard.set(encodedData, forKey: key)
            UserDefaults.standard.synchronize()
            return true
        }
        
        return false
    }
    
    public func checkLimitOfDrafts() -> Bool {
        if let savedArrayData = UserDefaults.standard.data(forKey: "\(userId)VideoEditingDictionary"),
           let videoEditingDictionary = try? JSONDecoder().decode([String: VideoEditingState].self, from: savedArrayData) {
            return videoEditingDictionary.count < maxDrafts
        }
        return true
    }
    
    public func getFilePath(uniqueId: String, fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return nil
        }
        
        let folderPath = documentsDirectory.appendingPathComponent("DraftVideo\(uniqueId)", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: folderPath.path) {
            do {
                try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating folder: \(error)")
                return nil
            }
        }
        
        return folderPath.appendingPathComponent(fileName)
    }
    
    public func saveFileToDocumentDirectory(
        uniqueId: String,
        fileName: String,
        image: UIImage? = nil,
        file: URL? = nil,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            completion(.failure(DraftManagerError.documentsDirectoryNotFound))
            return
        }
        
        let folderPath = documentsDirectory.appendingPathComponent("DraftVideo\(uniqueId)", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: folderPath.path) {
            do {
                try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        let fileURL = folderPath.appendingPathComponent(fileName)
        
        if let videoURL = file {
            URLSession.shared.dataTask(with: videoURL) { data, response, error in
                guard let data = data, error == nil else {
                    completion(.failure(error ?? DraftManagerError.dataLoadFailed))
                    return
                }
                
                do {
                    try data.write(to: fileURL, options: .atomic)
                    completion(.success(fileURL))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } else if let image = image {
            guard let imageData = image.pngData() else {
                completion(.failure(DraftManagerError.imageConversionFailed))
                return
            }
            
            do {
                try imageData.write(to: fileURL)
                completion(.success(fileURL))
            } catch {
                completion(.failure(error))
            }
        } else {
            completion(.failure(DraftManagerError.noDataProvided))
        }
    }
    
    public func loadFileFromDocumentDirectory(uniqueId: String, fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let folderPath = documentsDirectory.appendingPathComponent("DraftVideo\(uniqueId)", isDirectory: true)
        let fileURL = folderPath.appendingPathComponent(fileName)
        
        return fileURL
    }
    
    public func checkFileExistInDocumentDirectory(uniqueId: String, fileName: String) -> URL? {
        guard !fileName.isEmpty else {
            return nil
        }
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let folderPath = documentsDirectory.appendingPathComponent("DraftVideo\(uniqueId)", isDirectory: true)
        let fileURL = folderPath.appendingPathComponent(fileName)
        
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    public func deleteFromDocumentDirectory(uniqueId: String, fileName: String? = nil) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let folderPath = documentsDirectory.appendingPathComponent("DraftVideo\(uniqueId)", isDirectory: true)
        
        if let fileName = fileName {
            let filePath = folderPath.appendingPathComponent(fileName)
            do {
                try FileManager.default.removeItem(at: filePath)
                print("File \(filePath) deleted successfully")
            } catch {
                print("Error deleting file: \(error)")
            }
            return
        }
        
        do {
            try FileManager.default.removeItem(at: folderPath)
            print("Directory \(folderPath) deleted successfully")
        } catch {
            print("Error deleting directory: \(error)")
        }
        
        let key = "\(userId)VideoEditingDictionary"
        
        guard let savedArrayData = UserDefaults.standard.data(forKey: key),
              var videoEditingDictionary = try? JSONDecoder().decode([String: VideoEditingState].self, from: savedArrayData),
              !videoEditingDictionary.isEmpty else {
            return
        }

        if videoEditingDictionary.count == 1 {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            videoEditingDictionary.removeValue(forKey: uniqueId)
            
            if let encodedData = try? JSONEncoder().encode(videoEditingDictionary) {
                UserDefaults.standard.set(encodedData, forKey: key)
            }
        }
        
        UserDefaults.standard.synchronize()
    }
    
    public func deleteFile(filePath: URL) {
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
}

public enum DraftManagerError: Error {
    case documentsDirectoryNotFound
    case dataLoadFailed
    case imageConversionFailed
    case noDataProvided
    
    public var localizedDescription: String {
        switch self {
        case .documentsDirectoryNotFound:
            return "Documents directory not found"
        case .dataLoadFailed:
            return "Failed to load data"
        case .imageConversionFailed:
            return "Failed to convert image to PNG data"
        case .noDataProvided:
            return "No data provided for saving"
        }
    }
}