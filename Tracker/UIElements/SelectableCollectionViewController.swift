import UIKit

final class SelectableCollectionViewController: UIViewController {
    
    private let items: [CollectionItem]
    private let headerTitle: String
    private var selectedIndexPath: IndexPath?
    
    var onItemSelected: ((CollectionItem) -> Void)?
    
    init(items: [CollectionItem], headerTitle: String) {
        self.items = items
        self.headerTitle = headerTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        layout.headerReferenceSize = CGSize(width: view.bounds.width, height: 44)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = AppColors.background
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SelectableCell.self, forCellWithReuseIdentifier: SelectableCell.reuseId)
        collectionView.register(HeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: HeaderView.reuseId)
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppLayout.padding),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppLayout.padding),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UICollectionViewDataSource
extension SelectableCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SelectableCell.reuseId,
            for: indexPath
        ) as! SelectableCell
        
        let isSelected = indexPath == selectedIndexPath
        cell.configure(with: items[indexPath.item], isSelected: isSelected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: HeaderView.reuseId,
            for: indexPath
        ) as! HeaderView
        header.titleLabel.text = headerTitle
        return header
    }
}

// MARK: - UICollectionViewDelegate
extension SelectableCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedIndexPath == indexPath {
            selectedIndexPath = nil
        } else {
            selectedIndexPath = indexPath
        }
        collectionView.reloadData()
        onItemSelected?(items[indexPath.item])
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension SelectableCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 52, height: 52)
    }
}

final class SelectableCell: UICollectionViewCell {
    static let reuseId = "SelectableCell"
    
    private let label = UILabel()
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.font = AppFonts.bigTitle
        label.textAlignment = .center
        label.isHidden = true
        
        contentView.addSubview(label)
        contentView.addSubview(colorView)
        label.translatesAutoresizingMaskIntoConstraints = false
        colorView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 40),
            colorView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        contentView.layer.cornerRadius = AppLayout.cornerRadius
        contentView.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(with item: CollectionItem, isSelected: Bool) {
        switch item {
        case .emoji(let emoji):
            label.text = emoji
            label.isHidden = false
            colorView.isHidden = true
            
            contentView.backgroundColor = isSelected
            ? UIColor.systemGray5.withAlphaComponent(0.4)
            : UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemGray6.withAlphaComponent(0.3)
                : AppColors.background
            }
            
            contentView.layer.borderWidth = isSelected ? 2 : 0
            contentView.layer.borderColor = isSelected ? UIColor.systemGray4.cgColor : nil
            
        case .color(let color):
            label.isHidden = true
            colorView.isHidden = false
            colorView.backgroundColor = color
            
            contentView.backgroundColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemBackground
                : AppColors.background
            }
            
            contentView.layer.borderWidth = isSelected ? 2 : 0
            contentView.layer.borderColor = isSelected ? UIColor.systemGray4.cgColor : nil
        }
    }
}

final class HeaderView: UICollectionReusableView {
    static let reuseId = "HeaderView"
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bold(19)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(white: 1.0, alpha: 0.9) : AppColors.backgroundBlackButton
        }
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppLayout.padding),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppLayout.padding),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
