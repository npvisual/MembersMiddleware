// Generated using Sourcery 1.0.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

extension MembersAction {
    public var register: [String]? {
        get {
            guard case let .register(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .register = self, let newValue = newValue else { return }
            self = .register(newValue)
        }
    }

    public var isRegister: Bool {
        self.register != nil
    }

    public var stateChanged: [MembersState]? {
        get {
            guard case let .stateChanged(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .stateChanged = self, let newValue = newValue else { return }
            self = .stateChanged(newValue)
        }
    }

    public var isStateChanged: Bool {
        self.stateChanged != nil
    }

}
