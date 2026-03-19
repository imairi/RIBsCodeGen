//
//  Array+SourceKit.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/04.
//

import Foundation

extension Collection where Iterator.Element == SwiftNode {
    func extractDictionaryContainsKeyName(_ targetKeyName: String) -> SwiftNode {
        first(where: { $0.name.contains(targetKeyName) }) ?? .empty
    }

    func extractDictionaryContainsKeyNameLast(_ targetKeyName: String) -> SwiftNode {
        reversed().first(where: { $0.name.contains(targetKeyName) }) ?? .empty
    }

    func extractDictionaryByKeyName(_ targetKeyName: String) -> SwiftNode {
        first(where: { $0.name == targetKeyName }) ?? .empty
    }

    func filterByKeyName(_ targetKeyName: String) -> [SwiftNode] {
        filter { $0.name.contains(targetKeyName) }
    }

    func filterByKeyKind(_ targetKind: SwiftDeclarationKind) -> [SwiftNode] {
        filter { SwiftDeclarationKind(rawValue: $0.kind) == targetKind }
    }

    func filterByKeyKind(_ targetKind: SwiftExpressionKind) -> [SwiftNode] {
        filter { SwiftExpressionKind(rawValue: $0.kind) == targetKind }
    }

    func filterByKeyTypeName(_ targetTypeName: String) -> [SwiftNode] {
        filter { $0.typeName.contains(targetTypeName) }
    }
}

extension Collection where Iterator.Element == SwiftAttribute {
    func filterByAttribute(_ targetKind: SwiftDeclarationAttributeKind) -> [SwiftAttribute] {
        filter { $0.kind == targetKind }
    }
}

extension Collection where Iterator.Element == SwiftInheritedType {
    func filterByKeyName(_ targetKeyName: String) -> [SwiftInheritedType] {
        filter { $0.name.contains(targetKeyName) }
    }
}
