//
//  URL.swift
//
//
//  Created by Pat Nakajima on 5/6/24.
//

import Foundation

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
