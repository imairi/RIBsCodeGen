//
// Created by 今入　庸介 on 2022/05/09.
//

import Foundation
import SourceKittenFramework
import Rainbow
import PathKit

private enum RenameProtocolType: CaseIterable {
    case routing, listener, presentable
    
    var suffix: String {
        switch self {
        case .routing:
            return "Routing"
        case .listener:
            return "Listener"
        case .presentable:
            return "Presentable"
        }
    }
}

private enum RenameVariableType: CaseIterable {
    case routing, listener, presentableListener
    
    var suffix: String {
        switch self {
        case .routing:
            return "Routing?"
        case .listener:
            return "Listener?"
        case .presentableListener:
            return "PresentableListener?"
        }
    }
}

private enum RenameInheritedType: CaseIterable {
    case presentableInteractor, interactable, presentableListener
}

final class RenameCommand: Command {
    private let paths: [String]
    private let currentName: String
    private let newName: String
    
    private let interactorPath: String
    private let routerPath: String
    private let builderPath: String
    private let viewControllerPath: String?
    private let currentDependenciesPath: [String]
    private let parents: [String]
    
    private var replacedFilePaths = [String]()
    
    init(paths: [String], currentName: String, newName: String) {
        self.paths = paths
        self.currentName = currentName
        self.newName = newName
        
        guard !paths.filter({ $0.contains("/" + currentName + "/") }).isEmpty else {
            fatalError("Not found \(currentName) RIB directory.Might be wrong the target name.".red.bold)
            return
        }
        
        guard let interactorPath = paths.filter({ $0.contains("/" + currentName + "Interactor.swift") }).first else {
            fatalError("Not found \(currentName)Interactor.swift".red.bold)
        }
        
        guard let routerPath = paths.filter({ $0.contains("/" + currentName + "Router.swift") }).first else {
            fatalError("Not found \(currentName)Router.swift".red.bold)
        }
        
        guard let builderPath = paths.filter({ $0.contains("/" + currentName + "Builder.swift") }).first else {
            fatalError("Not found \(currentName)Builder.swift".red.bold)
        }
        
        self.interactorPath = interactorPath
        self.routerPath = routerPath
        self.builderPath = builderPath
        viewControllerPath = paths.filter({ $0.contains("/" + currentName + "ViewController.swift") }).first
        currentDependenciesPath = paths.filter({ $0.contains("/" + currentName + "/Dependencies/") })
    
        parents = paths
            .filter({ $0.contains("Component+\(currentName).swift") })
            .flatMap { $0.split(separator: "/") }
            .filter({ $0.contains("Component+\(currentName).swift") })
            .compactMap { $0.split(separator: "+").first }
            .map { $0.dropLast("Component".count) }
            .map { String($0) }
    }
    
    func run() -> Result {
        print("\nStart renaming ".bold + currentName.applyingBackgroundColor(.magenta).bold + " to ".bold + newName.applyingBackgroundColor(.blue).bold + ".".bold)
    
        var result: Result?
    
        print("\n\tStart renaming codes for related files.".bold)
        do {
            try renameForInteractor()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target Interactor."))
        }
    
        do {
            try renameForRouter()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target Router."))
        }
    
        do {
            try renameForBuilder()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target Builder."))
        }
    
        do {
            try renameForViewController()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target ViewController."))
        }
    
        do {
            try renameForDependencies()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target Dependencies."))
        }
    
        do {
            try renameForParentsInteractor()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target parent Interactor."))
        }
    
        do {
            try renameForParentsRouter()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target parent Router."))
        }
    
        do {
            try renameForParentsBuilder()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target parent Builder."))
        }
    
        do {
            try renameForParentsComponentExtensions()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target parent Component Extensions."))
        }
        
        do {
            try formatAllReplacedFiles()
        } catch {
            result = .failure(error: .failedFormat)
        }
    
        do {
            try renameDirectoriesAndFiles()
        } catch {
            result = .failure(error: .failedFormat)
        }
        
        return result ?? .success(message: "\nSuccessfully finished renaming ".green.bold + currentName.applyingBackgroundColor(.magenta).green.bold + " to ".green.bold + newName.applyingBackgroundColor(.blue).green.bold + " for related files.".green.bold)
    }
}

