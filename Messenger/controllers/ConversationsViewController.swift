//
//  ConversationViewController.swift
//  Messenger
//
//  Created by Terry on 2020/08/20.
//  Copyright © 2020 Terry. All rights reserved.
//


import UIKit
import FirebaseAuth
import JGProgressHUD

struct Conversation {
    let id: String
    let name: String
    let otheruserEmail : String
    let latestMessage : LatestMessage
}

struct LatestMessage {
    let date : String
    let text : String
    let isRead: Bool
}


//MARK:- 대화창
class ConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self,
                       forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversationLable : UILabel = {
        let lb = UILabel()
        lb.text = "메세지가 없습니다."
        lb.textAlignment = .center
        lb.textColor = .gray
        lb.font = .systemFont(ofSize: 21, weight: .medium)
        lb.isHidden = true
        
        return lb
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    //MARK:- LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didtapComposeBtn))
        
        view.addSubview(tableView)
        view.addSubview(noConversationLable)
        setupTableView()
        //fetchConversation()
        startListeningForConversations()
        
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name.didLogInNotification ,object: nil,queue: .main, using: {[weak self] _ in
            guard let strongSelf = self else{
                return
            }
            strongSelf.startListeningForConversations()
        })
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noConversationLable.frame = CGRect(x: 10,
                                           y: (view.height-100)/2,
                                           width: view.width-20,
                                           height: 100)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    
    private func startListeningForConversations(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        print("starting convesation fetch... ")
        
        
        let safeEmail = DatabaseManager.safeEamil(emailAddrss: email)
        
        DatabaseManager.shared.getAllConversations(for: safeEmail, completion: { [weak self]res in
            switch res {
            case .success(let conversation):
                print("success get convo model")
                guard !conversation.isEmpty else{
                    self?.tableView.isHidden = true
                    self?.noConversationLable.isHidden = false
                    return
                }
                self?.noConversationLable.isHidden = true
                self?.tableView.isHidden = false
                self?.conversations = conversation
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                self?.tableView.isHidden = true
                self?.noConversationLable.isHidden = false
                 
                print("failed to get Convos: \(error)")
            }
        })
    }
    
    @objc private func didtapComposeBtn(){
        print("대화상대 검색 ")
        let vc = NewConversationViewController()
        vc.completion = {[weak self] result in
            guard let strongSelf = self else {
                return 
            }
            
//            strongSelf.createnewConversition(result: result)
            
            let currentConversations = strongSelf.conversations

            if let targetConversation = currentConversations.first(where: {
                
                return $0.otheruserEmail == DatabaseManager.safeEamil(emailAddrss: result.email)
            }){
//                strongSelf.createnewConversition(result: result)
                print("기존에 있는대화  대화")
                let vc = ChatViewController(with: targetConversation.otheruserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }else{
                print("기존에 없는 대화")
                strongSelf.createnewConversition(result: result)
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }
    
    private func createnewConversition(result:SearchResul){
        let name = result.name
        let email = result.email
        
        // 새로운 대화는 데이터베이스를 확인한다.
        // 대화 아이디를 재사용할 경우 두 사용자와의 대화가 존재한다
        // 그렇지 않으면 기존 코드를 통해 안전한 이메일로 만든다.
        DatabaseManager.shared.conversationExists(with: email, completion: {[weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let conversationId):
                print("새로운 채팅 생성 성공")
                let vc = ChatViewController(with: email, id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
              
            case .failure(_):
                print("기존 채팅 생성 성공")
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
                
            }
        })
        
    }
    //로그인 인증
    private func validateAuth(){
        /*
         회원이 firebase에 존재하지 않을 경우에 로그인화면으로 이동
         */
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    private func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(model)
        
    }
    
    func openConversation(_ model : Conversation){
        let vc = ChatViewController(with: model.otheruserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteConversation(conversationId: conversationId, completion: {[weak self] success in
                if success {
                    
                    self?.conversations.remove(at: indexPath.row)
                    
                    tableView.deleteRows(at: [indexPath], with: .left)
                    
                }
            })
            
            
            tableView.endUpdates()
        }
    }
}
