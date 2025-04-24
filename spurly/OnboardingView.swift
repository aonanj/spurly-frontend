//
//  OnboardingView.swift
//  spurly-frontend
//  (COMPLETE FILE - Consolidated Version: Wednesday, April 23, 2025)
//  Includes Lifestyle Card, Age Check on Card 1, Topic Conflict Resolution
//

import SwiftUI
import UIKit

// MARK: - Spurly Color Palette Definition
extension Color {
    static let spurlyPrimaryBrand = Color(hex: "#219EBC") // Blue Green
    static let spurlyPrimaryBackground = Color(hex: "#FFF8F6") // Soft Blush White
    static let spurlySecondaryBackground = Color(hex: "#FFEAE3") // Pastel Coral
    static let spurlyPrimaryText = Color(hex: "#1D3557") // Deep Navy Blue
    static let spurlySecondaryText = Color(hex: "#5A6777") // Slate Blue-Grey
    static let spurlyAccent = Color(hex: "#FF9F1C") // Vibrant Tangerine Orange
    static let spurlyBordersSeparators = Color(hex: "#F0C9C2") // Muted Coral Beige
    static let spurlyPrimaryButton = Color(hex: "#1A7C94") // Darker Blue Green
    static let spurlySecondaryButton = Color(hex: "#CED4DA") // Light Grey

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Height PreferenceKey
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - FlowLayout Helper
struct FlowLayout<Data: RandomAccessCollection, ID: Hashable, ItemView: View>: View {
    let data: Data
    let idKeyPath: KeyPath<Data.Element, ID>
    let viewForItem: (Data.Element) -> ItemView
    let spacing: CGFloat

    init(_ data: Data, id: KeyPath<Data.Element, ID>, spacing: CGFloat = 8, @ViewBuilder viewForItem: @escaping (Data.Element) -> ItemView) {
        self.data = data
        self.idKeyPath = id
        self.spacing = spacing
        self.viewForItem = viewForItem
    }

    var body: some View {
        GeometryReader { geometry in
            content(in: geometry)
                .anchorPreference(key: HeightPreferenceKey.self, value: .bounds) { anchor in
                    max(0, geometry[anchor].maxY.isNaN ? 0 : geometry[anchor].maxY)
                }
        }
    }

