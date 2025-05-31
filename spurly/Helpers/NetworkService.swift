//
//  NetworkService.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import Foundation

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case badURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(message: String, statusCode: Int)
    case noData
    case unauthorized
    case profileNotFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message, let statusCode):
            return "Server error (\(statusCode)): \(message)"
        case .noData:
            return "No data received"
        case .unauthorized:
            return "Unauthorized access"
        case .profileNotFound:
            return "User profile not found"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}


class NetworkService {
    static let shared = NetworkService()

    // Configuration
    let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // Add retry configuration
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 1.0

    private init() {

        //Configure bsaeURL
        baseURL = "myapi.com"

        // Configure session with timeout
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: configuration)

        // Configure decoder/encoder
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Public Methods

    // MARK: Firebase Auth Methods


    func createAccountWithFirebase(requestData: CreateAccountRequest, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        performRequest(
            endpoint: "auth/firebase/register",
            method: .post,
            body: requestData,
            completion: completion
        )
    }

    func loginWithFirebase(requestData: LoginRequest, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        performRequest(
            endpoint: "auth/firebase/login",
            method: .post,
            body: requestData,
            completion: completion
        )
    }

    // MARK: Legacy Email/Password Methods (Deprecated - Remove when migration complete)

    func createAccount(requestData: CreateAccountRequest, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        performRequest(
            endpoint: "auth/register",
            method: .post,
            body: requestData,
            completion: completion
        )
    }

    func login(requestData: LoginRequest, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        performRequest(
            endpoint: "auth/login",
            method: .post,
            body: requestData,
            completion: completion
        )
    }

    func getUserProfile(userId: String, token: String, completion: @escaping (Result<UserProfileResponse, NetworkError>) -> Void) {
        performRequest(
            endpoint: "profile/\(userId)",
            method: .get,
            authToken: token,
            completion: completion
        )
    }

    // Secure Google Sign-In (validates on backend)
    func signInWithGoogle(idToken: String, serverAuthCode: String?, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        let payload = GoogleTokenPayload(idToken: idToken, serverAuthCode: serverAuthCode)
        performRequest(
            endpoint: "auth/google",
            method: .post,
            body: payload,
            completion: completion
        )
    }

    // Secure Apple Sign-In (validates on backend)
    func signInWithApple(identityToken: String, authorizationCode: String, email: String?, fullName: PersonNameComponents?, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        let payload = AppleTokenPayload(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            email: email,
            fullName: fullName
        )
        performRequest(
            endpoint: "auth/apple",
            method: .post,
            body: payload,
            completion: completion
        )
    }

    // Secure Facebook Sign-In (validates on backend)
    func signInWithFacebook(accessToken: String, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        let payload = FacebookTokenPayload(accessToken: accessToken)
        performRequest(
            endpoint: "auth/facebook",
            method: .post,
            body: payload,
            completion: completion
        )
    }

    func submitOnboardingProfile(requestData: OnboardingRequest, authToken: String, completion: @escaping (Result<OnboardingResponse, NetworkError>) -> Void) {
        performRequest(
            endpoint: "onboarding",
            method: .post,
            body: requestData,
            authToken: authToken,
            completion: completion
        )
    }

    func refreshToken(refreshToken: String, completion: @escaping (Result<TokenRefreshResponse, NetworkError>) -> Void) {
        struct RefreshTokenRequest: Codable {
            let refreshToken: String

            enum CodingKeys: String, CodingKey {
                case refreshToken = "refresh_token"
            }
        }

        let request = RefreshTokenRequest(refreshToken: refreshToken)
        performRequest(
            endpoint: "auth/refresh",
            method: .post,
            body: request,
            completion: completion
        )
    }

    // MARK: - Private Methods

