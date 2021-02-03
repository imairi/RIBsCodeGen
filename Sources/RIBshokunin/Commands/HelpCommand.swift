//
//  HelpCommand.swift
//  RIBshokunin
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation

struct HelpCommand: Command {
    func run() -> Result {
        let helpMessage = "USAGE: RIBsTreeMaker [analyze target path] [--under [RIB name]] "
        return .success(message: helpMessage)
    }
}