// MARK: - Run
private extension RenameCommand {
    func renameForInteractor() throws {
        print("\t\trename for \(interactorPath.lastElementSplittedBySlash)")
        let text = try String.init(contentsOfFile: interactorPath, encoding: .utf8)
        let replacedText = text
            .replacingOccurrences(of: "\(currentName)Interactor.swift", with: "\(newName)Interactor.swift")
            .replacingOccurrences(of: "protocol \(currentName)Routing:", with: "protocol \(newName)Routing:")
            .replacingOccurrences(of: "protocol \(currentName)Presentable:", with: "protocol \(newName)Presentable:")
            .replacingOccurrences(of: "protocol \(currentName)Listener:", with: "protocol \(newName)Listener:")
            .replacingOccurrences(of: "class \(currentName)Interactor", with: "class \(newName)Interactor")
            .replacingOccurrences(of: "extension \(currentName)Interactor", with: "extension \(newName)Interactor")
            .replacingOccurrences(of: "PresentableInteractor<\(currentName)Presentable>", with: "PresentableInteractor<\(newName)Presentable>")
            .replacingOccurrences(of: "\(currentName)Interactable", with: "\(newName)Interactable")
            .replacingOccurrences(of: "\(currentName)PresentableListener", with: "\(newName)PresentableListener")
            .replacingOccurrences(of: "router: \(currentName)Routing?", with: "router: \(newName)Routing?")
            .replacingOccurrences(of: "listener: \(currentName)Listener?", with: "listener: \(newName)Listener?")
            .replacingOccurrences(of: "presenter: \(currentName)Presentable", with: "presenter: \(newName)Presentable")
            .replacingOccurrences(of: "// MARK: - \(currentName)PresentableListener", with: "// MARK: - \(newName)PresentableListener")
        try Path(interactorPath).write(replacedText)
        replacedFilePaths.append(interactorPath)
    }
    
    func renameForRouter() throws {
        print("\t\trename for \(routerPath.lastElementSplittedBySlash)")
        let text = try String.init(contentsOfFile: routerPath, encoding: .utf8)
        let replacedText = text
            .replacingOccurrences(of: "\(currentName)Router.swift", with: "\(newName)Router.swift")
            .replacingOccurrences(of: "protocol \(currentName)Interactable:", with: "protocol \(newName)Interactable:")
            .replacingOccurrences(of: "protocol \(currentName)ViewControllable:", with: "protocol \(newName)ViewControllable:")
            .replacingOccurrences(of: "class \(currentName)Router:", with: "class \(newName)Router:")
            .replacingOccurrences(of: "extension \(currentName)Router", with: "extension \(newName)Router")
            .replacingOccurrences(of: "router: \(currentName)Routing?", with: "router: \(newName)Routing?")
            .replacingOccurrences(of: "listener: \(currentName)Listener?", with: "listener: \(newName)Listener?")
            .replacingOccurrences(of: "interactor: \(currentName)Interactable", with: "interactor: \(newName)Interactable")
            .replacingOccurrences(of: "viewController: \(currentName)ViewControllable", with: "viewController: \(newName)ViewControllable")
            .replacingOccurrences(of: "ViewableRouter<\(currentName)Interactable, \(currentName)ViewControllable>", with: "ViewableRouter<\(newName)Interactable, \(newName)ViewControllable>")
            .replacingOccurrences(of: ", \(currentName)Routing", with: ", \(newName)Routing")
            .replacingOccurrences(of: "Router<\(currentName)Interactable>", with: "Router<\(newName)Interactable>")
            .replacingOccurrences(of: "viewController: \(currentName)ViewControllable", with: "viewController: \(newName)ViewControllable")
            .replacingOccurrences(of: "// MARK: - \(currentName)Routing", with: "// MARK: - \(newName)Routing")
        try Path(routerPath).write(replacedText)
        replacedFilePaths.append(routerPath)
    }
    
