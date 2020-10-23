//
//  ChatModels.swift
//  Messenger
//
//  Created by Terry on 2020/10/23.
//  Copyright © 2020 Terry. All rights reserved.
//

import Foundation
import MessageKit

struct Message: MessageType {
    public var sender      : SenderType
    public var messageId   : String
    public var sentDate    : Date
    public var kind        : MessageKind
}

extension MessageKind{
    var messageKinString:String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "custom"
        case .linkPreview(_):
            return "linkPreview"
        }
    }
}

struct Sender: SenderType {
    public var photoURL        : String
    public var senderId        : String
    public var displayName     : String
    
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}
