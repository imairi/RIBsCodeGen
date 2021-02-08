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

    let command = makeCommand(commandLineArguments: arguments)
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

    print("firstArgument", firstArgument)
    let commandLineArgumentsLackOfFirst = commandLineArguments.dropFirst()
    let secondArgument = commandLineArgumentsLackOfFirst.first
    print("secondArgument", secondArgument ?? "nil")

    let optionArguments = commandLineArgumentsLackOfFirst.dropFirst()

//    var optionKey = ""
//    var arguments = [String:String]()
//    for (index, value) in optionArguments.enumerated() {
//        if index % 2 == 0 {
//            optionKey = value.replacingOccurrences(of: "--", with: "")
//        } else {
//            arguments[optionKey] = value
//        }
//    }

    var arguments = [String:String]()
    var latestOptionKey = ""
    optionArguments.forEach { argument in
        if argument.contains("--") {
            let optionKey = argument.replacingOccurrences(of: "--", with: "")
            arguments[optionKey] = ""
            latestOptionKey = optionKey
        } else {
            arguments[latestOptionKey] = argument
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
        let isOwnsView = arguments["noview"]?.isEmpty == false
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
        let isOwnsView = arguments["noview"]?.isEmpty == false
        let templateDirectory = setting?.templateDirectory ?? ""

        print("------------------")
        print("- targetDirectory", targetDirectory)
        print("- targetRIBName", targetRIBName)
        print("- isOwnsView", isOwnsView)
        print("- templateDirectory", templateDirectory)
        print("------------------")

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
        guard let tree = secondArgument else {
            print("markdown ファイルを指定して下さい")
            return HelpCommand()
        }

        guard let treePath = Path.current.glob(tree).first else {
            print("ファイルを指定して下さい。")
            return HelpCommand()
        }

        guard let treeString: String = try? treePath.read() else {
            print("ファイルが読み込めません")
            return HelpCommand()
        }

        guard let argumentParentRIBName = arguments["parent"] else {
            print("parent 引数足りない")
            return HelpCommand()
        }

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
            let targetDirectory = setting?.targetDirectory ?? ""
            let paths = allSwiftSourcePaths(directoryPath: targetDirectory)
            let targetRIBName = edge.target
            let isOwnsView = edge.isOwnsView
            let templateDirectory = setting?.templateDirectory ?? ""

            print("------------------")
            print("- targetDirectory", targetDirectory)
            print("- targetRIBName", targetRIBName)
            print("- isOwnsView", isOwnsView)
            print("- templateDirectory", templateDirectory)
            print("------------------")

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
        return HelpCommand()
    default:
        return HelpCommand()
    }
}

struct Node: CustomStringConvertible {
    let spaceCount: Int
    let ribName: String
    let isOwnsView: Bool

    var description: String {
        "<space: \(spaceCount), name: \(ribName), isOwnsView: \(isOwnsView)>"
    }
}

struct Edge: CustomStringConvertible {
    let parent: String
    let target: String
    let isOwnsView: Bool

    var description: String {
        let viewState = isOwnsView ? "" : "(noView)"
        return "[child:\(target)\(viewState) -> parent:\(parent)]"
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
