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

    private let spinner = JGProgressHUD()
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
        view.backgroundColor = .white
        searchBar.delegate = self
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))

        searchBar.becomeFirstResponder()
    }
    @objc private func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }
}

extension NewConversationViewController: UISearchBarDelegate{
    
}
