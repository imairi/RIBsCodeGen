//
//  CreateComponentExtension.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/05.
//

import Foundation
import SourceKittenFramework
import PathKit

struct CreateComponentExtension: Command {
    let needsCreateTargetFile: Bool
    let targetDirectory: String
    let templateDirectory: String
    let parent: String
    let child: String

    init(paths: [String],
         setting: Setting,
         parent: String,
         child: String) {
        targetDirectory = setting.targetDirectory
        templateDirectory = setting.templateDirectory
        needsCreateTargetFile = paths.filter({ $0.contains("\(parent)Component+\(child).swift") }).isEmpty

        self.parent = parent
        self.child = child
    }

    func run() -> Result {
        print("\nStart creating ComponentExtension between \(parent) and \(child).".bold)

        guard needsCreateTargetFile else {
            return .success(message: "No need to add ComponentExtension, it already be exists.".yellow.bold)
        }
        do {
            try createDirectory()
        } catch {
            print("  Failed to creating directory.".red.bold)
            return .failure(error: .failedCreateDirectory)
        }

        do {
            try createFiles()
        } catch {
            print("  Failed to creating file.".red.bold)
            print("  Check the template directory.".red.bold)
            return .failure(error: .failedCreateFile)
        }

        return .success(message: "Successfully finished creating \(parent)Component+\(child).swift".green.bold)
    }
}

// MARK: - Private methods
private extension CreateComponentExtension {
    func createDirectory() throws {
        let filePath = targetDirectory + "/\(parent)/Dependencies" // 親 Directory -> Dependencies
        print("  Creating directory: \(filePath)")
        guard !Path(filePath).exists else {
            print("  Skip to create directory: \(filePath)".yellow)
            return
        }

        try Path(stringLiteral: filePath).mkdir()
    }

    func createFiles() throws {
        let filePath = targetDirectory + "/\(parent)/Dependencies" + "/\(parent)Component+\(child).swift"
        print("  Creating file: \(filePath)")
        let template: String = try Path(templateDirectory + "/ComponentExtension/ComponentExtension.swift").read()
        let replacedText = template
            .replacingOccurrences(of: "___VARIABLE_productName___", with: "\(parent)")
            .replacingOccurrences(of: "___VARIABLE_childName___", with: "\(child)")
        try Path(filePath).write(replacedText)
    }
}

