//
// Created by 今入　庸介 on 2022/05/09.
//

import Foundation
import SourceKittenFramework
import Rainbow
import PathKit

struct RenameCommand: Command {
    private let currentName: String
    private let newName: String
    
    private let interactorPath: String
    private let routerPath: String
    private let builderPath: String
    private let viewControllerPath: String?
    
    init(paths: [String], currentName: String, newName: String) {
        self.currentName = currentName
        self.newName = newName
        
        guard let interactorPath = paths.filter({ $0.contains("/" + currentName + "Interactor.swift") }).first else {
            fatalError("Not found \(currentName)Interactor.swift".red.bold)
        }
        
        guard let routerPath = paths.filter({ $0.contains("/" + currentName + "Router.swift") }).first else {
            fatalError("Not found \(currentName)Router.swift".red.bold)
        }
        
        guard let builderPath = paths.filter({ $0.contains("/" + currentName + "Builder.swift") }).first else {
            fatalError("Not found \(currentName)Builder.swift".red.bold)
        }
        
        self.interactorPath = interactorPath
        self.routerPath = routerPath
        self.builderPath = builderPath
        viewControllerPath = paths.filter({ $0.contains("/" + currentName + "ViewController.swift") }).first
    }
    
    func run() -> Result {
        print("\nStart rename \(currentName) to \(newName)".bold)
        
        print("★ interactorPath", interactorPath)
        print("★ routerPath", routerPath)
        print("★ builderPath", builderPath)
        print("★ viewControllerPath", viewControllerPath ?? "nil")
        
        return .success(message: "succeeded")
    }
}

