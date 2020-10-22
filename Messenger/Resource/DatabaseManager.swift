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

//MARK:- DatabaseManager
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

//MARK:- FireBase database CRUD
extension DatabaseManager {
    
    //MARK:- Find User
    
    // userExists
    public func selectEmail(with email : String , completion: @escaping((Bool) -> Void)) {
        
//        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
//        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
//
        let safeEmail = DatabaseManager.safeEamil(emailAddrss: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.value as? [String:Any] != nil else{
                completion(false)
                return
            }
            
            completion(true)
            
        }
    }
    
    
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
            
            print("users ::: \(snapshot.value!)")
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
            self?.database.child("\(otherUserEmail)/convsersations").observeSingleEvent(of: .value, with: {[weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/convsersations").setValue([conversations])
                }else{
                    //create
                    self?.database.child("\(otherUserEmail)/convsersations").setValue([recipient_newConversationData])
                    
                }
            })
            
            //Update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String:Any]] {
                //conversation array exists for current user
                //you should append
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
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
    
    //F
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
                }else if type == "video" {
                    //photo
                    guard let videoUrl = URL(string: content),
                          let placeHolder = UIImage(named: "video_placeholder") else{
                        return nil
                    }
                    let media = Media(url: videoUrl ,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
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
    public func sendMessage(to conversation:String, otherUserEmail : String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void){
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
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
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
                    
                    var databaseEntryConversations = [[String:Any]]()
                    
                    let updateValue: [String:Any] = [
                        "date" : dateString,
                        "is_read" : false,
                        "message" : message,
                    ]
                    
                    if var currentUserConversations = snapshot.value as? [[String: Any]]  {
                        var targetConversaion: [String:Any]?
                        var position = 0
                        
                        for conversationDictionary in currentUserConversations {
                            //대화를 나누는 부분
                            if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                targetConversaion = conversationDictionary
                                break
                            }
                            position += 1
                            
                        }
                        
                        if var targetConversaion = targetConversaion {
                            targetConversaion["latest_message"] = updateValue
                            currentUserConversations[position] = targetConversaion
                            databaseEntryConversations = currentUserConversations
                        }else{
                            let newConversationData: [String:Any] = [
                                "id": conversation,
                                "other_user_email" : DatabaseManager.safeEamil(emailAddrss: otherUserEmail),
                                "name":name,
                                "latest_message" :updateValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations 
                        }
                    
                    }else {
                        let newConversationData: [String:Any] = [
                            "id": conversation,
                            "other_user_email" : DatabaseManager.safeEamil(emailAddrss: otherUserEmail),
                            "name":name,
                            "latest_message" : updateValue
                        ]
                        
                        databaseEntryConversations = [
                            newConversationData
                        ]
                    }
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations,withCompletionBlock: {error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        
                        
                        strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) {error, _ in
                            guard error == nil else{
                                completion(false)
                                return
                            }
                            //update latest message for recipient user
                            strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                                
                                let updateValue: [String:Any] = [
                                    "date" : dateString,
                                    "is_read" : false,
                                    "message" : message,
                                ]
                                var databaseEntryConversation = [[String: Any]]()
                                
                                guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                    return
                                }
                                
                                if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                    
                                    var targetConversaion: [String:Any]?
                                    
                                    var position = 0
                                    
                                    for conversationDictionary in otherUserConversations {
                                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                            targetConversaion = conversationDictionary
                                            break
                                        }
                                        position += 1
                                    }
                                    
                                    if var targetConversaion = targetConversaion {
                                        targetConversaion["latest_message"] = updateValue
                                        
                                         otherUserConversations[position] = targetConversaion
                                         databaseEntryConversation = otherUserConversations
                                    }else{
                                        //failed to find in current collection
                                        let newConversationData: [String:Any] = [
                                            "id": conversation,
                                            "other_user_email" : DatabaseManager.safeEamil(emailAddrss: currentEmail),
                                            "name":currentName,
                                            "latest_message" :updateValue
                                        ]
                                        otherUserConversations.append(newConversationData)
                                        databaseEntryConversations = otherUserConversations
                                    }
                                   
                                }else{
                                    //current collection does not exist
                                    let newConversationData: [String:Any] = [
                                        "id": conversation,
                                        "other_user_email" : DatabaseManager.safeEamil(emailAddrss: currentEmail),
                                        "name":currentName,
                                        "latest_message" : updateValue
                                    ]
                                    databaseEntryConversations = [
                                        newConversationData
                                    ]
                                }
                                
                                
                                strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversation,withCompletionBlock: {error, _ in
                                    guard error == nil else{
                                        completion(false)
                                        return
                                    }
                                    completion(true)
                                })
                            })
                        }
                    })
                })
            }
        })
    }
    ///채팅 삭제 메소드
    public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void){
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEamil(emailAddrss: email)
        
        print("\(conversationId)의 채팅을 삭제할 것이다 ")
        // 모든 유저의 채팅을 가져온다 .
        // 대상 ID가 있는 컬렉션에서 대화를 삭제한다.
        // 사용자를 위해 대화를 재설정
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) {snapshot in
            if var conversations = snapshot.value as? [[String: Any]]{
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                       id == conversationId {
                        print("찾은 대화 삭제")
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations, withCompletionBlock: {error, _ in
                    guard error == nil else {
                        completion(false)
                        print("새 대화 배열을 작성 하지 못했습니다.")
                        return
                    }
                    print("채팅 삭제")
                    completion(true)
                })
            }
        }
    }
    
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        let safeRecipientEmail = DatabaseManager.safeEamil(emailAddrss: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeSenderEmail = DatabaseManager.safeEamil(emailAddrss: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFecth))
                print("conversationExists Error")
                return
            }
            
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                print("conversationExists")
                guard let id = conversation["id"] as? String else {
                    print("conversationExists in conversation id error")
                    completion(.failure(DatabaseError.failedToFecth))
                    return
                }
                completion(.success(id))
                return
            }
            
            print("conversationExists falied ")
            completion(.failure(DatabaseError.failedToFecth))
            return
        })
        
        
    }
}


// 유저 메타데이터 래핑
struct ChatAppUser {
    let emailAddrss : String // 이메일
    let name        : String // 이름
    
    var safeEmail   : String {
        var safeEmail = emailAddrss.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePictureFileName  : String { //프로필 이미지
        //afraz9-gmail-com-profile-picture.png
        return "\(safeEmail)_profile_picture.png"
    }
}
