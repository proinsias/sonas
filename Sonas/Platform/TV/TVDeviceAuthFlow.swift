import Foundation

// MARK: - TVDeviceAuthState (T012)

enum TVDeviceAuthState: Equatable {
    case idle
    case pendingUserAction(userCode: String, verificationURL: String)
    case polling
    case authorized(accessToken: String)
    case expired
    case failed(reason: String)
}

// MARK: - TVDeviceAuthClientProtocol

protocol TVDeviceAuthClientProtocol: Sendable {
    func requestDeviceCode() async throws -> TVDeviceCodeResponse
    func pollForToken(deviceCode: String) async throws -> TVDeviceTokenResponse
}

// MARK: - Response types

struct TVDeviceCodeResponse {
    let deviceCode: String
    let userCode: String
    let verificationURL: String
    let expiresIn: Int
    let interval: Int
}

struct TVDeviceTokenResponse {
    let accessToken: String?
    let error: String?
}

// MARK: - TVDeviceAuthFlow (T012)

actor TVDeviceAuthFlow {
    private(set) var state: TVDeviceAuthState = .idle
    private let client: TVDeviceAuthClientProtocol
    private var pollingTask: Task<Void, Never>?
    private var expiresAt: Date?

    init(client: TVDeviceAuthClientProtocol = GoogleDeviceAuthClient()) {
        self.client = client
    }

    func startFlow() async {
        pollingTask?.cancel()
        state = .idle

        do {
            let response = try await client.requestDeviceCode()
            expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))
            state = .pendingUserAction(userCode: response.userCode, verificationURL: response.verificationURL)
        } catch {
            state = .failed(reason: error.localizedDescription)
        }
    }

    func poll(deviceCode: String) async {
        guard case .pendingUserAction = state else { return }
        state = .polling

        guard let expiresAt else {
            state = .failed(reason: "No expiry set")
            return
        }

        while Date() < expiresAt {
            do {
                let response = try await client.pollForToken(deviceCode: deviceCode)
                if let token = response.accessToken {
                    state = .authorized(accessToken: token)
                    return
                }
                if let error = response.error, error == "access_denied" {
                    state = .failed(reason: "Access denied")
                    return
                }
                try await Task.sleep(nanoseconds: 5_000_000_000)
            } catch is CancellationError {
                return
            } catch {
                state = .failed(reason: error.localizedDescription)
                return
            }
        }

        state = .expired
    }

    func cancel() {
        pollingTask?.cancel()
        pollingTask = nil
        state = .idle
    }
}

// MARK: - GoogleDeviceAuthClient

final class GoogleDeviceAuthClient: TVDeviceAuthClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func requestDeviceCode() async throws -> TVDeviceCodeResponse {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              !clientID.isEmpty,
              let url = URL(string: "https://oauth2.googleapis.com/device/code")
        else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "client_id=\(clientID)&scope=https://www.googleapis.com/auth/calendar.readonly"
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await session.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let deviceCode = json["device_code"] as? String,
              let userCode = json["user_code"] as? String,
              let verificationURL = json["verification_url"] as? String,
              let expiresIn = json["expires_in"] as? Int,
              let interval = json["interval"] as? Int
        else {
            throw URLError(.cannotParseResponse)
        }

        return TVDeviceCodeResponse(
            deviceCode: deviceCode,
            userCode: userCode,
            verificationURL: verificationURL,
            expiresIn: expiresIn,
            interval: interval
        )
    }

    func pollForToken(deviceCode: String) async throws -> TVDeviceTokenResponse {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              !clientID.isEmpty,
              let url = URL(string: "https://oauth2.googleapis.com/token")
        else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let grantType = "urn:ietf:params:oauth:grant-type:device_code"
        let body = "client_id=\(clientID)&device_code=\(deviceCode)&grant_type=\(grantType)"
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await session.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        return TVDeviceTokenResponse(
            accessToken: json["access_token"] as? String,
            error: json["error"] as? String
        )
    }
}
