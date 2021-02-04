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

        let parentRouterStructures = getSubStructures(from: parentRouterFileStructure,
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

        let parentRouterFileSubStructure = getSubStructures(from: parentRouterFileStructure.dictionary)
        let initLeadingPosition = getInnerLeadingPosition(from: parentRouterFileSubStructure, name: "\(parent)Router")

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

        let parentRouterStructures = getSubStructures(from: parentRouterFileStructure,
                                                      targetKind: .class,
                                                      targetKeyName: "\(parent)Router")

        var initArgumentEndPosition = 0

        let initSubStructures = getSubStructures(from: parentRouterStructures, name: "init")

        let initArguments = initSubStructures.filter { initStructure -> Bool in
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

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().filterByKeyName("\(parent)Router")
        let initStructure = parentRouterStructure.getSubStructures().filterByKeyName("init")
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

        let parentRouterStructure = parentRouterFileStructure.dictionary.getSubStructures().filterByKeyName("\(parent)Router")
        let initStructure = parentRouterStructure.getSubStructures().filterByKeyName("init")
        let superInitStructure = initStructure.getSubStructures().filterByKeyName("super.init")
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

// MARK: - Extensions
extension DependencyCommand {
    func getStructure(from structures: [[String: SourceKitRepresentable]], name: String) -> [String: SourceKitRepresentable] {
        let targetStructures = structures.filter { structure -> Bool in
            let keyName = getKeyName(from: structure)
            return keyName.contains(name) // test(), test2() などで誤検知あり
        }
        return targetStructures.first ?? [String: SourceKitRepresentable]()
    }

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
    func getSubStructures(from structure: Structure, targetKind: SwiftDeclarationKind, targetKeyName: String) -> [[String: SourceKitRepresentable]] {
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

extension Collection where Iterator.Element == [String: SourceKitRepresentable] {
    func filterByKeyName(_ targetKeyName: String) -> [String: SourceKitRepresentable] {
        let targetStructures = self.filter { structure -> Bool in
            let keyName = structure["key.name"] as? String ?? ""
            return keyName.contains(targetKeyName) // test(), test2() などで誤検知あり
        }
        return targetStructures.first ?? [String: SourceKitRepresentable]()
    }

    func filterByAttribute(_ targetKind: SwiftDeclarationAttributeKind) -> [String: SourceKitRepresentable] {
        let targetStructures = self.filter { structure -> Bool in
            let keyAttributes = structure["key.attribute"] as? String ?? ""
            let attributeKind = SwiftDeclarationAttributeKind(rawValue: keyAttributes)

            return attributeKind == targetKind
        }
        return targetStructures.first ?? [String: SourceKitRepresentable]()
    }
}

extension Dictionary where Key == String {
    func getKeyName() -> String {
        self["key.name"] as? String ?? ""
    }

    func getDeclarationKind() -> SwiftDeclarationKind? {
        guard let kindValue = self["key.kind"] as? String else {
            return nil
        }
        return SwiftDeclarationKind(rawValue: kindValue)
    }

    func getAttributes() -> [[String: SourceKitRepresentable]] {
        guard let attributes = self["key.attributes"] as? [[String: SourceKitRepresentable]] else {
            return [[String: SourceKitRepresentable]]()
        }
        return attributes
    }

    func getSubStructures() -> [[String: SourceKitRepresentable]] {
        guard let substructures = self["key.substructure"] as? [[String: SourceKitRepresentable]] else {
            return [[String: SourceKitRepresentable]]()
        }
        return substructures
    }

    func getOuterLeadingPosition() -> Int {
        // 外側の先頭の位置を確認する 【ここ→self.functionName（）】
        let targetLeadingPosition = self["key.nameoffset"] as? Int64 ?? 0
        return Int(targetLeadingPosition)
    }

    func getInnerLeadingPosition() -> Int {
        // 内側の先頭の位置を確認する 【self.functionName（←ここ）】
        let targetLeadingPosition = self["key.bodyoffset"] as? Int64 ?? 0
        return Int(targetLeadingPosition)
    }

    func getInnerTrailingPosition() -> Int {
        // 内側の末尾の位置を確認する 【self.functionName（ここ→）】
        let targetBodyOffset = self["key.bodyoffset"] as? Int64 ?? 0
        let targetBodyLength = self["key.bodylength"] as? Int64 ?? 0
        return Int(targetBodyOffset + targetBodyLength)
    }

    func getOuterTrailingPosition() -> Int {
        // 外側の末尾の位置を確認する 【self.functionName（）←ここ】
        return getInnerTrailingPosition() + 1
    }
}

// MARK: - 位置の計算
extension DependencyCommand {
    // TODO: 修飾子を考慮する必要あり
    func getOuterLeadingPosition(from structures: [[String: SourceKitRepresentable]], name: String) -> Int {
        guard let targetStructure = structures.filter({ getKeyName(from: $0).contains(name) }).first else {
            print("return 0")
            return 0
        }
        print("targetStructure", targetStructure)
        // 外側の先頭の位置を確認する 【ここ→self.functionName（）】
        let targetLeadingPosition = targetStructure["key.nameoffset"] as? Int64 ?? 0
        return Int(targetLeadingPosition)
    }

    func getInnerLeadingPosition(from structures: [[String: SourceKitRepresentable]], name: String) -> Int {
        guard let targetStructure = structures.filter({ getKeyName(from: $0).contains(name) }).first else {
            return 0
        }
        // 内側の先頭の位置を確認する 【self.functionName（←ここ）】
        let targetLeadingPosition = targetStructure["key.bodyoffset"] as? Int64 ?? 0
        return Int(targetLeadingPosition)
    }

    func getInnerTrailingPosition(from structures: [[String: SourceKitRepresentable]], name: String) -> Int {
        guard let targetStructure = structures.filter({ getKeyName(from: $0).contains(name) }).first else {
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

private extension String {
    func lowercasedFirstLetter() -> String {
        prefix(1).lowercased() + dropFirst()
    }
}
