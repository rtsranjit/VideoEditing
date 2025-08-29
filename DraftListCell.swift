//
//  DraftListCell.swift
//  sesiosnativeapp
//
//  Created by Ranjit Singh on 29/03/24.
//  Copyright © 2024 rtsranjit. All rights reserved.
//

import Foundation

class DraftListCell: UICollectionViewCell {
    
    var videoImage: UIImageView!
    var videoTextImage: UIImageView!
    
    var deleteBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        videoImage = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        videoImage.layer.masksToBounds = true
        videoImage.layer.cornerRadius = 5
        videoImage.contentMode = .scaleAspectFill
        self.addSubview(videoImage)
        
        videoTextImage = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        videoTextImage.layer.masksToBounds = true
        videoTextImage.layer.cornerRadius = 5
        videoTextImage.contentMode = .scaleAspectFill
        self.addSubview(videoTextImage)
       
        deleteBtn = UIButton(frame: CGRect(x: self.frame.width-35, y: 5, width: 30, height: 30))
        deleteBtn.layer.shadowColor = UIColor.black.cgColor
        deleteBtn.layer.shadowRadius = 6.0
        deleteBtn.layer.shadowOpacity = 1.0
        deleteBtn.layer.shadowOffset = CGSize(width: 0, height: 0)
        deleteBtn.layer.masksToBounds = false
        deleteBtn.setImage(UIImage(systemName: "trash")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: UIControl.State())
        deleteBtn.isUserInteractionEnabled = true
        self.addSubview(deleteBtn)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
