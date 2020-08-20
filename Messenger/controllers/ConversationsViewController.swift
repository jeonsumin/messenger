//
//  ViewController.swift
//  Messenger
//
//  Created by Terry on 2020/08/20.
//  Copyright © 2020 Terry. All rights reserved.
//

import UIKit

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        let isLoggedIn = UserDefaults.standard.bool(forKey: "logged_id")
        
        if !isLoggedIn {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false) 
        }
    }
}

