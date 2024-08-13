//
//  Edge.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/08.
//

import Foundation

struct Edge: CustomStringConvertible {
    let parent: String
    let target: String
    let isOwnsView: Bool
    let isNeedle: Bool

    var description: String {
        let viewState = isOwnsView ? "" : "(noView)"
        return "[child:\(target)\(viewState) -> parent:\(parent)]"
    }
}
