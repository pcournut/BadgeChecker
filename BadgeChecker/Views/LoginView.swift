//
//  LoginView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import Foundation
import iPhoneNumberField

class LoginInfo: ObservableObject {
    @Published var userFirstName: String = UserDefaults.standard.string(forKey: "userFirstName") ?? ""
    @Published var token: String = UserDefaults.standard.string(forKey: "token") ?? ""
    @Published var user_id: String = UserDefaults.standard.string(forKey: "user_id") ?? ""
    @Published var expires: Date = UserDefaults.standard.object(forKey: "expires") as? Date ?? Date.now
}

struct SendResult: Codable {
    var status: String?
    var statusCode: String?
}

struct VerifyResponse: Codable {
    var userFirstName: String
    var token: String
    var user_id: String
    var expires: Int
}

struct VerifyResult: Codable {
    var status: String?
    var statusCode: String?
    var response: VerifyResponse?
}

struct NotTwilioResult: Codable {
    var status: String?
    var statusCode: String?
    var response: VerifyResponse?
}

struct LoginView: View {
    
    @State private var phoneNumber: String = ""
    @State private var numberString: String?
    @State private var countryCode: String?
    @State private var code: String = ""
    @State private var isShowingPhoneNumber: Bool = true
    @State private var isShowingCode: Bool = false
    @State private var isShowingEventInitView: Bool = false
    @State private var isShowingAlert: Bool = false
    
    @StateObject var loginInfo = LoginInfo()
    
