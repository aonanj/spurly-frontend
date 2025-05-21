//
//  SpurManager.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI
import Combine

class SpurManager: ObservableObject {
    @Published var spurs: [Spur] = []
    @Published var showSpursView: Bool = false

    func loadSpurs(backendSpurData: [BackendSpurData]) {
        DispatchQueue.main.async {
            // Assign iconCategoryIndex based on the original order from the backend
            // This assumes the first spur data is "Main", second is "Warm", etc.
            self.spurs = backendSpurData.enumerated().map { (index, data) -> Spur in
                Spur(id: data.id,
                     variation: data.variation.capitalized,
                     text: data.text,
                     iconCategoryIndex: index) // Use the original index as the category index
            }.prefix(4).map{$0} // Ensure we only take up to 4 spurs

            if !self.spurs.isEmpty {
                self.showSpursView = true
                print("SpurManager: Loaded \(self.spurs.count) spurs. Showing SpursView.")
            } else {
                print("SpurManager: No spurs to load.")
                self.showSpursView = false
            }
        }
    }

    func saveSpur(spurId: String, newText: String) {
        DispatchQueue.main.async {
            if let index = self.spurs.firstIndex(where: { $0.id == spurId }) {
                self.spurs[index].text = newText
                print("SpurManager: Saved spur ID \(spurId)")
            }
        }
    }

    func deleteSpur(spurId: String) {
        DispatchQueue.main.async {
            self.spurs.removeAll { $0.id == spurId }
            print("SpurManager: Deleted spur ID \(spurId). Remaining: \(self.spurs.count)")
            if self.spurs.isEmpty {
                print("SpurManager: All spurs deleted. Hiding SpursView.")
                self.showSpursView = false
            }
        }
    }

    func clearAllSpursAndDismiss() {
        DispatchQueue.main.async {
            self.spurs = []
            self.showSpursView = false
            print("SpurManager: All spurs cleared and view dismissed.")
        }
    }
}
