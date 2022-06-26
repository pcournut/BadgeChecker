//
//  LoginView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import Foundation

class LoginInfo: ObservableObject {
    @Published var token : String = ""
    @Published var userID : String = ""
    @Published var userFirstName: String = ""
    @Published var userLastName: String = ""
}

struct LoginResponse: Codable {
    var token : String
    var user_id : String
    var userFirstName: String
    var userLastName: String
}

struct LoginResult: Codable {
    var status: String
    var response: LoginResponse
}

struct LoginView: View {
    
    @State private var email: String = "axel.duheme@gmail.com"
    @State private var password: String = "3121acb5a9f2529798dcf0af24d4409"
    @State private var isShowingEventInitView: Bool = false
    @State private var isShowingAlert: Bool = false
    
    @AppStorage("token") private var token = ""
    @AppStorage("userID") private var userID = ""
    @AppStorage("userFirstName") private var userFirstName = ""
    @AppStorage("userLastName") private var userLastName = ""
    @StateObject var loginInfo = LoginInfo()
    
    init() {
        //Use this if NavigationBarTitle is with Large Font
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color("KentoRed"))]

        //Use this if NavigationBarTitle is with displayMode = .inline
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color("KentoRed"))]
        
        // TODO: find a way to make this work
        UILabel.appearance().font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle(rawValue: "Courrier"))
        
        if !token.isEmpty && !userID.isEmpty && !userFirstName.isEmpty && !userLastName.isEmpty {
            loginInfo.token = token
            loginInfo.userID = userID
            loginInfo.userFirstName = userFirstName
            loginInfo.userLastName = userLastName
            isShowingEventInitView = true
        }
        
    }
    

    var body : some View {
        
        VStack {
            Image("Kento - text - selection")
                .resizable()
                .scaledToFit()
                .frame(width: 75.0, height: 75.0, alignment: .center)
            
            NavigationView {
                ZStack {
                    VStack(spacing: 30) {
                        
                        Image("Kento - sun")
                            .resizable()
                            .frame(width: 150.0, height: 150.0, alignment: .top)
                        
                        Text("Email")
                            .font(.title2)
                            .foregroundColor(Color("KentoRed"))
                        TextField("Enter email", text: $email)
                            .disableAutocorrection(true)
                            .foregroundColor(Color("KentoBeige"))
                            .autocapitalization(.none)
                            .multilineTextAlignment(.center)
                            .frame(width: 350, height: 40)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoBlueGrey")))
                        
                        Text("Password")
                            .font(.title2)
                            .foregroundColor(Color("KentoRed"))
                        SecureField("Enter password", text: $password)
                            .disableAutocorrection(true)
                            .foregroundColor(Color("KentoBeige"))
                            .autocapitalization(.none)
                            .multilineTextAlignment(.center)
                            .frame(width: 350, height: 40)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoBlueGrey")))
                            
                        
                        NavigationLink(destination: EventInitView(), isActive: $isShowingEventInitView) {
                            EmptyView()
                        }
                        
                        Button("Login") {
                            // TODO: login API call
                            login(email: email, password: password) { result in
                                switch result {
                                case .success(let response):
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
                            Alert(title: Text("Wrong Credentials"), message: Text("The username and/or password that you entered is wrong"), dismissButton: .default(Text("Got it!")))
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
        
        
        
    }
    
    func login(email: String, password: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        enum JSONDecodingError: Error {
            case failed
        }

        let urlString = "https://club-soda-test-pierre.bubbleapps.io/version-test/api/1.1/wf/Login"
        let parameters = [
          [
            "key": "email",
            "value": email,
            "type": "text"
          ],
          [
            "key": "password",
            "value": password,
            "type": "text"
          ]] as [[String : Any]]
        let request = multipartRequest(urlString: urlString, parameters: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                guard
                    let dataJSON = data,
                    let loginResult = try? JSONDecoder().decode(LoginResult.self, from: dataJSON)
                else {
                    print(response.debugDescription)
                    completion(.failure(JSONDecodingError.failed))
                    return
                }
                // TODO: populate loginInfo
                DispatchQueue.main.async {
                    // Persistent data
                    token = loginResult.response.token
                    userID = loginResult.response.user_id
                    userFirstName = loginResult.response.userFirstName
                    userLastName = loginResult.response.userLastName
                    
                    loginInfo.token = loginResult.response.token
                    loginInfo.userID = loginResult.response.user_id
                    loginInfo.userFirstName = loginResult.response.userFirstName
                    loginInfo.userLastName = loginResult.response.userLastName
                }
                completion(.success(true))
            } else {
                if let error = error {
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