    private func content(in geometry: GeometryProxy) -> some View {
        var currentX: CGFloat = 0, currentY: CGFloat = 0, rowHeight: CGFloat = 0
        var itemPositions: [ID: CGPoint] = [:]
        let isGeometryValid = geometry.size.width.isFinite && geometry.size.width > 0 && geometry.size.height.isFinite

        if isGeometryValid {
            for item in data {
                let itemID = item[keyPath: idKeyPath]
                let itemView = viewForItem(item)
                let itemSize = itemView.fixedSize().intrinsicContentSize
                guard itemSize.width.isFinite && itemSize.width >= 0 && itemSize.height.isFinite && itemSize.height >= 0 else { continue }
                let safeSpacing = max(0, spacing)
                if currentX + itemSize.width + safeSpacing > geometry.size.width && currentX > 0 {
                    if !rowHeight.isFinite { rowHeight = 0 }
                    currentY += rowHeight + safeSpacing
                    currentX = 0; rowHeight = 0
                }
                guard currentX.isFinite, currentY.isFinite else { continue }
                itemPositions[itemID] = CGPoint(x: currentX, y: currentY)
                currentX += itemSize.width + safeSpacing
                rowHeight = max(rowHeight, itemSize.height)
                guard currentX.isFinite, rowHeight.isFinite else { break }
            }
        }

        return ZStack(alignment: .topLeading) {
            if isGeometryValid {
                ForEach(data, id: idKeyPath) { item in
                    let itemID = item[keyPath: idKeyPath]
                    if let position = itemPositions[itemID], position.x.isFinite, position.y.isFinite {
                        viewForItem(item)
                            .alignmentGuide(.leading) { _ in -position.x }
                            .alignmentGuide(.top) { _ in -position.y }
                    }
                }
            }
        }
    }
}

// MARK: - IntrinsicContentSize Helper
extension View {
     var intrinsicContentSize: CGSize {
        let controller = UIHostingController(rootView: self.fixedSize(horizontal: true, vertical: true))
        let size = controller.view.intrinsicContentSize
        let safeWidth = (size.width.isNaN || size.width < 0) ? 0 : size.width
        let safeHeight = (size.height.isNaN || size.height < 0) ? 0 : size.height
        return CGSize(width: safeWidth + 1 , height: safeHeight + 1)
    }
}

// MARK: - TopicFlowItem Enum
enum TopicFlowItem: Identifiable, Hashable {
    case chip(String); case inputField
    var id: String { switch self { case .chip(let t): return "chip-\(t)"; case .inputField: return "inputField" } }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: TopicFlowItem, rhs: TopicFlowItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - ChipView Helper
struct ChipView: View {
    let topic: String; let isGreen: Bool; let deleteAction: () -> Void
    var body: some View {
        HStack(spacing: 4) {
            Text(topic).lineLimit(1).font(.system(size: 14)).foregroundColor(Color.spurlyPrimaryText.opacity(0.9))
            Button(action: deleteAction) { Image(systemName: "xmark.circle.fill").foregroundColor(Color.spurlySecondaryText) }
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background((isGreen ? Color.green.opacity(0.2) : Color.red.opacity(0.2)))
        .cornerRadius(16).fixedSize()
    }
}

// MARK: - OnboardingPayload Struct
struct OnboardingPayload: Codable {
    var name: String?; var age: Int?; var gender: String?; var pronouns: String?; var school: String?
    var job: String?; var drinking: String?; var ethnicity: String?; var current_city: String?; var hometown: String?
    var greenlight_topics: [String]?; var redlight_topics: [String]?; var dating_platform: String?
    var looking_for: String?; var kids: String?
    enum CodingKeys: String, CodingKey { case name, age, gender, pronouns, school, job, drinking, ethnicity, current_city = "current_city", hometown, greenlight_topics = "greenlight_topics", redlight_topics = "redlight_topics", dating_platform = "dating_platform", looking_for = "looking_for", kids }
    init(name: String?, age: Int?, gender: String?, pronouns: String?, ethnicity: String?, currentCity: String?, hometown: String?, school: String?, job: String?, drinking: String?, datingPlatform: String?, lookingFor: String?, kids: String?, greenlightTopics: [String]?, redlightTopics: [String]?) {
        self.name = name?.isEmpty ?? true ? nil : name; self.age = age; self.gender = gender?.isEmpty ?? true ? nil : gender; self.pronouns = pronouns?.isEmpty ?? true ? nil : pronouns
        self.school = school?.isEmpty ?? true ? nil : school; self.job = job?.isEmpty ?? true ? nil : job; self.drinking = drinking?.isEmpty ?? true ? nil : drinking
        self.ethnicity = ethnicity?.isEmpty ?? true ? nil : ethnicity; self.current_city = currentCity?.isEmpty ?? true ? nil : currentCity; self.hometown = hometown?.isEmpty ?? true ? nil : hometown
        self.dating_platform = datingPlatform?.isEmpty ?? true ? nil : datingPlatform; self.looking_for = lookingFor?.isEmpty ?? true ? nil : lookingFor; self.kids = kids?.isEmpty ?? true ? nil : kids
        self.greenlight_topics = greenlightTopics?.isEmpty ?? true ? nil : greenlightTopics; self.redlight_topics = redlightTopics?.isEmpty ?? true ? nil : redlightTopics
    }
}

// MARK: - OnboardingResponse Struct
struct OnboardingResponse: Codable { var user_id: String; var token: String }

// MARK: - TopicInputField View
struct TopicInputField: View {
    var label: String; @Binding var topics: [String]; var exclude: [String]; var allTopics: [String]; var isGreen: Bool
    @State private var newTopic = ""; @FocusState private var isTextFieldFocused: Bool; @State private var flowLayoutHeight: CGFloat = 30
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular); let inputFont = Font.custom("SF Pro Text", size: 16).weight(.regular); let placeholderText = "Add topic..."
    private var flowItems: [TopicFlowItem] { topics.map { TopicFlowItem.chip($0) } + [TopicFlowItem.inputField] }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(labelFont).foregroundColor(.spurlySecondaryText)
            FlowLayout(flowItems, id: \.id, spacing: 8) { item in
                switch item {
                case .chip(let topic): ChipView(topic: topic, isGreen: isGreen) { if let index = topics.firstIndex(of: topic) { topics.remove(at: index) } }
                case .inputField:
                    TextField(placeholderText, text: $newTopic)
                        .font(inputFont).foregroundColor(.spurlyPrimaryText).textFieldStyle(.plain)
                        .padding(.horizontal, 10).padding(.vertical, 5).background(Color.spurlySecondaryBackground)
                        .cornerRadius(16).frame(minWidth: 120, idealHeight: 30).fixedSize()
                        .focused($isTextFieldFocused).onSubmit { addCurrentTopic() }
                }
            }
            .frame(minHeight: flowLayoutHeight)
            .onPreferenceChange(HeightPreferenceKey.self) { calculatedHeight in
                let newHeight = max(30, calculatedHeight + 5)
                if calculatedHeight.isFinite, calculatedHeight >= 0, abs(flowLayoutHeight - newHeight) > 1 { flowLayoutHeight = newHeight }
            }
            .animation(.default, value: flowLayoutHeight)

