//
//  KeychainHelper.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import Foundation
import Security

class KeychainHelper {

    static let standard = KeychainHelper()
    private init() {} // Singleton

    func save(_ data: String, service: String, account: String) {
        guard let data = data.data(using: .utf8) else { return }
        save(data, service: service, account: account)
    }

    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data
        ] as CFDictionary

        // Delete any existing item
        SecItemDelete(query)

        // Add new item
        let status = SecItemAdd(query, nil)
        if status != errSecSuccess {
            print("KeychainHelper: Error saving data - \(status)")
        } else {
            print("KeychainHelper: Successfully saved data for service: \(service)")
        }
    }

    func read(service: String, account: String) -> String? {
        guard let data = readData(service: service, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func readData(service: String, account: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary

        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query, &dataTypeRef)

        if status == errSecSuccess {
            print("KeychainHelper: Successfully read data for service: \(service)")
            return dataTypeRef as? Data
        } else {
            if status != errSecItemNotFound { // Don't print error if simply not found
                 print("KeychainHelper: Error reading data - \(status)")
            }
            return nil
        }
    }

    func delete(service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary

        let status = SecItemDelete(query)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("KeychainHelper: Error deleting data - \(status)")
        } else {
             print("KeychainHelper: Successfully deleted data or data did not exist for service: \(service)")
        }
    }
}
