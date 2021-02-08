//
//  CreateRIBsCommand.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/04.
//

import Foundation
import SourceKittenFramework
import PathKit

struct CreateRIBsCommand: Command {
    let needsCreateTargetFile: Bool
    let targetDirectory: String
    let templateDirectory: String
    let target: String
    let isOwnsView: Bool

    init(paths: [String],
         setting: Setting,
         target: String,
         isOwnsView: Bool) {
        let parentRouterPath = paths.filter({ $0.contains("/" + target + "Router.swift") }).first
        let parentInteractorPath = paths.filter({ $0.contains("/" + target + "Interactor.swift") }).first
        let parentBuilderPath = paths.filter({ $0.contains("/" + target + "Builder.swift") }).first
        needsCreateTargetFile = [parentRouterPath, parentInteractorPath, parentBuilderPath].contains(nil)

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
private extension CreateRIBsCommand {
    func createDirectory() {
        let filePath = targetDirectory + "/\(target)"
        do {
            try Path(stringLiteral: filePath).mkdir()
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
            if FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil) {
                let template = readText(from: templateDirectory + "/\(fileType).swift")
                let replacedText = template
                    .replacingOccurrences(of: "___VARIABLE_productName___", with: "\(target)")
                    .replacingOccurrences(of: "___VARIABLE_productName_lowercased___", with: "\(target.lowercasedFirstLetter())")
                write(text: replacedText, toPath: filePath)
            } else {
                print("\(fileType)ファイル作成失敗")
            }
        }
    }
}

// MARK: - execute methods
private extension CreateRIBsCommand {
    func readText(from path: String) -> String {
        do {
            return try Path(path).read()
        } catch {
            print("読み込みエラー", error)
            return ""
        }
    }

    func write(text: String, toPath path: String) {
        do {
            try Path(path).write(text)
        } catch {
            print("書き込みエラー", error)
        }
    }

    func format(path: String) -> String? {
        var formattedText: String?
        do {
            guard let parentRouterFile = File(path: path) else {
                print("該当ファイルが見つかりませんでした。", path)
                return nil
            }
            formattedText = try parentRouterFile.format(trimmingTrailingWhitespace: true, useTabs: false, indentWidth: 4)
        } catch {
            print("フォーマットエラー", error)
        }

        return formattedText
    }
}
