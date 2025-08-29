//
//  DraftListViewController.swift
//  sesiosnativeapp
//
//  Created by APPLE AHEAD on 29/03/24.
//  Copyright © 2024 SocialEngineSolutions. All rights reserved.
//

import Foundation
import UIKit

class DraftListViewController: UIViewController {
    
    private lazy var closeBtn = UIButton()
    private lazy var titleLabel = UILabel()
    private lazy var infoBtn = UIButton()
    
    private lazy var collectionView = UICollectionView()
    
    var draftsArray: [UserEditingVideoState]? = DraftVideoManager.shared.getDraftsArray()
    
    init() {
        super.init(nibName: nil, bundle: nil) // Call designated initializer of UIViewController
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad() // Ensure to call the superclass's viewDidLoad() method
        self.initializeViews()
    }
}

extension DraftListViewController {
    
    func initializeViews() {
        
        self.view.backgroundColor = appforgroundcolor
        
        let topSafeAreaHeight = (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0.0)
        
        closeBtn.frame = CGRect(x: 10, y: topSafeAreaHeight, width: 40, height: 40)
        closeBtn.setImage(UIImage(systemName: "xmark")?.withRenderingMode(.alwaysOriginal).withTintColor(appFontColor), for: UIControl.State())
        closeBtn.addTarget(self, action: #selector(self.backBtnTapped), for: .touchUpInside)
        closeBtn.isUserInteractionEnabled = true
        closeBtn.backgroundColor = .clear
        closeBtn.setBackgroundColor(color: .clear, forState: UIControl.State())
        self.view.addSubview(closeBtn)
        
        titleLabel.frame = CGRect(x: (appWidth-(100/2))/2, y: topSafeAreaHeight, width: 100, height: 40)
        titleLabel.text = NSLocalizedString("drafts", comment: "").capitalized
        titleLabel.textColor = appFontColor
        titleLabel.font = UIFont(name: boldFont, size: fontSizeVeryVeryLarge)
        self.view.addSubview(titleLabel)
        
        infoBtn.frame = CGRect(x: view.frame.width-40-10, y: topSafeAreaHeight, width: 40, height: 40)
        infoBtn.setImage(UIImage(systemName: "info.circle")?.withRenderingMode(.alwaysOriginal).withTintColor(appFontColor), for: UIControl.State())
        infoBtn.addTarget(self, action: #selector(self.infoBtnTapped), for: .touchUpInside)
        infoBtn.isUserInteractionEnabled = true
        infoBtn.backgroundColor = .clear
        infoBtn.setBackgroundColor(color: .clear, forState: UIControl.State())
        self.view.addSubview(infoBtn)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let numberOfItems: CGFloat = (isIpad ? 5 : 3)
        layout.itemSize = CGSize(width: (appWidth-20-(10*(numberOfItems+1)))/numberOfItems, height: 160)
        
        collectionView = UICollectionView(frame: CGRect(x: 10, y: topSafeAreaHeight+titleLabel.frame.height, width: appWidth-20, height: appHeight-(topSafeAreaHeight+20)), collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.register(DraftListCell.self, forCellWithReuseIdentifier: "DraftListCell")
        self.view.addSubview(collectionView)
    }
    
    @objc func backBtnTapped() {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
    
    @objc func infoBtnTapped() {
        let alertController = UIAlertController(title: NSLocalizedString("About drafts", comment: ""), message: NSLocalizedString("Drafts are stored on your device. If you uninstall the app, all the drafts will be lost.", comment: ""), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func deleteBtnTapped(_ sender: UIButton) {
        let name = NSLocalizedString("draft", comment: "")
        showConfirmationAlert(NSLocalizedString("Delete", comment: ""),title: NSLocalizedString("Delete \(name)?", comment: ""), message: NSLocalizedString("Are you sure that you want to delete this \(name)?", comment: ""), presentWindow: self, success: { () -> Void in
            if let uniqueId = self.draftsArray?[sender.tag].videoTag {
                DraftVideoManager.shared.deleteFromDocumentDirectory(uniqueId: uniqueId)
                self.updateDraftsArray()
            }
        }) { () -> Void in
            print("user canceled")
        }
    }
    
    func updateDraftsArray() {
        self.draftsArray = DraftVideoManager.shared.getDraftsArray()
        self.collectionView.reloadData()
    }
}

extension DraftListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return draftsArray?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DraftListCell", for: indexPath) as! DraftListCell
        
        guard let draftsArray else { return cell }

        // Load canvasImageView's image from String
        if let string = draftsArray[indexPath.item].videoThumbnail?.first,
           let url = DraftVideoManager.shared.checkFileExistInDocumentDirectory(uniqueId: draftsArray[indexPath.item].videoTag, fileName: string) {
            
            if let url = DraftVideoManager.shared.checkFileExistInDocumentDirectory(uniqueId: draftsArray[indexPath.item].videoTag, fileName: "TextLayer.png") {
                do {
                    let data = try Data(contentsOf: url)
                    cell.videoTextImage.image = UIImage(data: data)
                } catch {
                    print("Error loading text image data:", error)
                    // Handle the error appropriately, e.g., show an error message to the user
                }
            }
            
            do {
                let data = try Data(contentsOf: url)
                cell.videoImage.image = UIImage(data: data)
            } catch {
                print("Error loading image data:", error)
                // Handle the error appropriately, e.g., show an error message to the user
            }
        } else {
            print("Error: Unable to load image from document directory")
            // Handle the case where either the filename is missing or the file couldn't be loaded
        }
        
        cell.deleteBtn.addTarget(self, action: #selector(self.deleteBtnTapped(_:)), for: .touchUpInside)
        cell.deleteBtn.tag = indexPath.item
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let draftsArray else { return }
        
        if let url = DraftVideoManager.shared.checkFileExistInDocumentDirectory(uniqueId: draftsArray[indexPath.item].videoTag, fileName: draftsArray[indexPath.item].videoURL) {
            
            let controller = UserEditingVideoViewController(videoURL: url, uniqueId: draftsArray[indexPath.item].videoTag)
            controller.draftVideos = true
            
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}
