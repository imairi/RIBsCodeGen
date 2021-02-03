//
//  SampleChildViewController.swift
//  MOV
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Mobility Technologies Co., Ltd. All rights reserved.
//

import RIBs
import RxSwift
import UIKit

protocol SampleChildPresentableListener: class {
}

final class SampleChildViewController: UIViewController, SampleChildPresentable, SampleChildViewControllable {

    weak var listener: SampleChildPresentableListener?
}

// MARK: - SampleChildPresentable
extension SampleChildViewController {

}
