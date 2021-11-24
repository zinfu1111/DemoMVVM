//
//  APIService.swift
//  DemoMVVM
//
//  Created by Paul on 2021/11/24.
//

import Foundation

class APIService: NSObject {
    
    private let source = URL(string: "https://api.github.com/users")!
    private let manager = RestManager()
    
    typealias ErrorHandler = (()->Void)
    typealias GetUsersDataHandler = ((_ model:[User])->Void)
    
    func apiToGetUsersData(compleiton: @escaping GetUsersDataHandler, failed: @escaping ErrorHandler) {
        
        manager.requestHttpHeaders.add(value: "application/vnd.github.v3+json", forkey: "Accept")
        manager.makeRequest(toURL: source, withHttpMethod: .get) { result in
            
            guard let data = result.data,let response = result.response else {
                if let error = result.error {
                    print(error.localizedDescription)
                }
                return
            }
            
//            print("[API]",String(data: data, encoding: .utf8))
            
            if response.httpStatusCode != 200 {
//                print("other httpStatusCode:", response.httpStatusCode)
            }
            let decoder = JSONDecoder()
            
            do {
                let result = try decoder.decode([User].self, from: data)
                compleiton(result)
            } catch let error {
                print(error.localizedDescription)
                failed()
            }
        }
        
    }
}
