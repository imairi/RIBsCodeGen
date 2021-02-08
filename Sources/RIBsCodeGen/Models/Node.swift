//
//  Node.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/08.
//

import Foundation

struct Node: CustomStringConvertible {
    let spaceCount: Int
    let ribName: String
    let isOwnsView: Bool

    var description: String {
        "<space: \(spaceCount), name: \(ribName), isOwnsView: \(isOwnsView)>"
    }
}
