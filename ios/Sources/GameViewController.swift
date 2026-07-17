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

    // WHY ◀▶ WERE UNRELIABLE.
    // The steering zone runs to the bottom of the canvas, which lands ~34pt from the
    // screen edge — inside iOS's home-indicator gesture region. There, the system takes
    // the first touch to see whether it's a home swipe, and only passes it on if it isn't:
    // held presses get delayed or cancelled outright. It reads as "sometimes it works,
    // sometimes it doesn't", and it hits ◀▶ hardest because they're HELD, low, exactly
    // where a thumb rests. Deferring the edge gesture gives the first touch to the game.
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { [.bottom] }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameView.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gameView.stop()
    }
}
