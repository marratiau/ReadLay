//
//  Font.swift
//  ReadLay
//
//  Created by Mateo Arratia on 12/15/25.
//

import SwiftUI

extension Font {
    // MARK: - Nunito Font Family

    // Regular weights
    static func nunito(size: CGFloat) -> Font {
        return .custom("Nunito-Regular", size: size)
    }

    static func nunitoMedium(size: CGFloat) -> Font {
        return .custom("Nunito-Medium", size: size)
    }

    static func nunitoSemiBold(size: CGFloat) -> Font {
        return .custom("Nunito-SemiBold", size: size)
    }

    static func nunitoBold(size: CGFloat) -> Font {
        return .custom("Nunito-Bold", size: size)
    }

    static func nunitoExtraBold(size: CGFloat) -> Font {
        return .custom("Nunito-ExtraBold", size: size)
    }

    static func nunitoBlack(size: CGFloat) -> Font {
        return .custom("Nunito-Black", size: size)
    }

    static func nunitoLight(size: CGFloat) -> Font {
        return .custom("Nunito-Light", size: size)
    }

    static func nunitoExtraLight(size: CGFloat) -> Font {
        return .custom("Nunito-ExtraLight", size: size)
    }

    // MARK: - Convenience Methods with Weight Parameter

    static func nunito(size: CGFloat, weight: Font.Weight) -> Font {
        switch weight {
        case .ultraLight:
            return .nunitoExtraLight(size: size)
        case .light:
            return .nunitoLight(size: size)
        case .regular:
            return .nunito(size: size)
        case .medium:
            return .nunitoMedium(size: size)
        case .semibold:
            return .nunitoSemiBold(size: size)
        case .bold:
            return .nunitoBold(size: size)
        case .heavy:
            return .nunitoExtraBold(size: size)
        case .black:
            return .nunitoBlack(size: size)
        default:
            return .nunito(size: size)
        }
    }
}