    func renameForBuilder() throws {
        print("\t\trename for \(builderPath.lastElementSplittedBySlash)")
        let text = try String.init(contentsOfFile: builderPath, encoding: .utf8)
        let replacedText = text
            .replacingOccurrences(of: "\(currentName)Builder.swift", with: "\(newName)Builder.swift")
            .replacingOccurrences(of: "\(currentName)Buildable", with: "\(newName)Buildable")
            .replacingOccurrences(of: "class \(currentName)Builder:", with: "class \(newName)Builder:")
            .replacingOccurrences(of: "\(currentName)Dependency", with: "\(newName)Dependency")
            .replacingOccurrences(of: "\(currentName)Component", with: "\(newName)Component")
            .replacingOccurrences(of: "\(currentName)ViewController", with: "\(newName)ViewController")
            .replacingOccurrences(of: "\(currentName.lowercasedFirstLetter())ViewController", with: "\(newName.lowercasedFirstLetter())ViewController")
            .replacingOccurrences(of: "\(currentName)ViewControllable", with: "\(newName)ViewControllable")
            .replacingOccurrences(of: "\(currentName)Listener", with: "\(newName)Listener")
            .replacingOccurrences(of: "\(currentName)Routing", with: "\(newName)Routing")
            .replacingOccurrences(of: "\(currentName)Router", with: "\(newName)Router")
            .replacingOccurrences(of: "\(currentName)Interactor", with: "\(newName)Interactor")
        try Path(builderPath).write(replacedText)
        replacedFilePaths.append(builderPath)
    }
    
    func renameForViewController() throws {
        guard let viewControllerPath = viewControllerPath else {
            return
        }
        print("\t\trename for \(viewControllerPath.lastElementSplittedBySlash)")
        let text = try String.init(contentsOfFile: viewControllerPath, encoding: .utf8)
        let replacedText = text
            .replacingOccurrences(of: "\(currentName)ViewController.swift", with: "\(newName)ViewController.swift")
            .replacingOccurrences(of: "\(currentName)Presentable", with: "\(newName)Presentable")
            .replacingOccurrences(of: "protocol \(currentName)PresentableListener", with: "protocol \(newName)PresentableListener")
            .replacingOccurrences(of: "class \(currentName)ViewController:", with: "class \(newName)ViewController:")
            .replacingOccurrences(of: "extension \(currentName)ViewController", with: "extension \(newName)ViewController")
            .replacingOccurrences(of: "\(currentName)ViewControllable", with: "\(newName)ViewControllable")
        try Path(viewControllerPath).write(replacedText)
        replacedFilePaths.append(viewControllerPath)
    }
    
    func renameForDependencies() throws {
        try currentDependenciesPath.forEach { dependencyPath in
            print("\t\trename for \(dependencyPath.lastElementSplittedBySlash)")
            let text = try String.init(contentsOfFile: dependencyPath, encoding: .utf8)
            let replacedText = text
                .replacingOccurrences(of: "protocol \(currentName)Dependency", with: "protocol \(newName)Dependency")
                .replacingOccurrences(of: "\(currentName)Component", with: "\(newName)Component")
                .replacingOccurrences(of: "scope of \(currentName) to provide for the", with: "scope of \(newName) to provide for the")
                .replacingOccurrences(of: " \(currentName.lowercasedFirstLetter())ViewController", with: " \(newName.lowercasedFirstLetter())ViewController")
            try Path(dependencyPath).write(replacedText)
            replacedFilePaths.append(dependencyPath)
        }
    }
    
