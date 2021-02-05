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
         targetDirectory: String,
         templateDirectory: String,
         parent: String,
         child: String) {
        print("--------------------------Create ComponentExtension \(parent)Dependency\(child)".applyingBackgroundColor(.magenta))
        print("")
        print("Analyze \(paths.count) swift files.".applyingStyle(.bold))
        print("")

        self.targetDirectory = targetDirectory
        self.templateDirectory = templateDirectory
        self.parent = parent
        self.child = child

        needsCreateTargetFile = paths.filter({ $0.contains("\(parent)Component+\(child).swift") }).isEmpty
    }

    func run() -> Result {
        guard needsCreateTargetFile else {
            return .success(message: "ComponentExtensionファイルはあります。")
        }
        createDirectory()
        createFiles()
        return .success(message: "")
    }
}

// MARK: - Private methods
private extension CreateComponentExtension {
    func createDirectory() {
        print("ディレクトリ作成開始")
        let filePath = targetDirectory + "/\(parent)/Dependencies" // 親Directory->Dependencies

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

        let filePath = targetDirectory + "/\(parent)/Dependencies" + "/\(parent)Component+\(child).swift"
        print(filePath)
        if FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil) {
            print("ComponentExtensionファイル作成成功")
            let template = readText(from: templateDirectory + "/ComponentExtension/ComponentExtension.swift")
            let replacedText = template
                .replacingOccurrences(of: "___VARIABLE_productName___", with: "\(parent)")
                .replacingOccurrences(of: "___VARIABLE_childName___", with: "\(child)")
            write(text: replacedText, toPath: filePath)
        } else {
            print("ComponentExtensionファイル作成失敗")
        }
    }
}

// MARK: - execute methods
private extension CreateComponentExtension {
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
//            print(text)
            print("... 書き込み中 ...", path)
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

