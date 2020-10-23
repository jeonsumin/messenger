//
//  LoginViewController.swift
//  Messenger
//
//  Created by Terry on 2020/08/20.
//  Copyright © 2020 Terry. All rights reserved.
//


import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

final class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    //MARK:- UI
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    //logo
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    //이메일
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none    // 자동 대소문자 유형
        field.autocorrectionType = .no          // 자동 보정 유형
        field.returnKeyType = .continue         // 리턴키
        field.layer.cornerRadius = 12           // 모서리 둥굴게
        field.layer.borderWidth = 1             // 태두리 픽셀
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground // 다크모드 호환성을 위하여
        return field
    }()
    
    //비밀번호
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none    // 자동 대소문자 유형
        field.autocorrectionType = .no          // 자동 보정 유형
        field.returnKeyType = .done         // 리턴키
        field.layer.cornerRadius = 12           // 모서리 둥굴게
        field.layer.borderWidth = 1             // 태두리 픽셀
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Passowrd..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    // 로그인 버튼
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .gray
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true // 경계 마스킹
        button.titleLabel?.font = .systemFont(ofSize: 20, weight:.bold)
        return button
    }()
    
    // 페이스북 로그인 버튼
    private let btnFBlogin : FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email,public_profile"]
        return button
    }()
    
    // 구글 로그인 버튼
    private let btnGoogleLogin = GIDSignInButton()
    
    
    private var loginObserver : NSObjectProtocol?
    
    
    //MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name.didLogInNotification ,object: nil,queue: .main, using: {[weak self] _ in
            guard let strongSelf = self else{
                return
            }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        title = "log In"
        view.backgroundColor = .secondarySystemBackground
        
        // 프로그래밍 방식의 barButtonItem 생성
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        //MARK:- add target
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside
        )
        
        //MARK:- add delegate
        emailField.delegate = self
        passwordField.delegate = self
        btnFBlogin.delegate = self
        
        //MARK: - add subView
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(btnFBlogin)
        scrollView.addSubview(btnGoogleLogin)
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // rootView에 프레임을 제공하여 각 UI의 위치 선정
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,
                                     width: scrollView.width-60,
                                     height: 52)
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom+10,
                                   width: scrollView.width-60,
                                   height: 52)
        
        btnFBlogin.frame = CGRect(x: 30,
                                  y: loginButton.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52)
        
        btnGoogleLogin.frame = CGRect(x: 30,
                                      y: btnFBlogin.bottom+10,
                                      width: scrollView.width-60,
                                      height: 52)
        
    }
    
    @objc private func loginButtonTapped(){
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        // 이메일, 패스워드 유효성 검사
        guard let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty, !password.isEmpty,
              password.count >= 6 else{
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        //MARK:- Friebase log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self ]data, error in
            
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            
            guard let result = data, error == nil else{
                print("Fiald Log In user with Email :: \(email)")
                return
            }
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEamil(emailAddrss: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: {[weak self]result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String:Any],
                          let name = userData["name"] as? String else{
                        return
                    }
                    UserDefaults.standard.set(name, forKey: "name")
                case .failure(let error):
                    print("Faild to read data with error \(error)")
                }
            })
            
            UserDefaults.standard.set(email, forKey: "email")
            
            
            
            print("Success Loggin In User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            let userName = UserDefaults.standard.value(forKey: "name")
            let userEmail = UserDefaults.standard.value(forKey: "email")
            print("loginUserDefualtsName::: \(userName), loginUserDefaultsEmail:::: \(userEmail)")
        })
    }
    
    // 회원가입 바버튼아이템 ActionMethod
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // 경고 알림창
    func alertUserLoginError(){
        let alert = UIAlertController(title: "알림", message: "로그인 해주시기 바랍니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    
}

// MARK:-TextFiled
extension LoginViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField{
            loginButtonTapped()
        }
        
        return true
    }
}
//MARK:- Facebook Login
extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no
    }
    //facebook login button
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("Faild log in with Facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start(completionHandler: {_, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("faild to make facebook graph request")
                return
            }
            
            print(result)
            
            guard let email = result["email"] as? String,
                  let name = result["name"] as? String,
                  let picture = result["picture"] as? [String:Any],
                  let data = picture["data"] as? [String:Any],
                  let pictureUrl = data["url"] as? String else {
                print("Faild to get email and name form fb result")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            
            UserDefaults.standard.set(name, forKey: "name")
            
            DatabaseManager.shared.selectEmail(with: email, completion: {exists in
                if !exists {
                    let chatUser = ChatAppUser(emailAddrss: email,
                                               name: name)
                    DatabaseManager.shared.insertUser(with: chatUser, comletion: {success in
                        if success {
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            
                            print("Downloading data from facebook iamge")
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _,_ in
                                guard let data = data else{
                                    print("Failed to get data from facebook")
                                    return
                                }
                                print("got data from FB, uploading,... ")
                                //upload Image... 
                                let filename = chatUser.profilePictureFileName
                                StorageManager.shard.uploadProfilePicture(with: data, fileName: filename, completion: {res in
                                    switch res {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                })
                            }).resume()
                            
                        }
                    })
                }
            })
            
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            //FaceBook Login
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: {[weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }
                guard authResult != nil , error == nil else{
                    if let error = error {
                        print("Facebook credential login Faild, MFA may be needed - \(error)")
                    }
                    return
                }
                
                print("SuccessFully logged user in")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
        
    }
    
    
}
