//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Terry on 2020/08/20.
//  Copyright © 2020 Terry. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class ProfileViewController: UIViewController {

    @IBOutlet weak var  tableView: UITableView!
    
    let data = ["로그아웃"]
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableHeaderView = createTableHeader()
    }
    func createTableHeader() -> UIView? {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEamil(emailAddrss: email)
        let filename = safeEmail + "_profile_picture.png"
        
        let path = "images/" + filename
        
        let headerview = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: self.view.width,
                                        height: 300))
        
        headerview.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (headerview.width-150) / 2,
                                                  y: 75,
                                                  width: 150,
                                                  height: 150))
        
        
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        
        headerview.addSubview(imageView)
        
        StorageManager.shard.downloadURL(for: path, completion: {[weak self] result in
            switch result {
            case .success(let url):
                self?.downloadImage(imageView: imageView, url: url)
                print("success to get Download Url ")
            case .failure(let error):
                print("Faild to get Download url: \(error)")
            }
        })
        
        return headerview
    }
    func downloadImage(imageView: UIImageView, url: URL){
        URLSession.shared.dataTask(with: url, completionHandler: {data, _, error in
            guard let data = data, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            } 
        }).resume()
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
                                      style: .destructive,
                                      handler: {[weak self] _ in
                                        
                                        guard let strongSelf = self else {
                                            return
                                        }
                                        
                                        //Log Out facebook
                                        FBSDKLoginKit.LoginManager().logOut()
                                        
                                        //google log out
                                        GIDSignIn.sharedInstance()?.signOut()
                                        
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

