//
//  OrderViewController.swift
//
//  Created by RIBsCodeGen.
//

import RIBs
import RxSwift
import UIKit

protocol OrderPresentableListener: class {
}

final class OrderViewController: UIViewController, OrderPresentable, OrderViewControllable {

    weak var listener: OrderPresentableListener?
}

// MARK: - OrderPresentable
extension OrderViewController {

}
