






import SwiftUI
import UIKit


struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

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


extension View {
     var intrinsicContentSize: CGSize {
        let controller = UIHostingController(rootView: self.fixedSize(horizontal: true, vertical: true))
        let size = controller.view.intrinsicContentSize
        let safeWidth = (size.width.isNaN || size.width < 0) ? 0 : size.width
        let safeHeight = (size.height.isNaN || size.height < 0) ? 0 : size.height
        return CGSize(width: safeWidth + 1 , height: safeHeight + 1)
    }
}


enum TopicFlowItem: Identifiable, Hashable {
    case chip(String); case inputField
    var id: String { switch self { case .chip(let t): return "chip-\(t)"; case .inputField: return "inputField" } }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: TopicFlowItem, rhs: TopicFlowItem) -> Bool { lhs.id == rhs.id }
}


struct ChipView: View {
    let topic: String; let isGreen: Bool; let deleteAction: () -> Void
    let topicChipGreen = Color(hex: "#D0FFBC")
    let topicChipRed = Color(hex: "#FF8488")
    var body: some View {
        HStack(spacing: 4) {
            Text(topic).lineLimit(1).font(.system(size: 14)).foregroundColor(Color.spurlyPrimaryText.opacity(0.9))
            Button(action: deleteAction) { Image(systemName: "xmark.circle.fill").foregroundColor(Color.spurlySecondaryText) }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .fixedSize()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isGreen
                      ? topicChipGreen.opacity(0.7)
                      : topicChipRed.opacity(0.7))
                .shadow(color: .black.opacity(0.5), radius: 4, x: 4, y: 4)
        )
    }
}


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


struct OnboardingResponse: Codable { var user_id: String; var token: String }


struct TopicInputField: View {
    var label: String; @Binding var topics: [String]; var exclude: [String]; var allTopics: [String]; var isGreen: Bool
    @State private var newTopic = ""; @FocusState private var isTextFieldFocused: Bool; @State private var flowLayoutHeight: CGFloat = 30
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular); let inputFont = Font.custom("SF Pro Text", size: 16).weight(.regular); let placeholderText = "add topic..."
    private var flowItems: [TopicFlowItem] {
        let chipItems = topics.map { TopicFlowItem.chip($0) }

        if topics.count < 5 {
            return chipItems + [TopicFlowItem.inputField]
        }
        else {
            return chipItems
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(labelFont).foregroundColor(.spurlySecondaryText)
            FlowLayout(flowItems, id: \.id, spacing: 8) { item in
                switch item {
                case .chip(let topic): ChipView(topic: topic, isGreen: isGreen) { if let index = topics.firstIndex(of: topic) { topics.remove(at: index) } }
                case .inputField:
                    TextField(placeholderText, text: $newTopic)
                        .font(inputFont).foregroundColor(.spurlyPrimaryText).textFieldStyle(.plain)
                        .padding(.horizontal, 10).padding(.vertical, 5).background(Color.spurlyTertiaryBackground)
                        .cornerRadius(16).frame(minWidth: 120, idealHeight: 30).fixedSize()
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4)
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
                    }
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

        guard !exclude.contains(topic) else {
            print("cannot add topic '\(topic)' to \(label) because it exists in the other list.")

             newTopic = ""
             DispatchQueue.main.async { isTextFieldFocused = false }
            return
        }
        if topics.count < 5 {
            topics.append(topic); newTopic = ""
            DispatchQueue.main.async { isTextFieldFocused = false }
        } else { print("topic limit reached for \(label). Cannot add '\(topic)'.") }
    }

    private func addCurrentTopic() {
        let trimmedTopic = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTopic.isEmpty && !topics.contains(trimmedTopic) {
            addTopic(trimmedTopic)
        } else {
            newTopic = ""
            DispatchQueue.main.async { isTextFieldFocused = false }
        }
    }
}


struct CustomTextFieldStyle: TextFieldStyle {

