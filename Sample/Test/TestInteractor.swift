//___FILEHEADER___

import RIBs
import RxSwift

protocol TestRouting: ViewableRouting {
}

protocol TestPresentable: Presentable {
    var listener: TestPresentableListener? { get set }
}

protocol TestListener: class {
}

final class TestInteractor: PresentableInteractor<TestPresentable>, TestInteractable, TestPresentableListener {

    weak var router: TestRouting?
    weak var listener: TestListener?

    override init(presenter: TestPresentable) {
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

// MARK: - TestPresentableListener
extension TestInteractor {

}
