//
//  UsersViewModel.swift
//  DemoMVVM
//
//  Created by Paul on 2021/11/24.
//

import UIKit

class UsersViewModel: NSObject {
    
    private var apiService:APIService!
    
    private(set) var userData = [User](){
        didSet{
            self.bindUserViewModelToController()
        }
    }
    
    var bindUserViewModelToController = {}
    
    override init() {
        super.init()
        self.apiService = APIService()
        callFuncToGetUser()
    }

    func callFuncToGetUser() {
        apiService.apiToGetUsersData {[weak self] model in
            guard let self = self else { return }
            self.userData = model
        } failed: {
            print("test e")
        }

    }
}