    let inputFont = Font.custom("SF Pro Text", size: 16).weight(.regular)
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.font(inputFont).foregroundColor(.spurlyPrimaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.spurlyTertiaryBackground)
            .cornerRadius(12).shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4)
     }
}
struct CustomPickerStyle<SelectionValue: Hashable>: View {
    let title: String; @Binding var selection: SelectionValue; let options: [SelectionValue]; let textMapping: (SelectionValue) -> String
    let inputFont = Font.custom("SF Pro Text", size: 16).weight(.regular); let placeholderColor = Color.spurlySecondaryText; let primaryColor = Color.spurlyPrimaryText
    let backgroundColor = Color.spurlyTertiaryBackground; let cornerRadius: CGFloat = 12; let paddingHorizontal: CGFloat = 12; let paddingVertical: CGFloat = 10; let minHeight: CGFloat
    init(title: String, selection: Binding<SelectionValue>, options: [SelectionValue], textMapping: @escaping (SelectionValue) -> String) {
        self.title = title; self._selection = selection; self.options = options; self.textMapping = textMapping
        let fontLineHeight = Font.system(size: 16).capHeight * 1.2; self.minHeight = fontLineHeight + (paddingVertical * 2)

    }
    var body: some View {
        Menu { Picker(title, selection: $selection) { ForEach(options, id: \.self) { option in Text(textMapping(option)).tag(option) } } } label: {
            HStack {
                Text(currentSelectionText).font(inputFont).foregroundColor(isPlaceholder ? placeholderColor : primaryColor)
                    .accessibilityHint(isPlaceholder ? "empty. tap to select \(title)." : "selected: \(currentSelectionText). tap to change.")
                Spacer(); Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundColor(.spurlySecondaryText)
            }
            .padding(.horizontal, paddingHorizontal).padding(.vertical, paddingVertical).frame(maxWidth: .infinity).frame(minHeight: minHeight)
            .background(backgroundColor).cornerRadius(cornerRadius).shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4)
        }
    }
    private var isPlaceholder: Bool { if let o = selection as? Optional<Any>, o == nil { return true }; if let s = selection as? String, s.isEmpty { return true }; return false }
    private var currentSelectionText: String { isPlaceholder ? "" : textMapping(selection) }
}


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
                                    Color.white.opacity(0.8),
                                    Color.spurlyHighlight.opacity(0.5)
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 6
                    )
            );
        }
    }
}