            if isTextFieldFocused && !newTopic.isEmpty {
                let filteredTopics = allTopics.filter { $0.lowercased().hasPrefix(newTopic.lowercased()) && !topics.contains($0) && !exclude.contains($0) }.prefix(2)
                if !filteredTopics.isEmpty {
                        // ForEach(Array(filteredTopics), id: \.self) { suggestion in
                        //    Text(suggestion).font(inputFont).foregroundColor(.spurlyPrimaryText).padding(.vertical, 6)
                        //        .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle()).onTapGesture { addTopic(suggestion) }
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filteredTopics), id: \.self) { suggestion in
                            Button(action: { addTopic(suggestion) }) {
                                Text(suggestion).font(inputFont).foregroundColor(.spurlyPrimaryText)
                                    .padding(.vertical, 10).padding(.horizontal, 12).frame(maxWidth: .infinity, alignment: .leading)

                            }.buttonStyle(.plain)
                            if(suggestion != filteredTopics.last) {
                                Divider().background(Color.spurlyBordersSeparators).padding(.horizontal, 10)
                            }
                        }
                    }//.background(Color.spurlySecondaryBackground)
                        .cornerRadius(8).padding(.top, 4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.spurlyBordersSeparators, lineWidth: 1))
                        .frame(maxHeight: min(CGFloat(filteredTopics.count), 2.0) * 44)
                        .clipped()
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
        }
    }

    private func addTopic(_ topic: String) {
        // Prevent adding if already in the other list (even if typed fully)
        guard !exclude.contains(topic) else {
            print("Cannot add topic '\(topic)' to \(label) because it exists in the other list.")
            // Optionally clear input and dismiss keyboard
             newTopic = ""
             DispatchQueue.main.async { isTextFieldFocused = false }
            return
        }
        if topics.count < 5 {
            topics.append(topic); newTopic = ""
            DispatchQueue.main.async { isTextFieldFocused = false }
        } else { print("Topic limit reached for \(label). Cannot add '\(topic)'.") }
    }

    private func addCurrentTopic() {
        let trimmedTopic = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTopic.isEmpty && !topics.contains(trimmedTopic) {
            addTopic(trimmedTopic) // addTopic now contains the check against the exclude list
        } else {
            newTopic = ""
            DispatchQueue.main.async { isTextFieldFocused = false }
        }
    }
}

