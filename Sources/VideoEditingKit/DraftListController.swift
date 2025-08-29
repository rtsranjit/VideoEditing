import Foundation
import UIKit

@available(iOS 14.0, *)
public class DraftListController: UIViewController {
    
    private lazy var closeButton = UIButton()
    private lazy var titleLabel = UILabel()
    private lazy var infoButton = UIButton()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    
    private var draftsArray: [VideoEditingState]? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    public var onDraftSelected: ((VideoEditingState) -> Void)?
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDrafts()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDrafts()
    }
    
    private func loadDrafts() {
        draftsArray = DraftManager.shared.getDraftsArray()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let safeArea = view.safeAreaLayoutGuide
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .label
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Drafts"
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = .label
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)
        view.addSubview(infoButton)
        
        setupCollectionView()
        
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            closeButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            
            infoButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            infoButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: 44),
            infoButton.heightAnchor.constraint(equalToConstant: 44),
            
            collectionView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }
    
    private func setupCollectionView() {
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        let numberOfItems: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
        let spacing: CGFloat = 10
        let availableWidth = view.frame.width - 32 - (spacing * (numberOfItems - 1))
        let itemWidth = availableWidth / numberOfItems
        
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.2)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(DraftCell.self, forCellWithReuseIdentifier: "DraftCell")
        view.addSubview(collectionView)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func infoTapped() {
        let alert = UIAlertController(
            title: "About Drafts",
            message: "Drafts are stored on your device. If you uninstall the app, all drafts will be lost.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func deleteTapped(_ sender: UIButton) {
        guard let drafts = draftsArray, sender.tag < drafts.count else { return }
        
        let draft = drafts[sender.tag]
        
        let alert = UIAlertController(
            title: "Delete Draft?",
            message: "Are you sure you want to delete this draft?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            DraftManager.shared.deleteFromDocumentDirectory(uniqueId: draft.videoTag)
            self.loadDrafts()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension DraftListController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return draftsArray?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DraftCell", for: indexPath) as! DraftCell
        
        guard let drafts = draftsArray, indexPath.item < drafts.count else { return cell }
        let draft = drafts[indexPath.item]
        
        cell.configure(with: draft)
        cell.deleteButton.tag = indexPath.item
        cell.deleteButton.addTarget(self, action: #selector(deleteTapped(_:)), for: .touchUpInside)
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let drafts = draftsArray, indexPath.item < drafts.count else { return }
        let draft = drafts[indexPath.item]
        
        onDraftSelected?(draft)
    }
}

@available(iOS 14.0, *)
class DraftCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let textImageView = UIImageView()
    let deleteButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .systemGray6
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        contentView.addSubview(imageView)
        
        textImageView.contentMode = .scaleAspectFill
        textImageView.layer.cornerRadius = 8
        textImageView.layer.masksToBounds = true
        contentView.addSubview(textImageView)
        
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .white
        deleteButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        deleteButton.layer.cornerRadius = 15
        deleteButton.layer.shadowColor = UIColor.black.cgColor
        deleteButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        deleteButton.layer.shadowOpacity = 0.3
        deleteButton.layer.shadowRadius = 4
        contentView.addSubview(deleteButton)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        textImageView.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            textImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            textImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            deleteButton.widthAnchor.constraint(equalToConstant: 30),
            deleteButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func configure(with draft: VideoEditingState) {
        if let thumbnailName = draft.videoThumbnail?.first,
           let thumbnailURL = DraftManager.shared.checkFileExistInDocumentDirectory(uniqueId: draft.videoTag, fileName: thumbnailName),
           let thumbnailData = try? Data(contentsOf: thumbnailURL) {
            imageView.image = UIImage(data: thumbnailData)
        }
        
        if let textLayerURL = DraftManager.shared.checkFileExistInDocumentDirectory(uniqueId: draft.videoTag, fileName: "TextLayer.png"),
           let textLayerData = try? Data(contentsOf: textLayerURL) {
            textImageView.image = UIImage(data: textLayerData)
        }
    }
}