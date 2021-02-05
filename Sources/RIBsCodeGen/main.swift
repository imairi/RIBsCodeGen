//
//  main.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation
import PathKit

let version = "0.1.0"

func main() {
    let arguments = [String](CommandLine.arguments.dropFirst())
//    let command = makeCommand(commandLineArguments: arguments)
    let command = makeCommand(commandLineArguments: ["dependency"])
    let result = command.run()

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

    let optionArguments = commandLineArguments.dropFirst()

    var optionKey = ""
    var arguments = [String:String]()
    for (index, value) in optionArguments.enumerated() {
        if index % 2 == 0 {
            optionKey = value.replacingOccurrences(of: "--", with: "")
        } else {
            arguments[optionKey] = value
        }
    }

    switch firstArgument {
    case "help":
        return HelpCommand()
    case "version":
        return VersionCommand(version: version)
    case "単体のみ"://単純にテンプレートからの作成をするだけ。
        let targetDirectory = "/Users/imairiyousuke/git/RIBsCodeGen/Sample"
        let paths = allSwiftSourcePaths(directoryPath: targetDirectory)
        let parent = "ParentDemo"
        let isOwnsView = true
        let templateDirectory = "/Users/imairiyousuke/git/RIBsCodeGen/Templates"
        return CreateRIBsCommand(paths: paths,
                                 targetDirectory: targetDirectory,
                                 templateDirectory: templateDirectory,
                                 target: parent,
                                 isOwnsView: isOwnsView)
    case "依存のみ"://既存の RIB を使って依存だけをはる
        return HelpCommand()//TODO:修正
    case "単体（子）のみ + 依存"://子 + 依存。単体をテンプレートから作成→ComponentExtensionの追加→依存の解決。
        let targetDirectory = "/Users/imairiyousuke/git/RIBsCodeGen/Sample"
        let paths = allSwiftSourcePaths(directoryPath: targetDirectory)
        let parent = "ParentDemo"
        let child = "ChildDemo"
        let isOwnsView = true
        let templateDirectory = "/Users/imairiyousuke/git/RIBsCodeGen/Templates"

        // 単体
        let childRIBCreateCommand = CreateRIBsCommand(paths: paths,
                                                      targetDirectory: targetDirectory,
                                                      templateDirectory: templateDirectory,
                                                      target: child,
                                                      isOwnsView: isOwnsView)
        _ = childRIBCreateCommand.run()

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
    default:// scaffold
        let targetDirectory = "/Users/imairiyousuke/git/RIBsCodeGen/Sample"
        let parent = "ParentDemo"
        let child = "ChildDemo"
        let templateDirectory = "/Users/imairiyousuke/git/RIBsCodeGen/Templates"

        // 親
        let paths0 = allSwiftSourcePaths(directoryPath: targetDirectory)
        let parentRIBCreateCommand = CreateRIBsCommand(paths: paths0,
                                                       targetDirectory: targetDirectory,
                                                       templateDirectory: templateDirectory,
                                                       target: parent,
                                                       isOwnsView: false)
        _ = parentRIBCreateCommand.run()

        // 子
        let paths = allSwiftSourcePaths(directoryPath: targetDirectory)
        let childRIBCreateCommand = CreateRIBsCommand(paths: paths,
                                                      targetDirectory: targetDirectory,
                                                      templateDirectory: templateDirectory,
                                                      target: child,
                                                      isOwnsView: true)
        _ = childRIBCreateCommand.run()

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
