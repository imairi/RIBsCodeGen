//___FILEHEADER___

import RIBs
import RxSwift

protocol TestChildRouting: ViewableRouting {
}

protocol TestChildPresentable: Presentable {
    var listener: TestChildPresentableListener? { get set }
}

protocol TestChildListener: class {
}

final class TestChildInteractor: PresentableInteractor<TestChildPresentable>, TestChildInteractable, TestChildPresentableListener {

    weak var router: TestChildRouting?
    weak var listener: TestChildListener?

    override init(presenter: TestChildPresentable) {
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

// MARK: - TestChildPresentableListener
extension TestChildInteractor {

}
