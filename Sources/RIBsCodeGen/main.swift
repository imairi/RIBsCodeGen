//
//  main.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation
import PathKit
import Yams
import SourceKittenFramework

var setting: Setting!

func main() {
    let ribsCodeGenString = "RI".red.bold.underline
        + "Bs".lightRed.bold.underline
        + "Co".lightMagenta.bold.underline
        + "de".magenta.bold.underline
        + "Gen".lightBlue.bold.underline
    let startMessage = "\nStart ".bold.underline + ribsCodeGenString + " operation.\n".bold.underline
    print(startMessage)
    
    let arguments = [String](CommandLine.arguments.dropFirst())
    guard let analaizedSettings = analyzeSettings() else {
        print("")
        print("\nRIBsCodeGen operation failed. Check the above error logs.".red)
        print("")
        exit(1)
    }
    setting = analaizedSettings

    run(with: arguments)
}

// MARK: - Execute
func run(with commandLineArguments: [String]) {
    guard let argument = analyzeArguments(commandLineArguments: commandLineArguments) else {
        return showResult(.failure(error: .lackOfArguments))
    }

    switch argument.action {
    case .help:
        let result = HelpCommand().run()
        showResult(result)
        exit(0)
    case .add where !argument.hasParent:
        let result = makeCreateRIBCommand(argument: argument).run()
        showResult(result)
        exit(0)
    case .add where argument.hasParent:
        let resultCreateRIB = makeCreateRIBCommand(argument: argument).run()
        showResult(resultCreateRIB)

        let resultCreateComponentExtension = makeCreateComponentExtension(argument: argument).run()
        showResult(resultCreateComponentExtension)

        let resultDependency = makeDependencyCommand(argument: argument).run()
        showResult(resultDependency)
        exit(0)
    case .link:
        let resultCreateComponentExtension = makeCreateComponentExtension(argument: argument).run()
        showResult(resultCreateComponentExtension)

        let resultDependency = makeDependencyCommand(argument: argument).run()
        showResult(resultDependency)
        exit(0)
    case .scaffold:
        let edges = makeEdges(argument: argument)
        edges.forEach { edge in
            let resultCreateRIB = makeCreateRIBCommand(edge: edge).run()
            showResult(resultCreateRIB)

            let resultCreateComponentExtension = makeCreateComponentExtension(edge: edge).run()
            showResult(resultCreateComponentExtension)

            let resultDependency = makeDependencyCommand(edge: edge).run()
            showResult(resultDependency)
        }
        exit(0)
    case .rename:
        guard let renameSetting = analyzeRenameSettings() else {
            return
        }
        let currentName = argument.actionTarget
        guard let newName = argument.options.first?.value else {
            return
        }
        let resultRenameCommand = makeRenameCommand(renameSetting: renameSetting, currentName: currentName, newName: newName).run()
        showResult(resultRenameCommand)
        exit(0)
    case .unlink:
        guard let unlinkSetting = analyzeUnlinkSettings() else {
            return
        }
        let resultUnlink = makeUnlink(targetName: argument.actionTarget, parentName: argument.parent, unlinkSetting: unlinkSetting).run()
        showResult(resultUnlink)
        exit(0)
    case .remove:
        guard let unlinkSetting = analyzeUnlinkSettings() else {
            return
        }
        let targetName = argument.actionTarget
        let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
        let parents = paths
            .filter({ $0.contains("Component+\(targetName).swift") })
            .flatMap { $0.split(separator: "/") }
            .filter({ $0.contains("Component+\(targetName).swift") })
            .compactMap { $0.split(separator: "+").first }
            .map { $0.dropLast("Component".count) }
            .map { String($0) }
        parents.forEach { parentName in
            let resultUnlink = makeUnlink(targetName: targetName, parentName: parentName, unlinkSetting: unlinkSetting).run()
            showResult(resultUnlink)
        }
        let resultDeleteRIB = makeDeleteRIBCommand(argument: argument).run()
        showResult(resultDeleteRIB)
        exit(0)
    default:
        let result = HelpCommand().run()
        showResult(result)
        exit(0)
    }
}

