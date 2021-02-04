//
//  Result.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation

enum Result {
    case success(message: String)
    case failure(error: Error)
}
