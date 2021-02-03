//
//  DependencyCommand.swift
//  RIBshokunin
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
        }

//        let parentRouterFile = File(path: parentRouterPath!)!
//        print("before", parentRouterFile.contents)
//        let a = try! parentRouterFile.format(trimmingTrailingWhitespace: true, useTabs: true, indentWidth: 4)
//        print("after", a)
    }
    
    func run() -> Result {
        return .success(message: "dependency completed")
    }

    func addChildListenerIfNeeded(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterStructure = try! Structure(file: parentRouterFile)
//        print(parentRouterStructure)

        // key.substructure はソースコードの class, protocol などの一塊の集まり。
        let substructures = getSubStructures(from: parentRouterStructure.dictionary)

        var isConformsToChild = false
        var insertPosition = 0

        for substructure in substructures {
            let kind = getDeclarationKind(from: substructure)
            let keyName = getKeyName(from: substructure)

            // Interactable に ChildListener を付与するかどうかの判定
            if kind == .some(.protocol) , keyName == "\(parent)Interactable" {
                print("Interactable 準拠しているものを確認する")
                if let inheritedTypes = substructure["key.inheritedtypes"] as? [[String: SourceKitRepresentable]] {
                    for inheritedType in inheritedTypes {
                        guard let inheritedTypeName = inheritedType["key.name"] as? String else {
                            continue
                        }
                        print("inheritedTypeName: \(inheritedTypeName)") // 準拠している Protocol 一覧
                        if inheritedTypeName.contains(child + "Listener") {
                            isConformsToChild = true
                        }
                    }
                }
                print("\(parent) は \(child) に準拠しているか→", isConformsToChild)

                if let elements = substructure["key.elements"] as? [[String: SourceKitRepresentable]],
                   let lastElement = elements.last {
                    guard let keyLength = lastElement["key.length"] as? Int64,
                          let keyOffset = lastElement["key.offset"] as? Int64 else {
                        continue
                    }

                    insertPosition = Int(keyOffset + keyLength) // ファイルの最初からこの数の箇所に挿入する
                    print("insertPosition:", insertPosition)
                }
            }
        }

        do {
            if !isConformsToChild { // 親RouterのInteractableを、ChildListener に準拠させる
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

        let parentRouterStructures = getStructures(from: parentRouterFileStructure,
                                                  targetKind: .class,
                                                  targetKeyName: "\(parent)Router")

        var hasChildBuilder = false

        for parentRouterStructure in parentRouterStructures {
            guard let kind = getDeclarationKind(from: parentRouterStructure) else {
                continue
            }

            // var instance のみを取り出す
            guard [.varInstance].contains(kind) else {
                continue
            }

            let keyName = getKeyName(from: parentRouterStructure)
            guard let keyTypeName = parentRouterStructure["key.typename"] as? String else {
                continue
            }

            print("Router instance -> ", keyName)
            print("Router instance type -> ", keyTypeName)

            // 子 RIB の Builder がプロパティとして含まれているかチェックする
            // private let updateAccountBuilder: UpdateAccountBuildable のようなものが入っているかチェック
            if keyTypeName == "\(child)Buildable" {
                hasChildBuilder = true
            }
        }

        print("\(parent)Router は \(child)Builder を保持しているか→", hasChildBuilder)
        return hasChildBuilder
    }

    func addChildBuilderProperty(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)
//        print(parentRouterStructure)

        let parentRouterStructures = getStructures(from: parentRouterFileStructure,
                                                  targetKind: .class,
                                                  targetKeyName: "\(parent)Router")

        var initLeadingPosition = 0

        for parentRouterStructure in parentRouterStructures {

            guard let kind = getDeclarationKind(from: parentRouterStructure) else {
                continue
            }

            // init の塊を解析する
            let methodName = getKeyName(from: parentRouterStructure)
            if kind == .functionMethodInstance,
               methodName.contains("init") {

                // init の override 修飾子の位置を確認する
                if let attributes = parentRouterStructure["key.attributes"] as? [[String: SourceKitRepresentable]] {
                    for attribute in attributes {
                        guard let key = attribute["key.attribute"] as? String,
                              let attributeKind = SwiftDeclarationAttributeKind(rawValue: key),
                              attributeKind == .override else {
                            return
                        }
                        let overrideAttributeOffset = attribute["key.offset"] as? Int64
                        initLeadingPosition = Int(overrideAttributeOffset ?? 0)
                    }
                } else {
                    // TODO: init の初期位置を確認する
                }
            }
        }

        print("initLeadingPosition", initLeadingPosition)

        do {
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)
            let propertyInsertIndex = text.utf8.index(text.startIndex, offsetBy: initLeadingPosition)
            text.insert(contentsOf: "private let \(child.lowercased())Builder: \(child)Buildable\n\n", at: propertyInsertIndex)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print(error)
        }
    }

    // TODO: override を同時に削除しないといけない★
    func addChildBuilderArgument(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)
