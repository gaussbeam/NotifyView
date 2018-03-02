//
//  NotifyView.swift
//  NotifyKit
//
//  Created by Hanyu Koji on 2018/03/02.
//  Copyright © 2018年 gaussbeam. All rights reserved.
//

import UIKit

public class NotifyView: UIView {
    
    // MARK: - IBOutlet
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var topPadding:    NSLayoutConstraint!
    @IBOutlet private weak var leftPadding:   NSLayoutConstraint!
    @IBOutlet private weak var bottomPadding: NSLayoutConstraint!
    @IBOutlet private weak var rightPadding:  NSLayoutConstraint!
    
    // MARK: - Variables
    var animateDurationType: AnimateDurationType = .medium
    var displayDurationType: DisplayDurationType = .short
    var padding: UIEdgeInsets = UIEdgeInsets(top: 4.0,
                                             left: 12.0,
                                             bottom: 4.0,
                                             right: 12.0)
    
    var titleColor: UIColor = .black
    var titleFont: UIFont = .boldSystemFont(ofSize: 10.0)

    /// Constraint for animation
    fileprivate var topConstraint: NSLayoutConstraint!

    func configure(title: String) {
        self.isHidden = true

        // TODO: Timing, Approach
        self.titleLabel.font = self.titleFont
        self.titleLabel.textColor = titleColor
        self.topPadding.constant = self.padding.top
        self.leftPadding.constant = self.padding.left
        self.bottomPadding.constant = self.padding.bottom
        self.rightPadding.constant = self.padding.right

        self.titleLabel.text = title
        self.titleLabel.sizeToFit()
        self.setNeedsLayout()
    }
}

// MARK: - Constants

public extension NotifyView {
    enum AnimateDurationType {
        case fast
        case medium
        case slow
        case custom(TimeInterval)
        
        var duration: TimeInterval {
            switch self {
            case .fast:
                return 0.2
                
            case .medium:
                return 0.4
                
            case .slow:
                return 0.8
                
            case .custom(let interval):
                return interval
            }
        }
    }
    
    enum DisplayDurationType {
        case short
        case long
        case forever
        case custom(TimeInterval)
        
        var duration: TimeInterval? {
            switch self {
            case .short:
                return 2.0
                
            case .long:
                return 4.0
            
            case .custom(let interval):
                return interval
                
            case .forever:
                return nil
            }
        }
    }
    
    enum AnimateStyle {
        case none
        case animate(relatedAnimation:  ((CGFloat) -> Void)?, completion: (() -> Void)?)
    }
}

// MARK: - Layout

private extension NotifyView {
    func configureConstraints() {
        guard let superView = self.superview else { return }
        
        // Setup Auto Layout
        self.translatesAutoresizingMaskIntoConstraints = false
        self.leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        self.widthAnchor.constraint(equalTo: superView.widthAnchor).isActive = true

        // 上端のconstraintは表示アニメーションに使用するため保持
        let topConstraint = self.topAnchor.constraint(equalTo: superView.topAnchor)
        self.topConstraint = topConstraint
    }
    
    func prepareForHideIfNeeded(_ style: AnimateStyle) {
        guard let displayDuration = self.displayDurationType.duration else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
            switch style {
            case .none:
                self.hide(.none)
                
            case .animate(_, _):
                // TODO: refine interface passing handlers
                self.hide(.animate(relatedAnimation: nil, completion: nil))
            }
        }
    }
}

extension NotifyView {
    func show(_ style: AnimateStyle) {
        self.configureConstraints()
        
        switch style {
        case .none:
            self.isHidden = false
            prepareForHideIfNeeded(style)

        case .animate(let related, let completion):
            // アニメーションの初期状態(親ビューの上端より上に配置しておく)
            topConstraint.constant = -self.frame.height
            topConstraint.isActive = true

            self.isHidden = false
            DispatchQueue.main.async {
                // 親ビューの上端とビューの上端を揃える
                self.topConstraint.constant = 0.0
                
                UIView.animate(withDuration: self.animateDurationType.duration,
                               animations: {
                                related?(self.frame.height)
                                self.superview?.layoutIfNeeded()
                },
                               completion: { _ in
                    completion?()
                                self.prepareForHideIfNeeded(style)
                })
            }
        }
    }
    
    func hide(_ style: AnimateStyle) {
        switch style {
        case .none:
            self.isHidden = true

        case .animate(let related, let completion):
            
            /// 親ビューの上端に向かって消えるようにアニメーションを行う
            DispatchQueue.main.async {
                // 親ビューの上端より上になるようアニメーションさせる
                self.topConstraint?.constant = -self.frame.height
                
                UIView.animate(
                    withDuration: self.animateDurationType.duration,
                    animations: {
                        related?(self.frame.height)
                        self.superview?.layoutIfNeeded()
                },
                    completion: { _ in
                        completion?()
                        self.removeFromSuperview()
                })
            }
        }
    }
}

extension NotifyView {
    static func notifyView() -> NotifyView {
        let nib = UINib.init(nibName: "NotifyView", bundle: nil)
        let views: Array = nib.instantiate(withOwner: self, options: nil)
        
        return views.first as! NotifyView
    }
}
