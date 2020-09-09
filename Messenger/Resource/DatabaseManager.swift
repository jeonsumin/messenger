//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Terry on 2020/08/23.
//  Copyright © 2020 Terry. All rights reserved.
//

import Foundation
import FirebaseDatabase
import MessageKit
final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEamil(emailAddrss: String) -> String {
        var safeEmail = emailAddrss.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    public func test(){
        database.child("한글테스트").setValue(["something": "한글한글"])
    }
    
    
}

extension DatabaseManager{
    public func getDataFor(path: String, completion: @escaping (Result<Any,Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value){ snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFecth))
                return
            }
            completion(.success(value))
        }
    }
}

//MARK: = Account Management

extension DatabaseManager {
    
    //MARK:- Find User
    public func selectEmail(with email : String , completion: @escaping((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            
            completion(true)
            
        }
    }
    
    //MARK: -Inserts new User to database
    public func insertUser(with user: ChatAppUser, comletion: @escaping (Bool) -> Void ){
        database.child(user.safeEmail).setValue([
            "name" : user.name
            ], withCompletionBlock: { error,_  in
                guard error == nil else{
                    print("Failed to write to databas")
                    comletion(false)
                    return
                }
                
                self.database.child("users").observeSingleEvent(of: .value, with: {snapshot in
                    if var usersCollection = snapshot.value as? [[String: String]]{
                        // append to user dictionary
                        let newElement =  [
                            "name": user.name,
                            "email": user.safeEmail
                        ]
                        
                        usersCollection.append(newElement)
                        
                        self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                comletion(false)
                                return
                            }
                            comletion(true)
                            
                        })
                    }else{
                        //create that array
                        let newCollection: [[String: String]] = [
                            [
                                "name": user.name,
                                "email": user.safeEmail
                            ]
                        ]
                        self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                comletion(false)
                                return
                            }
                            comletion(true)
                            
                        })
                        
                    }
                })
        })
    }
    public func getAllusers(completion: @escaping (Result<[[String: String]],Error>) -> Void ) {
        database.child("users").observeSingleEvent(of: .value, with: {snapshot in
            guard let value = snapshot.value as? [[String:String]] else{
                completion(.failure(DatabaseError.failedToFecth))
                return
            }
            completion(.success(value))
        })
    }
    public enum DatabaseError : Error {
        case failedToFecth
    }
}