// MARK: - Convenient methods
func showResult(_ result: Result) {
    switch result {
    case let .success(message):
        print(message)
    case let .failure(error):
        print(error.message.red)
        print("\nRIBsCodeGen operation failed. Check the above error logs.".red)
        print("")
        exit(Int32(error.code))
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

// MARK: - Analyze methods
func analyzeArguments(commandLineArguments: [String]) -> Argument? {
    guard let firstArgumentString = commandLineArguments.first else {
        print("Set action for first argument.".red.bold)
        return nil
    }
    let commandLineArgumentsLackOfFirst = commandLineArguments.dropFirst()
    let secondArgumentString = commandLineArgumentsLackOfFirst.first

    let action = Action(name: firstArgumentString, target: secondArgumentString)

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

    return Argument(action: action, options: otherArguments)
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

func analyzeRenameSettings() -> RenameSetting? {
    guard let settingFilePath = Path.current.glob(".ribscodegen_rename").first else {
        print("Not found setting file, add .ribscodegen_rename at current directory".red.bold)
        return nil
    }
    
    let settingFile: String? = try? settingFilePath.read()
    guard let settingFileString = settingFile else {
        print("Failed to read .ribscodegen_rename.".red.bold)
        return nil
    }
    
    let decoder = YAMLDecoder()
    do {
        return try decoder.decode(RenameSetting.self, from: settingFileString)
    } catch {
        print("Failed to decode .ribscodegen_rename. Check the setting values.".red.bold)
        return nil
    }
}

func analyzeUnlinkSettings() -> UnlinkSetting? {
    guard let settingFilePath = Path.current.glob(".ribscodegen_unlink").first else {
        print("Not found setting file, add .ribscodegen_unlink at current directory".red.bold)
        return nil
    }
    
    let settingFile: String? = try? settingFilePath.read()
    guard let settingFileString = settingFile else {
        print("Failed to read .ribscodegen_unlink.".red.bold)
        return nil
    }
    
    let decoder = YAMLDecoder()
    do {
        return try decoder.decode(UnlinkSetting.self, from: settingFileString)
    } catch {
        print("Failed to decode .ribscodegen_unlink. Check the setting values.".red.bold)
        return nil
    }
}

// MARK: - Make command methods
func makeCreateRIBCommand(argument: Argument) -> Command {
    let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
    return CreateRIBCommand(paths: paths,
                            setting: setting,
                            target: argument.actionTarget,
                            isOwnsView: !argument.noView)
}

func makeCreateRIBCommand(edge: Edge) -> Command {
    let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
    return CreateRIBCommand(paths: paths,
                            setting: setting,
                            target: edge.target,
                            isOwnsView: edge.isOwnsView)
}

func makeCreateComponentExtension(argument: Argument) -> Command {
    let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
    return CreateComponentExtension(paths: paths,
                                    setting: setting,
                                    parent: argument.parent,
                                    child: argument.actionTarget)
}

func makeCreateComponentExtension(edge: Edge) -> Command {
    let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
    return CreateComponentExtension(paths: paths,
                                    setting: setting,
                                    parent: edge.parent,
                                    child: edge.target)
}

func makeDependencyCommand(argument: Argument) -> Command {
    let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
    return DependencyCommand(paths: paths,
                             parent: argument.parent,
                             child: argument.actionTarget)
}

func makeDependencyCommand(edge: Edge) -> Command {
    let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
    return DependencyCommand(paths: paths,
                             parent: edge.parent,
                             child: edge.target)
}

func makeEdges(argument: Argument) -> [Edge] {
    guard let treePath = Path.current.glob(argument.actionTarget).first else {
        fatalError("Needs to add markdown file path for second argument.".red.bold)
    }

    guard let treeString: String = try? treePath.read() else {
        fatalError("Failed to read file: \(treePath)".red.bold)
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

    return edges.reversed()
}

func makeRenameCommand(renameSetting: RenameSetting, currentName: String, newName: String) -> Command {
    let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
    return RenameCommand(paths: paths, renameSetting: renameSetting, currentName: currentName, newName: newName)
}

func makeUnlink(targetName: String, parentName: String, unlinkSetting: UnlinkSetting) -> Command {
    let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
    return UnlinkCommand(
        paths: paths,
        targetName: targetName,
        parentName: parentName,
        unlinkSetting: unlinkSetting
    )
}

func makeDeleteRIBCommand(argument: Argument) -> Command {
    let paths = allSwiftSourcePaths(directoryPath: setting.targetDirectory)
    return DeleteRIBCommand(
        paths: paths,
        targetName: argument.actionTarget
    )
}

func validateBuilderIsNeedle(builderFilePath: String) -> Bool {
    var ribName = builderFilePath.lastElementSplittedBySlash
    ribName.removeLast("Builder.swift".count)

    let builderFile = File(path: builderFilePath)!
    let builderFileStructure = try! Structure(file: builderFile)
    let builderClasses = builderFileStructure.dictionary.getSubStructures().filterByKeyKind(.class)

    return builderClasses.filterByKeyName("\(ribName)Component").first != nil
}

main()