    func renameForParentsInteractor() throws {
        try parents.forEach { parentName in
            guard let parentInteractorPath = paths.filter({ $0.contains("/" + parentName + "Interactor.swift") }).first else {
                fatalError("Not found \(parentName)Interactor.swift".red.bold)
            }
    
            print("\t\trename for \(parentInteractorPath.lastElementSplittedBySlash)")
            let text = try String.init(contentsOfFile: parentInteractorPath, encoding: .utf8)
            let replacedText = text
                .replacingOccurrences(of: "\(currentName)Listener", with: "\(newName)Listener")
                .replacingOccurrences(of: "routeTo\(currentName)", with: "routeTo\(newName)")
                .replacingOccurrences(of: "switchTo\(currentName)", with: "switchTo\(newName)")
                .replacingOccurrences(of: "detach\(currentName)", with: "detach\(newName)")
                .replacingOccurrences(of: "remove\(currentName)", with: "remove\(newName)")
                .replacingOccurrences(of: "deactivate\(currentName)", with: "deactivate\(newName)")
            try Path(parentInteractorPath).write(replacedText)
            replacedFilePaths.append(parentInteractorPath)
        }
    }
    
    func renameForParentsRouter() throws {
        try parents.forEach { parentName in
            guard let parentRouterPath = paths.filter({ $0.contains("/" + parentName + "Router.swift") }).first else {
                fatalError("Not found \(parentName)Router.swift".red.bold)
            }
    
            print("\t\trename for \(parentRouterPath.lastElementSplittedBySlash)")
            let text = try String.init(contentsOfFile: parentRouterPath, encoding: .utf8)
            let replacedText = text
                .replacingOccurrences(of: "\(currentName)Listener", with: "\(newName)Listener")
                .replacingOccurrences(of: "routeTo\(currentName)", with: "routeTo\(newName)")
                .replacingOccurrences(of: "switchTo\(currentName)", with: "switchTo\(newName)")
                .replacingOccurrences(of: "\(currentName.lowercasedFirstLetter())Builder: \(currentName)Buildable", with: "\(newName.lowercasedFirstLetter())Builder: \(newName)Buildable")
                .replacingOccurrences(of: "self.\(currentName.lowercasedFirstLetter())Builder = \(currentName.lowercasedFirstLetter())Builder", with: "self.\(newName.lowercasedFirstLetter())Builder = \(newName.lowercasedFirstLetter())Builder")
                .replacingOccurrences(of: "\(currentName.lowercasedFirstLetter())Builder.build", with: "\(newName.lowercasedFirstLetter())Builder.build")
                .replacingOccurrences(of: "is \(currentName)Routing", with: "is \(newName)Routing")
                .replacingOccurrences(of: " \(currentName)ViewControllable", with: " \(newName)ViewControllable")
                .replacingOccurrences(of: "detach\(currentName)(", with: "detach\(newName)(")
                .replacingOccurrences(of: "remove\(currentName)(", with: "remove\(newName)(")
            try Path(parentRouterPath).write(replacedText)
            replacedFilePaths.append(parentRouterPath)
        }
    }
    
