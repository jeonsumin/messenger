//
//  NewconversationTableViewCell.swift
//  Messenger
//
//  Created by Terry on 2020/09/09.
//  Copyright © 2020 Terry. All rights reserved.
//

import UIKit

class NewconversationTableViewCell: UITableViewCell {

        static let identifier = "NewConversationCell"
        
        private let userImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 50
            imageView.layer.masksToBounds = true
            return imageView
        }()
        
        private let userNameLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 21, weight: .semibold)
            return label
        }()
        
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.addSubview(userImageView)
            contentView.addSubview(userNameLabel)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            userImageView.frame = CGRect(x: 10,
                                         y: 10,
                                         width: 100,
                                         height: 100)
            userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                         y: 10,
                                         width: contentView.width - 20 - userImageView.width,
                                         height: contentView.height - 20)
        }
        
        public func configure(with model: SearchResul){
            userNameLabel.text = model.name
            
            let path = "images/\(model.email)_profile_picture.png"
            print(path)
            StorageManager.shard.downloadURL(for: path, completion: { [weak self ] res in
                switch res {
                case .success(let url) :
                    DispatchQueue.main.async {
                        self?.userImageView.sd_setImage(with: url, completed: nil)
                    }
                case .failure(let error):
                    print("falied to get image url: \(error)")
                }
            })
        }
    }
