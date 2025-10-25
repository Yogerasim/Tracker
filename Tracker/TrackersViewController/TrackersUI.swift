import UIKit

final class TrackersUI {
    
    // MARK: - Buttons
    lazy var filtersButton: FiltersButton = {
        let button = FiltersButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 20).isActive = true
        button.heightAnchor.constraint(equalToConstant: 20).isActive = true
        if let image = UIImage(resource: .plus)?.withRenderingMode(.alwaysTemplate) {
            button.setImage(image, for: .normal)
        }
        button.tintColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
            ? AppColors.textPrimary
            : AppColors.backgroundBlackButton
        }
        button.imageView?.contentMode = .scaleAspectFit
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 11.5, bottom: 12, trailing: 11.5)
        return button
    }()
    
    lazy var dateButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 77).isActive = true
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.layer.cornerRadius = 12
        button.titleLabel?.font = AppFonts.caption2
        button.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
            ? AppColors.textPrimary
            : AppColors.textSecondary.withAlphaComponent(0.1)
        }
        button.setTitleColor(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
            ? AppColors.backgroundBlackButton
            : AppColors.textPrimary
        }, for: .normal)
        
        return button
    }()
    
    // MARK: - Search Bar
    let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = NSLocalizedString("trackers.search_placeholder", comment: "")
        sb.searchBarStyle = .minimal
        sb.backgroundImage = UIImage()
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()
    
    // MARK: - CollectionView
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                                  heightDimension: .absolute(140))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(150))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 16, trailing: 0)
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .estimated(40))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            section.boundarySupplementaryItems = [sectionHeader]
            
            return section
        }
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = AppColors.background
        cv.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.reuseIdentifier)
        cv.register(TrackerSectionHeaderView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier)
        return cv
    }()
    
    // MARK: - Title and Placeholder
    let titleView = MainTitleLabelView(title: NSLocalizedString("trackers.title", comment: ""))
    let placeholderView = PlaceholderView()
    
    // MARK: - Calendar
    lazy var calendarView: UIDatePicker = {
        let dp = UIDatePicker()
        dp.translatesAutoresizingMaskIntoConstraints = false
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .inline
        dp.locale = Locale(identifier: "ru_RU")
        dp.calendar = Calendar(identifier: .gregorian)
        dp.backgroundColor = AppColors.background
        return dp
    }()
    
    lazy var calendarContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = AppColors.background
        container.layer.cornerRadius = AppLayout.cornerRadius
        container.isHidden = true
        container.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            calendarView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            calendarView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            calendarView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }()
}
