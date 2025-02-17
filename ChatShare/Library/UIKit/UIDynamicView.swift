//
//  UIDynamicView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/17.
//

import UIKit
import SnapKit

public class UIDynamicView<Content>: UIView where Content: UIView {
    
    public var content: Content {
        get { _content }
        set { setContentView(_content) }
    }
    
    private var _content: Content
    
    public init(content: Content, frame: CGRect = .zero) {
        _content = content
        super.init(frame: frame)
        setContentView(nil)
    }
    
    public init(frame: CGRect = .zero, content: () -> Content) {
        _content = content()
        super.init(frame: frame)
        setContentView(nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setContentView(_ newContent: Content?) {
        let resetView = { (newContent: Content) -> Void in
            self.subviews.forEach { $0.removeFromSuperview() }
            self.addSubview(newContent)
            self._content = newContent
            self._content.snp.remakeConstraints { make in
                make.edges.equalTo(self)
            }
        }
        if let newContent, newContent !== _content {
            resetView(newContent)
        } else if newContent == nil {
            resetView(_content)
        }
    }
}
