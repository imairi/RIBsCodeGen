//
//  DependencyCommand.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation
import SourceKittenFramework
import Rainbow
import PathKit

struct DependencyCommand: Command {
    private let parent: String
    private let child: String

    private let parentInteractorPath: String
    private let parentRouterPath: String
    private let parentBuilderPath: String
    private let childInteractorPath: String
    private let childRouterPath: String
    private let childBuilderPath: String

    init(paths: [String], parent: String, child: String) {
        self.parent = parent
        self.child = child
        
        guard let parentInteractorPath = paths.filter({ $0.contains("/" + parent + "Interactor.swift") }).first else {
            fatalError("Not found \(parent)Interactor.swift".red.bold)
        }

        guard let parentRouterPath = paths.filter({ $0.contains("/" + parent + "Router.swift") }).first else {
            fatalError("Not found \(parent)Router.swift".red.bold)
        }

        guard let parentBuilderPath = paths.filter({ $0.contains("/" + parent + "Builder.swift") }).first else {
            fatalError("Not found \(parent)Builder.swift".red.bold)
        }

        guard let childInteractorPath = paths.filter({ $0.contains("/" + child + "Interactor.swift") }).first else {
            fatalError("Not found \(child)Interactor.swift".red.bold)
        }

        guard let childRouterPath = paths.filter({ $0.contains("/" + child + "Router.swift") }).first else {
            fatalError("Not found \(child)Router.swift".red.bold)
        }

        guard let childBuilderPath = paths.filter({ $0.contains("/" + child + "Builder.swift") }).first else {
            fatalError("Not found \(child)Builder.swift".red.bold)
        }

        self.parentInteractorPath = parentInteractorPath
        self.parentRouterPath = parentRouterPath
        self.parentBuilderPath = parentBuilderPath
        self.childInteractorPath = childInteractorPath
        self.childRouterPath = childRouterPath
        self.childBuilderPath = childBuilderPath
    }
    
    func run() -> Result {
        print("\nStart adding dependency and builder initialize".bold)

        print("Updating Router for dependency between \(parent) and \(child).")
        let resolveDependencyForRouterResult = resolveDependencyForRouter()
        switch resolveDependencyForRouterResult {
        case let .success(message):
            print("\(message)".green)
        case let .failure(error):
            return .failure(error: error)
        }

        print("Updating Builder for dependency between \(parent) and \(child).")
        let resolveDependencyForBuilderResult = resolveDependencyForBuilder()
        switch resolveDependencyForBuilderResult {
        case let .success(message):
            print("\(message)".green)
        case let .failure(error):
            return .failure(error: error)
        }

        return .success(message: "Successfully finished adding \(child) dependency and builder initialize to \(parent) Router/Builder.".green.bold)
    }
}

// MARK: - Run
private extension DependencyCommand {
    func resolveDependencyForRouter() -> Result {
        do {
            try addChildListenerIfNeeded(parentRouterPath: parentRouterPath)
        } catch {
            return .failure(error: .failedToAddChildListener)
        }

        if hasChildBuilderInRouter(parentRouterPath: parentRouterPath) {
            print("  Skip to add child Builder to parent Router.".yellow)
        } else {
            do {
                try addChildBuilderProperty(parentRouterPath: parentRouterPath)
                try addChildBuilderArgument(parentRouterPath: parentRouterPath)
                try addChildBuilderInitialize(parentRouterPath: parentRouterPath)
                try removeRouterInitializeOverrideAttribute(parentRouterPath: parentRouterPath)
            } catch {
                return .failure(error: .failedToAddChildListener)
            }
        }

        do {
            let formattedText = try Formatter.format(path: parentRouterPath)
            write(text: formattedText, toPath: parentRouterPath)
            return .success(message: "Resolve \(child) dependencies for \(parent) Router")
        } catch {
            return .failure(error: .failedFormat)
        }
    }

    func resolveDependencyForBuilder() -> Result {
        let childIsNeedle = validateBuilderIsNeedle(builderFilePath: childBuilderPath)

        do {
            if childIsNeedle {
                try addChildComponentInitialize(parentBuilderPath: parentBuilderPath)
            } else {
                try addChildDependency(parentBuilderPath: parentBuilderPath)
            }
            try addChildBuilderInitialize(parentBuilderPath: parentBuilderPath)
            try addChildBuilderToRouterInit(parentBuilderPath: parentBuilderPath)
        } catch {
            return .failure(error: .failedToAddChildBuilder)
        }

        do {
            let formattedText = try Formatter.format(path: parentBuilderPath)
            write(text: formattedText, toPath: parentBuilderPath)
            return .success(message: "Resolve \(child) dependencies for \(parent) Builder")
        } catch {
            return .failure(error: .failedFormat)
        }
    }
}

