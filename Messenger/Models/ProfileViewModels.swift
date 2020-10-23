//
//  ProfileViewModels.swift
//  Messenger
//
//  Created by Terry on 2020/10/23.
//  Copyright © 2020 Terry. All rights reserved.
//

import Foundation



enum ProfileViewModelType{
    case info, logout
}

struct ProfileViewModel {
    let viewModelType : ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
