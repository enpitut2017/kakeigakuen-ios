//
//  TouchesBeganExtension.swift
//  Pods-kakei-chan-agent-ios
//
//  Created by 赤坂勝哉 on 2018/02/03.
//

import Foundation
import UIKit

extension UIScrollView {
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // touchesBeganを次のレスポンダーにつなげる
        self.next?.touchesBegan(touches, with: event)
    }
}
