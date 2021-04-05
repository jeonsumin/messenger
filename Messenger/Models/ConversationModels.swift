//
//  ConversationModels.swift
//  Messenger
//
//  Created by Terry on 2020/10/23.
//  Copyright © 2020 Terry. All rights reserved.
//

import Foundation


struct Conversation {
    let id: String
    let name: String
    let otheruserEmail : String
    let latestMessage : LatestMessage
}

struct LatestMessage {
    let date : String
    let text : String
    let isRead: Bool
}
