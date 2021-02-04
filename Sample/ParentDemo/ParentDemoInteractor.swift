//___FILEHEADER___

import RIBs
import RxSwift

protocol ParentDemoRouting: ViewableRouting {
}

protocol ParentDemoPresentable: Presentable {
    var listener: ParentDemoPresentableListener? { get set }
}

protocol ParentDemoListener: class {
}

final class ParentDemoInteractor: PresentableInteractor<ParentDemoPresentable>, ParentDemoInteractable, ParentDemoPresentableListener {

    weak var router: ParentDemoRouting?
    weak var listener: ParentDemoListener?

    override init(presenter: ParentDemoPresentable) {
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

// MARK: - ParentDemoPresentableListener
extension ParentDemoInteractor {

}
