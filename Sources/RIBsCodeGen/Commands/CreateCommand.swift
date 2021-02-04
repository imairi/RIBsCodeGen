//
//  CreateCommand.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/04.
//

import Foundation
import SourceKittenFramework
import PathKit

struct CreateCommand: Command {
    let needsCreateTargetFile: Bool
    let targetDirectory: String
    let templateDirectory: String
    let target: String
    let isOwnsView: Bool

    init(paths: [String],
         targetDirectory: String,
         templateDirectory: String,
         target: String,
         isOwnsView: Bool) {
        print("")
        print("Analyze \(paths.count) swift files.".applyingStyle(.bold))
        print("")

        self.targetDirectory = targetDirectory
        self.templateDirectory = templateDirectory
        self.target = target
        self.isOwnsView = isOwnsView

        let parentRouterPath = paths.filter({ $0.contains(target + "Router.swift") }).first
        let parentInteractorPath = paths.filter({ $0.contains(target + "Interactor.swift") }).first
        let parentBuilderPath = paths.filter({ $0.contains(target + "Builder.swift") }).first

        needsCreateTargetFile = [parentRouterPath, parentInteractorPath, parentBuilderPath].contains(nil)
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
private extension CreateCommand {
    func createDirectory() {
        print("ディレクトリ作成開始")
        let filePath = targetDirectory + "/\(target)"

        do {
            try FileManager.default.createDirectory(atPath: filePath,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            print("ディレクトリ作成失敗", error)
        }
    }

    func createFiles() {
        print("ファイル作成開始")

        let fileTypes: [String]
        if isOwnsView {
            fileTypes = ["Router", "Interactor", "Builder", "ViewController"]
        } else {
            fileTypes = ["Router", "Interactor", "Builder"]
        }

        fileTypes.forEach { fileType in
            let filePath = targetDirectory + "/\(target)/\(target)\(fileType).swift"
            print(filePath)
            if FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil) {
                print("\(fileType)ファイル作成成功")
                let template = readText(from: templateDirectory + "/\(fileType).swift")
                let replacedText = template.replacingOccurrences(of: "___VARIABLE_productName___", with: "\(target)")
                write(text: replacedText, toPath: filePath)
            } else {
                print("\(fileType)ファイル作成失敗")
            }
        }
    }
}

// MARK: - execute methods
private extension CreateCommand {
    func readText(from path: String) -> String {
        do {
            return try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
        } catch {
            print("読み込みエラー", error)
            return ""
        }
    }

    func write(text: String, toPath path: String) {
        do {
            print(text)
            print("... 書き込み中 ...")
            try text.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
            print("... 書き込み完了 ...")
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