// MARK: - Private methods for Router
private extension DependencyCommand {
    func addChildListenerIfNeeded(parentRouterPath: String) throws {
        print("  Adding child listener to parent Interactable.")
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)

        let interactables = parentRouterFileStructure.dictionary
            .getSubStructures()
            .filterByKeyKind(.protocol)
            .filterByKeyName("\(parent)Interactable")

        guard let interactable = interactables.first else {
            print("Not found: \(parent)Interactable".red.bold)
            throw Error.failedToAddChildListener
        }

        let inheritedTypes = interactable.getInheritedTypes()
        let isConformsToChildListener = !inheritedTypes.filterByKeyName("\(child)Listener").isEmpty
        let insertPosition = interactable.getInnerLeadingPosition() - 2 // TODO: 準拠している Protocol の最後の末尾を起点にしたほうがよい

        guard !isConformsToChildListener else {
            print("  Skip to add child Listener to parent Router.".yellow)
            return
        }
        // 親RouterのInteractableを、ChildListener に準拠させる
        var text = try String(contentsOfFile: parentRouterFile.path!, encoding: .utf8)
        let insertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)
        text.insert(contentsOf: ",\n \(child)Listener", at: insertIndex)

        write(text: text, toPath: parentRouterPath)
    }

    func hasChildBuilderInRouter(parentRouterPath: String) -> Bool {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractDictionaryContainsKeyName("\(parent)Router")
        let varInstanceArray = parentRouterStructure.getSubStructures().filterByKeyKind(.varInstance)
        let childBuildableInstanceArray = varInstanceArray.filterByKeyTypeName("\(child)Buildable")
        let hasChildBuilder = !childBuildableInstanceArray.isEmpty
        return hasChildBuilder
    }

    func addChildBuilderProperty(parentRouterPath: String) throws {
        print("  Adding child builder declaration to parent Router.")
        let parentRouterFile = File(path: parentRouterPath)!
        let initializeLines = parentRouterFile.lines.filter { $0.content.contains("init") }

        guard let routerInitializeLine = initializeLines.filter({ $0.content.contains("\(parent)Interactable") }).first else {
            print("  Failed to find \(parent)Router initialize line.".red)
            return
        }

        let initLeadingPosition = routerInitializeLine.byteRange.location.value

        var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)
        let propertyInsertIndex = text.utf8.index(text.startIndex, offsetBy: initLeadingPosition)
        text.insert(contentsOf: "private let \(child.lowercasedFirstLetter())Builder: \(child)Buildable\n\n", at: propertyInsertIndex)

        write(text: text, toPath: parentRouterPath)
    }

    func addChildBuilderArgument(parentRouterPath: String) throws {
        print("  Adding child builder for Router initialize argument.")
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractDictionaryContainsKeyName("\(parent)Router")
        let initStructure = parentRouterStructure.getSubStructures().extractDictionaryContainsKeyName("init")
        let initArguments = initStructure.getSubStructures().filterByKeyKind(.varParameter)

        var initArgumentEndPosition = 0

        guard let lastArgumentLength = initArguments.last?["key.length"] as? Int64,
              let lastArgumentOffset = initArguments.last?["key.offset"] as? Int64 else {
            return
        }
        initArgumentEndPosition = Int(lastArgumentOffset + lastArgumentLength)

        var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)
        let argumentInsertIndex = text.utf8.index(text.startIndex, offsetBy: initArgumentEndPosition)
        text.insert(contentsOf: ",\n \(child.lowercasedFirstLetter())Builder: \(child)Buildable", at: argumentInsertIndex)

        write(text: text, toPath: parentRouterPath)
    }

    func addChildBuilderInitialize(parentRouterPath: String) throws {
        print("  Adding child builder initialize to parent Router.")
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractDictionaryContainsKeyName("\(parent)Router")
        let initStructure = parentRouterStructure.getSubStructures().extractDictionaryContainsKeyName("init")
        let superInitStructure = initStructure.getSubStructures().extractDictionaryContainsKeyName("super.init")
        let superInitStartPosition = superInitStructure.getOuterLeadingPosition()

        var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)

        let builderInitializeInsertIndex = text.utf8.index(text.startIndex, offsetBy: superInitStartPosition)
        text.insert(contentsOf: "self.\(child.lowercasedFirstLetter())Builder = \(child.lowercasedFirstLetter())Builder\n", at: builderInitializeInsertIndex)

        write(text: text, toPath: parentRouterPath)
    }

    func removeRouterInitializeOverrideAttribute(parentRouterPath: String) throws {
        print("  Removing override attribute from parent Router init function.")
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractDictionaryContainsKeyName("\(parent)Router")
        let initStructure = parentRouterStructure.getSubStructures().extractDictionaryContainsKeyName("init")
        let attributes = initStructure.getAttributes()
        let shouldRemoveOverrideAttribute = !attributes.filterByAttribute(.override).isEmpty

        guard shouldRemoveOverrideAttribute else {
            print("  Skip to remove override attribute from init function.".yellow)
            return
        }
        var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)
        text = text.replacingOccurrences(of: "override init", with: "init")

        write(text: text, toPath: parentRouterPath)
    }
}

