import UIKit

enum MainHeaderLayoutHelper {
    /// Универсальная настройка хедера для экранов с кнопками (например, трекеры)
    static func setupTrackerLayout(
        in view: UIView,
        titleView: UIView,
        addButton: UIButton,
        dateButton: UIButton,
        searchBar: UISearchBar,
        collectionView: UICollectionView
    ) {
        [addButton, titleView, dateButton, searchBar, collectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        view.subviews.forEach { subview in
            if String(describing: type(of: subview)).contains("MainTitle") {
                subview.isUserInteractionEnabled = false
            }
        }
        
        let spacingButtonToTitle: CGFloat = 2
        let spacingTitleToSearch: CGFloat = 2
        let spacingSearchToCollection: CGFloat = 8
        
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.widthAnchor.constraint(equalToConstant: 42),
            addButton.heightAnchor.constraint(equalToConstant: 42),
            
            titleView.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: spacingButtonToTitle),
            titleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            
            dateButton.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
            dateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dateButton.widthAnchor.constraint(equalToConstant: 77),
            dateButton.heightAnchor.constraint(equalToConstant: 34),
            
            searchBar.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: spacingTitleToSearch),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: spacingSearchToCollection),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        view.bringSubviewToFront(addButton)
        view.bringSubviewToFront(dateButton)
    }
    
    static func setupSimpleTitle(in view: UIView, titleView: UIView) {
        view.addSubview(titleView)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        
        let visualTopOffset: CGFloat = 42 + 2
        
        NSLayoutConstraint.activate([
            titleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: visualTopOffset),
            titleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25)
        ])
    }
}
