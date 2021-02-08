//
//  main.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation
import PathKit
import Yams

let version = "0.1.0"

var setting: Setting!

func main() {
    let arguments = [String](CommandLine.arguments.dropFirst())

    guard let setting = analyzeSettings() else {
        print("")
        print("\n failure.".red.applyingStyle(.bold))
        exit(1)
    }
    RIBsCodeGen.setting = setting

    let result = run(with: arguments)

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

func analyzeArguments(commandLineArguments: [String]) -> Argument? {
    guard let firstArgument = commandLineArguments.first else {
        print("引数足りない")
        return nil
    }

    let commandLineArgumentsLackOfFirst = commandLineArguments.dropFirst()
    guard let secondArgument = commandLineArgumentsLackOfFirst.first else {
        print("引数足りない")
        return nil
    }
    let optionArguments = commandLineArgumentsLackOfFirst.dropFirst()

    var otherArguments = [String:String]()
    var latestOptionKey = ""
    optionArguments.forEach { argument in
        if argument.contains("--") {
            let optionKey = argument.replacingOccurrences(of: "--", with: "")
            otherArguments[optionKey] = ""
            latestOptionKey = optionKey
        } else {
            otherArguments[latestOptionKey] = argument
        }
    }

    return Argument(first: firstArgument, second: secondArgument, options: otherArguments)
}

func analyzeSettings() -> Setting? {
    guard let settingFilePath = Path.current.glob(".ribscodegen").first else {
        print("設定ファイルがありません。")
        return nil
    }

    let settingFile: String? = try? settingFilePath.read()
    guard let settingFileString = settingFile else {
        print("設定ファイルが読み込めません。")
        return nil
    }

    let decoder = YAMLDecoder()
    do {
        return try decoder.decode(Setting.self, from: settingFileString)
    } catch {
        print("設定ファイルの形式がおかしい", error)
        return nil
    }
}

func run(with commandLineArguments: [String]) -> Result {
    guard let argument = analyzeArguments(commandLineArguments: commandLineArguments) else {
        return .failure(error: .lackOfArguments)
    }

    switch argument.first {
    case "help":
        let command = HelpCommand()
        return command.run()
    case "version":
        let command = VersionCommand(version: version)
        return command.run()
    case "add" where !argument.hasParent:
        let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
        let command = CreateRIBsCommand(paths: paths,
                                        targetDirectory: setting.targetDirectory,
                                        templateDirectory: setting.templateDirectory,
                                        target: argument.second,
                                        isOwnsView: !argument.noView)
        return command.run()
    case "add" where argument.hasParent:
        // 単体
        let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
        let childRIBCreateCommand = CreateRIBsCommand(paths: paths,
                                                      targetDirectory: setting.targetDirectory,
                                                      templateDirectory: setting.templateDirectory,
                                                      target: argument.second,
                                                      isOwnsView: !argument.noView)
        _ = childRIBCreateCommand.run()

        // ComponentExtension
        let paths2 = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
        let createComponentExtensionCommand = CreateComponentExtension(paths: paths2,
                                                                       targetDirectory: setting.targetDirectory,
                                                                       templateDirectory: setting.templateDirectory,
                                                                       parent: argument.parent,
                                                                       child: argument.second)
        _ = createComponentExtensionCommand.run()


        // 依存の解決
        let paths3 = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
        return DependencyCommand(paths: paths3, parent: argument.parent, child: argument.second).run()
    case "link":
        // ComponentExtension
        let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
        let createComponentExtensionCommand = CreateComponentExtension(paths: paths,
                                                                       targetDirectory: setting.targetDirectory,
                                                                       templateDirectory: setting.templateDirectory,
                                                                       parent: argument.parent,
                                                                       child: argument.second)
        _ = createComponentExtensionCommand.run()

        // 依存の解決
        let paths3 = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
        let dependencyCommand = DependencyCommand(paths: paths3, parent: argument.parent, child: argument.second)
        return dependencyCommand.run()
    case "scaffold":
        guard let treePath = Path.current.glob(argument.second).first else {
            print("ファイルを指定して下さい。")
            return HelpCommand().run()
        }

        guard let treeString: String = try? treePath.read() else {
            print("ファイルが読み込めません")
            return HelpCommand().run()
        }

        let argumentParentRIBName = argument.parent

        print(treeString)


        let treeArray = treeString.components(separatedBy: "\n")
        let reversedTreeArray = treeArray.reversed()
        let nodes: [Node] = reversedTreeArray
            .map { $0.components(separatedBy: "- ") }
            .map { array -> Node? in
                let spaceCount = array.first?.count ?? 0
                guard let ribName = array.last, !ribName.isEmpty else {
                    return nil
                }
                let erasedSpaceRIBName = ribName.replacingOccurrences(of: " ", with: "")
                let isOwnsView = !erasedSpaceRIBName.contains("*")
                let extractedRIBNameString = erasedSpaceRIBName.replacingOccurrences(of: "*", with: "")
                return Node(spaceCount: spaceCount, ribName: extractedRIBNameString, isOwnsView: isOwnsView)
            }
            .compactMap { $0 }

        var edges = [Edge]()
        for (index, node) in nodes.enumerated() {
            let filteredNodes = nodes[index..<nodes.count]

            guard let parentNode = filteredNodes.filter({ $0.spaceCount < node.spaceCount }).first else {
                print("\(node.ribName)は最上位ノード")
                edges.append(Edge(parent: argumentParentRIBName, target: node.ribName, isOwnsView: node.isOwnsView))
                continue
            }
            edges.append(Edge(parent: parentNode.ribName, target: node.ribName, isOwnsView: node.isOwnsView))
        }

        print(edges)

        edges.reversed().forEach { edge in
            let targetDirectory = setting.targetDirectory
            let paths = allSwiftSourcePaths(directoryPath: targetDirectory)
            let targetRIBName = edge.target
            let isOwnsView = edge.isOwnsView
            let templateDirectory = setting.templateDirectory

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
                                                                           parent: edge.parent,
                                                                           child: targetRIBName)
            _ = createComponentExtensionCommand.run()


            // 依存の解決
            let paths3 = allSwiftSourcePaths(directoryPath: targetDirectory)
            let dependencyCommand = DependencyCommand(paths: paths3, parent: edge.parent, child: targetRIBName)
            _ = dependencyCommand.run()
        }
        return HelpCommand().run()
    default:
        return HelpCommand().run()
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
