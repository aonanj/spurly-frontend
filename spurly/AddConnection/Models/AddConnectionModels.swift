//
//  AddConnectionModels.swift
//  spurly
//
//  Created by Alex Osterlind on 5/7/25.
//

import SwiftUI

struct AddConnectionPayload: Codable {
    var connectionName: String?;
    var connectionAge: Int?;
    var connectionGender: String?;
    var connectionPronouns: String?;
    var connectionSchool: String?
    var connectionJob: String?;
    var connectionDrinking: String?;
    var connectionEthnicity: String?;
    var connectionCurrentCity: String?;
    var connectionHometown: String?
    var connectionGreenlights: [String]?;
    var connectionRedlights: [String]?;
    var connectionDatingPlatform: String?
    var connectionLookingFor: String?;
    var connectionKids: String?
    enum CodingKeys: String, CodingKey { case connectionName, connectionAge, connectionGender, connectionPronouns, connectionSchool, connectionJob, connectionDrinking, connectionEthnicity, connectionCurrentCity, connectionHometown, connectionGreenlights, connectionRedlights, connectionDatingPlatform, connectionLookingFor, connectionKids }
    init(connectionName: String?, connectionAge: Int?, connectionGender: String?, connectionPronouns: String?, connectionSchool: String?, connectionJob: String?, connectionDrinking: String?, connectionEthnicity: String?, connectionCurrentCity: String?, connectionHometown: String?, connectionGreenlights: [String]?, connectionRedlights: [String]?, connectionDatingPlatform: String?, connectionLookingFor: String?, connectionKids: String?) {
        self.connectionName = connectionName?.isEmpty ?? true ? nil : connectionName; self.connectionAge = connectionAge; self.connectionGender = connectionGender?.isEmpty ?? true ? nil : connectionGender; self.connectionPronouns = connectionPronouns?.isEmpty ?? true ? nil : connectionPronouns
        self.connectionSchool = connectionSchool?.isEmpty ?? true ? nil : connectionSchool; self.connectionJob = connectionJob?.isEmpty ?? true ? nil : connectionJob; self.connectionDrinking = connectionDrinking?.isEmpty ?? true ? nil : connectionDrinking
        self.connectionEthnicity = connectionEthnicity?.isEmpty ?? true ? nil : connectionEthnicity; self.connectionCurrentCity = connectionCurrentCity?.isEmpty ?? true ? nil : connectionCurrentCity; self.connectionHometown = connectionHometown?.isEmpty ?? true ? nil : connectionHometown
        self.connectionDatingPlatform = connectionDatingPlatform?.isEmpty ?? true ? nil : connectionDatingPlatform; self.connectionLookingFor = connectionLookingFor?.isEmpty ?? true ? nil : connectionLookingFor; self.connectionKids = connectionKids?.isEmpty ?? true ? nil : connectionKids
        self.connectionGreenlights = connectionGreenlights?.isEmpty ?? true ? nil : connectionGreenlights; self.connectionRedlights = connectionRedlights?.isEmpty ?? true ? nil : connectionRedlights
    }
}


struct AddConnectionResponse: Codable { var user_id: String; var token: String }
