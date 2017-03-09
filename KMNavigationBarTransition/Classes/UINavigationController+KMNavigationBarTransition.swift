//
//  UINavigationController+KMNavigationBarTransition.swift
//  KMNavigationBarTransition
//
//  Created by 伯驹 黄 on 2016/12/23.
//  Copyright © 2016年 伯驹 黄. All rights reserved.
//

import UIKit

extension UINavigationBar {
    func setBar(using bar: UINavigationBar?) {
        barTintColor = bar?.barTintColor
        setBackgroundImage(bar?.backgroundImage(for: .default), for: .default)
        shadowImage = bar?.shadowImage
    }
}

extension UINavigationController {
    static let _onceToken = UUID().uuidString

    open override class func initialize() {

        DispatchQueue.once(token: _onceToken) {
            KMSwizzleMethod(self,
                originalSelector: #selector(pushViewController),
                swizzledSelector: #selector(km_pushViewController))

            KMSwizzleMethod(self,
                originalSelector: #selector(popViewController),
                swizzledSelector: #selector(km_popViewController))

            KMSwizzleMethod(self,
                originalSelector: #selector(popToViewController),
                swizzledSelector: #selector(km_popToViewController))

            KMSwizzleMethod(self,
                originalSelector: #selector(popToRootViewController),
                swizzledSelector: #selector(km_popToRootViewController))

            KMSwizzleMethod(self,
                originalSelector: #selector(setViewControllers),
                swizzledSelector: #selector(km_setViewControllers))
        }
    }

    var km_containerViewBackgroundColor: UIColor {
        return UIColor.white
    }

    func km_pushViewController(_ viewController: UIViewController, animated: Bool) {
        guard let disappearingViewController = viewControllers.last else {
            return km_pushViewController(viewController, animated: animated)
        }
        if km_transitionContextToViewController == nil || disappearingViewController.km_transitionNavigationBar == nil {
            disappearingViewController.km_addTransitionNavigationBarIfNeeded()
        }
        if animated {
            km_transitionContextToViewController = viewController
            if disappearingViewController.km_transitionNavigationBar != nil {
                disappearingViewController.km_prefersNavigationBarBackgroundViewHidden = true
            }
        }
        return km_pushViewController(viewController, animated: animated)
    }

    func km_popViewController(animated: Bool) -> UIViewController {
        if viewControllers.count < 2 {
            return km_popViewController(animated: animated)
        }
        let disappearingViewController = viewControllers.last
        disappearingViewController?.km_addTransitionNavigationBarIfNeeded()
        let appearingViewController = viewControllers[viewControllers.count - 2]
        if appearingViewController.km_transitionNavigationBar != nil {
            let appearingNavigationBar = appearingViewController.km_transitionNavigationBar
            navigationBar.setBar(using: appearingNavigationBar)
        }
        if animated {
            disappearingViewController?.km_prefersNavigationBarBackgroundViewHidden = true
        }

        return km_popViewController(animated: animated)
    }

    func km_popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController] {

        if !viewControllers.contains(viewController) || viewControllers.count < 2 {
            return km_popToViewController(viewController, animated: animated)
        }
        let disappearingViewController = viewControllers.last
        disappearingViewController?.km_addTransitionNavigationBarIfNeeded()
        if viewController.km_transitionNavigationBar != nil {
            let appearingNavigationBar = viewController.km_transitionNavigationBar
            navigationBar.setBar(using: appearingNavigationBar)
        }
        if animated {
            disappearingViewController?.km_prefersNavigationBarBackgroundViewHidden = true
        }
        return km_popToViewController(viewController, animated: animated)
    }

    func km_popToRootViewController(animated: Bool) -> [UIViewController] {
        if viewControllers.count < 2 {
            return km_popToRootViewController(animated: animated)
        }
        let disappearingViewController = viewControllers.last
        disappearingViewController?.km_addTransitionNavigationBarIfNeeded()
        let rootViewController = viewControllers.first
        if let bar = rootViewController?.km_transitionNavigationBar {
            navigationBar.setBar(using: bar)
        }
        if animated {
            disappearingViewController?.km_prefersNavigationBarBackgroundViewHidden = true
        }
        return km_popToRootViewController(animated: animated)
    }

    func km_setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        if animated {
            if let disappearingViewController = self.viewControllers.last, let controller = viewControllers.last {
                if disappearingViewController != controller {
                    disappearingViewController.km_addTransitionNavigationBarIfNeeded()
                    if disappearingViewController.km_transitionNavigationBar != nil {
                        disappearingViewController.km_prefersNavigationBarBackgroundViewHidden = true
                    }
                }
            }
        }
        return km_setViewControllers(viewControllers, animated: animated)
    }

    var km_transitionContextToViewController: UIViewController? {
        set {
            let wrapper = KMWeakObjectContainer(object: newValue)
            objc_setAssociatedObject(self, &AssociatedKeys.transitionContextToViewController, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        get {
            return (objc_getAssociatedObject(self, &AssociatedKeys.transitionContextToViewController) as? KMWeakObjectContainer)?.object
        }
    }
}

extension DispatchQueue {

    private static var _onceTracker = [String]()

    public class func once(token: String, block: () -> Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }

        if _onceTracker.contains(token) {
            return
        }

        _onceTracker.append(token)
        block()
    }
}
