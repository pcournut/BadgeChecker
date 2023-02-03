//
//  LoginViewModel.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 11/12/2022.
//

import Foundation


class LoginViewModel: ObservableObject {
    
    @Published var phoneNumber: String = ""
    @Published var numberString: String?
    @Published var countryCode: String?
    @Published var code: String = ""
    @Published var isShowingPhoneNumber: Bool = true
    @Published var isShowingCode: Bool = false
    @Published var isShowingEventInitView: Bool = false
    @Published var isShowingAlert: Bool = false
    @Published var isShowingWaitingView: Bool = false
    @Published var mainViewOpacity = 1.0
    
    func sendCode(phoneCountryCode: String, phoneNumber: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        enum JSONDecodingError: Error {
            case failed
        }
        
        enum WrongNumberError: Error {
            case failed
        }
        
        // TODO: max attempt reached (more than 5 times) error
        
        let urlString = "https://club-soda-test-pierre.bubbleapps.io/version-test/api/1.1/wf/PasswordlessSendCode"
        let parameters = [
            ["key": "phoneCountryCode",
             "value": phoneCountryCode,
             "type": "text"],
            ["key": "phoneNumber",
             "value": phoneNumber,
             "type": "text"]
        ]
        let request = multipartRequest(urlString: urlString, parameters: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                guard
                    let dataJSON = data,
                    let result = try? JSONDecoder().decode(SendResult.self, from: dataJSON)
                else {
                    print(response.debugDescription)
                    completion(.failure(JSONDecodingError.failed))
                    return
                }
                
                if result.status != nil {
                    completion(.success(true))
                } else {
                    print(response.debugDescription)
                    completion(.failure(WrongNumberError.failed))
                }
            } else {
                if let error = error {
                    completion(.failure((error)))
                }
            }
        }.resume()
        
        
    }
    
    func verifyCode(phoneCountryCode: String, phoneNumber: String, code: String, completion: @escaping (Result<VerifyResponse, Error>) -> Void) {
        enum JSONDecodingError: Error {
            case failed
        }
        enum WrongCodeError: Error {
            case failed
        }
        
        let urlString = "https://club-soda-test-pierre.bubbleapps.io/version-test/api/1.1/wf/PasswordlessVerifyCode"
        let parameters = [
            ["key": "phoneCountryCode",
             "value": phoneCountryCode,
             "type": "text"],
            ["key": "phoneNumber",
             "value": phoneNumber,
             "type": "text"],
            ["key": "code",
             "value": code,
             "type": "text"]
        ]
        let request = multipartRequest(urlString: urlString, parameters: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                guard
                    let dataJSON = data,
                    let result = try? JSONDecoder().decode(VerifyResult.self, from: dataJSON)
                else {
                    print(response.debugDescription)
                    completion(.failure(JSONDecodingError.failed))
                    return
                }
                
                if result.status != nil {
                    completion(.success(result.response!))
                } else {
                    print(response.debugDescription)
                    completion(.failure(WrongCodeError.failed))
                }
                
            } else {
                if let error = error {
                    print(response.debugDescription)
                    completion(.failure((error)))
                }
            }
        }.resume()
        
        
    }
    
    func loginNoTwilio(phoneCountryCode: String, phoneNumber: String, completion: @escaping (Result<VerifyResponse, Error>) -> Void) {
        enum JSONDecodingError: Error {
            case failed
        }
        
        enum WrongNumberError: Error {
            case failed
        }
        
        // TODO: max attempt reached (more than 5 times) error
        
        let urlString = "https://club-soda-test-pierre.bubbleapps.io/version-test/api/1.1/wf/PasswordlessVerifyCodeNOTWILIO"
        let parameters = [
            ["key": "phoneCountryCode",
             "value": phoneCountryCode,
             "type": "text"],
            ["key": "phoneNumber",
             "value": phoneNumber,
             "type": "text"]
        ]
        let request = multipartRequest(urlString: urlString, parameters: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                guard
                    let dataJSON = data,
                    let result = try? JSONDecoder().decode(NotTwilioResult.self, from: dataJSON)
                else {
                    print(response.debugDescription)
                    completion(.failure(JSONDecodingError.failed))
                    return
                }
                
                if result.status != nil {
                    completion(.success(result.response!))
                } else {
                    print(response.debugDescription)
                    completion(.failure(WrongNumberError.failed))
                }
                
            } else {
                if let error = error {
                    print(response.debugDescription)
                    completion(.failure((error)))
                }
            }
        }.resume()
        
        
        
    }
    
}
    
