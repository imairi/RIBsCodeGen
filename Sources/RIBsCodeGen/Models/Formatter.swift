//
//  Formatter.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/08.
//

import Foundation
import SourceKittenFramework

private enum FormatterError: Swift.Error {
    case notFoundTargetFile

    var message: String {
        switch self {
        case .notFoundTargetFile:
            return "Not found target file for formatting."
        }
    }

    var code: Int {
        return 1
    }
}


enum Formatter {
    static func format(path: String) throws -> String {
        guard let parentRouterFile = File(path: path) else {
            print("Not found target file: \(path)".red.bold)
            throw FormatterError.notFoundTargetFile
        }
        return try parentRouterFile.format(trimmingTrailingWhitespace: true, useTabs: false, indentWidth: 4)
    }
}
