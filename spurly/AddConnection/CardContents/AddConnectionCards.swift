//
//  AddConnectionCards.swift
//
//  Author: phaeton order llc
//  Target: spurly
//


import SwiftUI

struct AddConnectionCardView<Content: View>: View {
    let addConnectionCardTitle: String;
    let addConnectionCardIcon: Image;
    let addConnectionCardContent: Content
    private let cardBackgroundColor = Color.spurlyCardBackground; private let cardOpacity: Double = 0.92
    private let cardCornerRadius: CGFloat = 12.0; private let cardTitleFont = Font.custom("SF Pro Text", size: 18).weight(.bold)
    init(
        title: String,
        icon: Image,
        @ViewBuilder addConnectionCardContent: () -> Content
    ) {
        self.addConnectionCardTitle = title; self.addConnectionCardIcon = icon; self.addConnectionCardContent = addConnectionCardContent()
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 10) {
                Spacer()
                HStack(alignment: .center, spacing: 5) {
                    addConnectionCardIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.spurlyPrimaryText)
                    Text(addConnectionCardTitle).font(cardTitleFont).foregroundColor(.spurlyPrimaryText)

                }
                addConnectionCardContent.padding(.horizontal).opacity(1).padding(.vertical);
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

struct AddConnectionBasicsCardContent: View {
    @Binding var connectionName: String
    @Binding var connectionAge: Int?
    @Binding var connectionGender: String
    @Binding var connectionPronouns: String
    @Binding var connectionEthnicity: String
    @Binding var connectionShowAgeError: Bool
    @FocusState private var connectionFieldIsFocused: Bool
    let genderOptions = ["", "male", "female", "non-binary", "other"]
    let pronounOptions = ["", "he/him", "she/her", "they/them", "other"]
    let ethnicityOptions = ["", "american indian/alaska native", "asian", "black/african american", "hispanic/Latino", "aanhpi", "white", "middle eastern/north african", "multiracial", "other"]
    let ageOptions: [Int?] = [nil] + Array(18..<100).map { Optional($0) }
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("their name").font(labelFont).foregroundColor(.spurlySecondaryText)
            TextField("...", text: $connectionName)
                .textFieldStyle(CustomTextFieldStyle())
                .textContentType(.name)
                .focused($connectionFieldIsFocused)
                .limitInputLength(for: $connectionName)
                .onSubmit { connectionFieldIsFocused = false }
            Spacer().frame(height: 8)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("their age").font(labelFont).foregroundColor(.spurlySecondaryText)
                    CustomPickerStyle(title: "connectionAge", selection: $connectionAge, options: ageOptions, textMapping: { $0 != nil ? "\($0!)" : "" })
                        .opacity(1)
                        .frame(height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: (connectionShowAgeError && !(connectionAge ?? 0 >= 18)) ? 2 : 0)
                        )
                    if connectionShowAgeError && !(connectionAge ?? 0 >= 18) {
                        Text("connection must be 18")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .alignmentGuide(.top) { d in d[.top] }
                VStack(alignment: .leading, spacing: 8) {
                    Text("their gender").font(labelFont).foregroundColor(.spurlySecondaryText)
                    CustomPickerStyle(title: "connectionGender", selection: $connectionGender, options: genderOptions, textMapping: { $0 }).frame(height: 44)
                }.alignmentGuide(.top) { d in d[.top] }
            }
            Spacer().frame(height: 8)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("their pronouns").font(labelFont).foregroundColor(.spurlySecondaryText)
                    CustomPickerStyle(title: "connectionPronouns", selection: $connectionPronouns, options: pronounOptions, textMapping: { $0 }).frame(height: 44)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("their ethnicity").font(labelFont).foregroundColor(.spurlySecondaryText)
                    CustomPickerStyle(title: "connectionEthnicity", selection: $connectionEthnicity, options: ethnicityOptions, textMapping: { $0 }).frame(height: 44)
                }
            }
            Spacer().frame(height: 8)
        }
    }
}
struct AddConnectionBackgroundCardContent: View {
    @FocusState private var connectionIsCityFieldFocused: Bool;
    @FocusState private var connectionIsWorkFieldFocused: Bool;
    @FocusState private var connectionIsSchoolFieldFocused: Bool;
    @FocusState private var connectionIsHometownFieldFocused: Bool
    @Binding var connectionCurrentCity: String;
    @Binding var connectionJob: String;
    @Binding var connectionSchool: String;
    @Binding var connectionHometown: String
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("their city")
                .font(labelFont)
                .foregroundColor(.spurlySecondaryText); TextField(
                    "...",
                    text: $connectionCurrentCity
                )
                .textFieldStyle(CustomTextFieldStyle())
                .textContentType(.addressCity)
                .limitInputLength(for: $connectionCurrentCity); Spacer()
                .frame(height: 4)
                .focused($connectionIsCityFieldFocused).onSubmit { connectionIsCityFieldFocused = false }
            Text("their job")
                .font(labelFont)
                .foregroundColor(.spurlySecondaryText); TextField(
                    "...",
                    text: $connectionJob
                )
                .textFieldStyle(CustomTextFieldStyle())
                .textContentType(.jobTitle)
                .limitInputLength(for: $connectionJob); Spacer()
                .frame(height: 4)
                .focused($connectionIsWorkFieldFocused).onSubmit { connectionIsWorkFieldFocused = false }
            Text("their school")
                .font(labelFont)
                .foregroundColor(.spurlySecondaryText); TextField(
                    "...",
                    text: $connectionSchool
                )
                .textFieldStyle(CustomTextFieldStyle())
                .textContentType(.organizationName)
                .limitInputLength(for: $connectionSchool); Spacer()
                .frame(height: 4)
                .focused($connectionIsSchoolFieldFocused).onSubmit { connectionIsSchoolFieldFocused = false }
            Text("their hometown")
                .font(labelFont)
                .foregroundColor(.spurlySecondaryText); TextField(
                    "...",
                    text: $connectionHometown
                )
                .textFieldStyle(CustomTextFieldStyle())
                .textContentType(.addressCity)
                .limitInputLength(for: $connectionHometown)
                .focused($connectionIsHometownFieldFocused).onSubmit { connectionIsHometownFieldFocused = false }
        }
    }
}
struct AddConnectionAboutCardContent: View {
    @Binding var connectionGreenlights: [String];
    @Binding var connectionRedlights: [String];
    @Binding var allTopics: [String]
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TopicInputField(label: "their likes", topics: $connectionGreenlights, exclude: connectionRedlights, allTopics: allTopics, isGreen: true)
            TopicInputField(label: "their dislikes", topics: $connectionRedlights, exclude: connectionGreenlights, allTopics: allTopics, isGreen: false)
        }
    }
}
struct AddConnectionLifestyleCardContent: View {
    @Binding var connectionDrinking: String;
    @Binding var connectionDatingPlatform: String;
    @Binding var connectionLookingFor: String;
    @Binding var connectionKids: String
    let drinkingOptions = ["", "often", "socially", "rarely", "never"];
    let datingPlatformOptions = ["", "tinder", "bumble", "hinge", "raya", "plenty of fish", "match.com", "okcupid", "instagram", "feeld", "grindr", "other"]
    let lookingForOptions = ["", "casual", "short term", "long term", "marriage", "enm", "not sure"];
    let kidsOptions = ["", "want", "don't want", "have kids", "have kids, want more", "not sure"]
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) { Text("their drinking").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "connectionDrinking", selection: $connectionDrinking, options: drinkingOptions, textMapping: { $0 }).frame(height: 44) }
                VStack(alignment: .leading, spacing: 8) { Text("their dating app").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "connectionDatingPlatform", selection: $connectionDatingPlatform, options: datingPlatformOptions, textMapping: { $0 }).frame(height: 44) }
            }; Spacer().frame(height: 4)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) { Text("they're looking for").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "looking for", selection: $connectionLookingFor, options: lookingForOptions, textMapping: { $0 }).frame(height: 44) }
                VStack(alignment: .leading, spacing: 8) { Text("their kids").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "kids", selection: $connectionKids, options: kidsOptions, textMapping: { $0 }).frame(height: 44) }
            }; Spacer().frame(height: 8)
        }.padding(.top, 24).padding(.bottom, 20)
    }
}
