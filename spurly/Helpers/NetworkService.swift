//
//  NetworkService.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import Foundation

enum NetworkError: Error {
    case badURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(message: String, statusCode: Int)
    case unknown
}

// NEW: Response struct for profile check
struct UserProfileResponse: Decodable {
    let exists: Bool // Or any other fields your backend returns
    // If the backend just returns 200 for exists and 404 for not exists,
    // this struct might not even need 'exists', we can infer from status code.
    // For this example, we'll assume a boolean field `exists`.
//  MARK:  Backend Response for Profile Check: If your backend returns a 200 OK with a body like {"exists": true} when the profile exists, the UserProfileResponse struct and decoding logic in NetworkService are appropriate. If a 200 OK means "exists" and 404 Not Found means "does not exist" (without a specific JSON body for the 200 case), you'll adjust NetworkService.getUserProfile to infer exists: true from the 200 status code directly. The current code handles 404 as a failure that AuthManager interprets as userProfileExists = false.
}

// MARK: Google token payload to send to middleware
struct GoogleTokenpayload: Codable {
    let idToken: String
    let serverAuthCode: String?
}


class NetworkService {
    static let shared = NetworkService()
    // Ensure this baseURL is correct and consistent with your other API calls.
    // It might be better to have a general API base URL and append paths.
    // MARK: API Endpoint for Profile Check: Ensure the URL https://your-backend-api.com/api/profile/\(userId) in NetworkService.swift matches your actual backend endpoint for checking profile existence. The HTTP method should be GET.
    private let baseApiURL = URL(string: "https://your-backend-api.com/api")! // Example base API URL

    private init() {}

    func createAccount(requestData: CreateAccountRequest, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        let endpoint = baseApiURL.appendingPathComponent("/auth/register")
        performRequest(url: endpoint, method: "POST", body: requestData, completion: completion)
    }

    func login(requestData: LoginRequest, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        let endpoint = baseApiURL.appendingPathComponent("/auth/login")
        performRequest(url: endpoint, method: "POST", body: requestData, completion: completion)
    }

    // NEW: Method to get user profile status
    func getUserProfile(userId: String, token: String, completion: @escaping (Result<UserProfileResponse, NetworkError>) -> Void) {
        // Adjust the endpoint path as per your backend API design
        guard let url = URL(string: "\(baseApiURL)/profile/\(userId)") else {
            completion(.failure(.badURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("NetworkService: Performing GET request to \(url) for user profile")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("NetworkService (Profile): Request failed - \(error.localizedDescription)")
                    completion(.failure(.requestFailed(error)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("NetworkService (Profile): Invalid response object")
                    completion(.failure(.invalidResponse))
                    return
                }

                print("NetworkService (Profile): Received response with status code: \(httpResponse.statusCode)")
                if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                     print("NetworkService (Profile): Response data: \(responseString)")
                }

                // Handle 404 as profile not existing
                if httpResponse.statusCode == 404 {
                    print("NetworkService (Profile): Profile not found (404).")
                    // You could complete with a specific "profile not found" error or a success with "exists: false"
                    // For this example, we let the AuthManager interpret the 404 from the error.
                    completion(.failure(.serverError(message: "Profile not found.", statusCode: httpResponse.statusCode)))
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    var errorMessage = "Server error occurred."
                    if let data = data, let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                        errorMessage = errorResponse.message
                        print("NetworkService (Profile): Server error message - \(errorMessage)")
                    } else if let data = data, let messageString = String(data: data, encoding: .utf8) {
                        errorMessage = messageString
                         print("NetworkService (Profile): Server error message string - \(errorMessage)")
                    }
                    completion(.failure(.serverError(message: errorMessage, statusCode: httpResponse.statusCode)))
                    return
                }

                guard let data = data else {
                    print("NetworkService (Profile): No data received")
                    completion(.failure(.invalidResponse))
                    return
                }

                do {
                    // If your backend simply returns 200 OK for an existing profile without a body,
                    // or with a body like {"exists": true}
                    // For a 200 OK indicating profile exists:
                    // If the backend sends `{"exists": true}` or similar:
                     let decodedResponse = try JSONDecoder().decode(UserProfileResponse.self, from: data)
                     completion(.success(decodedResponse))
                    // If 200 OK means exists and no specific body is expected for "exists: true":
                    // completion(.success(UserProfileResponse(exists: true)))
                } catch {
                    print("NetworkService (Profile): Decoding error - \(error.localizedDescription)")
                    if let decodingError = error as? DecodingError {
                        self.logDecodingError(decodingError) // Assuming logDecodingError is defined
                    }
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }

    func signInWithGoogleToken(idToken: String, serverAuthCode: String?, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        // Adjust the endpoint path as per your backend API design for Google Sign-In
        let endpoint = baseApiURL.appendingPathComponent("/auth/google")

        let payload = GoogleTokenpayload(idToken: idToken, serverAuthCode: serverAuthCode)

        performRequest(url: endpoint, method: "POST", body: payload, completion: completion)
    }

    private func performRequest<T: Decodable, U: Encodable>(
        url: URL,
        method: String,
        body: U?,
        authToken: String? = nil, // Optional token for general requests
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                completion(.failure(.decodingError(error)))
                return
            }
        }

        print("NetworkService: Performing \(method) request to \(url)")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("NetworkService: Request body: \(bodyString)")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("NetworkService: Request failed - \(error.localizedDescription)")
                    completion(.failure(.requestFailed(error)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("NetworkService: Invalid response object")
                    completion(.failure(.invalidResponse))
                    return
                }

                print("NetworkService: Received response with status code: \(httpResponse.statusCode)")
                if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                     print("NetworkService: Response data: \(responseString)")
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    var serverMsg = "Server error (\(httpResponse.statusCode))."
                    if let data = data, let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                        print("NetworkService: Server error message - \(errorResponse.message)")
                        serverMsg = errorResponse.message // Use the message from APIErrorResponse
                    } else if let data = data, let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                        serverMsg += " Details: \(errorString)"
                    }
                    completion(.failure(.serverError(message: serverMsg, statusCode: httpResponse.statusCode)))
                    return
                }

                guard let data = data else {
                    print("NetworkService: No data received")
                    completion(.failure(.invalidResponse))
                    return
                }

                do {
                    let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedResponse))
                } catch {
                    print("NetworkService: Decoding error - \(error.localizedDescription)")
                    if let decodingError = error as? DecodingError {
                        self.logDecodingError(decodingError)
                    }
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }

    private func logDecodingError(_ error: DecodingError) {
        switch error {
        case .typeMismatch(let key, let value):
            print("DecodingError: Type mismatch for key \(key), value \(value)")
        case .valueNotFound(let key, let value):
            print("DecodingError: Value not found for key \(key), value \(value)")
        case .keyNotFound(let key, let value):
            print("DecodingError: Key not found for key \(key), value \(value)")
        case .dataCorrupted(let key):
            print("DecodingError: Data corrupted for key \(key)")
        @unknown default:
            print("DecodingError: \(error.localizedDescription)")
        }
    }

    struct APIErrorResponse: Codable, Error {
        let message: String
        let errorCode: String?
        enum CodingKeys: String, CodingKey {
            case message, errorCode = "error_code"
        }
    }
}
