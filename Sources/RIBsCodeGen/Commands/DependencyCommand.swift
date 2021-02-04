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

    private var structures: [Structure]?
    private let parent: String
    private let child: String

    init(paths: [String], parent: String, child: String) {
        print("")
        print("Analyze \(paths.count) swift files.".applyingStyle(.bold))
        print("")
        self.parent = parent
        self.child = child
        
        var parentInteractorPath: String?
        paths.forEach { string in
            if string.contains(parent + "Interactor.swift") {
                parentInteractorPath = string
            }
        }
        var parentRouterPath: String?
        paths.forEach { string in
            if string.contains(parent + "Router.swift") {
                parentRouterPath = string
            }
        }
        var parentBuilderPath: String?
        paths.forEach { string in
            if string.contains(parent + "Builder.swift") {
                parentBuilderPath = string
            }
        }
        var childInteractorPath: String?
        paths.forEach { string in
            if string.contains(child + "Interactor.swift") {
                childInteractorPath = string
            }
        }
        var childRouterPath: String?
        paths.forEach { string in
            if string.contains(child + "Router.swift") {
                childRouterPath = string
            }
        }
        var childBuilderPath: String?
        paths.forEach { string in
            if string.contains(child + "Builder.swift") {
                childBuilderPath = string
            }
        }
        print(parentInteractorPath ?? "nil")
        print(parentRouterPath ?? "nil")
        print(parentBuilderPath ?? "nil")
        print(childInteractorPath ?? "nil")
        print(childRouterPath ?? "nil")
        print(childBuilderPath ?? "nil")
        structures = nil

        addChildListenerIfNeeded(parentRouterPath: parentRouterPath!)

        if !hasChildBuilder(parentRouterPath: parentRouterPath!) {
            addChildBuilderProperty(parentRouterPath: parentRouterPath!)
            addChildBuilderArgument(parentRouterPath: parentRouterPath!)
            addChildBuilderInitialize(parentRouterPath: parentRouterPath!)
            removeRouterInitializeOverrideAttribute(parentRouterPath: parentRouterPath!)
        }

        // フォーマットして保存
        if let formattedText = format(path: parentRouterPath!) {
            write(text: formattedText, toPath: parentRouterPath!)
        }
    }
    
    func run() -> Result {
        return .success(message: "dependency completed")
    }

    func addChildListenerIfNeeded(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)
//        print(parentRouterStructure)

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
//        print(parentRouterStructure)

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
//        print(parentRouterStructure)

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
        print(parentRouterFileStructure.dictionary.bridge())

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
        print(parentRouterFileStructure.dictionary.bridge())

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
//        print(parentRouterFileStructure)

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

// MARK: - execute
extension DependencyCommand {
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
