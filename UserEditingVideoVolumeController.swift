//
//  UserEditingVideoVolumeController.swift
//  sesiosnativeapp
//
//  Created by Ranjit Singh on 03/05/24.
//  Copyright © 2024 rtsranjit. All rights reserved.
//

import Foundation

class UserEditingVideoVolumeController: UIViewController {
    
    weak var userEditingVC: UserEditingVideoViewController?
        
    override func viewDidLoad() {
        initializeViews()
    }
    
}

extension UserEditingVideoVolumeController {
    
    func initializeViews() {
                
        // Labels and sliders
        var labels = [NSLocalizedString("Video Audio", comment: "")]
        
        var voiceOverNotAdded = false
        if let count = userEditingVC?.voiceOverVC.audioArray.count,
           count>0 {
            labels.append(NSLocalizedString("Voice-Over Audio", comment: ""))
        } else {
            voiceOverNotAdded = true
        }
        
        if userEditingVC?.adjustedMusicDuration != nil {
            labels.append(NSLocalizedString("Site Audio", comment: ""))
        }
        
        // Calculate the height of the popup view based on the number of sliders and labels
        let numberOfSliders = labels.count
        let popupHeight = CGFloat(numberOfSliders) * 80 + 180 // Adjusted height based on slider and label heights
        
        // Transparent view
        let transparentView = UIView(frame: CGRect(x: 0, y: 0, width: appWidth, height: appHeight - popupHeight))
        transparentView.backgroundColor = .clear
        let gesture = UITapGestureRecognizer(target: self, action: #selector(closeButtonTapped))
        transparentView.addGestureRecognizer(gesture)
        view.addSubview(transparentView)
        
        // Blur effect view
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = CGRect(x: 0, y: appHeight - popupHeight, width: appWidth, height: popupHeight)
        blurEffectView.layer.cornerRadius = 20
        blurEffectView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        blurEffectView.layer.masksToBounds = true
        view.addSubview(blurEffectView)
        
        // Popup view
        let popUpView = UIView(frame: CGRect(x: 0, y: appHeight - popupHeight, width: appWidth, height: popupHeight))
        popUpView.backgroundColor = .clear
        popUpView.layer.cornerRadius = 20
        popUpView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        popUpView.isUserInteractionEnabled = true
        view.addSubview(popUpView)
        
        // Voice over text label
        let voiceOverText = UILabel(frame: CGRect(x: 0, y: 10, width: appWidth, height: 40))
        voiceOverText.textAlignment = .center
        voiceOverText.text = NSLocalizedString("Volume controls", comment: "")
        voiceOverText.textColor = .white
        voiceOverText.font = UIFont.boldSystemFont(ofSize: 20)
        popUpView.addSubview(voiceOverText)
        
        // Stack view to hold all label-slider pairs
        let stackView = UIStackView(frame: CGRect(x: 20, y: 70, width: appWidth - 40, height: CGFloat(numberOfSliders) * 80.0))
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = 0

        for index in 0..<labels.count {
            
            // Create a sub-stack view for each label-slider pair
            let stackSubView = UIStackView()
            stackSubView.axis = .vertical
            stackSubView.alignment = .fill
            stackSubView.distribution = .fill
            stackSubView.spacing = 10

            // Create label
            let label = UILabel()
            label.text = labels[index]
            label.textColor = .white
            label.textAlignment = .left
            stackSubView.addArrangedSubview(label)

            // Create slider
            let slider = UISlider()
            
            var count = index
            if count==1 && voiceOverNotAdded {
                count = 2
            }
            slider.tag = count
            
            if slider.tag == 0 {
                slider.value = self.userEditingVC?.playerVolume ?? 1.0
            } else if slider.tag == 1 {
                slider.value = self.userEditingVC?.voiceOverAudioVolume ?? 1.0
            } else if slider.tag == 2 {
                slider.value = self.userEditingVC?.audioPlayer?.volume ?? 1.0
            }
            
            slider.tintColor = .white
            slider.minimumTrackTintColor = .lightGray
            slider.minimumValueImage = UIImage(systemName: "speaker.fill")
            slider.maximumValueImage = UIImage(systemName: "speaker.wave.3.fill")
            slider.setThumbImage(getThumbImage(slider.value), for: .normal)
            slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
            stackSubView.addArrangedSubview(slider)

            // Add the sub-stack view (label-slider pair) to the main stack view
            stackView.addArrangedSubview(stackSubView)
        }

        popUpView.addSubview(stackView)
        
        // Done button
        let bottomSafeAreaHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0.0
        
        let doneButton = UIButton()
        doneButton.backgroundColor = .gray
        doneButton.setTitle(NSLocalizedString("Done", comment: ""), for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.layer.masksToBounds = true
        doneButton.layer.cornerRadius = 20
        doneButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        popUpView.addSubview(doneButton)
        
        // Set constraints for done button
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.leadingAnchor.constraint(equalTo: popUpView.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: popUpView.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: popUpView.bottomAnchor, constant: -0 - bottomSafeAreaHeight),
            doneButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

}

extension UserEditingVideoVolumeController {
    
    @objc func closeButtonTapped() {
        self.dismiss(animated: true)
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        sender.setThumbImage(getThumbImage(sender.value), for: UIControl.State())
        
        // Calculate the volume value from the slider's value
        let volume = sender.value
        
        // Determine which player's volume to update based on the slider's tag
        switch sender.tag {
        case 0: // Video Audio slider
            self.userEditingVC?.playerVolume = volume
            self.userEditingVC?.player.volume = volume
        case 1: // Voice-Over Audio slider
            self.userEditingVC?.voiceOverAudioVolume = volume
            self.userEditingVC?.voiceOverVC.audioPlayer?.volume = volume
        case 2: // Site Audio slider
            self.userEditingVC?.audioPlayer?.volume = volume
        default:
            break
        }
    }
        
    func getThumbImage(_ value: Float) -> UIImage {
        return UIImage(systemName: "\(Int(value*10)).circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .thin, scale: .medium))?.withRenderingMode(.alwaysOriginal).withTintColor(.white) ?? UIImage()
    }
}
