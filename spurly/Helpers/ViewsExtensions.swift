//
//  ViewsExtensions.swift
//
//  Author: phaeton order llc
//  Target: spurly
//
import SwiftUI

extension View {
     var intrinsicContentSize: CGSize {
        let controller = UIHostingController(rootView: self.fixedSize(horizontal: true, vertical: true))
        let size = controller.view.intrinsicContentSize
        let safeWidth = (size.width.isNaN || size.width < 0) ? 0 : size.width
        let safeHeight = (size.height.isNaN || size.height < 0) ? 0 : size.height
        return CGSize(width: safeWidth + 1 , height: safeHeight + 1)
    }
}

#if canImport(UIKit)
import UIKit
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            self.hideKeyboard()
        }
    }
 }

extension Font {
    var uiFont: UIFont {
        let style: UIFont.TextStyle
        switch self { case .largeTitle: style = .largeTitle; case .title: style = .title1; case .title2: style = .title2; case .title3: style = .title3; case .headline: style = .headline; case .subheadline: style = .subheadline; case .body: style = .body; case .callout: style = .callout; case .caption: style = .caption1; case .caption2: style = .caption2; case .footnote: style = .footnote; default: style = .body }
        let size = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style).pointSize; return UIFont.systemFont(ofSize: size)
    }
    var capHeight: CGFloat { uiFont.capHeight }
}
#else
extension Font { var capHeight: CGFloat { return 16 * 0.7 } }
#endif

extension Color {

    static var tappablePrimaryBg: some View {
        primaryBg
            .hideKeyboardOnTap()
            .ignoresSafeArea()
    }
}

extension Image {
    private static let _spurlyBackgroundIcon = Image("SpurlyBackgroundBrandColor")
    private static let _spurlyBannerLogo = Image("SpurlyBannerBrandColor")
    private static let _menuIcon = Image("MenuIcon")
    private static let _addConnection = Image("AddConnectionIcon")
    private static let _cancelAddConnectionIcon = Image("CancelAddConnectionIcon")

    static var tappableBgIcon: some View {
        _spurlyBackgroundIcon
            .resizable()
            .scaledToFit()
            .opacity(0.7)
            .allowsHitTesting(false) // Make sure it doesn't block taps
            .hideKeyboardOnTap()
    }

    static var bannerLogo: some View {
        _spurlyBannerLogo
            .resizable()
            .scaledToFit()
    }

    static var menuIcon: some View {
        _menuIcon
            .imageScale(.large)
            .font(.title2)
            .foregroundColor(.primaryText)
            .shadow(
                color: .primaryText.opacity(0.5),
                radius: 5,
                x: 3,
                y: 3
            )
    }

    static var connectionIcon: some View {
        _addConnection
            .font(.title2)
            .foregroundColor(.primaryText)
            .shadow(
                color: .primaryText.opacity(0.5),
                radius: 5,
                x: 3,
                y: 3
            )
    }

    static var cancelAddConnectionIcon: some View {
        _cancelAddConnectionIcon
            .imageScale(.large)
            .font(.title2)
            .foregroundColor(.primaryText)
            .shadow(
                color: .primaryText.opacity(0.5),
                radius: 5,
                x: 3,
                y: 3
            )
    }
}

extension Text {
    private static let _bannerTagText = Text("less guessing. more connecting.")

    static var bannerTag: some View {
        _bannerTagText
            .font(Font.custom("SF Pro Text", size: 16)
            .weight(.bold))
            .foregroundColor(.brandColor)
            .shadow(color: .black.opacity(0.55), radius: 4, x: 4, y: 4)
    }
}


