//
//  HelpCommand.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation

struct HelpCommand: Command {
    func run() -> Result {
        let helpMessage = """
        USAGE: ribscodegen [action] [arguments]

        - bulk generation
        ribscodegen scaffold [tree.md] --parent [parent RIB name]

        - add RIB
        ribscodegen add [target RIB name]

        - add viewless RIB
        ribscodegen add [target RIB name] --noview

        - add RIB and link parent
        ribscodegen add [target RIB name] --parent [parent RIB name]

        - link RIB
        ribscodegen link [target RIB name] --parent [parent RIB name]

        cf. More details in https://github.com/imairi/RIBsCodeGen/

        """.lightBlue

        return .success(message: helpMessage)
    }
}
