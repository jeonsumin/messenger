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
import SDWebImage

final class ProfileViewController: UIViewController {
    
    @IBOutlet weak var  tableView: UITableView!
    
    var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableHeaderView = createTableHeader()
        data.append(ProfileViewModel(viewModelType: .info, title: "이름 \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .info, title: "이메일  \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")", handler: nil))
        
        
        data.append(ProfileViewModel(viewModelType: .info, title: "로그아웃", handler: {[weak self] in
            guard let strongSelf = self else {
                return
            }
            let actionSheet =  UIAlertController(title: "",
                                                 message: "",
                                                 preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "로그아웃",
                                                style: .destructive,
                                                handler: {[weak self] _ in
                                                    
                                                    guard let strongSelf = self else {
                                                        return
                                                    }
                                                    
                                                    UserDefaults.standard.setValue(nil, forKey: "email")
                                                    UserDefaults.standard.setValue(nil, forKey: "name")
                                                    
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
            
            strongSelf.present(actionSheet, animated: true)
        }))
        
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
        
        headerview.backgroundColor = .secondarySystemBackground
        
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
        
        StorageManager.shard.downloadURL(for: path, completion: { result in
            switch result {
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
                print("success to get Download Url ")
            case .failure(let error):
                print("Faild to get Download url: \(error)")
            }
        })
        
        return headerview
    }
}

extension ProfileViewController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        data[indexPath.row].handler?()
        
    }
    
}

class ProfileTableViewCell: UITableViewCell {
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel){
        
        self.textLabel?.text = viewModel.title
        
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
}
