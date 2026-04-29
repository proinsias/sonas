import Foundation
@testable import Sonas
import XCTest

// MARK: - Stubs

final class MockDeviceAuthClient: TVDeviceAuthClientProtocol, Sendable {
    enum Behavior {
        case success(deviceCode: String, userCode: String, verificationURL: String)
        case tokenReady(accessToken: String)
        case pending
        case accessDenied
        case networkError
    }

    private let behavior: Behavior

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func requestDeviceCode() async throws -> TVDeviceCodeResponse {
        switch behavior {
        case let .success(deviceCode, userCode, verificationURL):
            return TVDeviceCodeResponse(
                deviceCode: deviceCode,
                userCode: userCode,
                verificationURL: verificationURL,
                expiresIn: 1800,
                interval: 5
            )
        case .networkError:
            throw URLError(.notConnectedToInternet)
        default:
            return TVDeviceCodeResponse(
                deviceCode: "dc-123",
                userCode: "XXXX-YYYY",
                verificationURL: "https://accounts.google.com/device",
                expiresIn: 1800,
                interval: 5
            )
        }
    }

    func pollForToken(deviceCode _: String) async throws -> TVDeviceTokenResponse {
        switch behavior {
        case let .tokenReady(accessToken):
            return TVDeviceTokenResponse(accessToken: accessToken, error: nil)
        case .pending:
            return TVDeviceTokenResponse(accessToken: nil, error: "authorization_pending")
        case .accessDenied:
            return TVDeviceTokenResponse(accessToken: nil, error: "access_denied")
        case .networkError:
            throw URLError(.notConnectedToInternet)
        default:
            return TVDeviceTokenResponse(accessToken: nil, error: "authorization_pending")
        }
    }
}

// MARK: - TVDeviceAuthFlowTests (T012a)

final class TVDeviceAuthFlowTests: XCTestCase {
    func test_given_idle_when_startFlowSucceeds_then_pendingUserAction() async {
        let client = MockDeviceAuthClient(
            behavior: .success(
                deviceCode: "dc-abc",
                userCode: "ABCD-1234",
                verificationURL: "https://accounts.google.com/device"
            )
        )
        let sut = TVDeviceAuthFlow(client: client)

        await sut.startFlow()

        let state = await sut.state
        if case let .pendingUserAction(userCode, verificationURL) = state {
            XCTAssertEqual(userCode, "ABCD-1234")
            XCTAssertEqual(verificationURL, "https://accounts.google.com/device")
        } else {
            XCTFail("Expected pendingUserAction, got \(state)")
        }
    }

    func test_given_pendingUserAction_when_pollCalled_then_stateIsPollingThenAuthorized() async {
        let client = MockDeviceAuthClient(behavior: .tokenReady(accessToken: "tok-xyz"))
        let sut = TVDeviceAuthFlow(client: client)
        await sut.startFlow()

        await sut.poll(deviceCode: "dc-abc")

        let state = await sut.state
        if case let .authorized(token) = state {
            XCTAssertEqual(token, "tok-xyz")
        } else {
            XCTFail("Expected authorized, got \(state)")
        }
    }

    func test_given_polling_when_tokenReceived_then_authorized() async {
        let client = MockDeviceAuthClient(behavior: .tokenReady(accessToken: "tok-live"))
        let sut = TVDeviceAuthFlow(client: client)
        await sut.startFlow()

        await sut.poll(deviceCode: "dc-123")

        let state = await sut.state
        XCTAssertEqual(state, .authorized(accessToken: "tok-live"))
    }

    func test_given_polling_when_accessDenied_then_failed() async {
        let client = MockDeviceAuthClient(behavior: .accessDenied)
        let sut = TVDeviceAuthFlow(client: client)
        await sut.startFlow()

        await sut.poll(deviceCode: "dc-123")

        let state = await sut.state
        if case let .failed(reason) = state {
            XCTAssertEqual(reason, "Access denied")
        } else {
            XCTFail("Expected failed, got \(state)")
        }
    }

    func test_given_polling_when_networkError_then_failed() async {
        let client = MockDeviceAuthClient(behavior: .networkError)
        let sut = TVDeviceAuthFlow(client: client)

        await sut.startFlow()

        let state = await sut.state
        if case .failed = state {
        } else {
            XCTFail("Expected failed on network error, got \(state)")
        }
    }

    func test_given_anyState_when_cancelCalled_then_idle() async {
        let client = MockDeviceAuthClient(
            behavior: .success(
                deviceCode: "dc-abc",
                userCode: "ABCD-1234",
                verificationURL: "https://accounts.google.com/device"
            )
        )
        let sut = TVDeviceAuthFlow(client: client)
        await sut.startFlow()

        await sut.cancel()

        let state = await sut.state
        XCTAssertEqual(state, .idle)
    }
}
