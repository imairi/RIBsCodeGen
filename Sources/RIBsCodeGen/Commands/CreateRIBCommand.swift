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
        print("\nStart creating \(target) RIB.".bold)

        guard needsCreateTargetFile else {
            return .success(message: "No need to add RIB, it already be exists.".yellow.bold)
        }

        do {
            try createDirectory()
        } catch {
            return .failure(error: .failedCreateDirectory)
        }

        do {
            try createFiles()
        } catch {
            return .failure(error: .failedCreateFile)
        }

        return .success(message: "Successfully finished creating \(target) RIB.".green.bold)
    }
}

// MARK: - Private methods
private extension CreateRIBCommand {
    func createDirectory() throws {
        let filePath = targetDirectory + "/\(target)"
        print("  Creating directory: \(filePath)")
        guard !Path(filePath).exists else {
            print("  Skip to create directory: \(filePath)")
            return
        }
        try Path(filePath).mkdir()
    }

    func createFiles() throws {
        let fileTypes: [String]
        if isOwnsView {
            fileTypes = ["Router", "Interactor", "Builder", "ViewController"]
        } else {
            fileTypes = ["Router", "Interactor", "Builder"]
        }

        try fileTypes.forEach { fileType in
            let filePath = targetDirectory + "/\(target)/\(target)\(fileType).swift"
            print("  Creating file: \(filePath)")
            let template: String = try Path(templateDirectory + "/\(fileType).swift").read()
            let replacedText = template
                .replacingOccurrences(of: "___VARIABLE_productName___", with: "\(target)")
                .replacingOccurrences(of: "___VARIABLE_productName_lowercased___", with: "\(target.lowercasedFirstLetter())")
            try Path(filePath).write(replacedText)
            let formattedText = try Formatter.format(path: filePath)
            try Path(filePath).write(formattedText)
        }
    }
}