//        print(parentRouterStructure)

        let parentRouterStructures = getStructures(from: parentRouterFileStructure,
                                                  targetKind: .class,
                                                  targetKeyName: "\(parent)Router")

        var initArgumentEndPosition = 0

        for parentRouterStructure in parentRouterStructures {

            guard let kind = getDeclarationKind(from: parentRouterStructure) else {
                continue
            }

            // init の塊を解析する
            let methodName = getKeyName(from: parentRouterStructure)
            if kind == .functionMethodInstance,
               methodName.contains("init") {
                let initStructures = getSubStructures(from: parentRouterStructure)

                let initArguments = initStructures.filter { initStructure -> Bool in
                    guard let kindValue = initStructure["key.kind"] as? String,
                          let kind = SwiftDeclarationKind(rawValue: kindValue),
                          kind == .varParameter else {
                        return false
                    }
                    return true
                }
                print("Router 初期化メソッドの最後の引数", initArguments.last ?? "nil")
                guard let lastArgumentLength = initArguments.last?["key.length"] as? Int64,
                      let lastArgumentOffset = initArguments.last?["key.offset"] as? Int64 else {
                    return
                }
                initArgumentEndPosition = Int(lastArgumentOffset + lastArgumentLength)

//                let initBodyLength = parentRouterStructure["key.bodylength"] as? Int64 ?? 0
//                let initBodyOffset = parentRouterStructure["key.bodyoffset"] as? Int64 ?? 0
//                initArgumentEndPosition = Int(initBodyOffset + initBodyLength)
//
//                print("after", initArgumentEndPosition)
            }
        }

        print("initArgumentEndPosition", initArgumentEndPosition)

        do {
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)

            let argumentInsertIndex = text.utf8.index(text.startIndex, offsetBy: initArgumentEndPosition)
            text.insert(contentsOf: ",\n \(child.lowercased())Builder: \(child)Buildable", at: argumentInsertIndex)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print(error)
        }
    }

    func addChildBuilderInitialize(parentRouterPath: String) {

        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterFileStructure = try! Structure(file: parentRouterFile)
        print(parentRouterFileStructure)

        let parentRouterStructures = getStructures(from: parentRouterFileStructure,
                                                  targetKind: .class,
                                                  targetKeyName: "\(parent)Router")
        
        let initSubStructures = getSubStructures(from: parentRouterStructures, name: "init")
        let superInitStartPosition = getOuterLeadingPosition(from: initSubStructures, name: "super.init")

        do {
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)

            let builderInitializeInsertIndex = text.utf8.index(text.startIndex, offsetBy: superInitStartPosition)
            text.insert(contentsOf: "self.\(child.lowercased())Builder = \(child.lowercased())Builder\n", at: builderInitializeInsertIndex)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print(error)
        }
    }
}

extension DependencyCommand {
    func getSubStructures(from structure: [String: SourceKitRepresentable]) -> [[String: SourceKitRepresentable]] {
        return structure["key.substructure"] as? [[String: SourceKitRepresentable]] ?? []
    }

    func getSubStructures(from structures: [[String: SourceKitRepresentable]], name: String) -> [[String: SourceKitRepresentable]] {
        let targetStructures = structures.filter { structure -> Bool in
            let keyName = getKeyName(from: structure)
            return keyName.contains(name) // test(), test2() などで誤検知あり
        }
        return getSubStructures(from: targetStructures.first!)
    }

    func getOuterLeadingPosition(from structures: [[String: SourceKitRepresentable]], name: String) -> Int {
        guard let targetStructure = structures.filter({ getKeyName(from: $0) == name }).first else {
            return 0
        }
        // 外側の先頭の位置を確認する 【ここ→self.functionName（）】
        let targetLeadingPosition = targetStructure["key.nameoffset"] as? Int64 ?? 0
        return Int(targetLeadingPosition)
    }

    func getInnerLeadingPosition(from structures: [[String: SourceKitRepresentable]], name: String) -> Int {
        guard let targetStructure = structures.filter({ getKeyName(from: $0) == name }).first else {
            return 0
        }
        // 内側の先頭の位置を確認する 【self.functionName（←ここ）】
        let targetLeadingPosition = targetStructure["key.bodyoffset"] as? Int64 ?? 0
        return Int(targetLeadingPosition)
    }

    func getInnerTrailingPosition(from structures: [[String: SourceKitRepresentable]], name: String) -> Int {
        guard let targetStructure = structures.filter({ getKeyName(from: $0) == name }).first else {
            return 0
        }
        // 内側の末尾の位置を確認する 【self.functionName（ここ→）】
        let targetBodyOffset = targetStructure["key.bodyoffset"] as? Int64 ?? 0
        let targetBodyLength = targetStructure["key.bodylength"] as? Int64 ?? 0
        return Int(targetBodyOffset + targetBodyLength)
    }

    func getOuterTrailingPosition(from structures: [[String: SourceKitRepresentable]], name: String) -> Int {
        // 外側の末尾の位置を確認する 【self.functionName（）←ここ】
        return getInnerTrailingPosition(from: structures, name: name) + 1
    }

    func getDeclarationKind(from structure: [String: SourceKitRepresentable]) -> SwiftDeclarationKind? {
        guard let kindValue = structure["key.kind"] as? String else {
            return nil
        }

        return SwiftDeclarationKind(rawValue: kindValue)
    }

    func getKeyName(from structure: [String: SourceKitRepresentable]) -> String {
        structure["key.name"] as? String ?? ""
    }

    // class, protocol 限定がよいかも？
    func getStructures(from structure: Structure, targetKind: SwiftDeclarationKind, targetKeyName: String) -> [[String: SourceKitRepresentable]] {
        // class, protocol などの一塊の集まり
        let substructures = getSubStructures(from: structure.dictionary)

        for substructure in substructures {
            let kind = getDeclarationKind(from: substructure)
            let keyName = getKeyName(from: substructure)

            if kind == targetKind, keyName == targetKeyName {
                return getSubStructures(from: substructure)
            }
        }

        return []
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
}
