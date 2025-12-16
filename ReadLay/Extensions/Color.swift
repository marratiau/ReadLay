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

    // ReadLay fresh blue/cream/brown palette
    static let readlayDarkBrown = Color(red: 102/255, green: 40/255, blue: 12/255)    // #66280C - Primary text, headings
    static let readlayTan = Color(red: 165/255, green: 102/255, blue: 58/255)         // #A5663A - Secondary text, accents
    static let readlayCream = Color(red: 233/255, green: 203/255, blue: 142/255)      // #E9CB8E - Light backgrounds, highlights
    static let readlayPaleMint = Color(red: 169/255, green: 216/255, blue: 222/255)   // #A9D8DE - Subtle backgrounds, cards
    static let readlayLightBlue = Color(red: 104/255, green: 174/255, blue: 201/255)  // #68AEC9 - Active states, links
    static let readlayMediumBlue = Color(red: 53/255, green: 118/255, blue: 174/255)  // #3576AE - Primary buttons, emphasis

    // Gradient book spine colors - cycles through palette-inspired colors
    static func readlaySpineColor(index: Int) -> Color {
        let colors: [Color] = [
            Color(red: 53/255, green: 118/255, blue: 174/255),    // Medium Blue
            Color(red: 80/255, green: 140/255, blue: 185/255),    // Between Medium and Light Blue
            Color(red: 104/255, green: 174/255, blue: 201/255),   // Light Blue
            Color(red: 136/255, green: 195/255, blue: 211/255),   // Between Light Blue and Pale Mint
            Color(red: 169/255, green: 216/255, blue: 222/255),   // Pale Mint
            Color(red: 201/255, green: 209/255, blue: 182/255),   // Between Pale Mint and Cream
            Color(red: 233/255, green: 203/255, blue: 142/255),   // Cream
            Color(red: 199/255, green: 152/255, blue: 100/255),   // Between Cream and Tan
            Color(red: 165/255, green: 102/255, blue: 58/255),    // Tan
            Color(red: 133/255, green: 71/255, blue: 35/255),     // Between Tan and Dark Brown
            Color(red: 102/255, green: 40/255, blue: 12/255),     // Dark Brown
            Color(red: 120/255, green: 65/255, blue: 50/255)      // Warm brown variation
        ]
        return colors[index % colors.count]
    }
}

struct ColorTheme{
    
    let accent = Color("AccentColor")
    let background = Color("BackgroundColor")
}
