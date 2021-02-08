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
        
        guard let parentInteractorPath = paths.filter({ $0.contains(parent + "Interactor.swift") }).first else {
            fatalError("\(parent)Interactor.swift が見つかりません。")
        }

        guard let parentRouterPath = paths.filter({ $0.contains(parent + "Router.swift") }).first else {
            fatalError("\(parent)Router.swift が見つかりません。")
        }

        guard let parentBuilderPath = paths.filter({ $0.contains(parent + "Builder.swift") }).first else {
            fatalError("\(parent)Builder.swift が見つかりません。")
        }

        guard let childInteractorPath = paths.filter({ $0.contains(child + "Interactor.swift") }).first else {
            fatalError("\(child)Interactor.swift が見つかりません。")
        }

        guard let childRouterPath = paths.filter({ $0.contains(child + "Router.swift") }).first else {
            fatalError("\(child)Router.swift が見つかりません。")
        }

        guard let childBuilderPath = paths.filter({ $0.contains(child + "Builder.swift") }).first else {
            fatalError("\(child)Builder.swift が見つかりません。")
        }

        self.parentInteractorPath = parentInteractorPath
        self.parentRouterPath = parentRouterPath
        self.parentBuilderPath = parentBuilderPath
        self.childInteractorPath = childInteractorPath
        self.childRouterPath = childRouterPath
        self.childBuilderPath = childBuilderPath
    }
    
    func run() -> Result {
        resolveDependencyForRouter()
        resolveDependencyForBuilder()
        return .success(message: "dependency completed")
    }
}

// MARK: - Run
private extension DependencyCommand {
    func resolveDependencyForRouter() {
        addChildListenerIfNeeded(parentRouterPath: parentRouterPath)

        if !hasChildBuilder(parentRouterPath: parentRouterPath) {
            addChildBuilderProperty(parentRouterPath: parentRouterPath)
            addChildBuilderArgument(parentRouterPath: parentRouterPath)
            addChildBuilderInitialize(parentRouterPath: parentRouterPath)
            removeRouterInitializeOverrideAttribute(parentRouterPath: parentRouterPath)
        }

        do {
            let formattedText = try Formatter.format(path: parentRouterPath)
            write(text: formattedText, toPath: parentRouterPath)
        } catch {
            print("Failed to format file: \(parentRouterPath)".red.bold, error)
        }
    }

    func resolveDependencyForBuilder() {
        addChildDependency(parentBuilderPath: parentBuilderPath)
        addChildBuilderInitialize(parentBuilderPath: parentBuilderPath)
        addChildBuilderToRouterInit(parentBuilderPath: parentBuilderPath)

        do {
            let formattedText = try Formatter.format(path: parentBuilderPath)
            write(text: formattedText, toPath: parentBuilderPath)
        } catch {
            print("Failed to format file: \(parentBuilderPath)".red.bold, error)
        }
    }
}

// MARK: - Private methods for Router
private extension DependencyCommand {
    func addChildListenerIfNeeded(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)

        let interactables = parentRouterFileStructure.dictionary
            .getSubStructures()
            .filterByKeyKind(.protocol)
            .filterByKeyName("\(parent)Interactable")

        guard let interactable = interactables.first else {
            print("Not found: \(parent)Interactable".red.bold)
            return
        }

        let inheritedTypes = interactable.getInheritedTypes()
        let isConformsToChildListener = !inheritedTypes.filterByKeyName("\(child)Listener").isEmpty
        let insertPosition = interactable.getInnerLeadingPosition() - 2 // TODO: 準拠している Protocol の最後の末尾を起点にしたほうがよい

