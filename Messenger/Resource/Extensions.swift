//
//  Extensions.swift
//  Messenger
//
//  Created by Terry on 2020/08/21.
//  Copyright © 2020 Terry. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    public var width: CGFloat{
        return  frame.size.width
    }
    public var height: CGFloat{
        return  frame.size.height
    }
    public var top: CGFloat{
        return  frame.origin.y
    }
    public var bottom: CGFloat{
        return  frame.size.height +  frame.origin.y
    }
    public var left: CGFloat{
        return  frame.origin.x
    }
    public var right: CGFloat{
        return  frame.size.width +  frame.origin.x
    }
    
}


extension Notification.Name {
    /// 사용자가 로그인 할때 알림
    static let didLogInNotification = Notification.Name("didLogInNotification")
}

