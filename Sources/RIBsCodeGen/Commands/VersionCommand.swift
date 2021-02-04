//
//  VersionCommand.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation

struct VersionCommand: Command {
    let version: String

    func run() -> Result {
        return .success(message: version)
    }
}

