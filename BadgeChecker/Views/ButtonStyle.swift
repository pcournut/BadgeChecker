//
//  ButtonStyle.swift
//  BadgeChecker
//
//  Created by Pierre Cournut on 23/04/2022.
//

import Foundation

public protocol ButtonStyle {
  associatedtype Body: View

  func makeBody(configuration: Self.Configuration) -> Self.Body

  typealias Configuration = ButtonStyleConfiguration
}

public struct ButtonStyleConfiguration {
  public let label: ButtonStyleConfiguration.Label
  public let isPressed: Bool
}

struct RoundedRectangleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button(action: {}, label: {
      HStack {
        Spacer()
        configuration.label.foregroundColor(.black)
        Spacer()
      }
    })
    // 👇🏻 makes all taps go to the original button
    .allowsHitTesting(false)
    .padding()
    .background(Color.yellow.cornerRadius(8))
    .scaleEffect(configuration.isPressed ? 0.95 : 1)
  }
}