// MARK: - Custom Styles
struct CustomTextFieldStyle: TextFieldStyle {
    let inputFont = Font.custom("SF Pro Text", size: 16).weight(.regular)
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.font(inputFont).foregroundColor(.spurlyPrimaryText)
            .padding(.horizontal, 12).padding(.vertical, 10).background(Color.spurlySecondaryBackground).cornerRadius(8)
            .opacity(1)
    }
}
struct CustomPickerStyle<SelectionValue: Hashable>: View {
    let title: String; @Binding var selection: SelectionValue; let options: [SelectionValue]; let textMapping: (SelectionValue) -> String
    let inputFont = Font.custom("SF Pro Text", size: 16).weight(.regular); let placeholderColor = Color.spurlySecondaryText; let primaryColor = Color.spurlyPrimaryText
    let backgroundColor = Color.spurlySecondaryBackground; let cornerRadius: CGFloat = 8; let paddingHorizontal: CGFloat = 12; let paddingVertical: CGFloat = 10; let minHeight: CGFloat
    init(title: String, selection: Binding<SelectionValue>, options: [SelectionValue], textMapping: @escaping (SelectionValue) -> String) {
        self.title = title; self._selection = selection; self.options = options; self.textMapping = textMapping
        let fontLineHeight = Font.system(size: 16).capHeight * 1.2; self.minHeight = fontLineHeight + (paddingVertical * 2)

    }
    var body: some View {
        Menu { Picker(title, selection: $selection) { ForEach(options, id: \.self) { option in Text(textMapping(option)).tag(option) } } } label: {
            HStack {
                Text(currentSelectionText).font(inputFont).foregroundColor(isPlaceholder ? placeholderColor : primaryColor)
                    .accessibilityHint(isPlaceholder ? "Empty. Tap to select \(title)." : "Selected: \(currentSelectionText). Tap to change.")
                Spacer(); Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundColor(.spurlySecondaryText)
            }
            .padding(.horizontal, paddingHorizontal).padding(.vertical, paddingVertical).frame(maxWidth: .infinity).frame(minHeight: minHeight)
            .background(backgroundColor).cornerRadius(cornerRadius).contentShape(Rectangle())
        }
    }
    private var isPlaceholder: Bool { if let o = selection as? Optional<Any>, o == nil { return true }; if let s = selection as? String, s.isEmpty { return true }; return false }
    private var currentSelectionText: String { isPlaceholder ? "" : textMapping(selection) }
}

// MARK: - Onboarding Card View
struct OnboardingCardView<Content: View>: View {
    let title: String; let content: Content
    private let cardBackgroundColor = Color(hex:"#F9FAFB"); private let cardOpacity: Double = 0.85
    private let cardCornerRadius: CGFloat = 12.0; private let cardTitleFont = Font.custom("SF Pro Text", size: 18).weight(.medium)
    init(title: String, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text(title).font(cardTitleFont).foregroundColor(.spurlyPrimaryText).frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal).padding(.top, 30).padding(.bottom, 10)
            content.padding(.horizontal); Spacer()
        }
        .frame(maxWidth: .infinity).background(cardBackgroundColor).opacity(cardOpacity).cornerRadius(cardCornerRadius)
        .overlay(RoundedRectangle(cornerRadius: cardCornerRadius).stroke(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.8), Color.spurlyBordersSeparators.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4))
    }
}

