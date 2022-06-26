//
//  Button.swift
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