        do {
            guard !isConformsToChildListener else {
                print("Skip to add child listener to parent router.")
                return
            }
            // 親RouterのInteractableを、ChildListener に準拠させる
            var text = try String(contentsOfFile: parentRouterFile.path!, encoding: .utf8)
            let insertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)
            text.insert(contentsOf: ",\n \(child)Listener", at: insertIndex)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print("Failed to read file: \(parentRouterFile.path ?? "")".red.bold, error)
        }
    }

    func hasChildBuilder(parentRouterPath: String) -> Bool {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractByKeyName("\(parent)Router")
        let varInstanceArray = parentRouterStructure.getSubStructures().filterByKeyKind(.varInstance)
        let childBuildableInstanceArray = varInstanceArray.filterByKeyTypeName("\(child)Buildable")
        let hasChildBuilder = !childBuildableInstanceArray.isEmpty
        return hasChildBuilder
    }

    func addChildBuilderProperty(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractByKeyName("\(parent)Router")
        let initLeadingPosition = parentRouterStructure.getInnerLeadingPosition()

        do {
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)
            let propertyInsertIndex = text.utf8.index(text.startIndex, offsetBy: initLeadingPosition)
            text.insert(contentsOf: "\n\nprivate let \(child.lowercasedFirstLetter())Builder: \(child)Buildable", at: propertyInsertIndex)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print("Failed to read file: \(parentRouterFile.path ?? "")".red.bold, error)
        }
    }

    func addChildBuilderArgument(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractByKeyName("\(parent)Router")
        let initStructure = parentRouterStructure.getSubStructures().extractByKeyName("init")
        let initArguments = initStructure.getSubStructures().filterByKeyKind(.varParameter)

        var initArgumentEndPosition = 0

        guard let lastArgumentLength = initArguments.last?["key.length"] as? Int64,
              let lastArgumentOffset = initArguments.last?["key.offset"] as? Int64 else {
            return
        }
        initArgumentEndPosition = Int(lastArgumentOffset + lastArgumentLength)

        do {
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)

            let argumentInsertIndex = text.utf8.index(text.startIndex, offsetBy: initArgumentEndPosition)
            text.insert(contentsOf: ",\n \(child.lowercasedFirstLetter())Builder: \(child)Buildable", at: argumentInsertIndex)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print("Failed to read file: \(parentRouterFile.path ?? "")".red.bold, error)
        }
    }

    func removeRouterInitializeOverrideAttribute(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractByKeyName("\(parent)Router")
        let initStructure = parentRouterStructure.getSubStructures().extractByKeyName("init")
        let attributes = initStructure.getAttributes()
        let shouldRemoveOverrideAttribute = !attributes.filterByAttribute(.override).isEmpty

        do {
            guard shouldRemoveOverrideAttribute else {
                print("Skip to remove override attribute from init function.")
                return
            }
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)
            text = text.replacingOccurrences(of: "override init", with: "init")

            write(text: text, toPath: parentRouterPath)
        } catch {
            print("Failed to read file: \(parentRouterFile.path ?? "")".red.bold, error)
        }
    }

    func addChildBuilderInitialize(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractByKeyName("\(parent)Router")
        let initStructure = parentRouterStructure.getSubStructures().extractByKeyName("init")
        let superInitStructure = initStructure.getSubStructures().extractByKeyName("super.init")
        let superInitStartPosition = superInitStructure.getOuterLeadingPosition()

        do {
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)

            let builderInitializeInsertIndex = text.utf8.index(text.startIndex, offsetBy: superInitStartPosition)
            text.insert(contentsOf: "self.\(child.lowercasedFirstLetter())Builder = \(child.lowercasedFirstLetter())Builder\n", at: builderInitializeInsertIndex)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print("Failed to read file: \(parentRouterFile.path ?? "")".red.bold, error)
        }
    }
}

