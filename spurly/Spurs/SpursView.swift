// SpursView.swift

import SwiftUI
import UIKit // For UIPasteboard

struct SpursView: View {
    @EnvironmentObject var spurManager: SpurManager
    @Environment(\.dismiss) var dismiss

    @State private var currentCardIndex: Int = 0
    @State private var editedSpurTexts: [String] = []

    @State private var showFeedback: Bool = false
    @State private var feedbackMessage: String = ""

    // Structure to hold icon names for navigation
    struct SpurNavigationIconSet {
        let activeName: String
        let inactiveName: String
    }

    // Define the icon sets based on the order of spurs.
    // This assumes the spurs from spurManager.spurs will correspond to this order
    // and their `iconCategoryIndex` will map to this array.
    private let navigationIconSets: [SpurNavigationIconSet] = [
        SpurNavigationIconSet(activeName: "navMainSpurActive", inactiveName: "navMainSpurInactive"),
        SpurNavigationIconSet(activeName: "navWarmSpurActive", inactiveName: "navWarmSpurInactive"),
        SpurNavigationIconSet(activeName: "navCoolSpurActive", inactiveName: "navCoolSpurInactive"),
        SpurNavigationIconSet(activeName: "navPlayfulSpurActive", inactiveName: "navPlayfulSpurInactive")
    ]

    private var totalCards: Int {
        spurManager.spurs.count
    }

    // Layout constants
    let cardWidthMultiplier: CGFloat = 0.8
    let cardHeightMultiplier: CGFloat = 0.42 // Adjusted for content
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.tappablePrimaryBg.ignoresSafeArea() //
                Image.tappableBgIcon // From ViewsExtensions.swift
                    .frame(width: screenWidth * 1.5, height: screenHeight * 1.5)
                    .position(x: screenWidth / 2, y: screenHeight * 0.46)

