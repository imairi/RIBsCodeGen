//
//  String+Foundation.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/04.
//

import Foundation

extension String {
    func lowercasedFirstLetter() -> String {
        prefix(1).lowercased() + dropFirst()
    }

    var lastElementSplittedBySlash: String {
        String(self.split(separator: "/").last ?? "")
    }
}
