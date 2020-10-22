//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Terry on 2020/08/20.
//  Copyright © 2020 Terry. All rights reserved.
//


import UIKit
import FirebaseAuth
import JGProgressHUD

//MARK:- 회원가입
class RegisterViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .dark)

    
    //MARK:- UI
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    //MARK: 프로필 이미지
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        //imageView.layer.borderColor = UIColor.lightGray.cgColor
        //imageView.layer.borderWidth = 2
        return imageView
    }()
    
    //MARK: 이름
    private let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none    // 자동 대소문자 유형
        field.autocorrectionType = .no          // 자동 보정 유형
        field.returnKeyType = .continue         // 리턴키
        field.layer.cornerRadius = 12           // 모서리 둥굴게
        field.layer.borderWidth = 1             // 태두리 픽셀
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "first Name..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()

    //MARK: 이메일
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
        field.backgroundColor = .white
        return field
    }()
    
    //MARK: 비밀번호
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
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    //MARK: 회원가입 버튼
    private let RegisterButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight:.bold)
        return button
    }()
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "log In"
        self.view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        
        //MARK: delegate
        emailField.delegate = self
        passwordField.delegate = self
        
        //MARK: target
        RegisterButton.addTarget(self, action: #selector(RegisterButtonTapped), for: .touchUpInside
        )
        
        //MARK: addsubView
        self.view.addSubview(scrollView)
        self.scrollView.addSubview(imageView)
        self.scrollView.addSubview(emailField)
        self.scrollView.addSubview(passwordField)
        self.scrollView.addSubview(RegisterButton)
        self.scrollView.addSubview(firstNameField)
        
        //MARK: 이미지뷰 제스처 활성화
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        //MARK: TapGesture
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(didTapChangeProfilePic))
        imageView.addGestureRecognizer(gesture)
        
    }
    //MARK: viewDidLayoutSubviews
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        imageView.layer.cornerRadius = imageView.width/2.0
        firstNameField.frame = CGRect(x: 30,
                                      y: imageView.bottom+10,
                                      width: scrollView.width-60,
                                      height: 52)
//        lastNameField.frame = CGRect(x: 30,
//                                     y: firstNameField.bottom+10,
//                                     width: scrollView.width-60,
//                                     height: 52)
        emailField.frame = CGRect(x: 30,
                                  y: firstNameField.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,
                                     width: scrollView.width-60,
                                     height: 52)
        RegisterButton.frame = CGRect(x: 30,
                                      y: passwordField.bottom+10,
                                      width: scrollView.width-60,
                                      height: 52)
    }
    
    //MARK: didTapChangeProfilePic
    @objc private func didTapChangeProfilePic(){
        print("changeProfilePic")
        presentPhotoActionSheet()
    }
    
    //MARK:- Action Method
    @objc private func RegisterButtonTapped(){
        print("회원가입 버튼 Tapped")
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        
        //유효성 검사
        guard let Name = firstNameField.text,
            let email = emailField.text,
            let password = passwordField.text,
            !email.isEmpty,
            !password.isEmpty,
            !Name.isEmpty,
//            !lastName.isEmpty,
            password.count >= 6 else{
                alertUserLoginError()
                return
        }
        
        spinner.show(in: view)
        
        //MARK: Friebase log In
        DatabaseManager.shared.selectEmail(with: email) { [weak self]exists in
            
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()

            }
            guard !exists else{
                //useralready exists
                strongSelf.alertUserLoginError(message: "Looks Like a user account for that email address already exists. ")
                return
            }
            
            // firebase Auth인증 이메일 유저 생성
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { authRes, error in
                
                guard authRes != nil, error == nil else{
                    print("Error cureating user")
                    return
                }
                
                let chatuser = ChatAppUser(emailAddrss: email, name: Name)
                DatabaseManager.shared.insertUser(with:chatuser, comletion: {success in
                    if success {
                        //upload Image
                        guard let image = strongSelf.imageView.image,
                            let data = image.pngData() else {
                            return
                        }
                        let filename = chatuser.profilePictureFileName
                        StorageManager.shard.uploadProfilePicture(with: data, fileName: filename, completion: {res in
                            switch res {
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                print(downloadUrl)
                            case .failure(let error):
                                print("Storage manager error: \(error)")
                            }
                        })
                    }
                })

                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    //MARK:alertUserLoginError
    func alertUserLoginError(message : String = "이메일 또는 비밀번호를 확인해주세요."){
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    //MARK:didTapRegister
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

//MARK:- TextfieldDelegate
extension RegisterViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField{
            RegisterButtonTapped()
        }
        
        return true
    }
}

//MARK:- ImagePickerDelegate
extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
    func presentPhotoActionSheet(){
        // custom Alert 시트 생성
        let actionSheet = UIAlertController(title: "프로필 이미지",
                                            message: "선택해주세요",
                                            preferredStyle: .actionSheet) 
        // alert시트에 액션 추가
        actionSheet.addAction(UIAlertAction(title: "취소",
                                            style: .cancel,
                                            handler: nil))
        
        actionSheet.addAction(UIAlertAction(title: "카메라",
                                            style: .default,
                                            handler: {
                                                [weak self] _ in
                                                self?.presentCamera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "앨범",
                                            style: .default,
                                            handler: {[weak self]_ in
                                                self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    //MARK:
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true // 편집 허용
        present(vc, animated: true)
        
    }
    //MARK:
    func presentPhotoPicker(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
        
    }
    
    //MARK:
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        print("imagePickerConteroller :::: 선택한 이미지 세팅")
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else{
            return
        }
        self.imageView.image = selectedImage
    }
    
    
    /// 이미지피커뷰 닫기
    //MARK:
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated: true, completion: nil)
    }
}
