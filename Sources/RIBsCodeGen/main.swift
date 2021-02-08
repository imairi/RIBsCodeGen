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
        print("Lack of argument.".red.bold)
        return nil
    }

    let commandLineArgumentsLackOfFirst = commandLineArguments.dropFirst()
    guard let secondArgument = commandLineArgumentsLackOfFirst.first else {
        print("Lack of argument.".red.bold)
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
        print("Not found setting file, add .ribscodegen at current directory".red.bold)
        return nil
    }

    let settingFile: String? = try? settingFilePath.read()
    guard let settingFileString = settingFile else {
        print("Failed to read .ribscodegen.".red.bold)
        return nil
    }

    let decoder = YAMLDecoder()
    do {
        return try decoder.decode(Setting.self, from: settingFileString)
    } catch {
        print("Failed to decode .ribscodegen. Check the setting values.".red.bold)
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
        let command = CreateRIBCommand(paths: paths,
                                       setting: setting,
                                       target: argument.second,
                                       isOwnsView: !argument.noView)
        return command.run()
    case "add" where argument.hasParent:
        // 単体
        let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
        let childRIBCreateCommand = CreateRIBCommand(paths: paths,
                                                     setting: setting,
                                                     target: argument.second,
                                                     isOwnsView: !argument.noView)
        _ = childRIBCreateCommand.run()

        // ComponentExtension
        let paths2 = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
        let createComponentExtensionCommand = CreateComponentExtension(paths: paths2,
                                                                       setting: setting,
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
                                                                       setting: setting,
                                                                       parent: argument.parent,
                                                                       child: argument.second)
        _ = createComponentExtensionCommand.run()

        // 依存の解決
        let paths3 = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
        let dependencyCommand = DependencyCommand(paths: paths3, parent: argument.parent, child: argument.second)
        return dependencyCommand.run()
    case "scaffold":
        guard let treePath = Path.current.glob(argument.second).first else {
            print("Needs to add markdown file path for second argument.".red.bold)
            return HelpCommand().run()
        }

        guard let treeString: String = try? treePath.read() else {
            print("Failed to read file: \(treePath)".red.bold)
            return HelpCommand().run()
        }

        let argumentParentRIBName = argument.parent

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
                edges.append(Edge(parent: argumentParentRIBName, target: node.ribName, isOwnsView: node.isOwnsView))
                continue
            }
            edges.append(Edge(parent: parentNode.ribName, target: node.ribName, isOwnsView: node.isOwnsView))
        }

        edges.reversed().forEach { edge in
            let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
            let targetRIBName = edge.target
            let isOwnsView = edge.isOwnsView

            // 単体
            let childRIBCreateCommand = CreateRIBCommand(paths: paths,
                                                         setting: setting,
                                                         target: targetRIBName,
                                                         isOwnsView: isOwnsView)
            _ = childRIBCreateCommand.run()

            // ComponentExtension
            let paths2 = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
            let createComponentExtensionCommand = CreateComponentExtension(paths: paths2,
                                                                           setting: setting,
                                                                           parent: edge.parent,
                                                                           child: targetRIBName)
            _ = createComponentExtensionCommand.run()


            // 依存の解決
            let paths3 = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
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
