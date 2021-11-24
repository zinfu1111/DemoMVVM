//
//  RestManager.swift
//  DemoMVVM
//
//  Created by Paul on 2021/11/24.
//

import Foundation

//自定型別 (structs、enums)，都是 RestManager 類別的內部型別 (Inner Types)。

class RestManager {
    var requestHttpHeaders = RestEntity()
    var urlQueryParameters = RestEntity()
    var httpBodyParameters = RestEntity()
    var httpBodyMultipartParameters = MultipartEntity()
    
    var httpBody: Data?

    func makeRequest(toURL url: URL,
                             withHttpMethod httpMethod: HttpMethod,
                             completion: @escaping (_ result: Results) -> Void) {
        //.userInitiated 優先考慮我們的工作，並降低其他在背景執行的工作的優先級別。
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let targetURL = self?.addURLQueryParameters(toURL: url)
            let httpBody = self?.getHttpBody()
            guard let request = self?.prepareRequest(withURL: targetURL, httpBody: httpBody, httpMethod: httpMethod) else {
                completion(Results(withError: CustomError.failedToCreateRequest))
                return
            }
            
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
            sessionConfiguration.urlCache = nil
            let session = URLSession(configuration: sessionConfiguration)
            let task = session.dataTask(with: request) { (data, response, error) in
                completion(Results(withData: data, response: Response(fromURLResponse: response), error: error))
            }
            task.resume()
        }
    }
    
    //建立另一個解決從 URL 擷取單一資料的問題，而無需準備一個網路請求或關心伺服器的回應。
    func getData(fromURL url: URL, completion: @escaping (_ data: Data?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
            sessionConfiguration.urlCache = nil
            let session = URLSession(configuration: sessionConfiguration)
            let task = session.dataTask(with: url, completionHandler: { (data, response, error) in
                guard let data = data else { completion(nil); return }
                completion(data)
            })
            task.resume()
        }
    }
    
    private func addURLQueryParameters(toURL url: URL) -> URL {
        if urlQueryParameters.totalItems() > 0 {
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return url
            }
            var queryItems = [URLQueryItem]()
            for (key, value) in urlQueryParameters.allValues() {
                let item = URLQueryItem(name: key,
                                        value: value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
                queryItems.append(item)
            }
            
            urlComponents.queryItems = queryItems
            guard let updatedURL = urlComponents.url else {
                return url
            }
            
            return updatedURL
        }
        return url
    }
    
    private func getHttpBody() -> Data? {
        guard let contentType = requestHttpHeaders.value(forkey: "Content-Type") else {
            return nil
        }
        if contentType.contains("application/json") {
            return try? JSONSerialization.data(withJSONObject: httpBodyParameters.allValues(),
                                               options: [.prettyPrinted, .sortedKeys])
        } else if contentType.contains("application/x-www-form-urlencoded") {
            let bodyString = httpBodyParameters.allValues().map {
                "\($0)=\(String(describing: $1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))"
            }.joined(separator: "&")
            return bodyString.data(using: .utf8)
        } else if contentType.contains("multipart/form-data") {
            return requestWithFormData()
        }
        
        return httpBody
    }
    
    private func prepareRequest(withURL url: URL?, httpBody: Data?, httpMethod: HttpMethod) -> URLRequest? {
        guard let url = url else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        
        for (header, value) in requestHttpHeaders.allValues() {
            request.setValue(value, forHTTPHeaderField: header)
        }
        
        request.httpBody = httpBody
        return request
    }
    
    private func requestWithFormData() -> Data {
        var body = Data()
        var boundary: String = ""
        
        for i in httpBodyMultipartParameters.allValues() {
            body.appendString(string: "--\(i.boundary)\r\n")
            body.appendString(string: "Content-Disposition: form-data; name=\"\(i.key)\"; filename=\"\(i.filename)\"\r\n") //此處放入file name，以隨機數代替，可自行放入
            body.appendString(string: "Content-Type: \(i.data.mimeType)\r\n\r\n")
            body.append(i.data)
            body.appendString(string: "\r\n")
            
            boundary = i.boundary
        }
        
        body.appendString(string: "--\(boundary)--\r\n")
        
        return body
    }
}


//Extension 是用於自定型別的實作
extension RestManager {
    enum HttpMethod: String {
        case get
        case post
        case put
        case patch
        case delete
    }
    
    enum CustomError: Error {
        case failedToCreateRequest
    }
    
    struct RestEntity {
        private var values: [String: String] = [:]
        
        mutating func add(value: String, forkey key: String) {
            values[key] = value
        }
        
        func value(forkey key: String) -> String? {
            return values[key]
        }
        
        func allValues() -> [String: String] {
            return values
        }
        
        func totalItems() -> Int {
            return values.count
        }
    }
    
    //管理回應(HTTP 狀態碼、HTTP 標頭、回應本文)
    struct Response {
        var response: URLResponse?      //處理實際的回應物件，不會包含伺服器回傳的實際資料。
        var httpStatusCode: Int = 0     //請求結果，狀態碼2xx、3xx ... 等
        var headers = RestEntity()      //標頭
        
        init(fromURLResponse response: URLResponse?) {
            guard let response = response else { return }
            self.response = response
            httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            if let headerFields = (response as? HTTPURLResponse)?.allHeaderFields {
                for (key, value) in headerFields {
                    headers.add(value: "\(value)", forkey: "\(key)")
                }
            }
        }
    }
    
    struct Results {
        var data: Data?
        var response: Response?
        var error: Error?
        
        init(withData data: Data?, response: Response?, error: Error?) {
            self.data = data
            self.response = response
            self.error = error
        }
        
        init(withError error: Error) {
            self.error = error
        }
    }
    
    struct MultipartEntity {
        private var values: [Multipart] = []
        
        mutating func add(value: Multipart) {
            values.append(value)
        }
        
        func value(index: Int) -> Multipart? {
            return values[index]
        }
        
        func allValues() -> [Multipart] {
            return values
        }
        
        func totalItems() -> Int {
            return values.count
        }
    }
    
    struct Multipart {
        var boundary: String
        var key: String
        var data: Data
        var filename: String
        
        init(boundary: String, key: String, data: Data, filename: String) {
            self.boundary = boundary
            self.key = key
            self.data = data
            self.filename = filename
        }
    }
    
}

extension RestManager.CustomError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .failedToCreateRequest: return NSLocalizedString("Unable to create the URLRequest object", comment: "")
        }
    }
}

extension Data{
    mutating func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
    
    private static let mimeTypeSignatures: [UInt8 : String] = [
        0xFF : "image/jpeg",
        0x89 : "image/png",
        0x47 : "image/gif",
        0x49 : "image/tiff",
        0x4D : "image/tiff",
        0x25 : "application/pdf",
        0xD0 : "application/vnd",
        0x46 : "text/plain",
        ]

    var mimeType: String {
        var c: UInt8 = 0
        copyBytes(to: &c, count: 1)
        return Data.mimeTypeSignatures[c] ?? "application/octet-stream"
    }
}
