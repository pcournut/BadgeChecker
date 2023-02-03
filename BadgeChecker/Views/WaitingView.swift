//
//  WaitingView.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 17/01/2023.
//

import SwiftUI
import iActivityIndicator

struct WaitingView: View {
    var body: some View {
        VStack(spacing: 24) {

            HStack(spacing: 24) {
                iActivityIndicator(style: .arcs())
//                iActivityIndicator(style: .arcs(width: 8))
//                iActivityIndicator(style: .arcs(count: 10))
            }

//            HStack(spacing: 24) {
//                iActivityIndicator(style: .bars(opacityRange: 1...1))
//                iActivityIndicator(style: .bars(scaleRange: 1...1))
//                iActivityIndicator(style: .bars(count: 3))
//            }
//
//            HStack(spacing: 24) {
//                iActivityIndicator(style: .blinking())
//                iActivityIndicator(style: .blinking(count: 4))
//                iActivityIndicator(style: .blinking(count: 3, size: 50))
//            }
//
//            HStack(spacing: 24) {
//                iActivityIndicator() // The Default
//                iActivityIndicator(style: .classic(count: 13, width: 2))
//                iActivityIndicator(style: .classic(count: 3, width: 50))
//            }
//
//            HStack(spacing: 24) {
//                iActivityIndicator(style: .rotatingShapes())
//                iActivityIndicator(style: .rotatingShapes(count: 3, size: 30))
//                iActivityIndicator(style: .rotatingShapes(content: AnyView(Text("🎃").fixedSize())))
//            }
//
//            HStack(alignment: .center, spacing: 24) {
//                iActivityIndicator(style: .rowOfShapes())
//                iActivityIndicator(style: .rowOfShapes(count: 1, opacityRange: 0...1))
//                iActivityIndicator(style: .rowOfShapes(count: 3, scaleRange: 0.1...1))
//            }
        }
        .padding()
        .foregroundColor(Color("KentoRed"))
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        .background(Color("KentoBeige").edgesIgnoringSafeArea(.all))
        
    }
}
