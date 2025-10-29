import Foundation
import Combine

final class FiltersViewModel {
    
    @Published private(set) var filteredTrackers: [Tracker] = []
    @Published var selectedFilterIndex: Int = 0
    @Published var selectedDate: Date = Date()
    @Published var searchText: String = ""
    
    var selectedCategory: TrackerCategory?
    var onFilteredTrackersUpdated: (() -> Void)?
    
    private let trackersProvider: () -> [Tracker]
    private let isCompletedProvider: (Tracker, Date) -> Bool
    private let dateFilter: TrackersDateFilter
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()
    private var hasInitialDataLoaded = false
    
    // MARK: - Init
    init(
        trackersProvider: @escaping () -> [Tracker],
        isCompletedProvider: @escaping (Tracker, Date) -> Bool,
        dateFilter: TrackersDateFilter
    ) {
        self.trackersProvider = trackersProvider
        self.isCompletedProvider = isCompletedProvider
        self.dateFilter = dateFilter
        
        setupFilteringPipeline()
    }
    
    // MARK: - Combine pipeline
    private func setupFilteringPipeline() {
        Publishers.CombineLatest3($selectedDate, $selectedFilterIndex, $searchText)
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] (date, filterIndex, text) in
                guard let self else { return }
                guard self.hasInitialDataLoaded else {
                    return
                }
                self.applyAllFilters(for: date)
            }
            .store(in: &cancellables)
    }
    
    func setInitialDataLoaded() {
        hasInitialDataLoaded = true
        applyAllFilters(for: selectedDate)
    }

    // MARK: - Filtering logic
    func applyAllFilters(for date: Date) {
        // 1️⃣ Берём исходные трекеры
        var trackers = trackersProvider()

        // 2️⃣ Применяем фильтр по дате
        trackers = dateFilter.filterTrackersByDay(trackers, date: date)

        // 3️⃣ Применяем фильтр по выполнению / индексу
        trackers = dateFilter.filterTrackersByIndex(
            trackers,
            selectedFilterIndex: selectedFilterIndex,
            currentDate: date,
            searchText: searchText,
            completionChecker: isCompletedProvider
        )

        // 4️⃣ (опционально) Применяем фильтр по категориям
        trackers = trackers.filter { _ in true }

        // 5️⃣ Проверяем, изменился ли результат фильтрации
        if trackers.map({ $0.id }) != filteredTrackers.map({ $0.id }) {
            filteredTrackers = trackers
            print("🔁 [FiltersViewModel] Обновлены фильтрованные трекеры для даты \(date): \(trackers.map { $0.name })")
            onFilteredTrackersUpdated?()
        } else {
            // Если изменений нет — логируем это один раз, без обновления UI
            print("⚙️ [FiltersViewModel] Фильтрация на дату \(date) не изменила список трекеров.")
        }
    }
    
    func selectFilter(index: Int) {
        selectedFilterIndex = index
    }
}
