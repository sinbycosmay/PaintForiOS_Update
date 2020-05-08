
import UIKit
class ViewController: UIViewController {
    @IBOutlet weak var paintImageView: PaintImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

extension CGFloat {
    static func screenWidth() -> CGFloat {
        return UIScreen.main.bounds.size.width
    }
    static func screenHeight() -> CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    static func ptHeight(h: CGFloat) -> CGFloat {
        return h/512.0*CGFloat.screenHeight()
    }
    
    static func ptWidth(w: CGFloat) -> CGFloat {
        return w / 683.0 * CGFloat.screenWidth()
    }
}



