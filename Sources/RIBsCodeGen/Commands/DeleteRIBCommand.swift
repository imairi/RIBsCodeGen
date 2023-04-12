//
// Created by 今入　庸介 on 2022/05/26.
//

import Foundation
import SourceKittenFramework
import PathKit

struct DeleteRIBCommand: Command {
    private let paths: [String]
    private let targetName: String
    
    init(paths: [String], targetName: String) {
        self.paths = paths
        self.targetName = targetName
    }
    
    func run() -> Result {
        print("\nStart deleting \(targetName) RIB.\n".bold)
    
        guard let interactorPath = paths.filter({ $0.contains("/\(targetName)/\(targetName)Interactor.swift") }).first else {
            return .failure(error: .failedToDelete("Not found \(targetName)/\(targetName)Interactor.swift. Interrupt deleting operation."))
        }
        let directoryPathString = "/" + interactorPath.split(separator: "/").dropLast(1).joined(separator: "/")
        let directoryPath = Path(directoryPathString)
        guard directoryPath.isDirectory else {
            return .failure(error: .failedToDelete("\(directoryPath) is not Directory. Failed to detect the target directory. Interrupt deleting operation."))
        }
        
        print("\tDelete ".magenta + " \(directoryPath) ".onMagenta + ".".magenta)
        let shellResult = shell("rm -rf \(directoryPath)")
        print("\t\(shellResult)")
        
        return .success(message: "\nSuccessfully finished deleting \(targetName) RIB.".green.bold)
    }
}
