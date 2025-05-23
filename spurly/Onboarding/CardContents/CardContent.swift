//
//  CardContent.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

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
                .limitInputLength(for: $name)
                .onSubmit { fieldIsFocused = false }
            Spacer().frame(height: 8)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("age").font(labelFont).foregroundColor(.spurlySecondaryText)
                    CustomPickerStyle(title: "age", selection: $age, options: ageOptions, textMapping: { $0 != nil ? "\($0!)" : "" })
                        .opacity(1)
                        .frame(height: 44)
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
                .alignmentGuide(.top) { d in d[.top] }
                VStack(alignment: .leading, spacing: 8) {
                    Text("gender").font(labelFont).foregroundColor(.spurlySecondaryText)
                    CustomPickerStyle(title: "gender", selection: $gender, options: genderOptions, textMapping: { $0 }).frame(height: 44)
                }.alignmentGuide(.top) { d in d[.top] }
            }
            Spacer().frame(height: 8)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("pronouns").font(labelFont).foregroundColor(.spurlySecondaryText)
                    CustomPickerStyle(title: "pronouns", selection: $pronouns, options: pronounOptions, textMapping: { $0 }).frame(height: 44)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("ethnicity").font(labelFont).foregroundColor(.spurlySecondaryText)
                    CustomPickerStyle(title: "ethnicity", selection: $ethnicity, options: ethnicityOptions, textMapping: { $0 }).frame(height: 44)
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
            Text("current city")
                .font(labelFont)
                .foregroundColor(.spurlySecondaryText); TextField(
                    "where at",
                    text: $currentCity
                )
                .textFieldStyle(CustomTextFieldStyle())
                .textContentType(.addressCity)
                .limitInputLength(for: $currentCity); Spacer()
                .frame(height: 4)
                .focused($isCityFieldFocused).onSubmit { isCityFieldFocused = false }
            Text("work")
                .font(labelFont)
                .foregroundColor(.spurlySecondaryText); TextField(
                    "what do",
                    text: $job
                )
                .textFieldStyle(CustomTextFieldStyle())
                .textContentType(.jobTitle)
                .limitInputLength(for: $job); Spacer()
                .frame(height: 4)
                .focused($isWorkFieldFocused).onSubmit { isWorkFieldFocused = false }
            Text("school")
                .font(labelFont)
                .foregroundColor(.spurlySecondaryText); TextField(
                    "how to",
                    text: $school
                )
                .textFieldStyle(CustomTextFieldStyle())
                .textContentType(.organizationName)
                .limitInputLength(for: $school); Spacer()
                .frame(height: 4)
                .focused($isSchoolFieldFocused).onSubmit { isSchoolFieldFocused = false }
            Text("hometown")
                .font(labelFont)
                .foregroundColor(.spurlySecondaryText); TextField(
                    "where from",
                    text: $hometown
                )
                .textFieldStyle(CustomTextFieldStyle())
                .textContentType(.addressCity)
                .limitInputLength(for: $hometown)
                .focused($isHometownFieldFocused).onSubmit { isHometownFieldFocused = false }
        }
    }
}
struct AboutMeCardContent: View {
    @Binding var greenlights: [String]; @Binding var redlights: [String]; @Binding var allTopics: [String]
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TopicInputField(label: "likes", topics: $greenlights, exclude: redlights, allTopics: allTopics, isGreen: true)
            TopicInputField(label: "dislikes", topics: $redlights, exclude: greenlights, allTopics: allTopics, isGreen: false)
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
                VStack(alignment: .leading, spacing: 8) { Text("drinking").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "drinking habits", selection: $drinking, options: drinkingOptions, textMapping: { $0 }).frame(height: 44) }
                VStack(alignment: .leading, spacing: 8) { Text("dating app").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "dating platform", selection: $datingPlatform, options: datingPlatformOptions, textMapping: { $0 }).frame(height: 44) }
            }; Spacer().frame(height: 4)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) { Text("looking for").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "looking for", selection: $lookingFor, options: lookingForOptions, textMapping: { $0 }).frame(height: 44) }
                VStack(alignment: .leading, spacing: 8) { Text("kids").font(labelFont).foregroundColor(.spurlySecondaryText); CustomPickerStyle(title: "kids", selection: $kids, options: kidsOptions, textMapping: { $0 }).frame(height: 44) }
            }; Spacer().frame(height: 8)
        }.padding(.top, 24).padding(.bottom, 20)
    }
}
