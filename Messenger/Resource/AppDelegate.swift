//
//  AppDelegate.swift
//  Messenger
//
//  Created by Terry on 2020/08/20.
//  Copyright © 2020 Terry. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    
    func application( _ application: UIApplication, didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey: Any]? ) -> Bool {
        
        FirebaseApp.configure()
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        return true
        
    }
    
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        ApplicationDelegate.shared.application( app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation] )
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    
    //google Login
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Failed to sign in with Goole: \(error)")
            }
            return
        }
        
        guard let user = user else {
            return
        }
        print("Did sign in with Google: \(user)")
        guard let name = user.profile.name,
            let uid = user.userID else {
            return
        }
        
        DatabaseManager.shared.selectEmail(with: uid, completion: { exists in
            if !exists {
                //insert tod database
                DatabaseManager.shared.insertUser(with: ChatAppUser(uid: uid, name: name))
            }
        })
        guard let authentication = user.authentication else {
            print("Missing auth object off of google user")
            return
            
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        FirebaseAuth.Auth.auth().signIn(with: credential, completion: { authResult ,error in
            guard authResult != nil, error == nil else{
                print("Faild to login in with google credential")
                return
            }
            print("SuccessFully singed in with google Card ")
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
        })
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("구글 로그인 연결 오류 ")
    }
    //
    //    func application(_ application: UIApplication, open url: URL, options:[UIApplication.OpenURLOptionsKey : Any]) -> Bool {
    //        return GIDSignIn.sharedInstance()?.handle(url)
    //    }
    //google Login //
}


