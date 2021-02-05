//
//  main.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation
import PathKit
import Yams

struct Setting: Codable {
    var targetDirectory: String
    var templateDirectory: String
}

let version = "0.1.0"

var setting: Setting?

func main() {
    let arguments = [String](CommandLine.arguments.dropFirst())
    print("arguments", arguments)
    let command = makeCommand(commandLineArguments: arguments)
    let result = command.run()

    guard let settingFilePath = Path.current.glob(".ribscodegen").first else {
        print("設定ファイルがありません。")
        return
    }

    let a: String? = try? settingFilePath.read()
    guard let settingFileString = a else {
        print("設定ファイルが読み込めません。")
        return
    }
    print("settingFile", settingFileString)
    let decoder = YAMLDecoder()
    do {
        setting = try decoder.decode(Setting.self, from: settingFileString)
    } catch {
        print("設定ファイルの形式がおかしい", error)
    }

    switch result {
    case let .success(message):
        print(message)
        exit(0)
    case let .failure(error):
        print(error.message.red)
        print("\n failure.".red.applyingStyle(.bold))
        exit(Int32(error.code))
    }
}

func makeCommand(commandLineArguments: [String]) -> Command {
    guard let firstArgument = commandLineArguments.first else {
        return HelpCommand()
    }

    print("firstArgument", firstArgument)
    let commandLineArgumentsLackOfFirst = commandLineArguments.dropFirst()
    let secondArgument = commandLineArgumentsLackOfFirst.first
    print("secondArgument", secondArgument ?? "nil")

    let optionArguments = commandLineArgumentsLackOfFirst.dropFirst()

    var optionKey = ""
    var arguments = [String:String]()
    for (index, value) in optionArguments.enumerated() {
        if index % 2 == 0 {
            optionKey = value.replacingOccurrences(of: "--", with: "")
        } else {
            arguments[optionKey] = value
        }
    }

    print("run with", arguments)

    switch firstArgument {
    case "help":
        return HelpCommand()
    case "version":
        return VersionCommand(version: version)
    case "add" where arguments["parent"] == nil://単純にテンプレートからの作成をするだけ。
        guard let secondArgument = secondArgument else {
            print("引数足りない")
            return HelpCommand()
        }
        let targetDirectory = setting?.targetDirectory ?? ""
        let paths = allSwiftSourcePaths(directoryPath: targetDirectory)
        let targetRIBName = secondArgument
        let isOwnsView = true
        let templateDirectory = setting?.templateDirectory ?? ""
        return CreateRIBsCommand(paths: paths,
                                 targetDirectory: targetDirectory,
                                 templateDirectory: templateDirectory,
                                 target: targetRIBName,
                                 isOwnsView: isOwnsView)
    case "add" where arguments["parent"] != nil://子 + 依存。単体をテンプレートから作成→ComponentExtensionの追加→依存の解決。
        guard let secondArgument = secondArgument,
              let parentRIBName = arguments["parent"] else {
            print("引数足りない")
            return HelpCommand()
        }
        let targetDirectory = setting?.targetDirectory ?? ""
        let paths = allSwiftSourcePaths(directoryPath: targetDirectory)
        let targetRIBName = secondArgument
        let isOwnsView = true
        let templateDirectory = setting?.templateDirectory ?? ""

        // 単体
        let childRIBCreateCommand = CreateRIBsCommand(paths: paths,
                                                      targetDirectory: targetDirectory,
                                                      templateDirectory: templateDirectory,
                                                      target: targetRIBName,
                                                      isOwnsView: isOwnsView)
        _ = childRIBCreateCommand.run()

        // ComponentExtension
        let paths2 = allSwiftSourcePaths(directoryPath: targetDirectory)
        let createComponentExtensionCommand = CreateComponentExtension(paths: paths2,
                                                                       targetDirectory: targetDirectory,
                                                                       templateDirectory: templateDirectory,
                                                                       parent: parentRIBName,
                                                                       child: targetRIBName)
        _ = createComponentExtensionCommand.run()


        // 依存の解決
        let paths3 = allSwiftSourcePaths(directoryPath: targetDirectory)
        return DependencyCommand(paths: paths3, parent: parentRIBName, child: targetRIBName)
    case "link"://既存の RIB を使って依存だけをはる
        guard let secondArgument = secondArgument,
              let parentRIBName = arguments["parent"] else {
            print("引数足りない")
            return HelpCommand()
        }
        let targetDirectory = setting?.targetDirectory ?? ""
        let parent = parentRIBName
        let child = secondArgument
        let templateDirectory = setting?.templateDirectory ?? ""
        // ComponentExtension
        let paths2 = allSwiftSourcePaths(directoryPath: targetDirectory)
        let createComponentExtensionCommand = CreateComponentExtension(paths: paths2,
                                                                       targetDirectory: targetDirectory,
                                                                       templateDirectory: templateDirectory,
                                                                       parent: parent,
                                                                       child: child)
        _ = createComponentExtensionCommand.run()


        // 依存の解決
        let paths3 = allSwiftSourcePaths(directoryPath: targetDirectory)
        return DependencyCommand(paths: paths3, parent: parent, child: child)
    case "scaffold":// ファイルから読み取り -> 一括作成
        // TODO:
        return HelpCommand()
    default:
        return HelpCommand()
    }
}

func allSwiftSourcePaths(directoryPath: String) -> [String] {
    let absolutePath = Path(directoryPath).absolute()

    do {
        return try absolutePath.recursiveChildren().filter({ $0.extension == "swift" }).map({ $0.string })
    } catch {
        return []
    }
}

main()
