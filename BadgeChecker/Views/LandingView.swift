//
//  LandingView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import SwiftUI
import Foundation

struct LandingView: View {
    
    init() {
            //Use this if NavigationBarTitle is with Large Font
            UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color("KentoRed"))]

            //Use this if NavigationBarTitle is with displayMode = .inline
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color("KentoRed"))]
        }
    
    var body: some View {
            
        VStack {

            Image("Kento - text")
                .resizable()
                .frame(width: 100.0, height: 100.0, alignment: .center)
            
            NavigationView {
                ZStack {
                    VStack(spacing: 30) {
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign up")
                                .font(.title3)
                                .foregroundColor(Color("KentoBlueGrey"))
                                .padding()
                                .frame(minWidth: 0, maxWidth: 350)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                        }
                        
                        Image("Kento - sun")
                            .resizable()
                            .frame(width: 150.0, height: 150.0, alignment: .top)
                        
                        NavigationLink(destination: LoginView()) {
                            Text("Login")
                                .font(.title3)
                                .foregroundColor(Color("KentoBlueGrey"))
                                .padding()
                                .frame(minWidth: 0, maxWidth: 350)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color("KentoRed")))
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Color("KentoBeige").edgesIgnoringSafeArea(.all))
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
            
        }
        .background(Color("KentoBlueGrey"))

    }
}