    init() {
        //Use this if NavigationBarTitle is with Large Font
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color("KentoRed"))]

        //Use this if NavigationBarTitle is with displayMode = .inline
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color("KentoRed"))]
        
        // TODO: find a way to make this work
        UILabel.appearance().font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle(rawValue: "Courrier"))
        
    }
    
    var body : some View {
        
        VStack {
            
            ZStack() {
                Image("Kento - text - selection")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75.0, height: 75.0, alignment: .center)
                
                Image(systemName: "person.crop.circle.badge.xmark")
                    .foregroundColor(Color("KentoRed"))
                    .font(.system(size: 25))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .onTapGesture {
                        loginInfo.expires = Date.now
                        isShowingEventInitView = false
                    }
            }
            
            
            NavigationView {
                ZStack {
                    VStack(spacing: 30) {
                        
                        
                        Image("Kento - sun")
                            .resizable()
                            .frame(width: 150.0, height: 150.0, alignment: .top)
                        
                        if isShowingPhoneNumber {
                            
                            iPhoneNumberField(text: $phoneNumber)
                                .flagHidden(false)
                                .flagSelectable(true)
                                .prefixHidden(false)
                                .defaultRegion("FR")
                                .autofillPrefix(true)
                                .onNumberChange { phoneNumber in
                                    if phoneNumber != nil {
                                        numberString = String(phoneNumber!.nationalNumber)
                                        countryCode = "+" + String(phoneNumber!.countryCode)
                                    } else {
                                        numberString = nil
                                        countryCode = nil
                                    }
                                }
                                .font(UIFont(size: 22, weight: .light, design: .monospaced))
                                .foregroundColor(Color("KentoRed"))
                                .clearButtonMode(.always)
                                .padding()
                                .accentColor(Color("KentoRed"))
                                .background(Color("KentoBlueGrey"))
                                .cornerRadius(10)
                                .padding()
                                .frame(minWidth: 0, maxWidth: 380)
                                
                            
                            if countryCode != nil && numberString != nil {
                                Button("Send code") {
                                    sendCode(phoneCountryCode: countryCode!, phoneNumber: numberString!) { result in
                                        switch result {
                                        case .success(_):
                                            self.isShowingPhoneNumber = false
                                            self.isShowingCode = true
                                        case .failure(_):
                                            self.isShowingAlert = true
                                        }
                                    }
                                }
                                .font(.title3)
                                .foregroundColor(Color("KentoBlueGrey"))
                                .padding()
                                .frame(minWidth: 0, maxWidth: 350)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                                .alert(isPresented: $isShowingAlert) {
                                    Alert(title: Text("Wrong phone number"), message: Text("The phone number that you entered is wrong"), dismissButton: .default(Text("Got it!")))
                                }
                                
                                Button("Direct login [dev]") {
                                    loginNoTwilio(phoneCountryCode: countryCode!, phoneNumber: numberString!) { result in
                                        switch result {
                                        case .success(_):
                                            self.isShowingPhoneNumber = true
                                            self.isShowingCode = false
                                            self.isShowingEventInitView = true
                                        case .failure(_):
                                            self.isShowingAlert = true
                                        }
                                    }
                                }
                                .font(.title3)
                                .foregroundColor(Color("KentoBlueGrey"))
                                .padding()
                                .frame(minWidth: 0, maxWidth: 350)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                                .alert(isPresented: $isShowingAlert) {
                                    Alert(title: Text("Wrong phone number"), message: Text("The phone number that you entered is wrong"), dismissButton: .default(Text("Got it!")))
                                }
                                
                            }
                            
                        }
                        
                        
                        if isShowingCode {
                            Text("Code")
                                .font(.title2)
                                .foregroundColor(Color("KentoRed"))
                            SecureField("Enter code", text: $code)
                                .disableAutocorrection(true)
                                .foregroundColor(Color("KentoBeige"))
                                .autocapitalization(.none)
                                .multilineTextAlignment(.center)
                                .frame(width: 350, height: 40)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoBlueGrey")))

                            Button("Verify code") {
                                verifyCode(phoneCountryCode: countryCode!, phoneNumber: numberString!, code: code) { result in
                                    switch result {
                                    case .success(let response):
                                        self.isShowingPhoneNumber = true
                                        self.isShowingCode = false
                                        self.isShowingEventInitView = response
                                    case .failure(_):
                                        self.isShowingAlert = true
                                    }
                                }
                            }
                            .font(.title3)
                            .foregroundColor(Color("KentoBlueGrey"))
                            .padding()
                            .frame(minWidth: 0, maxWidth: 350)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                            .alert(isPresented: $isShowingAlert) {
                                Alert(title: Text("Wrong phone number"), message: Text("The phone number that you entered is wrong"), dismissButton: .default(Text("Got it!")))
                            }
                        }
                        
                        NavigationLink(destination: EventInitView(), isActive: $isShowingEventInitView) {
                            EmptyView()
                        }
                        
                        Spacer()
                        
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Color("KentoBeige").edgesIgnoringSafeArea(.all))
                
            }
            .environmentObject(loginInfo)
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
        .background(Color("KentoBlueGrey"))
        .onAppear() {
            isShowingEventInitView = (Date.now < loginInfo.expires)
        }
        
        
        
    }
    
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
    
    func verifyCode(phoneCountryCode: String, phoneNumber: String, code: String, completion: @escaping (Result<Bool, Error>) -> Void) {
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
                    DispatchQueue.main.async {
                        loginInfo.userFirstName = result.response!.userFirstName
                        loginInfo.user_id = result.response!.user_id
                        loginInfo.token = result.response!.token
                        loginInfo.expires = Date.now.addingTimeInterval(TimeInterval(result.response!.expires))
                        
                        UserDefaults.standard.set(loginInfo.userFirstName, forKey: "userFirstName")
                        UserDefaults.standard.set(loginInfo.user_id, forKey: "user_id")
                        UserDefaults.standard.set(loginInfo.token, forKey: "token")
                        UserDefaults.standard.set(loginInfo.expires, forKey: "expires")
                    }
                    completion(.success(true))
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
    
    func loginNoTwilio(phoneCountryCode: String, phoneNumber: String, completion: @escaping (Result<Bool, Error>) -> Void) {
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
                    DispatchQueue.main.async {
                        loginInfo.userFirstName = result.response!.userFirstName
                        loginInfo.user_id = result.response!.user_id
                        loginInfo.token = result.response!.token
                        loginInfo.expires = Date.now.addingTimeInterval(TimeInterval(result.response!.expires))
                        
                        UserDefaults.standard.set(loginInfo.userFirstName, forKey: "userFirstName")
                        UserDefaults.standard.set(loginInfo.user_id, forKey: "user_id")
                        UserDefaults.standard.set(loginInfo.token, forKey: "token")
                        UserDefaults.standard.set(loginInfo.expires, forKey: "expires")
                        
                    }
                    completion(.success(true))
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