    private enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }

    // Overload for requests without body
    private func performRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        authToken: String? = nil,
        retryCount: Int = 0,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        performRequest(
            endpoint: endpoint,
            method: method,
            body: nil as Empty?,
            authToken: authToken,
            retryCount: retryCount,
            completion: completion
        )
    }

    private func performRequest<T: Decodable, U: Encodable>(
        endpoint: String,
        method: HTTPMethod,
        body: U? = nil,
        authToken: String? = nil,
        retryCount: Int = 0,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            completion(.failure(.badURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add auth token if provided
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode body if provided
        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                completion(.failure(.decodingError(error)))
                return
            }
        }

        // Debug logging
        #if DEBUG
        print("🌐 NetworkService: \(method.rawValue) \(url)")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Request body: \(bodyString)")
        }
        #endif

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.handleResponse(
                    data: data,
                    response: response,
                    error: error,
                    request: request,
                    retryCount: retryCount,
                    completion: completion
                )
            }
        }

        task.resume()
    }

    private func handleResponse<T: Decodable>(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        request: URLRequest,
        retryCount: Int,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // Check for network error
        if let error = error {
            #if DEBUG
            print("❌ Network error: \(error.localizedDescription)")
            #endif

            // Retry on network errors
            if retryCount < maxRetryAttempts {
                DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                    self?.retryRequest(request: request, retryCount: retryCount + 1, completion: completion)
                }
                return
            }

            completion(.failure(.requestFailed(error)))
            return
        }

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(.invalidResponse))
            return
        }

        #if DEBUG
        print("📥 Response status: \(httpResponse.statusCode)")
        if let data = data, let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response data: \(responseString)")
        }
        #endif

        // Handle different status codes
        switch httpResponse.statusCode {
        case 200...299:
            // Success
            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            // Special handling for profile endpoint with 204 No Content
            if httpResponse.statusCode == 204 || data.isEmpty {
                // For endpoints that return no content on success
                if T.self == UserProfileResponse.self {
                    let emptyResponse = UserProfileResponse(exists: true, userId: nil, name: nil, profileCompleted: nil)
                    completion(.success(emptyResponse as! T))
                    return
                }
            }

            do {
                let decodedResponse = try decoder.decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                #if DEBUG
                print("❌ Decoding error: \(error)")
                if let decodingError = error as? DecodingError {
                    logDecodingError(decodingError)
                }
                #endif
                completion(.failure(.decodingError(error)))
            }

        case 401:
            completion(.failure(.unauthorized))

        case 404:
            // Special handling for profile endpoint
            if request.url?.pathComponents.contains("profile") == true {
                completion(.failure(.profileNotFound))
            } else {
                let message = extractErrorMessage(from: data) ?? "Resource not found"
                completion(.failure(.serverError(message: message, statusCode: 404)))
            }

        case 500...599:
            // Server errors - retry if appropriate
            if retryCount < maxRetryAttempts {
                DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                    self?.retryRequest(request: request, retryCount: retryCount + 1, completion: completion)
                }
                return
            }

            let message = extractErrorMessage(from: data) ?? "Server error"
            completion(.failure(.serverError(message: message, statusCode: httpResponse.statusCode)))

        default:
            let message = extractErrorMessage(from: data) ?? "Request failed"
            completion(.failure(.serverError(message: message, statusCode: httpResponse.statusCode)))
        }
    }

    private func retryRequest<T: Decodable>(
        request: URLRequest,
        retryCount: Int,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        #if DEBUG
        print("🔄 Retrying request (attempt \(retryCount + 1)/\(maxRetryAttempts + 1))")
        #endif

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.handleResponse(
                    data: data,
                    response: response,
                    error: error,
                    request: request,
                    retryCount: retryCount,
                    completion: completion
                )
            }
        }

        task.resume()
    }

    private func extractErrorMessage(from data: Data?) -> String? {
        guard let data = data else { return nil }

        // Try to decode as APIErrorResponse
        if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
            return errorResponse.message
        }

        // Try to get raw string
        if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
            return errorString
        }

        return nil
    }

    private func logDecodingError(_ error: DecodingError) {
        switch error {
        case .typeMismatch(let type, let context):
            print("Type mismatch for type \(type): \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        case .valueNotFound(let type, let context):
            print("Value not found for type \(type): \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        case .keyNotFound(let key, let context):
            print("Key '\(key)' not found: \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        case .dataCorrupted(let context):
            print("Data corrupted: \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        @unknown default:
            print("Unknown decoding error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Async/Await Support

@available(iOS 13.0, *)
extension NetworkService {
    func createAccountWithFirebase(requestData: CreateAccountRequest) async throws -> AuthResponse {
        try await withCheckedThrowingContinuation { continuation in
            createAccountWithFirebase(requestData: requestData) { result in
                continuation.resume(with: result)
            }
        }
    }

    func loginWithFirebase(requestData: LoginRequest) async throws -> AuthResponse {
        try await withCheckedThrowingContinuation { continuation in
            loginWithFirebase(requestData: requestData) { result in
                continuation.resume(with: result)
            }
        }
    }

    func createAccount(requestData: CreateAccountRequest) async throws -> AuthResponse {
        try await withCheckedThrowingContinuation { continuation in
            createAccount(requestData: requestData) { result in
                continuation.resume(with: result)
            }
        }
    }

    func login(requestData: LoginRequest) async throws -> AuthResponse {
        try await withCheckedThrowingContinuation { continuation in
            login(requestData: requestData) { result in
                continuation.resume(with: result)
            }
        }
    }

    func getUserProfile(userId: String, token: String) async throws -> UserProfileResponse {
        try await withCheckedThrowingContinuation { continuation in
            getUserProfile(userId: userId, token: token) { result in
                continuation.resume(with: result)
            }
        }
    }

    func signInWithGoogle(idToken: String, serverAuthCode: String?) async throws -> AuthResponse {
        try await withCheckedThrowingContinuation { continuation in
            signInWithGoogle(idToken: idToken, serverAuthCode: serverAuthCode) { result in
                continuation.resume(with: result)
            }
        }
    }


    func signInWithApple(identityToken: String, authorizationCode: String, email: String?, fullName: PersonNameComponents?) async throws -> AuthResponse {
        try await withCheckedThrowingContinuation { continuation in
            signInWithApple(identityToken: identityToken, authorizationCode: authorizationCode, email: email, fullName: fullName) { result in
                continuation.resume(with: result)
            }
        }
    }

    func signInWithFacebook(accessToken: String) async throws -> AuthResponse {
        try await withCheckedThrowingContinuation { continuation in
            signInWithFacebook(accessToken: accessToken) { result in
                continuation.resume(with: result)
            }
        }
    }


    func submitOnboardingProfile(requestData: OnboardingRequest, authToken: String) async throws -> OnboardingResponse {
        try await withCheckedThrowingContinuation { continuation in
            submitOnboardingProfile(requestData: requestData, authToken: authToken) { result in
                continuation.resume(with: result)
            }
        }
    }
}
