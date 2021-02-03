//
//  SampleParentViewController.swift
//  MOV
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Yosuke Imairi. All rights reserved.
//

import RIBs
import RxSwift
import UIKit

protocol SampleParentPresentableListener: class {
}

final class SampleParentViewController: UIViewController, SampleParentPresentable, SampleParentViewControllable {

    weak var listener: SampleParentPresentableListener?
}

// MARK: - SampleParentPresentable
extension SampleParentViewController {

}