// MARK: - Private methods for Builder
private extension DependencyCommand {
    func addChildDependency(parentBuilderPath: String) {
        let parentBuilderFile = File(path: parentBuilderPath)!
        let parentBuilderFileStructure = try! Structure(file: parentBuilderFile)

        let parentBuilderProtocols = parentBuilderFileStructure.dictionary
            .getSubStructures()
            .filterByKeyKind(.protocol)

        guard let parentBuilderDependency = parentBuilderProtocols.filterByKeyName("\(parent)Dependency").first else {
            print("Not found protocol \(parent)Dependency.".red.bold)
            return
        }

        let shouldAddDependency = parentBuilderDependency.getInheritedTypes().filterByKeyName("\(parent)Dependency\(child)").isEmpty

        guard shouldAddDependency else {
            print("Skip to add \(parent)Dependency\(child).")
            return
        }

        let insertPosition = parentBuilderDependency.getInnerLeadingPosition() - 2// TODO: 準拠している Protocol の最後の末尾を起点にしたほうがよい

        do {
            var text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)
            let dependencyInsertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)
            text.insert(contentsOf: ",\n\("\(parent)Dependency\(child)")", at: dependencyInsertIndex)
            write(text: text, toPath: parentBuilderPath)
        } catch {
            print("Failed to read file: \(parentBuilderPath)".red.bold, error)
        }
    }

    func addChildBuilderInitialize(parentBuilderPath: String) {
        let parentBuilderFile = File(path: parentBuilderPath)!
        let parentBuilderFileStructure = try! Structure(file: parentBuilderFile)

        let parentBuilderClasses = parentBuilderFileStructure.dictionary
            .getSubStructures()
            .filterByKeyKind(.class)

        guard let parentBuilderClass = parentBuilderClasses.filterByKeyName("\(parent)Builder").first else {
            print("Not found \(parent)Builder class.".red.bold)
            return
        }

        let initStructure = parentBuilderClass.getSubStructures().extractByKeyName("build")
        let childBuilderInitializers = initStructure.getSubStructures().filterByKeyKind(.call).filterByKeyName("\(child)Builder")
        guard childBuilderInitializers.isEmpty else {
            print("Skip to add \(child)Builder initialize.")
            return
        }

        let parentRouter = initStructure.getSubStructures().filterByKeyKind(.call).extractByKeyName("\(parent)Router")

        let insertPosition = parentRouter.getOuterLeadingPosition() - "return ".count

        do {
            var text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)
            let dependencyInsertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)
            text.insert(contentsOf: "let \(child.lowercasedFirstLetter())Builder = \(child)Builder(dependency: component)\n", at: dependencyInsertIndex)
            write(text: text, toPath: parentBuilderPath)
        } catch {
            print("Failed to read file: \(parentBuilderPath)".red.bold, error)
        }
    }

    func addChildBuilderToRouterInit(parentBuilderPath: String) {
        let parentBuilderFile = File(path: parentBuilderPath)!
        let parentBuilderFileStructure = try! Structure(file: parentBuilderFile)

        let parentBuilderClasses = parentBuilderFileStructure.dictionary
            .getSubStructures()
            .filterByKeyKind(.class)

        guard let parentBuilderClass = parentBuilderClasses.filterByKeyName("\(parent)Builder").first else {
            print("Not found \(parent)Builder class.".red.bold)
            return
        }

        let initStructure = parentBuilderClass.getSubStructures().extractByKeyName("build")
        let parentRouter = initStructure.getSubStructures().filterByKeyKind(.call).extractByKeyName("\(parent)Router")

        let childBuilderArguments = parentRouter.getSubStructures().filterByKeyKind(.argument).filterByKeyName("\(child.lowercasedFirstLetter())Builder")
        guard childBuilderArguments.isEmpty else {
            print("Skip to add \(child)Builder for Router initialize argument.")
            return
        }

        let insertPosition = parentRouter.getInnerTrailingPosition()

        do {
            var text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)
            let dependencyInsertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)
            text.insert(contentsOf: ", \n\(child.lowercasedFirstLetter())Builder: \(child.lowercasedFirstLetter())Builder", at: dependencyInsertIndex)
            write(text: text, toPath: parentBuilderPath)
        } catch {
            print("Failed to read file: \(parentBuilderPath)".red.bold, error)
        }
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
