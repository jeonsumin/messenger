//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Terry on 2020/08/20.
//  Copyright © 2020 Terry. All rights reserved.
//

import UIKit
import FirebaseAuth
class ProfileViewController: UIViewController {

    @IBOutlet weak var  tableView: UITableView!
    
    let data = ["로그아웃"]
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }
}

extension ProfileViewController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let actionSheet =  UIAlertController(title: "",
                                       message: "",
                                       preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "로그아웃",
                                      style: .destructive, handler: {[weak self] _ in
                                        
                                        guard let strongSelf = self else {return}
                                        do{
                                            try FirebaseAuth.Auth.auth().signOut()
                                            
                                            let vc = LoginViewController()
                                            let nav = UINavigationController(rootViewController: vc)
                                            nav.modalPresentationStyle = .fullScreen
                                            strongSelf.present(nav, animated: true)
                                        }catch{
                                            print("Faild log out")
                                        }

        }))
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
}

