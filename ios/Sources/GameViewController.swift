import UIKit

final class GameViewController: UIViewController {
    private var gameView: GameView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        gameView = GameView(frame: view.bounds)
        gameView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(gameView)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameView.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gameView.stop()
    }
}
