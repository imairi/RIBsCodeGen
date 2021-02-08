//
//  CreateRIBCommand.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/04.
//

import Foundation
import SourceKittenFramework
import PathKit

struct CreateRIBCommand: Command {
    let needsCreateTargetFile: Bool
    let targetDirectory: String
    let templateDirectory: String
    let target: String
    let isOwnsView: Bool

    init(paths: [String],
         setting: Setting,
         target: String,
         isOwnsView: Bool) {
        var targetPaths = [String?]()

        let targetRouterPath = paths.filter({ $0.contains("/" + target + "Router.swift") }).first
        targetPaths.append(targetRouterPath)

        let targetInteractorPath = paths.filter({ $0.contains("/" + target + "Interactor.swift") }).first
        targetPaths.append(targetInteractorPath)

        let targetBuilderPath = paths.filter({ $0.contains("/" + target + "Builder.swift") }).first
        targetPaths.append(targetBuilderPath)

        if isOwnsView {
            let targetViewControllerPath = paths.filter({ $0.contains("/" + target + "ViewController.swift") }).first
            targetPaths.append(targetViewControllerPath)
        }

        needsCreateTargetFile = targetPaths.contains(nil)

        targetDirectory = setting.targetDirectory
        templateDirectory = isOwnsView ? setting.templateDirectory + "/OwnsView" : setting.templateDirectory + "/Default"
        
        self.target = target
        self.isOwnsView = isOwnsView
    }

    func run() -> Result {
        guard needsCreateTargetFile else {
            return .success(message: "")
        }
        createDirectory()
        createFiles()
        return .success(message: "")
    }
}

// MARK: - Private methods
private extension CreateRIBCommand {
    func createDirectory() {
        let filePath = targetDirectory + "/\(target)"
        guard !Path(filePath).exists else {
            print("ディレクトリ作成スキップ")
            return
        }
        do {
            try Path(filePath).mkdir()
        } catch {
            print("ディレクトリ作成失敗", error)
        }
    }

    func createFiles() {
        let fileTypes: [String]
        if isOwnsView {
            fileTypes = ["Router", "Interactor", "Builder", "ViewController"]
        } else {
            fileTypes = ["Router", "Interactor", "Builder"]
        }

        fileTypes.forEach { fileType in
            let filePath = targetDirectory + "/\(target)/\(target)\(fileType).swift"
            do {
                let template: String = try Path(templateDirectory + "/\(fileType).swift").read()
                let replacedText = template
                    .replacingOccurrences(of: "___VARIABLE_productName___", with: "\(target)")
                    .replacingOccurrences(of: "___VARIABLE_productName_lowercased___", with: "\(target.lowercasedFirstLetter())")
                try Path(filePath).write(replacedText)
                let formattedText = try Formatter.format(path: filePath)
                try Path(filePath).write(formattedText)
            } catch {
                print("\(fileType)ファイル書き込み失敗", error)

            }
        }
    }
}
