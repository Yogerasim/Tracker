import UIKit
import ObjectiveC.runtime

private struct AssociatedKeys {
    static var keyboardDismissAdded = "keyboardDismissAddedKey"
}

private final class KeyboardDismissGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissGestureDelegate()
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Если тап внутри UIControl (UITextField, UITextView, UIButton и т.д.) — игнорируем
        var view = touch.view
        while let v = view {
            if v is UIControl { return false }
            // Иногда текстовое поле вложено в другие вью — проверяем супервью по цепочке
            view = v.superview
        }
        return true
    }
    
    // Разрешаем одновременное распознавание жестов (не блокируем скроллы)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension UIViewController {
    
    // Включаем swizzling (вызывать единожды, например в AppDelegate)
    static func enableGlobalKeyboardDismiss() {
        let originalSelector = #selector(UIViewController.viewDidLoad)
        let swizzledSelector = #selector(UIViewController.swizzled_viewDidLoad)
        
        guard
            let originalMethod = class_getInstanceMethod(self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc private func swizzled_viewDidLoad() {
        // вызываем "оригинальный" viewDidLoad (из-за swizzling это вызовет оригинал)
        self.swizzled_viewDidLoad()
        
        // Защита — не добавляем дважды
        let alreadyAdded = objc_getAssociatedObject(self, &AssociatedKeys.keyboardDismissAdded) as? Bool ?? false
        if alreadyAdded { return }
        
        // Создаём тап-рекогнайзер
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardFromTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = KeyboardDismissGestureDelegate.shared
        
        // Добавляем на основной view контроллера
        view.addGestureRecognizer(tap)
        
        // Помечаем что добавили
        objc_setAssociatedObject(self, &AssociatedKeys.keyboardDismissAdded, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    @objc private func dismissKeyboardFromTap(_ sender: UITapGestureRecognizer) {
        // Дополнительно проверка: если тап был по контролу — игнорируем (защита)
        let location = sender.location(in: view)
        if let touched = view.hitTest(location, with: nil) {
            var v: UIView? = touched
            while let cur = v {
                if cur is UIControl {
                    return
                }
                v = cur.superview
            }
        }
        
        view.endEditing(true)
    }
}
