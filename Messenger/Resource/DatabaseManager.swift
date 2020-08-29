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
    
    public func selectEmail(with uid : String , completion: @escaping((Bool) -> Void)) {
        
        database.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            
            completion(true)
            
        }
    }
    
    //Inserts new User
    public func insertUser(with user: ChatAppUser){
        database.child(user.uid).setValue([
            "name" : user.name
        ])
    }
    
    //Inserts basic new User
    public func insertbasicUser(with user: String, Name: String){
        database.child(user).setValue(["name": Name])
    }
}

struct ChatAppUser {
    let uid             : String
    let name        : String
    
    // let profilePic  : String
}
