//
//  OnboardingCard.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

struct OnboardingCardView<Content: View>: View {
    let title: String; let icon: Image; let content: Content
    private let cardBackgroundColor = Color.spurlyCardBackground; private let cardOpacity: Double = 0.92
    private let cardCornerRadius: CGFloat = 12.0; private let cardTitleFont = Font.custom("SF Pro Text", size: 18).weight(.bold)
    init(title: String, icon: Image, @ViewBuilder content: () -> Content) { self.title = title; self.icon = icon; self.content = content() }
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 10) {
                Spacer()
                HStack(alignment: .center, spacing: 5) {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.spurlyPrimaryText)
                    Text(title).font(cardTitleFont).foregroundColor(.spurlyPrimaryText)

                }
                content.padding(.horizontal).opacity(1).padding(.vertical);
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(cardBackgroundColor)
            .opacity(cardOpacity).cornerRadius(cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color.spurlyCardBackground.opacity(0.4),
                                    Color.spurlyHighlight.opacity(0.8)
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 12
                    )
                    .cornerRadius(cardCornerRadius)
            );
        }
    }
}