struct BasicsCardContent: View {
    @Binding var name: String
    @Binding var age: Int?
    @Binding var gender: String
    @Binding var pronouns: String
    @Binding var ethnicity: String
    @Binding var showAgeError: Bool
    @FocusState private var fieldIsFocused: Bool
    let genderOptions = ["", "male", "female", "non-binary", "other"]
    let pronounOptions = ["", "he/him", "she/her", "they/them", "other"]
    let ethnicityOptions = ["", "american indian/alaska native", "asian", "black/african american", "hispanic/Latino", "aanhpi", "white", "middle eastern/north african", "multiracial", "other"]
    let ageOptions: [Int?] = [nil] + Array(18..<100).map { Optional($0) }
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("name").font(labelFont).foregroundColor(.spurlySecondaryText)
            TextField("what should we call you", text: $name)
                .textFieldStyle(CustomTextFieldStyle())
                .textContentType(.name)
                .focused($fieldIsFocused)
                .onSubmit { fieldIsFocused = false }
            Spacer().frame(height: 8)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("age").font(labelFont).foregroundColor(.spurlySecondaryText)
                    CustomPickerStyle(title: "age", selection: $age, options: ageOptions, textMapping: { $0 != nil ? "\($0!)" : "" })
                        .opacity(1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: (showAgeError && !(age ?? 0 >= 18)) ? 2 : 0)
                        )
                    if showAgeError && !(age ?? 0 >= 18) {
                        Text("you must be at least 18")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("gender").font(labelFont).foregroundColor(.spurlySecondaryText)
                    CustomPickerStyle(title: "gender", selection: $gender, options: genderOptions, textMapping: { $0 })
                }
            }
            Spacer().frame(height: 8)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("pronouns").font(labelFont).foregroundColor(.spurlySecondaryText)
                    CustomPickerStyle(title: "pronouns", selection: $pronouns, options: pronounOptions, textMapping: { $0 })
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("ethnicity").font(labelFont).foregroundColor(.spurlySecondaryText)
                    CustomPickerStyle(title: "ethnicity", selection: $ethnicity, options: ethnicityOptions, textMapping: { $0 })
                }
            }
            Spacer().frame(height: 8)
        }
    }
}
struct BackgroundCardContent: View {
    @FocusState private var isCityFieldFocused: Bool; @FocusState private var isWorkFieldFocused: Bool; @FocusState private var isSchoolFieldFocused: Bool; @FocusState private var isHometownFieldFocused: Bool
    @Binding var currentCity: String; @Binding var job: String; @Binding var school: String; @Binding var hometown: String
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("current city").font(labelFont).foregroundColor(.spurlySecondaryText); TextField("where at", text: $currentCity).textFieldStyle(CustomTextFieldStyle()).textContentType(.addressCity); Spacer().frame(height: 4)
                .focused($isCityFieldFocused).onSubmit { isCityFieldFocused = false }
            Text("work").font(labelFont).foregroundColor(.spurlySecondaryText); TextField("what do", text: $job).textFieldStyle(CustomTextFieldStyle()).textContentType(.jobTitle); Spacer().frame(height: 4)
                .focused($isWorkFieldFocused).onSubmit { isWorkFieldFocused = false }
            Text("school").font(labelFont).foregroundColor(.spurlySecondaryText); TextField("how to", text: $school).textFieldStyle(CustomTextFieldStyle()).textContentType(.organizationName); Spacer().frame(height: 4)
                .focused($isSchoolFieldFocused).onSubmit { isSchoolFieldFocused = false }
            Text("hometown").font(labelFont).foregroundColor(.spurlySecondaryText); TextField("where from", text: $hometown).textFieldStyle(CustomTextFieldStyle()).textContentType(.addressCity)
                .focused($isHometownFieldFocused).onSubmit { isHometownFieldFocused = false }
        }
    }
}
struct AboutMeCardContent: View {
    @Binding var greenlightTopics: [String]; @Binding var redlightTopics: [String]; @Binding var allTopics: [String]
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TopicInputField(label: "likes", topics: $greenlightTopics, exclude: redlightTopics, allTopics: allTopics, isGreen: true)
            TopicInputField(label: "dislikes", topics: $redlightTopics, exclude: greenlightTopics, allTopics: allTopics, isGreen: false)
        }
    }
}
struct LifestyleCardContent: View {
    @Binding var drinking: String; @Binding var datingPlatform: String; @Binding var lookingFor: String; @Binding var kids: String
    let drinkingOptions = ["", "often", "socially", "rarely", "never"]; let datingPlatformOptions = ["", "tinder", "bumble", "hinge", "raya", "plenty of fish", "match.com", "okcupid", "instagram", "feeld", "grindr", "other"]
    let lookingForOptions = ["", "casual", "short term", "long term", "marriage", "enm", "not sure"]; let kidsOptions = ["", "want", "don't want", "have kids", "have kids, want more", "not sure"]
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) { Text("drinking").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "drinking habits", selection: $drinking, options: drinkingOptions, textMapping: { $0 }) }
                VStack(alignment: .leading, spacing: 8) { Text("dating app").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "dating platform", selection: $datingPlatform, options: datingPlatformOptions, textMapping: { $0 }) }
            }; Spacer().frame(height: 8)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) { Text("looking for").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "looking for", selection: $lookingFor, options: lookingForOptions, textMapping: { $0 }) }
                VStack(alignment: .leading, spacing: 8) { Text("kids").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "kids", selection: $kids, options: kidsOptions, textMapping: { $0 }) }
            }; Spacer().frame(height: 8)
        }.padding(.top, 24).padding(.bottom, 20)
    }
}


