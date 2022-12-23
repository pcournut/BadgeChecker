//
//  LoginView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import Foundation
import iPhoneNumberField



struct LoginView: View {
    
    @StateObject var loginInfo = LoginInfo()
    @ObservedObject var viewModel = LoginViewModel()
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color("KentoRed"))]
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
                        viewModel.isShowingEventInitView = false
                    }
            }
            
            
            NavigationView {
                ZStack {
                    VStack(spacing: 30) {
                        
                        
                        Image("Kento - sun")
                            .resizable()
                            .frame(width: 150.0, height: 150.0, alignment: .top)
                        
                        if viewModel.isShowingPhoneNumber {
                            
                            iPhoneNumberField(text: $viewModel.phoneNumber)
                                .flagHidden(false)
                                .flagSelectable(true)
                                .prefixHidden(false)
                                .defaultRegion("FR")
                                .autofillPrefix(true)
                                .onNumberChange { phoneNumber in
                                    if phoneNumber != nil {
                                        viewModel.numberString = String(phoneNumber!.nationalNumber)
                                        viewModel.countryCode = "+" + String(phoneNumber!.countryCode)
                                    } else {
                                        viewModel.numberString = nil
                                        viewModel.countryCode = nil
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
                                
                            
                            if viewModel.countryCode != nil && viewModel.numberString != nil {
                                Button("Send code") {
                                    viewModel.sendCode(phoneCountryCode: viewModel.countryCode!, phoneNumber: viewModel.numberString!) { result in
                                        switch result {
                                        case .success(_):
                                            DispatchQueue.main.async {
                                                viewModel.isShowingPhoneNumber = false
                                                viewModel.isShowingCode = true
                                            }
                                        case .failure(_):
                                            viewModel.isShowingAlert = true
                                        }
                                    }
                                }
                                .font(.title3)
                                .foregroundColor(Color("KentoBlueGrey"))
                                .padding()
                                .frame(minWidth: 0, maxWidth: 350)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                                .alert(isPresented: $viewModel.isShowingAlert) {
                                    Alert(title: Text("Wrong phone number"), message: Text("The phone number that you entered is wrong"), dismissButton: .default(Text("Got it!")))
                                }
                                
                                Button("Direct login [dev]") {
                                    viewModel.loginNoTwilio(phoneCountryCode: viewModel.countryCode!, phoneNumber: viewModel.numberString!) { result in
                                        switch result {
                                        case .success(let response):
                                            DispatchQueue.main.async {
                                                loginInfo.userFirstName = response.userFirstName
                                                loginInfo.user_id = response.user_id
                                                loginInfo.token = response.token
                                                loginInfo.expires = Date.now.addingTimeInterval(TimeInterval(response.expires))
                                                
                                                UserDefaults.standard.set(loginInfo.userFirstName, forKey: "userFirstName")
                                                UserDefaults.standard.set(loginInfo.user_id, forKey: "user_id")
                                                UserDefaults.standard.set(loginInfo.token, forKey: "token")
                                                UserDefaults.standard.set(loginInfo.expires, forKey: "expires")
                                                
                                                viewModel.isShowingPhoneNumber = true
                                                viewModel.isShowingCode = false
                                                viewModel.isShowingEventInitView = true
                                            }
                                        case .failure(_):
                                            viewModel.isShowingAlert = true
                                        }
                                    }
                                }
                                .font(.title3)
                                .foregroundColor(Color("KentoBlueGrey"))
                                .padding()
                                .frame(minWidth: 0, maxWidth: 350)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                                .alert(isPresented: $viewModel.isShowingAlert) {
                                    Alert(title: Text("Wrong phone number"), message: Text("The phone number that you entered is wrong"), dismissButton: .default(Text("Got it!")))
                                }
                                
                            }
                            
                        }
                        
                        
                        if viewModel.isShowingCode {
                            Text("Code")
                                .font(.title2)
                                .foregroundColor(Color("KentoRed"))
                            SecureField("Enter code", text: $viewModel.code)
                                .disableAutocorrection(true)
                                .foregroundColor(Color("KentoBeige"))
                                .autocapitalization(.none)
                                .multilineTextAlignment(.center)
                                .frame(width: 350, height: 40)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoBlueGrey")))

                            Button("Verify code") {
                                viewModel.verifyCode(phoneCountryCode: viewModel.countryCode!, phoneNumber: viewModel.numberString!, code: viewModel.code) { result in
                                    switch result {
                                    case .success(let response):
                                        DispatchQueue.main.async {
                                            loginInfo.userFirstName = response.userFirstName
                                            loginInfo.user_id = response.user_id
                                            loginInfo.token = response.token
                                            loginInfo.expires = Date.now.addingTimeInterval(TimeInterval(response.expires))
                                            UserDefaults.standard.set(loginInfo.userFirstName, forKey: "userFirstName")
                                            UserDefaults.standard.set(loginInfo.user_id, forKey: "user_id")
                                            UserDefaults.standard.set(loginInfo.token, forKey: "token")
                                            UserDefaults.standard.set(loginInfo.expires, forKey: "expires")
                                            viewModel.isShowingPhoneNumber = true
                                            viewModel.isShowingCode = false
                                            viewModel.isShowingEventInitView = true
                                        }
                                    case .failure(_):
                                        viewModel.isShowingAlert = true
                                    }
                                }
                            }
                            .font(.title3)
                            .foregroundColor(Color("KentoBlueGrey"))
                            .padding()
                            .frame(minWidth: 0, maxWidth: 350)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                            .alert(isPresented: $viewModel.isShowingAlert) {
                                Alert(title: Text("Wrong phone number"), message: Text("The phone number that you entered is wrong"), dismissButton: .default(Text("Got it!")))
                            }
                        }
                        
                        NavigationLink(destination: EventInitView(), isActive: $viewModel.isShowingEventInitView) {
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
            viewModel.isShowingEventInitView = (Date.now < loginInfo.expires)
        }
        
    }
    
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