    func renameForParentsBuilder() throws {
        try parents.forEach { parentName in
            guard let parentBuilderPath = paths.filter({ $0.contains("/" + parentName + "Builder.swift") }).first else {
                fatalError("Not found \(parentName)Builder.swift".red.bold)
            }
    
            print("\t\trename for \(parentBuilderPath.lastElementSplittedBySlash)")
            let text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)
            let replacedText = text
                .replacingOccurrences(of: "\(parentName)Dependency\(currentName)", with: "\(parentName)Dependency\(newName)")
                .replacingOccurrences(of: "\(currentName.lowercasedFirstLetter())Builder = \(currentName)Builder", with: "\(newName.lowercasedFirstLetter())Builder = \(newName)Builder")
                .replacingOccurrences(of: "\(currentName.lowercasedFirstLetter())Builder: \(currentName.lowercasedFirstLetter())Builder", with: "\(newName.lowercasedFirstLetter())Builder: \(newName.lowercasedFirstLetter())Builder")
            try Path(parentBuilderPath).write(replacedText)
            replacedFilePaths.append(parentBuilderPath)
        }
    }
    
    func renameForParentsComponentExtensions() throws {
        try parents.forEach { parentName in
            guard let componentExtensionPath = paths.filter({ $0.contains("\(parentName)/Dependencies/\(parentName)Component+\(currentName).swift") }).first else {
                fatalError("Not found \(parentName)Component+\(currentName).swift".red.bold)
            }
    
            print("\t\trename for \(componentExtensionPath.lastElementSplittedBySlash)")
            let text = try String.init(contentsOfFile: componentExtensionPath, encoding: .utf8)
            let replacedText = text
                .replacingOccurrences(of: "\(parentName)Component+\(currentName).swift", with: "\(parentName)Component+\(newName).swift")
                .replacingOccurrences(of: "scope of \(parentName) to provide for the \(currentName) scope.", with: "scope of \(parentName) to provide for the \(newName) scope.")
                .replacingOccurrences(of: "\(parentName)Dependency\(currentName)", with: "\(parentName)Dependency\(newName)")
                .replacingOccurrences(of: ": \(currentName)Dependency", with: ": \(newName)Dependency")
                .replacingOccurrences(of: "var \(currentName.lowercasedFirstLetter())ViewController: \(currentName)ViewControllable", with: "var \(newName.lowercasedFirstLetter())ViewController: \(newName)ViewControllable")
            try Path(componentExtensionPath).write(replacedText)
            replacedFilePaths.append(componentExtensionPath)
        }
    }
    
    func formatAllReplacedFiles() throws {
        print("\n\tStart format for all replaced files.".bold)
        try replacedFilePaths.forEach { replacedFilePath in
            print("\t\tformat for \(replacedFilePath.lastElementSplittedBySlash)")
            let formattedText = try Formatter.format(path: replacedFilePath)
            try Path(replacedFilePath).write(formattedText)
        }
    }
    
    func renameDirectoriesAndFiles() throws {
        print("\n\tStart renaming directories and files.".bold)
        let targetRIBDirectoryPath = Path(interactorPath).parent()
        guard targetRIBDirectoryPath.isDirectory else {
            print("\t\tFailed to detect target RIB directory path.".red.bold)
            return
        }
        
        let targetRIBDependenciesDirectoryPath = try Path(targetRIBDirectoryPath.description + "/Dependencies")
        guard targetRIBDependenciesDirectoryPath.isDirectory else {
            print("\t\tFailed to detect target RIB Dependencies directory path.".red.bold)
            return
        }
        
        let targetRIBDependencyPaths = try targetRIBDependenciesDirectoryPath.children().map { $0.description }.filter { $0.contains("\(currentName)Component+") }
        
        let newDirectoryPath = Path(targetRIBDirectoryPath.parent().description + "/\(newName)")
        try newDirectoryPath.mkdir()
        print("\t\tNew directory was created.")
        print("\t\t\t\(newDirectoryPath.relativePath)".lightBlack)
        
        let newInteractorPath = Path(newDirectoryPath.description + "/" + interactorPath.lastElementSplittedBySlash.replacingOccurrences(of: currentName, with: newName))
        try Path(interactorPath).move(newInteractorPath)
        print("\t\tInteractor file was renamed and moved to new directory.")
        print("\t\t\t\(newInteractorPath.relativePath)".lightBlack)
        
        let newRouterPath = Path(newDirectoryPath.description + "/" + routerPath.lastElementSplittedBySlash.replacingOccurrences(of: currentName, with: newName))
        try Path(routerPath).move(newRouterPath)
        print("\t\tRouter file was renamed and moved to new directory.")
        print("\t\t\t\(newRouterPath.relativePath)".lightBlack)
        
        let newBuilderPath = Path(newDirectoryPath.description + "/" + builderPath.lastElementSplittedBySlash.replacingOccurrences(of: currentName, with: newName))
        try Path(builderPath).move(newBuilderPath)
        print("\t\tBuilder file was renamed and moved to new directory.")
        print("\t\t\t\(newBuilderPath.relativePath)".lightBlack)
        
        if let viewControllerPath = viewControllerPath {
            let newViewControllerPath = Path(newDirectoryPath.description + "/" + viewControllerPath.lastElementSplittedBySlash.replacingOccurrences(of: currentName, with: newName))
            try Path(viewControllerPath).move(newViewControllerPath)
            print("\t\tViewController file was renamed and moved to new directory.")
            print("\t\t\t\(newViewControllerPath.relativePath)".lightBlack)
        }
    
        let newDependenciesDirectoryPath = Path(newDirectoryPath.description + "/Dependencies")
        try newDependenciesDirectoryPath.mkdir()
        print("\t\tNew directory was created.")
        print("\t\t\t\(newDirectoryPath.relativePath)".lightBlack)
        
        try targetRIBDependencyPaths.forEach { targetRIBDependencyPath in
            let newDependencyPath = Path(newDependenciesDirectoryPath.description + "/" + targetRIBDependencyPath.lastElementSplittedBySlash.replacingOccurrences(of: "\(currentName)Component+", with: "\(newName)Component+"))
            try Path(targetRIBDependencyPath).move(newDependencyPath)
            print("\t\tComponent Extension file was renamed and moved to new directory.")
            print("\t\t\t\(newDependencyPath.relativePath)".lightBlack)
        }
    
        try parents.forEach { parentName in
            guard let parentInteractorPath = paths.filter({ $0.contains("/" + parentName + "Interactor.swift") }).first else {
                fatalError("Not found \(parentName)Interactor.swift.".red.bold)
            }
            let parentRIBDirectoryPath = Path(parentInteractorPath).parent()
            guard parentRIBDirectoryPath.isDirectory else {
                print("Failed to detect target parent RIB \(parentName) directory path.".red.bold)
                return
            }
    
            let parentRIBDependenciesDirectoryPath = try Path(parentRIBDirectoryPath.description + "/Dependencies")
            guard parentRIBDependenciesDirectoryPath.isDirectory else {
                print("Failed to detect target parent RIB \(parentName) Dependencies directory path.".red.bold)
                return
            }
    
            let parentRIBDependencyPaths = try parentRIBDependenciesDirectoryPath.children().map { $0.description }.filter { $0.contains("Component+\(currentName).swift") }
            try parentRIBDependencyPaths.forEach { parentRIBDependencyPath in
                let newDependencyPath = Path(parentRIBDependenciesDirectoryPath.description + "/" + parentRIBDependencyPath.lastElementSplittedBySlash.replacingOccurrences(of: "Component+\(currentName).swift", with: "Component+\(newName).swift"))
                try Path(parentRIBDependencyPath).move(newDependencyPath)
                print("\t\tComponent Extension file was renamed and moved to new directory.")
                print("\t\t\t\(newDependencyPath.relativePath)".lightBlack)
            }
        }
        
    }
}

extension Dictionary {
    func prettyPrinted() {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) else {
            print("JSON Serialization error")
            return
        }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("JSON Encoding error")
            return
        }
        print(jsonString)
    }
}

extension Array {
    func prettyPrinted() {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) else {
            print("JSON Serialization error")
            return
        }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("JSON Encoding error")
            return
        }
        print(jsonString)
    }
}

private extension String {
    var lastElementSplittedBySlash: String {
        String(self.split(separator: "/").last ?? "")
    }
}

private extension Path {
    var relativePath: String {
        self.description.replacingOccurrences(of: ".*\(setting.targetDirectory)", with: setting.targetDirectory, options: .regularExpression)
    }
}

func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.standardInput = nil
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}
