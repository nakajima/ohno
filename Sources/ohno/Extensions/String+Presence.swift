//
//  String+Presence.swift
//
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation

extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines) == ""
    }

    var presence: String? {
        return isBlank ? nil : self
    }
}
