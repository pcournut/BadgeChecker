//
//  LoginView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import Combine
import Foundation
import iPhoneNumberField


extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension UIApplication {
    func addTapGestureRecognizer() {
        guard let window = windows.first else { return }
        let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tapGesture.requiresExclusiveTouchType = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        window.addGestureRecognizer(tapGesture)
    }
}

extension UIApplication: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true // set to `false` if you don't want to detect tap during other gestures
    }
}

struct LoginView: View {
    
    @StateObject var loginInfo = LoginInfo()
    @ObservedObject var viewModel = LoginViewModel()
    
    @State var isEditing = false
    
    var body : some View {
        
        VStack {
            ZStack() {
                Image("Kento - text - selection")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75.0, height: 75.0, alignment: .center)
                
                if viewModel.isShowingEventInitView {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .foregroundColor(Color("KentoRed"))
                        .font(.system(size: 25))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .onTapGesture {
                            UserDefaults.standard.removeObject(forKey: "userFirstName")
                            UserDefaults.standard.removeObject(forKey: "user_id")
                            UserDefaults.standard.removeObject(forKey: "token")
                            UserDefaults.standard.removeObject(forKey: "expires")
                            
                            viewModel.isShowingEventInitView = false
                        }
                }
                
            }
            
            NavigationView {
                ZStack {
                    if viewModel.isShowingWaitingView {
                        WaitingView()
                    }
                    
                    VStack(spacing: 30) {
                        NavigationLink(destination: EventInitView(), isActive: $viewModel.isShowingEventInitView) {
                            EmptyView()
                        }
                        
                        if !isEditing {
                            Image("Kento - sun")
                                .resizable()
                                .frame(width: 150.0, height: 150.0, alignment: .top)
                        }
                        
                        if viewModel.isShowingPhoneNumber {
                            
                            iPhoneNumberField(
                                text: $viewModel.phoneNumber,
                                isEditing: $isEditing,
                                formatted: true
                            )
                                .flagHidden(false)
                                .flagSelectable(true)
                                .prefixHidden(false)
                                .defaultRegion("FR")
//                                .autofillPrefix(true)
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
                                Button(action: {
                                    if !viewModel.isShowingWaitingView {
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
                                }) {
                                    Text("Send code")
                                        .font(.title3)
                                        .foregroundColor(Color("KentoBlueGrey"))
                                        .padding()
                                        .frame(minWidth: 0, maxWidth: 350)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                                        .alert(isPresented: $viewModel.isShowingAlert) {
                                            Alert(title: Text("Wrong phone number"), message: Text("The phone number that you entered is wrong"), dismissButton: .default(Text("Got it!")))
                                        }
                                }
                                
                                Button(action: {
                                    if !viewModel.isShowingWaitingView {
                                        viewModel.mainViewOpacity = 0.5
                                        viewModel.isShowingWaitingView = true
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

                                                    viewModel.mainViewOpacity = 1.0
                                                    viewModel.isShowingPhoneNumber = true
                                                    viewModel.isShowingCode = false
                                                    viewModel.isShowingEventInitView = true
                                                    viewModel.isShowingWaitingView = false
                                                }
                                            case .failure(_):
                                                viewModel.isShowingAlert = true
                                                viewModel.mainViewOpacity = 1.0
                                                viewModel.isShowingWaitingView = false
                                            }
                                        }
                                    }
                                }) {
                                    Text("Direct login [dev]")
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
                            
                        }
                        
                        
                        if viewModel.isShowingCode {
                            SecureField("Enter code", text: $viewModel.code)
                                .textContentType(.oneTimeCode)
                                .disableAutocorrection(true)
                                .foregroundColor(Color("KentoBeige"))
                                .autocapitalization(.none)
                                .multilineTextAlignment(.center)
                                .frame(width: 350, height: 40)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoBlueGrey")))
                            
                            Button(action: {
                                if !viewModel.isShowingWaitingView {
                                    viewModel.mainViewOpacity = 0.5
                                    viewModel.isShowingWaitingView = true
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
                                                
                                                viewModel.mainViewOpacity = 1.0
                                                viewModel.isShowingPhoneNumber = true
                                                viewModel.isShowingCode = false
                                                viewModel.isShowingEventInitView = true
                                                viewModel.isShowingWaitingView = false
                                            }
                                        case .failure(_):
                                            viewModel.isShowingAlert = true
                                            viewModel.mainViewOpacity = 1.0
                                            viewModel.isShowingWaitingView = false
                                        }
                                    }
                                }
                            }) {
                                Text("Verify code")
                                    .font(.title3)
                                    .foregroundColor(Color("KentoBlueGrey"))
                                    .padding()
                                    .frame(minWidth: 0, maxWidth: 350)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                                    .alert(isPresented: $viewModel.isShowingAlert) {
                                        Alert(title: Text("Wrong phone number"), message: Text("The phone number that you entered is wrong"), dismissButton: .default(Text("Got it!")))
                                    }
                            }
                        } // isShowingCode
                        
                        Spacer()
                        
                    } // VStack
                    .frame(maxHeight: .infinity, alignment: .center)
                    .opacity(viewModel.mainViewOpacity)
                    
                } // ZStack
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Color("KentoBeige").edgesIgnoringSafeArea(.all))
                
            } // NavigationView
            .environmentObject(loginInfo)
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .edgesIgnoringSafeArea([.top, .bottom])
            
        } // VStack
        .background(Color("KentoBlueGrey"))
        .onAppear() {
            UIApplication.shared.addTapGestureRecognizer()
            viewModel.isShowingEventInitView = (Date.now < loginInfo.expires)
        }
        
    } // some View
    
} // View

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