//MARK: - Sendig Message / conversation
extension DatabaseManager {
    /*
     
     "dfdsfa" : {
     "message": [
     {
     "id" : String,
     "type": text,photo, vido,
     "content": Sring,
     "date" : Date(),
     "sender_email": String,
     "isRead" : true /false
     }
     ]
     }
     
     conversation => [
     ["conversation_id" :
     "other_user_email" :
     "latest_message": [ {  "data" :Date()
     "letest_message":"message"
     "is_read": true /faes
     }]
     }
     
     */
    //Create new conversation with target user Email and first message sent
    public func createNewConversation(with otherUserEmail: String, name:String, firstMessage: Message, completion: @escaping(Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                return
        }
        //특수문자 사용할 수 없음
        let safeEmail = DatabaseManager.safeEamil(emailAddrss: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        
        
        ref.observeSingleEvent(of: .value, with: {[weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else{
                completion(false)
                print("user not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText ):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String:Any] = [
                "id": conversationID,
                "other_user_email" : otherUserEmail,
                "name":name,
                "latest_message" : [
                    "date" : dateString,
                    "message" : message,
                    "is_read" : false
                ]
            ]
            
            let recipient_newConversationData: [String:Any] = [
                "id": conversationID,
                "other_user_email" : safeEmail,
                "name": currentName ,
                "latest_message" : [
                    "date" : dateString,
                    "message" : message,
                    "is_read" : false
                ]
            ]
            //update recipient conversation entry
            self?.database.child("\(otherUserEmail)/convsersation").observeSingleEvent(of: .value, with: {[weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/convsersation").setValue([conversationID])
                }else{
                    //create
                    self?.database.child("\(otherUserEmail)/convsersation").setValue([recipient_newConversationData])
                    
                }
            })
            
            //Update current user conversation entry
            if var conversations = userNode["conversation"] as? [[String:Any]] {
                //conversation array exists for current user
                //you should append
                
                conversations.append(newConversationData)
                userNode["conversation"] = conversations
                ref.setValue(userNode, withCompletionBlock: {[weak self] error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationID,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            }else{
                // conversation array does NOT exist
                //create it
                userNode["conversations"] = [
                    newConversationData
                ]
                ref.setValue(userNode, withCompletionBlock: {[weak self] error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationID,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation(name:String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void ){
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText ):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEamil(emailAddrss: myEmail)
        
        let collectionMessage : [String:Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKinString,
            "content": message,
            "date":dateString,
            "sender_email":currentUserEmail,
            "is_read": false,
            "name":name
        ]
        
        let value :[String:Any] = [
            "messages" :[
                collectionMessage
            ]
        ]
        print("adding convo:: \(conversationID)")
        database.child("\(conversationID)").setValue(value, withCompletionBlock: {error, _ in
            guard error == nil else{
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    //Fetches and return all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping(Result<[Conversation], Error>) -> Void ){
        database.child("\(email)/conversations").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFecth))
                return
            }
            let conversations: [Conversation] = value.compactMap({dictionary in
                guard let conversationId = dictionary["id"] as? String ,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["other_user_email"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String:Any],
                    let date = latestMessage["date"] as? String,
                    let message = latestMessage["message"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool else{
                        return nil
                }
                
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                return Conversation(id: conversationId, name: name, otheruserEmail: otherUserEmail, latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
        })
    }
    
    // gets all mmessage for a given conversation
    public func getAllMesageForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void ){
        database.child("\(id)/messages").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFecth))
                return
            }
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                    let isRead = dictionary["is_read"] as? Bool,
                    let messageID = dictionary["id"] as? String,
                    let content = dictionary["content"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let type = dictionary["type"] as? String,
                    let dateString = dictionary["date"] as? String,
                    let date = ChatViewController.dateFormatter.date(from: dateString)else {
                        return nil
                }
                
                var kind: MessageKind?
                if type == "photo" {
                    //photo
                    guard let imageUrl = URL(string: content),
                    let placeHolder = UIImage(systemName: "plus") else{
                        return nil
                    }
                    let media = Media(url: imageUrl ,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else{
                    return nil
                }
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: finalKind )
            })
            completion(.success(messages))
        })
    }
    
    // Sends a message with target conversation and message
    public func sendMessage(to conversation:String,otherUserEmail : String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void){
        // add new message to messages
        //update sender latest message
        // update recipient latest message
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEamil(emailAddrss: myEmail)
        
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: {[weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            
            guard var currentMessages = snapshot.value as? [[String:Any]] else{
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText ):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEamil(emailAddrss: myEmail)
            
            let newMessageEntry : [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKinString,
                "content": message,
                "date":dateString,
                "sender_email":currentUserEmail,
                "is_read": false,
                "name":name
            ]
            
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) {error, _ in
                guard error == nil else{
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    let updateValue: [String:Any] = [
                        "date" : dateString,
                        "is_read" : false,
                        "message" : message,
                    ]
                    
                    var targetConversaion: [String:Any]?
                    
                    var position = 0
                    
                    for conversationDictionary in currentUserConversations {
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                            targetConversaion = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    
                    targetConversaion?["latest_message"] = updateValue
                    guard let finalconversation = targetConversaion else {
                        completion(false)
                        return
                    }
                    currentUserConversations[position] = finalconversation
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(currentUserConversations,withCompletionBlock: {error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        
                        //update latest message for recipient user
                        strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) {error, _ in
                            guard error == nil else{
                                completion(false)
                                return
                            }
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                                guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                    completion(false)
                                    return
                                }
                                let updateValue: [String:Any] = [
                                    "date" : dateString,
                                    "is_read" : false,
                                    "message" : message,
                                ]
                                
                                var targetConversaion: [String:Any]?
                                
                                var position = 0
                                
                                for conversationDictionary in otherUserConversations {
                                    if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                        targetConversaion = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                
                                targetConversaion?["latest_message"] = updateValue
                                guard let finalconversation = targetConversaion else {
                                    completion(false)
                                    return
                                }
                                otherUserConversations[position] = finalconversation
                                strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations,withCompletionBlock: {error, _ in
                                    guard error == nil else{
                                        completion(false)
                                        return
                                    }
                                    completion(true)
                                })
                            })
                        };
                    })
                })
            }
        })
    };
}
    
    struct ChatAppUser {
        let emailAddrss : String
        let name        : String
        
        var safeEmail   : String {
            var safeEmail = emailAddrss.replacingOccurrences(of: ".", with: "-")
            safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
            return safeEmail
        }
        var profilePictureFileName  : String {
            //afraz9-gmail-com-profile-picture.png
            return "\(safeEmail)_profile_picture.png"
        }
}
