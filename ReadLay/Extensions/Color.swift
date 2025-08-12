//
//  Color.swift
//  ReadLay
//
//  Created by Mateo Arratia on 8/11/25.
//

import Foundation
import SwiftUI

extension Color{
    static let theme = ColorTheme()
    
    // Goodreads-inspired color palette
    static let goodreadsBeige = Color(red: 0.96, green: 0.94, blue: 0.89)
    static let goodreadsWarm = Color(red: 0.93, green: 0.89, blue: 0.82)
    static let goodreadsBrown = Color(red: 0.55, green: 0.45, blue: 0.35)
    static let goodreadsAccent = Color(red: 0.65, green: 0.52, blue: 0.39)
    static let shelfWood = Color(red: 0.76, green: 0.65, blue: 0.52)
    static let shelfShadow = Color(red: 0.45, green: 0.35, blue: 0.25)
}

struct ColorTheme{
    
    let accent = Color("AccentColor")
    let background = Color("BackgroundColor")
}
