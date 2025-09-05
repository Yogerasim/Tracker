import UIKit

extension TrackersViewController {
    func setupLayout() {
        view.addSubview(titleStack)
        view.addSubview(searchBar)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            // Заголовок + дата
            titleStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),

            // Поиск
            searchBar.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Коллекция
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setupPlaceholder() {
        view.addSubview(placeholderView)
        NSLayoutConstraint.activate([
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func updatePlaceholder() {
        placeholderView.isHidden = !trackers.isEmpty
    }
}
