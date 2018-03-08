//
//  NotifyView.swift
//  NotifyView
//
//  Created by Hanyu Koji on 2018/03/02.
//  Copyright © 2018年 gaussbeam. All rights reserved.
//

import UIKit

public struct NotifyViewStyle {
    var padding: UIEdgeInsets
    
    var backgroundColor: UIColor
    var titleColor: UIColor
    var titleFont: UIFont
    
    static var defaultStyle: NotifyViewStyle {
        return NotifyViewStyle(
            padding: UIEdgeInsets(top: 4.0, left: 12.0,  bottom: 4.0, right: 12.0),
            backgroundColor: .lightGray,
            titleColor: .black,
            titleFont: .boldSystemFont(ofSize: 10.0))
    }
}

public class NotifyView: UIView {
    
    // MARK: - IBOutlet
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var topPadding:    NSLayoutConstraint!
    @IBOutlet private weak var leftPadding:   NSLayoutConstraint!
    @IBOutlet private weak var bottomPadding: NSLayoutConstraint!
    @IBOutlet private weak var rightPadding:  NSLayoutConstraint!
    
    // MARK: - Variables
    fileprivate var displayDurationType: DisplayDurationType!
    fileprivate var showAnimateStyle: AnimateStyle = .none
    fileprivate var hideAnimateStyle: AnimateStyle = .none
    fileprivate var position: Position = .topEdge
    
    fileprivate var constraintForAnimate: NSLayoutConstraint!
}

// MARK: - Constants

public extension NotifyView {
    enum TransitionStyle {
        case wipe
        case dissolve
    }
    
    enum Position {
        case topEdge
        case bottomEdge
    }
    
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
        case animate(transitionStyle: TransitionStyle,
            durationType: AnimateDurationType,
            relatedAnimation:  ((CGFloat) -> Void)?,
            completion: (() -> Void)?)
    }
}

// MARK: - Layout

private extension NotifyView {
    func configure(title: String,
                   style: NotifyViewStyle) {
        self.isHidden = true
        
        self.topPadding.constant = style.padding.top
        self.leftPadding.constant = style.padding.left
        self.bottomPadding.constant = style.padding.bottom
        self.rightPadding.constant = style.padding.right

        self.backgroundColor = style.backgroundColor
        
        self.titleLabel.font = style.titleFont
        self.titleLabel.textColor = style.titleColor
        
        self.titleLabel.text = title
        self.titleLabel.sizeToFit()
    }
    
    func configureConstraints() {
        guard let superView = self.superview else { return }
        
        // Setup Auto Layout
        self.translatesAutoresizingMaskIntoConstraints = false
        self.leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        self.widthAnchor.constraint(equalTo: superView.widthAnchor).isActive = true

        switch self.position {
        case .topEdge:
            // Store constraint as property to animate
            let topConstraint = self.topAnchor.constraint(equalTo: superView.topAnchor)
            self.constraintForAnimate = topConstraint
            
        case .bottomEdge:
            // Store constraint as property to animate
            let bottomConstraint = self.bottomAnchor.constraint(equalTo: superView.bottomAnchor)
            self.constraintForAnimate = bottomConstraint
        }
    }
    
    func prepareForHideIfNeeded() {
        guard let displayDuration = self.displayDurationType.duration else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
            self.hide()
        }
    }
}

extension NotifyView {
    func show() {
        self.configureConstraints()
        
        switch self.showAnimateStyle {
        case .none:
            self.isHidden = false
            prepareForHideIfNeeded()
            
        case .animate(let transitionStyle, let durationType, let related, let completion):
            
            if transitionStyle == .wipe {
                switch self.position {
                case .topEdge:
                    constraintForAnimate.constant = -self.frame.height
                    
                case .bottomEdge:
                    constraintForAnimate.constant = self.frame.height
                }
                constraintForAnimate.isActive = true
            } else {
                self.alpha = 0.0
            }
            
            self.isHidden = false
            DispatchQueue.main.async {
                self.constraintForAnimate.constant = 0.0
                
                UIView.animate(withDuration: durationType.duration,
                               animations: {
                                related?(self.frame.height)
                                
                                if transitionStyle == .wipe {
                                    self.superview?.layoutIfNeeded()
                                } else {
                                    self.alpha = 1.0
                                }
                },
                               completion: { _ in
                                completion?()
                                self.prepareForHideIfNeeded()
                })
            }
        }
    }
    
    func hide() {
        switch self.hideAnimateStyle {
        case .none:
            self.isHidden = true
            self.removeFromSuperview()
            
        case .animate(let transitionStyle, let durationType, let related, let completion):
            
            /// Animate toward top or bottom edge of superview
            DispatchQueue.main.async {
                
                if transitionStyle == .wipe {
                    switch self.position {
                    case .topEdge:
                        self.constraintForAnimate?.constant = -self.frame.height
                        
                    case .bottomEdge:
                        self.constraintForAnimate.constant = self.frame.height
                    }
                } else {
                    self.alpha = 1.0
                }
                
                UIView.animate(
                    withDuration: durationType.duration,
                    animations: {
                        related?(self.frame.height)
                        
                        if transitionStyle == .wipe {
                            self.superview?.layoutIfNeeded()
                        } else {
                            self.alpha = 0.0
                        }
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

extension UIViewController {
    func notify(title: String,
                style: NotifyViewStyle = .defaultStyle,
                position: NotifyView.Position = .topEdge,
                displayDurationType: NotifyView.DisplayDurationType = .long,
                showAnimateStyle: NotifyView.AnimateStyle = .animate(transitionStyle: .wipe, durationType: .medium, relatedAnimation: nil, completion: nil),
                hideAnimateStyle: NotifyView.AnimateStyle = .animate(transitionStyle: .wipe, durationType: .medium, relatedAnimation: nil, completion: nil)) -> NotifyView {
        
        let notifyView = NotifyView.notifyView()
        
        notifyView.configure(title: title, style: style)
        self.view.addSubview(notifyView)
        self.view.setNeedsLayout()

        notifyView.displayDurationType = displayDurationType
        notifyView.showAnimateStyle = showAnimateStyle
        notifyView.hideAnimateStyle = hideAnimateStyle
        notifyView.position = position
        
        notifyView.show()
        
        return notifyView
    }
}
