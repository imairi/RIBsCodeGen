//
//  Dictionary+SourceKit.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/04.
//

import Foundation

extension SwiftNode {
    func getKeyName() -> String {
        name
    }

    func getTypeName() -> String {
        typeName
    }

    func getDeclarationKind() -> SwiftDeclarationKind? {
        SwiftDeclarationKind(rawValue: kind)
    }

    func getAttributes() -> [SwiftAttribute] {
        attributes
    }

    func getInheritedTypes() -> [SwiftInheritedType] {
        inheritedTypes
    }

    func getSubStructures() -> [SwiftNode] {
        substructures
    }

    func getOuterLeadingPosition() -> Int {
        // 外側の先頭の位置を確認する 【ここ→self.functionName（）】
        nameOffset
    }

    func getInnerLeadingPosition() -> Int {
        // 内側の先頭の位置を確認する 【self.functionName（←ここ）】
        bodyOffset
    }

    func getInnerTrailingPosition() -> Int {
        // 内側の末尾の位置を確認する 【self.functionName（ここ→）】
        bodyOffset + bodyLength
    }

    func getOuterTrailingPosition() -> Int {
        // 外側の末尾の位置を確認する 【self.functionName（）←ここ】
        return getInnerTrailingPosition() + 1
    }

    func getVariableTypeLeadingPosition() -> Int {
        // プロパティの型の先頭の位置を確認する【var router: ここ→OrderRouting?】
        nameOffset + nameLength
    }

    func getVariableTypeTrailingPosition() -> Int {
        // プロパティの型の先頭の位置を確認する【var router: OrderRouting?←ここ】
        offset + length
    }

    func getKeyNameLength() -> Int {
        nameLength
    }

    func getKeyLength() -> Int {
        length
    }

    func getKeyOffset() -> Int {
        offset
    }

    func getKeyBodyOffset() -> Int {
        bodyOffset
    }

    func getKeyBodyLength() -> Int {
        bodyLength
    }
}
