//MARK: - UIView

extension UIView {
    func adjust(toView view: UIView) {
        let sView = view
        let leading = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: sView, attribute: .leading, multiplier: 1.0, constant: 0)
        let trailing = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: sView, attribute: .trailing, multiplier: 1.0, constant: 0)
        let top = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: sView, attribute: .top, multiplier: 1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: sView, attribute: .bottom, multiplier: 1.0, constant: 0)
        
        [leading, trailing, top, bottom].forEach { $0.isActive = true }
    }
    
    func adjustToSuperview() {
        adjust(toView: self.superview!)
    }
    
    func center(withView view: UIView) {
        let sView = view
        
        let centerX = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: sView, attribute: .centerX, multiplier: 1.0, constant: 0)
        
        let centerY = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: sView, attribute: .centerY, multiplier: 1.0, constant: 0)
        [centerX, centerY].forEach { $0.isActive = true }
    }
    
    func centerToSuperview() {
        center(withView: self.superview!)
    }
}

//MARK: - UIViewController

extension UIViewController {
    class var coordinator: NavigationCoordinator {
        return (UIApplication.shared.delegate as! AppDelegate).coordinator
    }

    func findNavigationController() -> UINavigationController? {
        if let navVC = self as? UINavigationController {
            return navVC
        }
        return self.navigationController
    }
}

//MARK: - Optional

extension Optional where Wrapped == String {
    internal var valueOrEmpty: Wrapped {
        switch self {
        case .some(let value):
            return value
        default:
            return ""
        }
    }
}
