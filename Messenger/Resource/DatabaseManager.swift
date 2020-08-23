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
        database.child("foo").setValue(["something": true])
    }
    
    
}

//MARK: = Account Management

extension DatabaseManager {
    
    public func selectEmail(with email : String , completion: @escaping((Bool) -> Void)) {
        database.child(email).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            
            completion(true)
            
        }
    }
    
    //Inserts new User
    public func insertUser(with user: ChatAppUser){
        database.child(user.emailAddress).setValue([
            "first_name" : user.firstName,
            "last_name"  : user.lastname
        ])
    }
    
}

struct ChatAppUser {
    let firstName       : String
    let lastname        : String
    let emailAddress    : String
    // let profilePic  : String
}
