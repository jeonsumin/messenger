//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Terry on 2020/08/20.
//  Copyright © 2020 Terry. All rights reserved.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    public var completion:(([String : String]) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark) //로딩 뷰
    
    private var users = [[String:String]]()
    
    private var results = [[String:String]]() // search Results
    
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
        let searchbar = UISearchBar()
        searchbar.placeholder = "Search ...."
        return searchbar
    }()
    
    private let tableView: UITableView = {
       let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noResultsLabel: UILabel = {
       let lb = UILabel()
        lb.isHidden = true
        lb.text = "검색결과가 없습니다."
        lb.textAlignment = .center
        lb.textColor = .gray
        lb.font = .systemFont(ofSize: 21, weight: .medium)
        return lb
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        
        tableView.dataSource = self
        tableView.delegate = self
        view.backgroundColor = .white
        searchBar.delegate = self
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))

        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width / 4,
                                      y: (view.height-200)/2,
                                      width: view.width/2,
                                      height: 200)
    }
    @objc private func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }
}
extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell",for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //start conversation
        let targetUserData = results[indexPath.row]
        
        dismiss(animated: true, completion: {[weak self] in
            self?.completion?(targetUserData)
        })
    }
}


// 검색창
extension NewConversationViewController: UISearchBarDelegate{
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
        
        self.searchUsers(query: text)
    }
    
    func searchUsers(query: String ){
        // check if array has firebase results
        if hasFetched{
        // if it does : filter
            filterusers(with: query)
        }else{
        // if no, fetch then filter
            DatabaseManager.shared.getAllusers(completion: { [weak self] result in
                switch result {
                case .success(let userCollection):
                    self?.hasFetched = true
                    self?.users = userCollection
                    self?.filterusers(with: query)
                case .failure(let error ):
                    print("Faild to get uesers: \(error)")
                    
                }
            })
        }
        //update the UI: einte
    }
    func filterusers(with term: String ){
        guard hasFetched else {
            return
        }
        self.spinner.dismiss()
        
        let results: [[String:String]]  = self.users.filter({
            guard let name = $0["name"]?.lowercased() else{
                return false
            }
            
            return name.hasPrefix(term.lowercased())
        })
        self.results = results
        updateUI()
    }
    func updateUI(){
        if results.isEmpty {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        }else{
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}