// MARK: - Card Content Views
struct BasicsCardContent: View {
    @Binding var name: String; @Binding var age: Int?; @Binding var gender: String; @Binding var pronouns: String; @Binding var ethnicity: String
    let genderOptions = ["", "Male", "Female", "Non-binary", "Other"]; let pronounOptions = ["", "He/Him", "She/Her", "They/Them", "Other"]
    let ethnicityOptions = ["", "American Indian/Alaska Native", "Asian", "Black/African American", "Hispanic/Latino", "AANHPI", "White", "Middle Eastern/North African", "Multiracial", "Other"]
    let ageOptions: [Int?] = [nil] + Array(18..<100).map { Optional($0) }; let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name").font(labelFont).foregroundColor(.spurlySecondaryText); TextField("What should we call you", text: $name).textFieldStyle(CustomTextFieldStyle()).textContentType(.name); Spacer().frame(height: 8)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) { Text("Age").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "Age", selection: $age, options: ageOptions, textMapping: { $0 != nil ? "\($0!)" : "" }) }
                VStack(alignment: .leading, spacing: 8) { Text("Gender").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "Gender", selection: $gender, options: genderOptions, textMapping: { $0 }) }
            }; Spacer().frame(height: 8)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) { Text("Pronouns").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "Pronouns", selection: $pronouns, options: pronounOptions, textMapping: { $0 }) }
                VStack(alignment: .leading, spacing: 8) { Text("Ethnicity").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "Ethnicity", selection: $ethnicity, options: ethnicityOptions, textMapping: { $0 }) }
            }; Spacer().frame(height: 8)
        }
    }
}
struct BackgroundCardContent: View {
    @Binding var currentCity: String; @Binding var job: String; @Binding var school: String; @Binding var hometown: String
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current City").font(labelFont).foregroundColor(.spurlySecondaryText); TextField("Where at", text: $currentCity).textFieldStyle(CustomTextFieldStyle()).textContentType(.addressCity); Spacer().frame(height: 4)
            Text("Work").font(labelFont).foregroundColor(.spurlySecondaryText); TextField("What do", text: $job).textFieldStyle(CustomTextFieldStyle()).textContentType(.jobTitle); Spacer().frame(height: 4)
            Text("School").font(labelFont).foregroundColor(.spurlySecondaryText); TextField("How to", text: $school).textFieldStyle(CustomTextFieldStyle()).textContentType(.organizationName); Spacer().frame(height: 4)
            Text("Hometown").font(labelFont).foregroundColor(.spurlySecondaryText); TextField("Where from", text: $hometown).textFieldStyle(CustomTextFieldStyle()).textContentType(.addressCity)
        }
    }
}
struct AboutMeCardContent: View {
    @Binding var greenlightTopics: [String]; @Binding var redlightTopics: [String]; @Binding var allTopics: [String]
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TopicInputField(label: "Green Light Topics", topics: $greenlightTopics, exclude: redlightTopics, allTopics: allTopics, isGreen: true)
            TopicInputField(label: "Red Light Topics", topics: $redlightTopics, exclude: greenlightTopics, allTopics: allTopics, isGreen: false)
        }
    }
}
struct LifestyleCardContent: View {
    @Binding var drinking: String; @Binding var datingPlatform: String; @Binding var lookingFor: String; @Binding var kids: String
    let drinkingOptions = ["", "Often", "Socially", "Rarely", "Never"]; let datingPlatformOptions = ["", "Tinder", "Bumble", "Hinge", "Raya", "Plenty of Fish", "Match.com", "OkCupid", "Instagram", "Feeld", "Grindr", "Other"]
    let lookingForOptions = ["", "Casual", "Short term", "Long Term", "Marriage", "ENM", "Not sure"]; let kidsOptions = ["", "Want", "Don't want", "Have kids", "Have kids, want more", "Not sure"]
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) { Text("Drinking").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "Drinking Habits", selection: $drinking, options: drinkingOptions, textMapping: { $0 }) }
                VStack(alignment: .leading, spacing: 8) { Text("Dating App").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "Dating Platform", selection: $datingPlatform, options: datingPlatformOptions, textMapping: { $0 }) }
            }; Spacer().frame(height: 8)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) { Text("Looking For").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "Looking For", selection: $lookingFor, options: lookingForOptions, textMapping: { $0 }) }
                VStack(alignment: .leading, spacing: 8) { Text("Kids").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "Kids", selection: $kids, options: kidsOptions, textMapping: { $0 }) }
            }; Spacer().frame(height: 8)
        }
    }
}

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @State private var currentCardIndex = 0; let totalCards = 4
    @State private var name = ""; @State private var age: Int? = nil; @State private var gender = ""; @State private var pronouns = ""; @State private var ethnicity = ""
    @State private var currentCity = ""; @State private var hometown = ""; @State private var school = ""; @State private var job = ""
    @State private var drinking = ""; @State private var datingPlatform = ""; @State private var lookingFor = ""; @State private var kids = ""
    @State private var greenlightTopics: [String] = []; @State private var redlightTopics: [String] = []; @State private var allTopics: [String] = presetTopics
    var progress: Double { guard totalCards > 0 else { return 0.0 }; return Double(currentCardIndex + 1) / Double(totalCards) }
    var isAgeValidForSubmission: Bool { guard let currentAge = age else { return false }; return currentAge >= 18 }
    let cardWidthMultiplier: CGFloat = 0.8; let cardHeightMultiplier: CGFloat = 0.55



    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.spurlyPrimaryBackground.ignoresSafeArea()
                    Image("SpurlyBackgroundBrandColor").resizable().scaledToFit().frame(width: geometry.size.width * 1.4, height: geometry.size.height * 1.4).opacity(0.5).position(x: geometry.size.width / 2, y: geometry.size.height * 0.575).allowsHitTesting(false)
                    VStack(spacing: 0) {
                        VStack { Image("SpurlyBannerBrandColor").resizable().scaledToFit().frame(height: 70).padding(.top, geometry.safeAreaInsets.top + 15); Spacer() }.frame(height: geometry.size.height * 0.1)
                        Text("help spurly help you in finding your words").font(Font.custom("SF Pro Text", size: 16).weight(.bold)).foregroundColor(.spurlyPrimaryBrand).frame(maxWidth: .infinity, alignment: .center).padding(.horizontal).padding(.top, 50)
                        Spacer(minLength: 60)
                        ProgressView(value: progress).progressViewStyle(LinearProgressViewStyle(tint: .spurlyPrimaryBrand)).frame(width: geometry.size.width * cardWidthMultiplier * 0.8).padding(.bottom, 20)
                        Group {
                            switch currentCardIndex {
                            case 0: OnboardingCardView(title: "Basics") { BasicsCardContent(name: $name, age: $age, gender: $gender, pronouns: $pronouns, ethnicity: $ethnicity) }
                            case 1: OnboardingCardView(title: "Background") { BackgroundCardContent(currentCity: $currentCity, job: $job, school: $school, hometown: $hometown) }
                            case 2: OnboardingCardView(title: "About Me") { AboutMeCardContent(greenlightTopics: $greenlightTopics, redlightTopics: $redlightTopics, allTopics: $allTopics) }
                            case 3: OnboardingCardView(title: "Lifestyle") { LifestyleCardContent(drinking: $drinking, datingPlatform: $datingPlatform, lookingFor: $lookingFor, kids: $kids) }
                            default: EmptyView()
                            }
                        }.frame(width: geometry.size.width * cardWidthMultiplier, height: geometry.size.height * cardHeightMultiplier).padding(.bottom, 30)
                        HStack {
                            if currentCardIndex > 0 { Button { withAnimation { currentCardIndex -= 1 } } label: { Image(systemName: "arrow.left").padding().background(Circle().fill(Color.spurlyPrimaryBrand.opacity(0.6))).foregroundColor(.spurlyPrimaryBackground) } } else { Button {} label: { Image(systemName: "arrow.left").padding().background(Circle().fill(Color.clear)) }.hidden() }
                            Spacer()
                            let isNextButtonDisabled: Bool = { if currentCardIndex == 0 { return !(age ?? 0 >= 18) } else if currentCardIndex == totalCards - 1 { return !isAgeValidForSubmission } else { return false } }()
                            Button { if currentCardIndex < totalCards - 1 { withAnimation { currentCardIndex += 1 } } else { submit() } } label: { Image(systemName: currentCardIndex < totalCards - 1 ? "arrow.right" : "checkmark").padding().background(Circle().fill(isNextButtonDisabled ? Color.spurlySecondaryText.opacity(0.3) : Color.spurlyPrimaryBrand.opacity(0.6))).foregroundColor(Color.spurlyPrimaryBackground) }.disabled(isNextButtonDisabled)
                        }.padding(.top, 15).padding(.horizontal, geometry.size.width * (1.0 - cardWidthMultiplier) / 2.0).padding(.bottom, geometry.safeAreaInsets.bottom + 10)
                    }.padding(.bottom, geometry.safeAreaInsets.bottom + 5)
                }
                //.onChange(of: greenlightTopics, false) { _ in resolveTopicConflicts() }
                //.onChange(of: redlightTopics, false) { _ in resolveTopicConflicts() }
                .navigationBarHidden(true).ignoresSafeArea(.keyboard).contentShape(Rectangle()).onTapGesture { hideKeyboard() }
            }
        }
        .navigationViewStyle(.stack)
    }


    private func sendOnboardingData() {
        print("Attempting to submit onboarding data...")
        guard isAgeValidForSubmission else { print("Error: Age is required and must be 18 or older for submission."); return }
        let payload = OnboardingPayload( name: name, age: age, gender: gender, pronouns: pronouns, ethnicity: ethnicity, currentCity: currentCity, hometown: hometown, school: school, job: job, drinking: drinking, datingPlatform: datingPlatform, lookingFor: lookingFor, kids: kids, greenlightTopics: greenlightTopics, redlightTopics: redlightTopics )
        guard let encodedPayload = try? JSONEncoder().encode(payload) else { print("Error: Failed to encode payload."); return }
        print("Sending JSON payload:"); if let jsonString = String(data: encodedPayload, encoding: .utf8) { print(jsonString) } else { print("Could not convert encoded payload data to UTF8 string for printing.") }
        guard let url = URL(string: "http://127.0.0.1:5000/onboarding") else { print("Error: Invalid URL"); return } // Replace with actual URL
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.httpBody = encodedPayload
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error { print("Network Error: \(error.localizedDescription)"); return } // Handle error
                guard let httpResponse = response as? HTTPURLResponse else { print("Error: Invalid HTTP response."); return } // Handle error
                print("Received HTTP Status: \(httpResponse.statusCode)")
                guard (200...299).contains(httpResponse.statusCode) else { print("Error: Server returned status code \(httpResponse.statusCode)"); if let responseData = data, let errorString = String(data: responseData, encoding: .utf8) { print("Server Error Response: \(errorString)") }; return } // Handle error
                guard let responseData = data else { print("Error: No data received."); return } // Handle error
                do { let decodedResponse = try JSONDecoder().decode(OnboardingResponse.self, from: responseData); print("Success! User ID: \(decodedResponse.user_id), Token: \(decodedResponse.token)") /* Handle success */ } catch { print("Error: Failed to decode response: \(error)") /* Handle error */ }
            }
        }.resume()
    }
    private func submit() { hideKeyboard(); guard isAgeValidForSubmission else { print("Submit cancelled: Age validation failed."); return }; resolveTopicConflicts(); sendOnboardingData(); print("Submit action triggered!") }

    private func resolveTopicConflicts() {
        let greenSet = Set(greenlightTopics); let redSet = Set(redlightTopics)
        let conflictingTopics = greenSet.intersection(redSet)
        if !conflictingTopics.isEmpty {
            print("Conflict detected for topics: \(conflictingTopics). Removing from both lists.")
            greenlightTopics.removeAll { conflictingTopics.contains($0) }
            redlightTopics.removeAll { conflictingTopics.contains($0) }
        }
    }
}

// MARK: - Keyboard Helper & Font Helper
#if canImport(UIKit)
import UIKit
extension View { func hideKeyboard() { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } }
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

// MARK: - Preview Provider
#if DEBUG
struct OnboardingViewPreviewWrapper: View {
    @State private var allTopicsPreview = ["Travel", "Foodie", "Hiking", "Movies", "Music", "Art", "Gaming", "Sports"]
    var body: some View { OnboardingView() }
}
struct OnboardingView_Previews: PreviewProvider { static var previews: some View { OnboardingView() } }
#endif