struct OnboardingView: View {
    @State private var currentCardIndex = 0; let totalCards = 4
    @State private var name = ""
    @State private var age: Int? = nil
    @State private var gender = ""
    @State private var pronouns = ""
    @State private var ethnicity = ""
    @State private var currentCity = ""
    @State private var hometown = ""
    @State private var school = ""
    @State private var job = ""
    @State private var drinking = ""
    @State private var datingPlatform = ""
    @State private var lookingFor = ""
    @State private var kids = ""
    @State private var greenlightTopics: [String] = []
    @State private var redlightTopics: [String] = []
    @State private var allTopics: [String] = presetTopics
    @State private var showAgeError = false
    var progress: Double { guard totalCards > 0 else { return 0.0 }; return Double(currentCardIndex + 1) / Double(totalCards) }
    var isAgeValidForSubmission: Bool { guard let currentAge = age else { return false }; return currentAge >= 18 }
    let cardWidthMultiplier: CGFloat = 0.8; let cardHeightMultiplier: CGFloat = 0.5
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width//.resizable().scaledToFit().frame(width: 30, height: 30).foregroundColor(.spurlyPrimaryBrand)


    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.spurlyPrimaryBackground.ignoresSafeArea().onTapGesture { hideKeyboard() }
                    Image("SpurlyBackgroundBrandColor").resizable().scaledToFit().frame(width: geometry.size.width * 1.7, height: geometry.size.height * 1.5).opacity(0.7).position(x: screenWidth / 2, y: screenHeight * 0.52)
                    VStack(spacing: 0) {
                        VStack { Image("SpurlyBannerBrandColor").resizable().scaledToFit().frame(height: 100).padding(.top, geometry.safeAreaInsets.top + 15); Spacer() }.frame(height: geometry.size.height * 0.1)
                        Spacer().frame(height: geometry.size.height * 0.01)
                        Text("less guessing. more connecting.").font(Font.custom("SF Pro Text", size: 16).weight(.bold)).foregroundColor(.spurlyPrimaryBrand).frame(maxWidth: .infinity, alignment: .center).padding(.horizontal).padding(.top, 35).shadow(color: .black.opacity(0.55), radius: 4, x: 4, y: 4)
                        Spacer().frame(height: geometry.size.height * 0.07)
                        VStack(alignment: .center, spacing: 0) {
                            ZStack {
                                Capsule()
                                    .fill(Color.spurlyTertiaryBackground)
                                    .frame(width: geometry.size.width * cardWidthMultiplier * 0.8, height: 6)
                                    .opacity(0.6)
                                    .shadow(color: .black.opacity(0.5), radius: 3, x: 3, y: 3)
                                ProgressView(value: progress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .spurlyHighlight))
                                    .frame(width: geometry.size.width * cardWidthMultiplier * 0.8)
                                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                                    .opacity(0.8)
                            }
                            .padding(.bottom, 1)
                            .padding(.horizontal)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("(\(currentCardIndex + 1)/4)")
                                    .font(Font.custom("SF Pro Text", size: 12).weight(.regular))
                                    .foregroundColor(.spurlyHighlight)
                                Spacer()
                                Button(action: {
                                    if isAgeValidForSubmission {
                                        currentCardIndex += 1
                                    } else {
                                        showAgeError = true
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Text("skip ahead")
                                        Image(systemName: "arrow.right")
                                    }
                                }
                                .font(Font.custom("SF Pro Text", size: 12).weight(.regular))
                                .foregroundColor(.spurlyHighlight)
                            }
                            .frame(width: geometry.size.width * cardWidthMultiplier * 0.8)

                        }
                        .padding(.bottom, 15)
                        Spacer().frame(height: geometry.size.height * 0.06)
                        Group {
                            switch currentCardIndex {
                                case 0:
                                    OnboardingCardView(title: "basics", icon: Image(systemName: "person.crop.circle.fill")) {
                                        BasicsCardContent(name: $name, age: $age, gender: $gender, pronouns: $pronouns, ethnicity: $ethnicity, showAgeError: $showAgeError)
                                    }
                                case 1:
                                    OnboardingCardView(title: "background", icon: Image(systemName: "globe.americas.fill")) {
                                        BackgroundCardContent(currentCity: $currentCity, job: $job, school: $school, hometown: $hometown)
                                    }
                                case 2:
                                    OnboardingCardView(title: "about me", icon: Image(systemName: "person.text.rectangle.fill")) {
                                        AboutMeCardContent(greenlightTopics: $greenlightTopics, redlightTopics: $redlightTopics, allTopics: $allTopics)
                                    }
                                case 3:
                                    OnboardingCardView(title: "lifestyle", icon: Image(systemName: "heart.text.clipboard.fill")) {
                                        LifestyleCardContent(drinking: $drinking, datingPlatform: $datingPlatform, lookingFor: $lookingFor, kids: $kids)
                                    }
                                default: EmptyView()
                            }
                        }
                        .frame(width: geometry.size.width * cardWidthMultiplier, height: geometry.size.height * cardHeightMultiplier)
                        .padding(.bottom, 4)
                        Spacer()
                        HStack {
                            if currentCardIndex > 0 {
                                Button {
                                    withAnimation { currentCardIndex -= 1 }
                                } label: {
                                    Image(systemName: "arrow.left")
                                        .padding()
                                        .background(Circle().fill(Color.spurlySecondaryButton.opacity(0.6)).shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4))
                                        .foregroundColor(.spurlyPrimaryBackground)
                                }
                            } else {
                                Button {} label: {
                                    Image(systemName: "arrow.left")
                                        .padding()
                                        .background(Circle().fill(Color.clear))
                                }.hidden()
                            }
                            Spacer()
                            let isNextButtonDisabled: Bool = {
                                if currentCardIndex == 0 {
                                    return !(age ?? 0 >= 18)
                                } else if currentCardIndex == totalCards - 1 {
                                    return !isAgeValidForSubmission
                                } else {
                                    return false
                                }
                            }()
                            Button {
                                if isNextButtonDisabled {
                                    // Show error if age is invalid
                                    showAgeError = true
                                } else {
                                    // Clear error and proceed
                                    showAgeError = false
                                    if currentCardIndex < totalCards - 1 {
                                        withAnimation { currentCardIndex += 1 }
                                    } else {
                                        submit()
                                    }
                                }
                            } label: {
                                Image(systemName: currentCardIndex < totalCards - 1 ? "arrow.right" : "checkmark")
                                    .padding()
                                    .background(
                                        Circle()
                                            .fill(
                                                isNextButtonDisabled ? Color.spurlySecondaryText
                                                    .opacity(
                                                        0.2
                                                    ) : Color.spurlySecondaryButton
                                                    .opacity(0.7)
                                            ).shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4)
                                    )
                                    .foregroundColor(Color.spurlyPrimaryBackground)
                            }
                        }
                        .padding(.top, 15)
                        .padding(.horizontal, geometry.size.width * (1.0 - cardWidthMultiplier) / 2.0)
                        .padding(.bottom, 2)
                        Spacer()
                        VStack(spacing: 2) {
                            Text("we care about protecting your data")
                                .font(.footnote)
                                .foregroundColor(.spurlySecondaryText)
                                .opacity(0.6)
                            Link(destination: URL(string: "https://example.com")!) {
                                Text("learn more here")
                                    .underline()
                                    .font(.footnote)
                                    .foregroundStyle(Color.spurlySecondaryText)
                                    .opacity(0.6)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }.padding(.bottom, geometry.safeAreaInsets.bottom + 5).navigationBarHidden(true).ignoresSafeArea(.keyboard, edges: .bottom)
                        Spacer()
                }
            }
        }
        .navigationViewStyle(.stack)
    }


    private func sendOnboardingData() {
        print("attempting to submit onboarding data...")
        guard isAgeValidForSubmission else { print("error: age is required and must be 18 or older for submission."); return }
        let payload = OnboardingPayload( name: name, age: age, gender: gender, pronouns: pronouns, ethnicity: ethnicity, currentCity: currentCity, hometown: hometown, school: school, job: job, drinking: drinking, datingPlatform: datingPlatform, lookingFor: lookingFor, kids: kids, greenlightTopics: greenlightTopics, redlightTopics: redlightTopics )
        guard let encodedPayload = try? JSONEncoder().encode(payload) else { print("error: Failed to encode payload."); return }
        print("Sending JSON payload:"); if let jsonString = String(data: encodedPayload, encoding: .utf8) { print(jsonString) } else { print("could not convert encoded payload data to UTF8 string for printing.") }
        guard let url = URL(string: "http://") else { print("error: Invalid URL."); return }
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.httpBody = encodedPayload
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error { print("network Error: \(error.localizedDescription)"); return }
                guard let httpResponse = response as? HTTPURLResponse else { print("error: Invalid HTTP response."); return }
                print("Received HTTP Status: \(httpResponse.statusCode)")
                guard (200...299).contains(httpResponse.statusCode) else { print("error: Server returned status code \(httpResponse.statusCode)"); if let responseData = data, let errorString = String(data: responseData, encoding: .utf8) { print("Server Error Response: \(errorString)") }; return }
                guard let responseData = data else { print("error: No data received."); return }
                do { let decodedResponse = try JSONDecoder().decode(OnboardingResponse.self, from: responseData); print("Success! User ID: \(decodedResponse.user_id), Token: \(decodedResponse.token)") /* Handle success */ } catch { print("error: Failed to decode response: \(error)") /* Handle error */ }
            }
        }.resume()
    }
    private func submit() { hideKeyboard(); guard isAgeValidForSubmission else { print("Submit cancelled: age validation failed."); return }; resolveTopicConflicts(); sendOnboardingData(); print("Submit action triggered!") }

    private func resolveTopicConflicts() {
        let greenSet = Set(greenlightTopics); let redSet = Set(redlightTopics)
        let conflictingTopics = greenSet.intersection(redSet)
        if !conflictingTopics.isEmpty {
            print("conflict detected for topics: \(conflictingTopics). Removing from both lists.")
            greenlightTopics.removeAll { conflictingTopics.contains($0) }
            redlightTopics.removeAll { conflictingTopics.contains($0) }
        }
    }
}


#if DEBUG
struct OnboardingViewPreviewWrapper: View {

    var body: some View { OnboardingView() }
}
struct OnboardingView_Previews: PreviewProvider { static var previews: some View { OnboardingView() } }
#endif

