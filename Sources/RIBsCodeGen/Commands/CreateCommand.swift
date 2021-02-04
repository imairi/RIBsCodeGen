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
    let needsCreateParentFile: Bool
    let needsCreateChildFile: Bool
    let targetDirectory: String
    let templateDirectory: String
    let parent: String
    let child: String

    init(paths: [String], targetDirectory: String, templateDirectory: String, parent: String, child: String) {
        print("")
        print("Analyze \(paths.count) swift files.".applyingStyle(.bold))
        print("")

        self.targetDirectory = targetDirectory
        self.templateDirectory = templateDirectory
        self.parent = parent
        self.child = child

        let parentRouterPath = paths.filter({ $0.contains(parent + "Router.swift") }).first
        let parentInteractorPath = paths.filter({ $0.contains(parent + "Interactor.swift") }).first
        let parentBuilderPath = paths.filter({ $0.contains(parent + "Builder.swift") }).first

        needsCreateParentFile = [parentRouterPath, parentInteractorPath, parentBuilderPath].contains(nil)

        let childRouterPath = paths.filter({ $0.contains(child + "Router.swift") }).first
        let childInteractorPath = paths.filter({ $0.contains(child + "Interactor.swift") }).first
        let childBuilderPath = paths.filter({ $0.contains(child + "Builder.swift") }).first

        needsCreateChildFile = [childRouterPath, childInteractorPath, childBuilderPath].contains(nil)
    }

    func run() -> Result {
        if needsCreateChildFile {
            createDirectory(for: parent)
            createFiles(for: parent)
        }

        if needsCreateChildFile {
            createDirectory(for: child)
            createFiles(for: child)
        }

        return .success(message: "helpMessage")
    }
}

// MARK: - Private methods
private extension CreateCommand {
    func createDirectory(for target: String) {
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

    func createFiles(for target: String) {
        print("ファイル作成開始")
        ["Router", "Interactor", "Builder"].forEach { fileType in
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
