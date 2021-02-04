//
//  Error.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation

enum Error: Swift.Error {
    case notFoundStructure
    case unknown

    var message: String {
        switch self {
        case .notFoundStructure:
            return "Not found structure"
        case .unknown:
            return "Unknown error"
        }
    }

    var code: Int {
        return 1
    }
}