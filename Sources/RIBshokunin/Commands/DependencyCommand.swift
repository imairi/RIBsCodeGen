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
    }
    
    func run() -> Result {
        return .success(message: "dependency completed")
    }

    func addChildListenerIfNeeded(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterStructure = try! Structure(file: parentRouterFile)
//        print(parentRouterStructure)

        // key.substructure はソースコードの class, protocol などの一塊の集まり。
        let substructures = getSubstructures(from: parentRouterStructure.dictionary)

        var isConformsToChild = false
        var insertPosition = 0

        for substructure in substructures {
            guard let kindValue = substructure["key.kind"] as? String else {
                continue
            }

            guard let kind = SwiftDeclarationKind(rawValue: kindValue) else {
                continue
            }

            // class と protocol の塊のみを取り出す
            guard [.class, .protocol].contains(kind) else {
                continue
            }

            guard let keyName = substructure["key.name"] as? String else {
                continue
            }

            print("sub.key.name: \(keyName)")

            // Interactable に ChildListener を付与するかどうかの判定
            if keyName == "\(parent)Interactable" {
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
                text.insert(contentsOf: ",\r\n \(child)Listener", at: insertIndex)

                write(text: text, toPath: parentRouterPath)
            }
        } catch {
            print(error)
        }
    }

    func hasChildBuilder(parentRouterPath: String) -> Bool {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterStructure = try! Structure(file: parentRouterFile)
//        print(parentRouterStructure)

        // key.substructure はソースコードの class, protocol などの一塊の集まり。
        let substructures = getSubstructures(from: parentRouterStructure.dictionary)

        var hasChildBuilder = false

        for substructure in substructures {
            guard let kindValue = substructure["key.kind"] as? String else {
                continue
            }

            guard let kind = SwiftDeclarationKind(rawValue: kindValue) else {
                continue
            }

            // class と protocol の塊のみを取り出す
            guard [.class, .protocol].contains(kind) else {
                continue
            }

            guard let keyName = substructure["key.name"] as? String else {
                continue
            }

            print("sub.key.name: \(keyName)")

            // Router 内に 子 RIB の Builder があるかどうかのチェック
            // なければ、追加する
            if keyName == "\(parent)Router" {
                print("Router のプロパティを検査する")
                let substructures = getSubstructures(from: substructure)
                for substructure in substructures {

                    guard let kindValue = substructure["key.kind"] as? String else {
                        continue
                    }

                    guard let kind = SwiftDeclarationKind(rawValue: kindValue) else {
                        continue
                    }

                    // var instance のみを取り出す
                    guard [.varInstance].contains(kind) else {
                        continue
                    }

                    guard let keyName = substructure["key.name"] as? String,
                          let keyTypeName = substructure["key.typename"] as? String else {
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
            }
        }

        print("\(parent)Router は \(child)Builder を保持しているか→", hasChildBuilder)
        return hasChildBuilder
    }

    func addChildBuilderProperty(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterStructure = try! Structure(file: parentRouterFile)
//        print(parentRouterStructure)

        // key.substructure はソースコードの class, protocol などの一塊の集まり。
        let substructures = getSubstructures(from: parentRouterStructure.dictionary)

        var initLeadingPosition = 0

        for substructure in substructures {
            guard let kindValue = substructure["key.kind"] as? String else {
                continue
            }

            guard let kind = SwiftDeclarationKind(rawValue: kindValue) else {
                continue
            }

            // class と protocol の塊のみを取り出す
            guard [.class, .protocol].contains(kind) else {
                continue
            }

            guard let keyName = substructure["key.name"] as? String else {
                continue
            }

            print("sub.key.name: \(keyName)")

            // Router 内に 子 RIB の Builder があるかどうかのチェック
            // なければ、追加する
            if keyName == "\(parent)Router" {
                print("Router のプロパティを検査する")
                let substructures = getSubstructures(from: substructure)
                for substructure in substructures {

                    guard let kindValue = substructure["key.kind"] as? String else {
                        continue
                    }

                    guard let kind = SwiftDeclarationKind(rawValue: kindValue) else {
                        continue
                    }


                    // init の塊を解析する
                    if kind == .functionMethodInstance,
                       let methodName = substructure["key.name"] as? String,
                       methodName.contains("init") {

                        // init の override 修飾子の位置を確認する
                        if let attributes = substructure["key.attributes"] as? [[String: SourceKitRepresentable]] {
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

            }
        }

        print("initLeadingPosition", initLeadingPosition)

        do {
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)
            let propertyInsertIndex = text.utf8.index(text.startIndex, offsetBy: initLeadingPosition)
            text.insert(contentsOf: "private let \(child.lowercased())Builder: \(child)Buildable\r\n", at: propertyInsertIndex)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print(error)
        }
    }

    // TODO: override を同時に削除しないといけない★
    func addChildBuilderArgument(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterStructure = try! Structure(file: parentRouterFile)
//        print(parentRouterStructure)

        // key.substructure はソースコードの class, protocol などの一塊の集まり。
        let substructures = getSubstructures(from: parentRouterStructure.dictionary)

        var initArgumentEndPosition = 0

        for substructure in substructures {
            guard let kindValue = substructure["key.kind"] as? String else {
                continue
            }

            guard let kind = SwiftDeclarationKind(rawValue: kindValue) else {
                continue
            }

            // class と protocol の塊のみを取り出す
            guard [.class, .protocol].contains(kind) else {
                continue
            }

            guard let keyName = substructure["key.name"] as? String else {
                continue
            }

            print("sub.key.name: \(keyName)")

            // Router 内に 子 RIB の Builder があるかどうかのチェック
            // なければ、追加する
            if keyName == "\(parent)Router" {
                print("Router のプロパティを検査する")
                let substructures = getSubstructures(from: substructure)

                for substructure in substructures {

                    guard let kindValue = substructure["key.kind"] as? String else {
                        continue
                    }

                    guard let kind = SwiftDeclarationKind(rawValue: kindValue) else {
                        continue
                    }


                    // init の塊を解析する
                    if kind == .functionMethodInstance,
                       let methodName = substructure["key.name"] as? String,
                       methodName.contains("init") {
                        let initSubstructures = getSubstructures(from: substructure)

                        let initArguments = initSubstructures.filter { initSubstructure -> Bool in
                            guard let kindValue = initSubstructure["key.kind"] as? String,
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
                    }
                }
            }
        }

        print("initArgumentEndPosition", initArgumentEndPosition)

        do {
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)

            let argumentInsertIndex = text.utf8.index(text.startIndex, offsetBy: initArgumentEndPosition)
            text.insert(contentsOf: ",\r\n \(child.lowercased())Builder: \(child)Buildable", at: argumentInsertIndex)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print(error)
        }
    }

    func addChildBuilderInitialize(parentRouterPath: String) {
        let parentRouterFile = File(path: parentRouterPath)!
        let parentRouterStructure = try! Structure(file: parentRouterFile)
//        print(parentRouterStructure)

        // key.substructure はソースコードの class, protocol などの一塊の集まり。
        let substructures = getSubstructures(from: parentRouterStructure.dictionary)

        var initBodyEndPosition = 0

        for substructure in substructures {
            guard let kindValue = substructure["key.kind"] as? String else {
                continue
            }

            guard let kind = SwiftDeclarationKind(rawValue: kindValue) else {
                continue
            }

            // class と protocol の塊のみを取り出す
            guard [.class, .protocol].contains(kind) else {
                continue
            }

            guard let keyName = substructure["key.name"] as? String else {
                continue
            }

            print("sub.key.name: \(keyName)")

            // Router 内に 子 RIB の Builder があるかどうかのチェック
            // なければ、追加する
            if keyName == "\(parent)Router" {
                print("Router のプロパティを検査する")

                let substructures = getSubstructures(from: substructure)

                for substructure in substructures {

                    guard let kindValue = substructure["key.kind"] as? String else {
                        continue
                    }

                    guard let kind = SwiftDeclarationKind(rawValue: kindValue) else {
                        continue
                    }


                    // init の塊を解析する
                    if kind == .functionMethodInstance,
                       let methodName = substructure["key.name"] as? String,
                       methodName.contains("init") {

                        // init の中身の最後の位置を確認する
                        let initBodyLength = substructure["key.bodylength"] as? Int64 ?? 0
                        let initBodyOffset = substructure["key.bodyoffset"] as? Int64 ?? 0
                        initBodyEndPosition = Int(initBodyOffset + initBodyLength)
                    }
                }
            }
        }

        print("initBodyEndPosition", initBodyEndPosition)

        do {
            var text = try String.init(contentsOfFile: parentRouterFile.path!, encoding: .utf8)

            let builderInitializeInsertIndex = text.utf8.index(text.startIndex, offsetBy: initBodyEndPosition)
            text.insert(contentsOf: "self.\(child.lowercased())Builder = \(child.lowercased())Builder\r\n", at: builderInitializeInsertIndex)

            write(text: text, toPath: parentRouterPath)
        } catch {
            print(error)
        }
    }
}

extension DependencyCommand {
    func getSubstructures(from structure: [String: SourceKitRepresentable]) -> [[String: SourceKitRepresentable]] {
        return structure["key.substructure"] as? [[String: SourceKitRepresentable]] ?? []
    }

    func write(text: String, toPath path: String) {
        do {
            print(text)
            print("... 書き込み中 ...")
            try text.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
            print("... 書き込み完了 ...")
        } catch {
            print("書き込みエラー", error)
        }
    }
}
