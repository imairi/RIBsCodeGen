//
//  Argument.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/08.
//

import Foundation

struct Argument: CustomStringConvertible {
    let first: String
    let second: String
    let options: [String:String]

    var description: String {
        "1st: \(first), 2nd: \(second), options: \(options)"
    }
}

extension Argument {
    var hasParent: Bool {
        options["parent"]?.isEmpty == false // "--parent xxx 「xxx」のチェック"
    }

    var parent: String {
        guard let parentString = options["parent"] else {
            fatalError("--parent is needed.".bold.red)
        }
        return parentString
    }

    var noView: Bool {
        options["noview"] != nil // "--noview の存在有無"
    }
}
