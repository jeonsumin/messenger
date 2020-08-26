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
    public func insertUser(with user: ChatAppUser){
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "last_name"  : user.lastname
        ])
    }
    
    //Inserts basic new User
    public func insertbasicUser(with user: String, firstName :String, lastName: String){
        database.child(user).setValue(["first_name":firstName,
                                       "last_name" : lastName ])
    }
}

struct ChatAppUser {
    let firstName       : String
    let lastname        : String
    let emailAddress    : String
    
    
    //TODO:- Part5. 특수문자때문에 crash나는 문제 uid로 대체 한 후 Part6.facebook Login 보기 
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    // let profilePic  : String
}
