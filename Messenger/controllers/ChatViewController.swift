//
//  ChatViewController.swift
//  Messenger
//
//  Created by Terry on 2020/08/30.
//  Copyright © 2020 Terry. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView

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

class ChatViewController: MessagesViewController{
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false
    public let otherUserEmail: String
    
    private let conversationId: String?
    private var messages = [Message]()
    
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        let safeEamil = DatabaseManager.safeEamil(emailAddrss: email)
        
        return Sender(photoURL: "",
                      senderId: safeEamil,
                      displayName: "Me")
        
    }
    
    init(with email: String, id: String?) {
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        if let conversationId = conversationId {
            listenForMessage(id: conversationId, shouldScrollBottom: true)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
    }
    
    private func listenForMessage(id: String, shouldScrollBottom: Bool){
        DatabaseManager.shared.getAllMesageForConversation(with: id, completion: {[weak self] res in
            switch res{
            case .success(let messages):
                print("success in getting message :: \(messages)")
                guard !messages.isEmpty else {
                    return
                }
                
                self?.messages = messages
                
                DispatchQueue.main.async {
                    if shouldScrollBottom {
                        self?.messagesCollectionView.reloadDataAndKeepOffset()
                    }else{
                        self?.messagesCollectionView.scrollToBottom()
                    }
                }
                
            case .failure(let error):
                print("Failed to get message: \(error)")
            }
        })
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessage(id: conversationId, shouldScrollBottom: true)
        }
    }
    
}

extension ChatViewController :InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
            let selfSender = self.selfSender,
            let messageId = createMessageId() else{
                return
        }
        print("sending:::: \(text)")
        //create convo in database
        let mmessage = Message(sender: selfSender,
                               messageId: messageId,
                               sentDate: Date(),
                               kind: .text(text))
        //Send Message
        if isNewConversation {
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User" ,firstMessage:mmessage , completion: {[weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                }else{
                    print("falid message Sent ")
                }
            })
            
        } else {
            
            guard let conversationId = conversationId, 
            let name = self.title else {
                return
            }
            //append to exising conversion data
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail : otherUserEmail ,name: name, newMessage: mmessage, completion: {success in
                if success {
                    print("message sent")
                }else{
                    print("faild sent")
                }
            })
        }
    }
    
    private func createMessageId() -> String? {
        //date, otherUserEmail, senderEmail, randomInt
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEamil(emailAddrss: currentUserEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        print("create message id: \(newIdentifier)")
        
        return newIdentifier
    }
}

//MARK:- Message Delegate
extension ChatViewController :MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        
        fatalError("Self sender is nil, email shauld be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}
