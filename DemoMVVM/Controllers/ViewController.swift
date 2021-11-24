//
//  ViewController.swift
//  DemoMVVM
//
//  Created by Paul on 2021/11/24.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView:UITableView!

    private var viewModel:UsersViewModel!
    private var dataSource:UsersTableViewDataSource<UserTableViewCell,User>!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        callToViewModelToUIUpdate()
    }
    
    func callToViewModelToUIUpdate() {
        self.viewModel = UsersViewModel()
        self.viewModel.bindUserViewModelToController = {
            self.updateDataSource()
        }
    }
    
    func updateDataSource() {
        self.dataSource = UsersTableViewDataSource(cellIdentifier: "\(UserTableViewCell.self)", items: viewModel.userData, configCell: { cell,model in
            cell.titleLable.text = model.login ?? ""
            cell.subtitleLable.text = model.type ?? ""
            if let url = model.avatar_url?.absoluteString {
                cell.photoView.load(urlString: url)
            }
        })
        
        DispatchQueue.main.async {
            self.tableView.dataSource = self.dataSource
            self.tableView.reloadData()
        }
    }
}

