import UIKit
import ObjectiveC.runtime

private struct AssociatedKeys {
    static var keyboardDismissAdded: UInt8 = 0
}

private final class KeyboardDismissGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissGestureDelegate()
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let v = view {
            if v is UIControl { return false }
            view = v.superview
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension UIViewController {
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
        self.swizzled_viewDidLoad()
        
        let alreadyAdded = objc_getAssociatedObject(self, &AssociatedKeys.keyboardDismissAdded) as? Bool ?? false
        if alreadyAdded { return }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardFromTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = KeyboardDismissGestureDelegate.shared

        view.addGestureRecognizer(tap)

        objc_setAssociatedObject(self, &AssociatedKeys.keyboardDismissAdded, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    @objc private func dismissKeyboardFromTap(_ sender: UITapGestureRecognizer) {
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
