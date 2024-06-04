//
//  Setting.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/08.
//

import Foundation

struct Setting: Codable {
    var targetDirectory: String
    var templateDirectory: String
}

struct RenameSetting: Codable {
    var interactor: [String]
    var builder: [String]
    var router: [String]
    var viewController: [String]
    var componentExtension: [String]
    var parentInteractor: [String]
    var parentNormalBuilder: [String]
    var parentNeedleBuilder: [String]
    var parentRouter: [String]
    var parentComponentExtension: [String]
}

struct UnlinkSetting: Codable {
    var parentInteractor: [String]
    var parentNormalBuilder: [String]
    var parentNeedleBuilder: [String]
    var parentRouter: [String]
}
