import os.log
import Foundation
import Combine

import SwiftRex

// MARK: - ACTIONS
//sourcery: Prism
public enum MembersAction {
    case register([String])
    case stateChanged(MembersState)
}

// MARK: - STATE
public struct MembersState: Codable, Equatable {
    public let members: [String: MemberInfo]?
    
    public init(members: [String: MemberInfo]?) {
        self.members = members
    }
}

public struct MemberInfo: Equatable, Hashable {
    public let beaconid: UInt16
    public let email: String
    public let givenName: String
    public let familyName: String
    public let displayName: String
    public let tracking: Bool?

    public init(
        beaconid: UInt16 = UInt16.random(in: UInt16.min...UInt16.max),
        email: String,
        givenName: String,
        familyName: String,
        tracking: Bool? = true
    )
    {
        self.beaconid = beaconid
        self.email = email
        self.givenName = givenName
        self.familyName = familyName
        self.displayName = givenName + " " + familyName
        self.tracking = tracking
    }
}

extension MemberInfo: Codable { }

extension MemberInfo {
    public enum CodingKeys: String, CodingKey {
        case beaconid
        case email
        case givenName
        case displayName
        case familyName
        case tracking
    }
}

// MARK: - ERRORS
public enum MembersError: Error {
    case membersDecodingError
    case membersEncodingError
    case membersDataNotFoundError
}

// MARK: - PROTOCOL
public protocol MembersStorage {
    func register(keys: CollectionDifference<String>)
    func changeListeners() -> AnyPublisher<MembersState, MembersError>
}

// MARK: - MIDDLEWARE

/// The MembersMiddleware is specifically designed to suit the needs of one application.
///
/// It offers the following :
///   * it registers several keys with the data provider (see below),
///   * it listens to all state changes for the particular keys that were registered
///
/// Any new state change collected from the listener is dispatched as an action
/// so the global state can be modified accordingly.
///
public class MembersMiddleware: Middleware {
    
    public typealias InputActionType = MembersAction
    public typealias OutputActionType = MembersAction
    public typealias StateType = MembersState?
    
    private static let logger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "MembersMiddleware")

    private var output: AnyActionHandler<OutputActionType>? = nil
    private var getState: GetState<StateType>? = nil

    private var provider: MembersStorage
    
    private var stateChangeCancellable: AnyCancellable?
    private var operationCancellable: AnyCancellable?
    
    private var idBuffer: [String] = []

    public init(provider: MembersStorage) {
        self.provider = provider
    }
    
    public func receiveContext(getState: @escaping GetState<StateType>, output: AnyActionHandler<OutputActionType>) {
        os_log(
            "Receiving context...",
            log: MembersMiddleware.logger,
            type: .debug
        )
        self.getState = getState
        self.output = output
        self.stateChangeCancellable = provider
            .changeListeners()
            .sink { (completion: Subscribers.Completion<MembersError>) in
                var result: String = "success"
                if case let Subscribers.Completion.failure(err) = completion {
                    result = "failure : " + err.localizedDescription
                }
                os_log(
                    "State change completed with %s.",
                    log: MembersMiddleware.logger,
                    type: .debug,
                    result
                )
            } receiveValue: { members in
                os_log(
                    "State change receiving value for members : %s...",
                    log: MembersMiddleware.logger,
                    type: .debug,
                    String(describing: members)
                )
                self.output?.dispatch(.stateChanged(members))
            }
    }
    
    public func handle(
        action: InputActionType,
        from dispatcher: ActionSource,
        afterReducer : inout AfterReducer
    ) {
        switch action {
            case let .register(ids):
                // We gather the difference between the ids being
                // registered (members in the group / family) and
                // the ones in the existing buffer.
                let diff = ids.difference(from: idBuffer)
                os_log(
                    "Registering members : %s ...",
                    log: MembersMiddleware.logger,
                    type: .debug,
                    String(describing: diff)
                )
                // We send that difference to the provider so we
                // can add / remove listeners appropriately.
                provider.register(keys: diff)
                // Then we either apply the difference to the existing
                // buffer or use the existing buffer if there's no diff.
                idBuffer = idBuffer.applying(diff) ?? idBuffer
            default:
                os_log(
                    "Not handling this case : %s ...",
                    log: MembersMiddleware.logger,
                    type: .debug,
                    String(describing: action)
                )
                break
        }
    }
}
