//
//  Requests.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 30/04/2022.
//

import Foundation

func multipartRequest(urlString: String, parameters: [[String: Any]]? = nil, token: String? = nil) -> URLRequest {
    let boundary = "Boundary-\(UUID().uuidString)"
    var body = ""
    if parameters != nil {
        for param in parameters! {
            if param["disabled"] == nil {
                let paramName = param["key"]!
                body += "--\(boundary)\r\n"
                body += "Content-Disposition:form-data; name=\"\(paramName)\""
                if param["contentType"] != nil {
                    body += "\r\nContent-Type: \(param["contentType"] as! String)"
                }
                let paramType = param["type"] as! String
                if paramType == "text" {
                    let paramValue = param["value"] as! String
                    body += "\r\n\r\n\(paramValue)\r\n"
                } else {
                    let paramSrc = param["src"] as! String
                    let fileData = try! NSData(contentsOfFile:paramSrc, options:[]) as Data
                    let fileContent = String(data: fileData, encoding: .utf8)!
                    body += "; filename=\"\(paramSrc)\"\r\n"
                    + "Content-Type: \"content-type header\"\r\n\r\n\(fileContent)\r\n"
                }
            }
        }
    }

    body += "--\(boundary)--\r\n";
    let postData = body.data(using: .utf8)

    var request = URLRequest(url: URL(string: urlString)!,timeoutInterval: Double.infinity)
    if token != nil {
        request.addValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
    }
    
    request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    request.httpMethod = "POST"
    request.httpBody = postData
    return request
}

func getDataRequest(table: String, key: String, values: [String], cursor: Int, token:String) -> URLRequest {
    var valuesString = ""
    for valueIdx in values.indices {
        valuesString += "%22\(values[valueIdx])%22"
        if valueIdx < values.count - 1 {
            valuesString += "%2C"
        }
    }
    
    let urlString = "\(Endpoints.dataEndpoint)/\(table)?api_token=\(token)&constraints=%5B%7B%20%22key%22%3A%20%22\(key)%22%2C%22constraint_type%22%3A%22in%22%2C%22value%22%3A%5B\(valuesString)%5D%7D%5D&cursor=\(cursor)"
    var request = URLRequest(url: URL(string: urlString)!, timeoutInterval: Double.infinity)
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.httpMethod = "GET"
    return request
}