                if totalCards == 0 {
                    emptyStateView
                } else {
                    contentVStack(geometry: geometry)
                }
                feedbackOverlay
            }
            .onAppear(perform: setupView)
            .onChange(of: spurManager.spurs) { oldSpurs, newSpurs in
                 handleSpursChange(oldSpurs, newSpurs)
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(.keyboard)
            .onTapGesture { hideKeyboard() }
        }
    }

    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("no spurs to display or all processed.") // lowercase
                .font(.title2)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding()
            Button("close") { dismissView() }.padding().buttonStyle(.borderedProminent) // lowercase
            Spacer()
        }
    }

    private func contentVStack(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            headerSection(geometry: geometry)
            Spacer(minLength: screenHeight * 0.02)
            buildCardDisplay(geometry: geometry)
            Spacer(minLength: screenHeight * 0.03)
            iconNavigationSection(geometry: geometry)
            Spacer(minLength: screenHeight * 0.03)
            footerSection(geometry: geometry)
        }
    }

    private func headerSection(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                Spacer() // Balance for the close button
                Button(action: dismissView) {
                    Image(systemName: "xmark.circle.fill") // Changed icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.primaryText.opacity(0.7))
                }
                .padding(.trailing, 5)
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.55), radius: 4, x: 4, y: 4)
            }
            .padding(.horizontal)
            .padding(.top, geometry.safeAreaInsets.top > 40 ? geometry.safeAreaInsets.top - 50 : geometry.safeAreaInsets.top)
            Image.bannerLogo // From ViewsExtensions.swift
                .frame(height: screenHeight * 0.11)
            Text.bannerTag // From ViewsExtensions.swift, already lowercase
                .font(.caption)
        }
    }

    private func getCardIconName(for spur: Spur) -> String {
        if spur.iconCategoryIndex >= 0 && spur.iconCategoryIndex < navigationIconSets.count {
            return navigationIconSets[spur.iconCategoryIndex].activeName
        }
        return "lightbulb.fill" // Default fallback
    }

    @ViewBuilder
    private func buildCardDisplay(geometry: GeometryProxy) -> some View {
        Group {
            if currentCardIndex >= 0 && currentCardIndex < totalCards && currentCardIndex < editedSpurTexts.count {
                let spur = spurManager.spurs[currentCardIndex]
                let iconNameToUse = getCardIconName(for: spur)

                SpurDisplayCardView(
                    title: spur.variation, // Already lowercase from SpurManager
                    cardIconName: iconNameToUse,
                    spurText: $editedSpurTexts[currentCardIndex],
                    onCopy: {
                        UIPasteboard.general.string = editedSpurTexts[currentCardIndex]
                        showTemporaryFeedback("copied")
                    },
                    onSave: {
                        spurManager.saveSpur(spurId: spur.id, newText: editedSpurTexts[currentCardIndex])
                        showTemporaryFeedback("spur saved")
                    },
                    onDelete: {
                        spurManager.deleteSpur(spurId: spur.id)
                    }
                )
            } else if totalCards > 0 {
                Text("loading spur...").onAppear(perform: adjustCurrentIndex) // lowercase
            } else {
                EmptyView()
            }
        }
        .frame(width: geometry.size.width * cardWidthMultiplier, height: geometry.size.height * cardHeightMultiplier)
        .id(currentCardIndex)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity))
        )
        .animation(.easeInOut(duration: 0.3), value: currentCardIndex)
    }

    private func iconNavigationSection(geometry: GeometryProxy) -> some View {
        HStack(spacing: 20) { //
            ForEach(Array(spurManager.spurs.enumerated()), id: \.element.id) { (displayIndex, spur) in //
                if spur.iconCategoryIndex >= 0 && spur.iconCategoryIndex < navigationIconSets.count { //
                    let iconSet = navigationIconSets[spur.iconCategoryIndex] //
                    Button(action: { //
                        withAnimation { //
                            currentCardIndex = displayIndex //
                        }
                    }) {
                        VStack(spacing: 4) { // Wrap icon in VStack to add dot below
                            Image(currentCardIndex == displayIndex ? iconSet.activeName : iconSet.inactiveName) //
                                .resizable() //
                                .scaledToFit() //
                                .frame(width: 30, height: 30) //
                                .foregroundColor(.primaryText.opacity(0.7)) //
                                .shadow(color: .black.opacity(0.55), radius: 4, x: 4, y: 4) //

                            // Add a dot indicator if this is the active icon
                            if currentCardIndex == displayIndex {
                                Circle()
                                    .fill(Color.primaryText.opacity(0.7)) // Or your desired dot color e.g. Color.brandColor
                                    .frame(width: 7, height: 7)
                                    .shadow(color: .black.opacity(0.55), radius: 5, x: 4, y: 4)
                                    .transition(.opacity.combined(with: .scale)) // Animation for dot
                            } else {
                                // Placeholder to maintain layout consistency if needed, otherwise dot just won't appear
                                Circle().fill(Color.clear).frame(width: 7, height: 7)
                            }
                        }
                    }
                }
                if (displayIndex < spurManager.spurs.count - 1) { //
                    Image(systemName: "ellipsis") //
                        .resizable() //
                        .scaledToFit() //
                        .frame(width: 14, height: 14) //
                        .padding(.bottom, 10)
                        .foregroundColor(.primaryText.opacity(0.5)) //
                        .shadow(color: .black.opacity(0.55), radius: 4, x: 4, y: 4) //
                }
            }
        }
        .frame(maxWidth: .infinity) //
        .animation(.easeInOut(duration: 0.2), value: currentCardIndex) // Animation for the whole HStack when index changes
    }

    private func footerSection(geometry: GeometryProxy) -> some View {
        VStack(alignment: .center) {
            (
                Text("pick a spur ") +
                Text(Image(systemName: "mail.stack.fill")) +
                Text(" to edit ") +
                Text(Image(systemName: "pencil")) +
                Text(" and copy ") +
                Text(Image(systemName: "document.on.document.fill")) +
                Text("\nsave ") +
                Text(Image(systemName: "hand.thumbsup.fill")) +
                Text(" what you like, delete ") +
                Text(Image(systemName: "hand.thumbsdown.fill")) +
                Text(" what you don't")
            )
            .font(.footnote)
            .foregroundColor(.secondaryText.opacity(0.6)) // lowercase
        }
        .frame(maxWidth: .infinity)
        //.padding(.bottom, (geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 0))
    }

    private var feedbackOverlay: some View {
        Group {
            if showFeedback {
                Text(feedbackMessage) // feedbackMessage set to lowercase in showTemporaryFeedback
                    .padding().background(Color.black.opacity(0.7))
                    .foregroundColor(.white).cornerRadius(10)
                    .transition(.opacity.combined(with: .scale)).zIndex(1)
            }
        }
    }

    private func setupView() {
        initializeEditedTexts()
        adjustCurrentIndex()
    }

    private func handleSpursChange(_ oldSpurs: [Spur], _ newSpurs: [Spur]) {
        print("Spurs changed. Old count: \(oldSpurs.count), New count: \(newSpurs.count)")
        initializeEditedTexts()
        adjustCurrentIndex()
        if newSpurs.isEmpty && oldSpurs.count > 0 {
            dismissView()
        }
    }

    private func initializeEditedTexts() {
        editedSpurTexts = spurManager.spurs.map { $0.text }
        print("Initialized/Updated editedSpurTexts. Count: \(editedSpurTexts.count)")
    }

    private func adjustCurrentIndex() {
        let newTotalCards = spurManager.spurs.count
        if newTotalCards == 0 {
            if currentCardIndex != 0 { currentCardIndex = 0 }
        } else if currentCardIndex >= newTotalCards {
            currentCardIndex = max(0, newTotalCards - 1)
        }
        print("Adjusted currentCardIndex to: \(currentCardIndex), totalCards: \(newTotalCards)")
    }

    private func dismissView() {
        spurManager.clearAllSpursAndDismiss()
    }

    private func showTemporaryFeedback(_ message: String) {
        feedbackMessage = message.lowercased() // Ensure feedback is lowercase
        withAnimation(.easeInOut) { showFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut) { showFeedback = false }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview
#if DEBUG
struct SpursView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSpurManager = SpurManager()
        let mockConnectionManager = ConnectionManager()
        mockConnectionManager
            .setActiveConnection(
                connectionId: "conn123",
                connectionName: "Sarah"
            )
        // Assuming BackendSpurData is defined globally or imported
        let mockBackendSpurs = [
            BackendSpurData(
                id: "id1",
                variation: "main spur".lowercased(),
                text: "This is the main spur. It's a general suggestion for what you could say next. Feel free to edit it!"
            ),
            BackendSpurData(
                id: "id2",
                variation: "warm spur".lowercased(),
                text: "Here's a warmer, friendlier version for you! Try this if you want to be more inviting."
            ),
            BackendSpurData(id: "id3", variation: "cool spur", text: "A cooler, more direct approach might be this one. Good for getting straight to the point."),
            BackendSpurData(id: "id4", variation: "playful spur", text: "Or, if you're feeling playful, try this lighthearted option!")
        ]
        mockSpurManager.loadSpurs(backendSpurData: mockBackendSpurs)

        return SpursView()
            .environmentObject(mockSpurManager)
            .environmentObject(mockConnectionManager)
    }
}
#endif
