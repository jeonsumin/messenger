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

class LoginViewController: UIViewController {
    
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
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none    // 자동 보정 유형
        field.autocorrectionType = .no          // 자동 보정 유형
        field.returnKeyType = .continue         // 리턴키
        field.layer.cornerRadius = 12           // 모서리 둥굴게
        field.layer.borderWidth = 1             // 태두리 픽셀
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none    // 자동 보정 유형
        field.autocorrectionType = .no          // 자동 보정 유형
        field.returnKeyType = .done         // 리턴키
        field.layer.cornerRadius = 12           // 모서리 둥굴게
        field.layer.borderWidth = 1             // 태두리 픽셀
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Passowrd..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .gray
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight:.bold)
        return button
    }()
    
    private let btnFBlogin : FBLoginButton = {
       let button = FBLoginButton()
        button.permissions = ["email, public_profile"]
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "log In"
        self.view.backgroundColor = .white
        
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
        self.view.addSubview(scrollView)
        self.scrollView.addSubview(imageView)
        self.scrollView.addSubview(emailField)
        self.scrollView.addSubview(passwordField)
        self.scrollView.addSubview(loginButton)
        self.scrollView.addSubview(btnFBlogin)
    }
    
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
        btnFBlogin.frame.origin.y = loginButton.bottom+20
    }
    
    @objc private func loginButtonTapped(){
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else{
            alertUserLoginError()
            return
        }
        // Friebase log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self ]data, error in
            
            guard let strongSelf = self else {
                return
            }
            guard let result = data, error == nil else{
                print("Fiald Log In user with Email :: \(email)")
                return
            }
            let user = result.user
            print("Success Loggin In User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "알림", message: "로그인 해주시기 바랍니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
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

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("Faild log in with Facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, name"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start(completionHandler: {_, result, error in
            guard let result = result as? [String: Any],
                error == nil else {
                print("faild to make facebook graph request")
                return
            }
            print("\(result)")

            guard let userName = result["name"] as? String,
                let email = result["email"] as? String else{
                    print("faild email and name from fb result")
                    return
            }
            let nameComponents = userName.components(separatedBy: " ")
            guard nameComponents.count == 2 else{
                return
            }
            
            let firstName = nameComponents[0]
            let lastName = nameComponents[1]
            
            DatabaseManager.shared.selectEmail(with: email, completion: {exists in
                if !exists {
                    DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firstName,
                                                                        lastname: lastName,
                                                                        emailAddress: email))
                }
            }
            )
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
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
