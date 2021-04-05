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
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation

final class ChatViewController: MessagesViewController{

    private var sendderPhotoURL: URL?
    private var otherUserPhotoURL: URL?

    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
   
    public let otherUserEmail: String
    private var conversationId: String?
    public var isNewConversation = false
    
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
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
    }
    
    private func setupInputButton(){
        let button = InputBarButtonItem()
        
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside {[weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
    }
    
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController(title: "선택",
                                            message: "",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "사진", style: .default, handler: { [weak self] _ in
            self?.presentPhotoinputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "비디오", style: .default, handler: { [weak self] _ in
            self?.presentVideoinputActionSheet()
        }))
       
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    
    private func presentPhotoinputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "where would you like to attache a photo from ",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "카메라", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "앨범", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    private func presentVideoinputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "where would you like to attache a video from ",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
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
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }else{

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

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
            let imageData = image.pngData() ,
            let messageId = createMessageId(),
            let conversationId = conversationId,
            let name = self.title,
            let selfSender = self.selfSender
            else {
                return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData(){
            
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            //upload image
            StorageManager.shard.uploadMessagePhoto(with: imageData, fileName: fileName, completion: {[weak self ]result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    //Ready to send message
                    print("UPloaded Message Photo : \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus")
                        else {
                            return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let mmessage = Message(sender: selfSender,
                                           messageId: messageId,
                                           sentDate: Date(),
                                           kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: mmessage, completion: {success in
                        
                        if success {
                            print("sent photo message")
                        }else{
                            print("faild to send photo message")
                        }
                        
                    })
                    
                case .failure(let error):
                    print("message photo upload error: \(error)")
                }
            })
            //send Message
        }else if let videoUrl = info[.mediaURL] as? URL{
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            //upload video
            StorageManager.shard.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: {[weak self ]result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    //Ready to send message
                    print("UPloaded Message Video : \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus")
                        else {
                            return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let mmessage = Message(sender: selfSender,
                                           messageId: messageId,
                                           sentDate: Date(),
                                           kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: mmessage, completion: {success in
                        
                        if success {
                            print("sent photo message")
                        }else{
                            print("faild to send photo message")
                        }
                        
                    })
                    
                case .failure(let error):
                    print("message photo upload error: \(error)")
                }
            })
        }
        
    }
}

extension ChatViewController :InputBarAccessoryViewDelegate {
    
    //MARK:-sender false
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
        print("mmessage:::: \(mmessage)")
        //Send Message
        if isNewConversation {
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User" ,firstMessage:mmessage , completion: {[weak self] success in
                if success {
                    print("message sent!!!!!")
                    self?.isNewConversation = false
                    
                    let newConversationId = "conversation_\(mmessage.messageId)"
                    self?.conversationId = newConversationId
                    self?.listenForMessage(id: newConversationId, shouldScrollBottom: true)
                    self?.messageInputBar.inputTextView.text = nil
                }else{
                    print("falid message Sent !!!")
                }
            })
            
        } else {
            
            guard let conversationId = conversationId, 
                let name = self.title else {
                    return
            }
            print("conversationId ::: \(conversationId), otherUserEmail::: \(self.otherUserEmail)")
            //append to exising conversion data
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail : otherUserEmail ,name: name, newMessage: mmessage, completion: {[weak self] success in
                if success {
                    self?.messageInputBar.inputTextView.text = nil
                    print("message sent????")
                }else{
                    print("faild message sent????")
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else{
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            return .link
        }
        return .secondarySystemBackground
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let sender = message.sender
        if sender.senderId == selfSender?.senderId{
            // 사용자 설정 이미지보여주기
            if let currentUserImage = self.sendderPhotoURL {
                avatarView.sd_setImage(with: currentUserImage, completed: nil)
                
            }else{
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                let safeEmail = DatabaseManager.safeEamil(emailAddrss: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                //기본 url
                StorageManager.shard.downloadURL(for: path, completion: {[weak self] result in
                    
                    switch result {
                    case .success(let url):
                        self?.sendderPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                        
                    case .failure(let error):
                        print("\(error)")
                    }
                    
                })
            }
        }else{
            // 다른 상대 이미지
            if let otherUserPhotoURL = self.otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUserPhotoURL, completed: nil)
            }else{
                let email = self.otherUserEmail
                
                let safeEmail = DatabaseManager.safeEamil(emailAddrss: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                //기본 url
                StorageManager.shard.downloadURL(for: path, completion: {[weak self] result in
                    
                    switch result {
                    case .success(let url):
                        self?.otherUserPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                        
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            }
        }
    }
    
}

extension ChatViewController : MessageCellDelegate{
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else{
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else{
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            
            present(vc, animated: true)
        default:
            break
        }
    }
}
