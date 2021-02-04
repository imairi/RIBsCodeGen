//
//  DependencyCommand.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//

import Foundation
import SourceKittenFramework
import Rainbow

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
        print("")
        print("Analyze \(paths.count) swift files.".applyingStyle(.bold))
        print("")
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

        // フォーマットして保存
        if let formattedText = format(path: parentRouterPath) {
            write(text: formattedText, toPath: parentRouterPath)
        }
    }

    func resolveDependencyForBuilder() {
        addChildDependency(parentBuilderPath: parentBuilderPath)
        addChildBuilderInitialize(parentBuilderPath: parentBuilderPath)
        addChildBuilderToRouterInit(parentBuilderPath: parentBuilderPath)

        // フォーマットして保存
        if let formattedText = format(path: parentBuilderPath) {
            write(text: formattedText, toPath: parentBuilderPath)
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
            print("\(parent)Interactable がありません。")
            return
        }

        let inheritedTypes = interactable.getInheritedTypes()
        let isConformsToChildListener = !inheritedTypes.filterByKeyName("\(child)Listener").isEmpty
        let insertPosition = interactable.getInnerLeadingPosition() - 2

        do {
            if !isConformsToChildListener { // 親RouterのInteractableを、ChildListener に準拠させる
                var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)
                let insertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)
                text.insert(contentsOf: ",\n \(child)Listener", at: insertIndex)

                write(text: text, toPath: parentRouterPath)
            }
        } catch {
            print(error)
        }
    }

    func hasChildBuilder(parentRouterPath: String) -> Bool {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractByKeyName("\(parent)Router")
        let varInstanceArray = parentRouterStructure.getSubStructures().filterByKeyKind(.varInstance)
        let childBuildableInstanceArray = varInstanceArray.filterByKeyTypeName("\(child)Buildable")
        let hasChildBuilder = !childBuildableInstanceArray.isEmpty
        print("\(parent)Router は \(child)Builder を保持しているか→", hasChildBuilder)
        return hasChildBuilder
    }

    func addChildBuilderProperty(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractByKeyName("\(parent)Router")
        let initLeadingPosition = parentRouterStructure.getInnerLeadingPosition()

        print("initLeadingPosition", initLeadingPosition)

        do {
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)
            let propertyInsertIndex = text.utf8.index(text.startIndex, offsetBy: initLeadingPosition)
            text.insert(contentsOf: "\n\nprivate let \(child.lowercasedFirstLetter())Builder: \(child)Buildable", at: propertyInsertIndex)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print(error)
        }
    }

    func addChildBuilderArgument(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractByKeyName("\(parent)Router")
        let initStructure = parentRouterStructure.getSubStructures().extractByKeyName("init")
        let initArguments = initStructure.getSubStructures().filterByKeyKind(.varParameter)

        var initArgumentEndPosition = 0

        print("Router 初期化メソッドの最後の引数", initArguments.last ?? "nil")
        guard let lastArgumentLength = initArguments.last?["key.length"] as? Int64,
              let lastArgumentOffset = initArguments.last?["key.offset"] as? Int64 else {
            return
        }
        initArgumentEndPosition = Int(lastArgumentOffset + lastArgumentLength)

        print("initArgumentEndPosition★", initArgumentEndPosition)

        do {
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)

            let argumentInsertIndex = text.utf8.index(text.startIndex, offsetBy: initArgumentEndPosition)
            text.insert(contentsOf: ",\n \(child.lowercasedFirstLetter())Builder: \(child)Buildable", at: argumentInsertIndex)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print(error)
        }
    }

    func removeRouterInitializeOverrideAttribute(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().extractByKeyName("\(parent)Router")
        let initStructure = parentRouterStructure.getSubStructures().extractByKeyName("init")
        let attributes = initStructure.getAttributes()
        let shouldRemoveOverrideAttribute = !attributes.filterByAttribute(.override).isEmpty

        print("shouldRemoveOverrideAttribute★", shouldRemoveOverrideAttribute)

        do {
            guard shouldRemoveOverrideAttribute else {
                print("override 消す処理をスキップ")
                return
            }
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)
            text = text.replacingOccurrences(of: "override init", with: "init")

            print(text)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print(error)
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
            print(error)
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
            print("protocol \(parent)Dependency が見つかりません。")
            return
        }

        let shouldAddDependency = parentBuilderDependency.getInheritedTypes().filterByKeyName("\(parent)Dependency\(child)").isEmpty

        guard shouldAddDependency else {
            print("\(parent)Dependency\(child)は存在する。")
            return
        }

        let insertPosition = parentBuilderDependency.getInnerTrailingPosition() - 3

        do {
            var text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)
            let dependencyInsertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)
            text.insert(contentsOf: ",\n\("\(parent)Dependency\(child)")", at: dependencyInsertIndex)
            write(text: text, toPath: parentBuilderPath)
        } catch {
            print(error)
        }
    }

    func addChildBuilderInitialize(parentBuilderPath: String) {
        let parentBuilderFile = File(path: parentBuilderPath)!
        let parentBuilderFileStructure = try! Structure(file: parentBuilderFile)

        let parentBuilderClasses = parentBuilderFileStructure.dictionary
            .getSubStructures()
            .filterByKeyKind(.class)

        guard let parentBuilderClass = parentBuilderClasses.filterByKeyName("\(parent)Builder").first else {
            print("class \(parent)Builder が見つかりません。")
            return
        }

        let initStructure = parentBuilderClass.getSubStructures().extractByKeyName("build")
        let parentRouter = initStructure.getSubStructures().filterByKeyKind(.call).extractByKeyName("\(parent)Router")

        let insertPosition = parentRouter.getOuterLeadingPosition() - "return ".count

        do {
            var text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)
            let dependencyInsertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)
            text.insert(contentsOf: "let \(child.lowercasedFirstLetter())Builder = \(child)Builder(component: dependency)\n", at: dependencyInsertIndex)
            write(text: text, toPath: parentBuilderPath)
        } catch {
            print(error)
        }
    }

    func addChildBuilderToRouterInit(parentBuilderPath: String) {
        let parentBuilderFile = File(path: parentBuilderPath)!
        let parentBuilderFileStructure = try! Structure(file: parentBuilderFile)

        let parentBuilderClasses = parentBuilderFileStructure.dictionary
            .getSubStructures()
            .filterByKeyKind(.class)

        guard let parentBuilderClass = parentBuilderClasses.filterByKeyName("\(parent)Builder").first else {
            print("class \(parent)Builder が見つかりません。")
            return
        }

        let initStructure = parentBuilderClass.getSubStructures().extractByKeyName("build")
        let parentRouter = initStructure.getSubStructures().filterByKeyKind(.call).extractByKeyName("\(parent)Router")

        let insertPosition = parentRouter.getInnerTrailingPosition()

        do {
            var text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)
            let dependencyInsertIndex = text.utf8.index(text.startIndex, offsetBy: insertPosition)
            text.insert(contentsOf: ", \n\(child.lowercasedFirstLetter())Builder: \(child.lowercasedFirstLetter())Builder", at: dependencyInsertIndex)
            write(text: text, toPath: parentBuilderPath)
        } catch {
            print(error)
        }
    }
}

// MARK: - execute methods
private extension DependencyCommand {
    func write(text: String, toPath path: String) {
        do {
            print(text)
            print("... 書き込み中 ...")
//            try text.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
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
