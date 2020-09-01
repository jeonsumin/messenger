//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Terry on 2020/08/23.
//  Copyright © 2020 Terry. All rights reserved.
//

import Foundation
import FirebaseDatabase

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
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping(Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        //특수문자 사용할 수 없음
        let safeEmail = DatabaseManager.safeEamil(emailAddrss: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        
        
        ref.observeSingleEvent(of: .value, with: {snapshot in
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
                "latest_message" : [
                    "date" : dateString,
                    "message" : message,
                    "is_read" : false
                ]
            ]
            
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
                    self?.finishCreatingConversation(conversationID: conversationID, firstMessage: firstMessage, completion: completion)
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
                    self?.finishCreatingConversation(conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation(conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void ){
        
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
            "is_read": false
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
    public func getAllConversations(for email: String, completion: @escaping(Result<String, Error>) -> Void ){
        
    }
    
    // gets all mmessage for a given conversation
    public func getAllMesageForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void ){
        
    }
    
    // Sends a message with target conversation and message
    public func sendMessage(to conversation:String, mmessage: Message, completion: @escaping (Bool) -> Void){
        
    }
    
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
