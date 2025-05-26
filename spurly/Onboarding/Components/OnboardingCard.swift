//
//  OnboardingCard.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

struct OnboardingCardView<Content: View>: View {

    private var title = "about you"

    let content: Content
    private let cardBackgroundColor = Color.cardBg; private let cardOpacity: Double = 0.81
    private let cardCornerRadius: CGFloat = 12.0; private let cardTitleFont = Font.custom("SF Pro Text", size: 20).weight(.heavy)
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 5) {
                Spacer()
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.primaryText)
                    Text(title)
                        .font(cardTitleFont)
                        .foregroundColor(Color.primaryText)

                }
                .padding(.top, 15)
                .padding(.bottom, 10)
                content.padding(.horizontal, 10).padding(.vertical, 5);
                Spacer()
            }
            .background(cardBackgroundColor)
            .opacity(cardOpacity).cornerRadius(cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color.cardBg.opacity(0.4),
                                    Color.highlight.opacity(0.85)
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 12
                    )
                    .cornerRadius(cardCornerRadius)
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard)
    }
}
