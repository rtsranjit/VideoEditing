//
//  UserEditingVideoModel.swift
//  sesiosnativeapp
//
//  Created by APPLE AHEAD on 29/03/24.
//  Copyright © 2024 SocialEngineSolutions. All rights reserved.
//

import Foundation

struct UserEditingVideoState: Codable {
    
    let videoTag: String
    let createdTime: Date // Property to store the date and time
    
    let videoURL: String
    //    let textColor: String?
    //    let drawColor: String?
    let canvasImage: String?
    let canvasFrame: String
    let textViewsData: [TextViewState]
    
    let videoThumbnail: [String]?
    
    let rangeDict: [Int: TextViewStateDuration]?
    
    let voiceOverModel: [AudioModel]?
    
    let pointsDrawnArray: [[[DrawnPoints]]]
    
    let siteAudioURL: String?
    var adjustedMusicDuration: Double? = nil
    
    var videoAudioVolume: Double
    var voiceOverAudioVolume: Double
    var siteAudioVolume: Double
}

struct DrawnPoints: Codable {
    let x: CGFloat
    let y: CGFloat
    
    let color: String
    
    static let example = DrawnPoints(x: 0, y: 0, color: "#ffffff")
}

struct TextViewState: Codable {
    let text: String?
    let attributedText: Data?
    let frame: String
    let bounds: String
    let center: String
    let transform: String
    let textAlignment: NSTextAlignment.RawValue
    let contentSize: String // Store content size as string
    let tag: Int
    
    let backgroundColorString: String
    
    let fontURLString: String?
}

struct TextViewStateDuration: Codable {
    let beginTime: Double
    let duration: Double
}
