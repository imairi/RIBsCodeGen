//
//  Dictionary+SourceKit.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/04.
//

import Foundation
import SourceKittenFramework

extension Dictionary where Key == String {
    func getKeyName() -> String {
        self["key.name"] as? String ?? ""
    }
    
    func getTypeName() -> String {
        self["key.typename"] as? String ?? ""
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

    func getInheritedTypes() -> [[String: SourceKitRepresentable]] {
        guard let inheritedtypes = self["key.inheritedtypes"] as? [[String: SourceKitRepresentable]] else {
            return [[String: SourceKitRepresentable]]()
        }
        return inheritedtypes
    }

    func getElements() -> [[String: SourceKitRepresentable]] {
        guard let elements = self["key.elements"] as? [[String: SourceKitRepresentable]] else {
            return [[String: SourceKitRepresentable]]()
        }
        return elements
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
    
    func getVariableTypeLeadingPosition() -> Int {
        // プロパティの型の先頭の位置を確認する【var router: ここ→OrderRouting?】
        let targetNameOffset = self["key.nameoffset"] as? Int64 ?? 0
        let targetNameLength = self["key.namelength"] as? Int64 ?? 0
        return Int(targetNameOffset + targetNameLength)
    }
    
    func getVariableTypeTrailingPosition() -> Int {
        // プロパティの型の先頭の位置を確認する【var router: OrderRouting?←ここ】
        let targetOffset = self["key.offset"] as? Int64 ?? 0
        let targetLength = self["key.length"] as? Int64 ?? 0
        return Int(targetOffset + targetLength)
    }
    
    func getKeyNameLength() -> Int {
        Int(self["key.namelength"] as? Int64 ?? 0)
    }
    
    func getKeyLength() -> Int {
        Int(self["key.length"] as? Int64 ?? 0)
    }
    
    func getKeyOffset() -> Int {
        Int(self["key.offset"] as? Int64 ?? 0)
    }
    
    func getKeyBodyOffset() -> Int {
        Int(self["key.bodyoffset"] as? Int64 ?? 0)
    }
    
    func getKeyBodyLength() -> Int {
        Int(self["key.bodylength"] as? Int64 ?? 0)
    }
}
