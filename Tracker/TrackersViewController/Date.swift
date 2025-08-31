import UIKit

extension TrackersViewController {
    @objc func openDatePicker() {
        dateTextField.becomeFirstResponder()
    }

    @objc func donePickingDate() {
        dateTextField.resignFirstResponder()
    }

    @objc func dateChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
    }

    func updateDateText() {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "dd.MM.yy"
        dateTextField.text = df.string(from: currentDate)
    }
}
