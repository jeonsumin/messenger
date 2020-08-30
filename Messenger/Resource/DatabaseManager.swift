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
    
    public func test(){
        database.child("한글테스트").setValue(["something": "한글한글"])
    }
    
    
}

//MARK: = Account Management

extension DatabaseManager {
    
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
    
    //Inserts new User
    public func insertUser(with user: ChatAppUser, comletion: @escaping (Bool) -> Void ){
        database.child(user.safeEmail).setValue([
            "name" : user.name
            ], withCompletionBlock: { error,_  in
                guard error == nil else{
                    print("Failed to write to databas")
                    comletion(false)
                    return
                }
                comletion(true)
                
        })
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
