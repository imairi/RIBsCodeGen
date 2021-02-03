//
//  Command.swift
//  RIBshokunin
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation

protocol Command {
    func run() -> Result
}
