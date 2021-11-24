//
//  User.swift
//  DemoMVVM
//
//  Created by Paul on 2021/11/24.
//

import Foundation

struct User:Codable {
    
    let login:String?
    let type:String?
    let avatar_url:URL?
    let id:Int?
    let name:String?
    let location:String?
    let blog:URL?
    let followers:Int?
    let following:Int?
    let email:String?
}
