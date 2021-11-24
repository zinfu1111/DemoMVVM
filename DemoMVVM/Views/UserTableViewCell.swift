//
//  UserTableViewCell.swift
//  DemoMVVM
//
//  Created by Paul on 2021/11/24.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var subtitleLable: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        photoView.layer.cornerRadius = photoView.frame.height * 0.5
        photoView.clipsToBounds = true
        
    }
    
}
