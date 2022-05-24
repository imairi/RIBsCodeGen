//
//  Error.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation

enum Error: Swift.Error {
    case notFoundStructure
    case lackOfArguments
    case unknown
    case failedCreateDirectory
    case failedCreateFile
    case failedFormat
    case failedToAddChildListener
    case failedToAddChildBuilder
    case failedToRename(String)
    case failedToUnlink(String)

    var message: String {
        switch self {
        case .notFoundStructure:
            return "Not found structure"
        case .lackOfArguments:
            return "Not found essential arguments"
        case .unknown:
            return "Unknown error"
        case .failedCreateDirectory:
            return "Failed to create directory."
        case .failedCreateFile:
            return "Failed to write file."
        case .failedFormat:
            return "Failed to format file."
        case .failedToAddChildListener:
            return "Failed to add child listener."
        case .failedToAddChildBuilder:
            return "Failed to add child builder."
        case let .failedToRename(reason):
            return reason
        case let .failedToUnlink(reason):
            return reason
        }
    }

    var code: Int {
        return 1
    }
}
