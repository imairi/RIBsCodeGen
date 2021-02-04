//___FILEHEADER___

import RIBs
import RxSwift

protocol ChildDemoRouting: ViewableRouting {
}

protocol ChildDemoPresentable: Presentable {
    var listener: ChildDemoPresentableListener? { get set }
}

protocol ChildDemoListener: class {
}

final class ChildDemoInteractor: PresentableInteractor<ChildDemoPresentable>, ChildDemoInteractable, ChildDemoPresentableListener {

    weak var router: ChildDemoRouting?
    weak var listener: ChildDemoListener?

    override init(presenter: ChildDemoPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
    }

    override func willResignActive() {
        super.willResignActive()
    }
}

// MARK: - ChildDemoPresentableListener
extension ChildDemoInteractor {

}