// MARK: - Private methods for Builder
private extension DependencyCommand {
    func addChildDependency(parentBuilderPath: String) throws {
        print("  Adding child dependency to parent Dependency.")
        let parentBuilderFile = File(path: parentBuilderPath)!
        let parentBuilderFileStructure = try Structure(file: parentBuilderFile)

        let parentBuilderProtocols = parentBuilderFileStructure.dictionary
            .getSubStructures()
            .filterByKeyKind(.protocol)

        guard let parentBuilderDependency = parentBuilderProtocols.filterByKeyName("\(parent)Dependency").first else {
            print("Not found protocol \(parent)Dependency.".red.bold)
            throw Error.failedToAddChildBuilder
        }

        let shouldAddDependency = parentBuilderDependency.getInheritedTypes().filterByKeyName("\(parent)Dependency\(child)").isEmpty

        guard shouldAddDependency else {
            print("  Skip to add \(parent)Dependency\(child).".yellow)
            return
        }

        let insertPosition = parentBuilderDependency.getInnerLeadingPosition() - 2// TODO: 準拠している Protocol の最後の末尾を起点にしたほうがよい

        var text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)
        let dependencyInsertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)
        text.insert(contentsOf: ",\n\("\(parent)Dependency\(child)")", at: dependencyInsertIndex)
        write(text: text, toPath: parentBuilderPath)
    }

    func addChildComponentInitialize(parentBuilderPath: String) throws {
        print("  Adding child builder instance to parent Component.")
        let parentBuilderFile = File(path: parentBuilderPath)!
        let parentBuilderFileStructure = try Structure(file: parentBuilderFile)

        let parentBuilderClasses = parentBuilderFileStructure.dictionary
            .getSubStructures()
            .filterByKeyKind(.class)

        guard let parentComponentClass = parentBuilderClasses.filterByKeyName("\(parent)Component").first else {
            print("  Not found \(parent)Component class.".red.bold)
            throw Error.failedToAddChildBuilder
        }

        let insertPosition = parentComponentClass.getInnerTrailingPosition()

        var text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)

        let dependencyInsertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)

        let initArguments = try getChildComponentInitArguments(childBuilderPath: childBuilderPath)
        if initArguments.isEmpty {
            text.insert(contentsOf: "var \(child.lowercasedFirstLetter())Component: \(child)Component {\n\(child)Component(parent: self)\n}\n", at: dependencyInsertIndex)
        } else {
            let arguments = initArguments.map { "\($0.name): \($0.type)" }.joined(separator: ", ")
            let innerArguments = initArguments.map { $0.name }.map { "\($0): \($0)" }.joined(separator: ", ")
            text.insert(contentsOf: "func \(child.lowercasedFirstLetter())Component(\(arguments)) -> \(child)Component {\n\(child)Component(parent: self, \(innerArguments))\n}\n", at: dependencyInsertIndex)
        }

        write(text: text, toPath: parentBuilderPath)
    }

    func addChildBuilderInitialize(parentBuilderPath: String) throws {
        print("  Adding child builder initialize to parent Builder.")
        let parentBuilderFile = File(path: parentBuilderPath)!
        let parentBuilderFileStructure = try Structure(file: parentBuilderFile)

        let parentBuilderClasses = parentBuilderFileStructure.dictionary
            .getSubStructures()
            .filterByKeyKind(.class)

        guard let parentBuilderClass = parentBuilderClasses.filterByKeyName("\(parent)Builder").first else {
            print("  Not found \(parent)Builder class.".red.bold)
            throw Error.failedToAddChildBuilder
        }

        guard let buildMethod = parentBuilderClass.getSubStructures().filterByKeyName("build").first else {
            print("  Not found build method in \(parent)Builder class.".red.bold)
            throw Error.failedToAddChildBuilder
        }

        let childBuilderInitializeCalls = buildMethod.getSubStructures()
            .filterByKeyKind(.call)
            .filterByKeyName("\(child)Builder")
            .filter { childBuilderCall in
                let childBuilderInitializeCall = childBuilderCall
                    .getSubStructures()
                    .filterByKeyKind(.argument)
                    .filterByKeyName("dependency")
                return !childBuilderInitializeCall.isEmpty
            }

        guard childBuilderInitializeCalls.isEmpty else {
            print("  Skip to add child Builder initialize to parent Router.".yellow)
            return
        }

        guard let parentRouterInitializeLine = parentBuilderFile.lines.filter({ $0.content.contains("\(parent)Router") }).first else {
            print("  Failed to find \(parent)Router initialize line.".red)
            return
        }

        let insertPosition = parentRouterInitializeLine.byteRange.location.value

        var text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)

        let dependencyInsertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)

        let childIsNeedle = validateBuilderIsNeedle(builderFilePath: childBuilderPath)

        if childIsNeedle {
            let initArguments = try getChildComponentInitArguments(childBuilderPath: childBuilderPath)
            if initArguments.isEmpty {
                text.insert(contentsOf: "let \(child.lowercasedFirstLetter())Builder = \(child)Builder {\n component.\(child.lowercasedFirstLetter())Component\n}\n", at: dependencyInsertIndex)
            } else {
                let arguments = initArguments.map { $0.name }.joined(separator: ", ")
                let innerArguments = initArguments.map { $0.name }.map { "\($0): \($0)" }.joined(separator: ", ")
                text.insert(contentsOf: "let \(child.lowercasedFirstLetter())Builder = \(child)Builder { \(arguments) in\n component.\(child.lowercasedFirstLetter())Component(\(innerArguments))\n}\n", at: dependencyInsertIndex)
            }
        } else {
            text.insert(contentsOf: "let \(child.lowercasedFirstLetter())Builder = \(child)Builder(dependency: component)\n", at: dependencyInsertIndex)
        }
        write(text: text, toPath: parentBuilderPath)
    }

    func getChildComponentInitArguments(childBuilderPath: String) throws -> [(name: String, type: String)] {
        let childBuilderFile = File(path: childBuilderPath)!
        let childBuilderFileStructure = try Structure(file: childBuilderFile)
        let childBuilderClasses = childBuilderFileStructure.dictionary.getSubStructures().filterByKeyKind(.class)

        guard let childComponentClass = childBuilderClasses.filterByKeyName("\(child)Component").first else {
            print("  Not found \(child)Component class.".red.bold)
            throw Error.failedToAddChildBuilder
        }

        let initStructure = childComponentClass.getSubStructures().extractDictionaryContainsKeyName("init")
        let initArguments = initStructure.getSubStructures().filterByKeyKind(.varParameter)
        let childComponentArguments = initArguments
            .filter { $0.getKeyName() != "parent" }
            .map { (name: $0.getKeyName(), type: $0.getTypeName()) }

        return childComponentArguments
    }

    func addChildBuilderToRouterInit(parentBuilderPath: String) throws {
        print("  Adding child builder for parent Router initialize argument.")
        let parentBuilderFile = File(path: parentBuilderPath)!
        let parentBuilderFileStructure = try Structure(file: parentBuilderFile)

        let parentBuilderClasses = parentBuilderFileStructure.dictionary
            .getSubStructures()
            .filterByKeyKind(.class)

        guard let parentBuilderClass = parentBuilderClasses.filterByKeyName("\(parent)Builder").first else {
            print("  Not found \(parent)Builder class.".red.bold)
            throw Error.failedToAddChildBuilder
        }

        let isNeedle = validateBuilderIsNeedle(builderFilePath: parentBuilderPath)

        let initStructure = isNeedle ? parentBuilderClass.getSubStructures().extractDictionaryContainsKeyNameLast("build") :  parentBuilderClass.getSubStructures().extractDictionaryContainsKeyName("build")
        let parentRouter = initStructure.getSubStructures().filterByKeyKind(.call).extractDictionaryContainsKeyName("\(parent)Router")

        let childBuilderArguments = parentRouter.getSubStructures().filterByKeyKind(.argument).filterByKeyName("\(child.lowercasedFirstLetter())Builder")
        guard childBuilderArguments.isEmpty else {
            print("  Skip to add \(child)Builder for Router initialize argument.".yellow)
            return
        }

        let insertPosition = parentRouter.getInnerTrailingPosition()

        var text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)
        let dependencyInsertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)
        text.insert(contentsOf: ", \n\(child.lowercasedFirstLetter())Builder: \(child.lowercasedFirstLetter())Builder", at: dependencyInsertIndex)
        write(text: text, toPath: parentBuilderPath)
    }
}

// MARK: - execute methods
private extension DependencyCommand {
    func write(text: String, toPath path: String) {
        do {
            try Path(path).write(text)
        } catch {
            print("Failed to write file: \(path)", error)
        }
    }
}
