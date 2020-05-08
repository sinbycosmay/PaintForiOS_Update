import UIKit

struct FillLineInfo : Hashable {
    let lineNumber:Int
    var xLeft:Int
    var xRight:Int
}
typealias ColorValue = (red:UInt8,green:UInt8,blue:UInt8,alpha:UInt8)
class PaintImageView: UIImageView {
    
    var newColor: UIColor = .blue
    var unchangeableColors = [UIColor]()
    @IBAction func yellow_button(_ sender: Any) {
        newColor = UIColor.yellow
    }
    @IBAction func blue(_ sender: Any) {
        newColor = UIColor.blue
    }
    @IBAction func gray(_ sender: Any) {
        newColor = UIColor.white
    }
    @IBAction func red(_ sender: Any) {
        newColor=UIColor.red
    }
    @IBAction func green(_ sender: Any) {
        newColor=UIColor.green
    }
    @IBAction func orange(_ sender: Any) {
        newColor = UIColor.orange
    }
    var seedPointArray = [[CGPoint.init(x: 540, y: 198),
                           CGPoint.init(x: 460, y: 63),
                           CGPoint.init(x: 693.0, y: 217.0),
                           CGPoint.init(x: 207, y: 614)],
                          [CGPoint.init(x: 370, y: 362),
                           CGPoint.init(x: 464, y: 448)]
    ]
    
    var currentSeedPointArray = [CGPoint]()
    
    private var pixels:Array<UInt32>
    private var imageSize = CGSize.zero
    private var seedPointList = StackList<CGPoint>()
    private var scanedLines = [Int:FillLineInfo]()
    var colorTolorance = 100
    
    override init(image: UIImage?) {
        self.pixels = Array<UInt32>()
        super.init(image: image)
    }
    
    override init(frame: CGRect) {
        self.pixels = Array<UInt32>()
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.pixels = Array<UInt32>()
        super.init(coder: aDecoder)
    }
    
    override var contentMode: UIView.ContentMode {
        didSet {
            if contentMode != .scaleToFill {
                self.contentMode = .scaleToFill
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 , let touch = touches.first{
            let point = touch.location(in: self)
            floodFill(from: point)
            print(point)
        }
    }

    private func floodFill(from point:CGPoint, fillOtherSeed: Bool = true) {
        if let imageRef = image?.cgImage  {
            let width = imageRef.width
            let height = imageRef.height
            let widthScale = CGFloat(width) / bounds.width
            let heightScale = CGFloat(height) / bounds.height
            let realPoint = CGPoint(x: point.x * widthScale, y: point.y * heightScale)
            scanedLines = [:]
            imageSize = CGSize(width: width, height: height)
            pixels = Array<UInt32>(repeating: 0, count: width * height)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitsPerComponent = 8
            let bytesPerRow = width * 4
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            if let context = CGContext(data: &(pixels), width: width, height: height, bitsPerComponent: bitsPerComponent,
                                       bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) {
                context.draw(imageRef, in: CGRect(x: 0, y: 0, width: width, height: height))
                let pixelIndex = lrintf(Float(realPoint.y)) * width + lrintf(Float(realPoint.x))
                let newColorRgbaValue = newColor.rgbaValue
                let colorRgbaValue = pixels[pixelIndex]
                
                let clearColor = UIColor.clear
                if compareColor(color: colorRgbaValue, otherColor: clearColor.rgbaValue, tolorance: colorTolorance) {
                    return
                }
                
                for color in unchangeableColors {
                    let colorValue = color.rgbaValue
                    if compareColor(color: colorRgbaValue, otherColor: colorValue, tolorance: colorTolorance) {
                        return
                    }
                }
                
                if isBlackColor(color: colorRgbaValue) {
                    return
                }
                if compareColor(color: colorRgbaValue, otherColor: newColorRgbaValue, tolorance: colorTolorance) {
                    return
                }
                
                seedPointList.push(realPoint)
                while !seedPointList.isEmpty {
                    if let point = seedPointList.pop() {
                        let (xLeft,xRight) = fillLine(seedPoint: point, newColorRgbaValue: newColorRgbaValue,
                                                      originalColorRgbaValue: colorRgbaValue)
                        scanLine(lineNumer: Int(point.y) + 1, xLeft: xLeft, xRight: xRight, originalColorRgbaValue: colorRgbaValue)
                        scanLine(lineNumer: Int(point.y) - 1, xLeft: xLeft, xRight: xRight, originalColorRgbaValue: colorRgbaValue)

                        if fillOtherSeed == true {
                            if let scanlie = scanedLines[Int(point.y)] {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                                    self.fillColorWithOtherSeed(scanline: scanlie, widthScale: widthScale, heightScale: heightScale)
                                }
                            }
                        }
                    }
                }
                
                
                if let cgImage = context.makeImage() {
                    let img = UIImage(cgImage: cgImage, scale: image?.scale ?? 2, orientation: .up)
                    let transition = CATransition.init()
                    transition.duration = 0.3
                    transition.timingFunction = CAMediaTimingFunction.init(name: .linear)
                    transition.type = .fade
                    layer.add(transition, forKey: "colorAnimation")
                    image = img
                }
            }
        }
    }
    private func fillColorWithOtherSeed(scanline: FillLineInfo, widthScale: CGFloat, heightScale: CGFloat) {
        
        for  array in seedPointArray {
            for p in array {
                let x = Int(p.x * widthScale)
                let y = Int(p.y * heightScale)
                if (scanline.lineNumber == y) && (scanline.xLeft < x && scanline.xRight > x) {
                    currentSeedPointArray = array
                    guard let index = currentSeedPointArray.firstIndex(of: p) else { return  }
                    currentSeedPointArray.remove(at: index)
                    for p in currentSeedPointArray {
                        floodFill(from: p, fillOtherSeed: false)
                    }
                    
                }
            }
        }
    }
    private  func fillLine(seedPoint:CGPoint,newColorRgbaValue:UInt32,originalColorRgbaValue:UInt32) -> (Int,Int) {
        let imageW = Int(imageSize.width)
        let currntLineMinIndex = Int(seedPoint.y) * imageW
        let currntLineMaxIndex = currntLineMinIndex + imageW
        let currentPixelIndex = currntLineMinIndex + Int(seedPoint.x)
        var xleft = Int(seedPoint.x)
        var xright = xleft
        if pixels.count >= currntLineMaxIndex {
            var tmpIndex = currentPixelIndex
            while tmpIndex >=  currntLineMinIndex &&
                compareColor(color: originalColorRgbaValue, otherColor: pixels[tmpIndex], tolorance: colorTolorance){
                    pixels[tmpIndex] = newColorRgbaValue
                    tmpIndex -= 1
                    xleft -= 1
            }
            tmpIndex = currentPixelIndex + 1
            while tmpIndex < currntLineMaxIndex &&
                compareColor(color: originalColorRgbaValue, otherColor: pixels[tmpIndex], tolorance: colorTolorance){
                    pixels[tmpIndex] = newColorRgbaValue
                    tmpIndex += 1
                    xright += 1
            }
        }
        return (xleft + 1,xright)
    }
    
    private func scanLine(lineNumer:Int,xLeft:Int,xRight:Int,originalColorRgbaValue:UInt32) {
        if lineNumer < 0 || CGFloat(lineNumer) > imageSize.height - 1{
            return
        }
        var xCurrent = xLeft
        let currentLineOriginalIndex = lineNumer * Int(imageSize.width)
        var currentPixelIndex = currentLineOriginalIndex + xLeft
        var currntLineMaxIndex = currentLineOriginalIndex + xRight
        var leftSpiltIndex:Int?
        if var scanLine = scanedLines[lineNumer] {
            if scanLine.xLeft >= xRight || scanLine.xRight <= xLeft {
            }else if scanLine.xLeft <= xLeft && scanLine.xRight >= xRight {
                return
            }else if scanLine.xLeft <= xLeft && scanLine.xRight <= xRight {
                xCurrent = scanLine.xRight + 1
                currentPixelIndex = currentLineOriginalIndex + scanLine.xRight + 1
                scanLine.xRight = xRight
                scanedLines[lineNumer] = scanLine
            }else if scanLine.xLeft >= xLeft && scanLine.xRight >= xRight {
                currntLineMaxIndex = currentLineOriginalIndex + scanLine.xLeft - 1
                leftSpiltIndex = currentLineOriginalIndex + scanLine.xLeft
                scanLine.xLeft = xLeft
                scanedLines[lineNumer] = scanLine
            }else if scanLine.xLeft >= xLeft && scanLine.xRight <= xRight {
                scanLine.xLeft = xLeft
                scanLine.xRight = xRight
                scanedLines[lineNumer] = scanLine
            }
        }else {
            scanedLines[lineNumer] = FillLineInfo(lineNumber: lineNumer, xLeft: xLeft, xRight: xRight)
        }
        while currentPixelIndex <= currntLineMaxIndex {
            var isFindSeed = false

            while currentPixelIndex < currntLineMaxIndex &&
                compareColor(color: originalColorRgbaValue, otherColor: pixels[currentPixelIndex], tolorance: colorTolorance) {
                    isFindSeed = true
                    currentPixelIndex += 1
                    xCurrent += 1
            }
            
            if isFindSeed {
                if compareColor(color: originalColorRgbaValue, otherColor: pixels[currentPixelIndex], tolorance: colorTolorance) &&
                    currentPixelIndex == currntLineMaxIndex {

                    if leftSpiltIndex == nil ||
                        !compareColor(color: originalColorRgbaValue, otherColor: pixels[leftSpiltIndex!], tolorance: colorTolorance){
                        seedPointList.push(CGPoint(x: xCurrent, y: lineNumer))
                    }
                }else {
                    seedPointList.push(CGPoint(x: xCurrent - 1, y: lineNumer))
                }
            }
            currentPixelIndex += 1
            xCurrent += 1
        }
    }
    
    private func isBlackColor(color:UInt32) -> Bool {
        let colorRed = Int((color >> 0) & 0xff)
        let colorGreen = Int((color >> 8) & 0xff)
        let colorBlue = Int((color >> 16) & 0xff)
        let colorAlpha = Int((color >> 24) & 0xff)
        
        if colorRed < colorTolorance &&
            colorGreen < colorTolorance &&
            colorBlue < colorTolorance &&
            colorAlpha > 255 - colorTolorance{
            return true
        }
        return false
    }
    private func compareColor(color:UInt32, otherColor:UInt32, tolorance:Int) -> Bool {
        if color == otherColor {
            return true
        }
        let colorRed = Int((color >> 0) & 0xff)
        let colorGreen = Int((color >> 8) & 0x00ff)
        let colorBlue = Int((color >> 16) & 0xff)
        let colorAlpha = Int((color >> 24) & 0xff)
        
        let otherColorRed = Int((otherColor >> 0) & 0xff)
        let otherColorGreen = Int((otherColor >> 8) & 0xff)
        let otherColorBlue = Int((otherColor >> 16) & 0xff)
        let otherColorAlpha = Int((otherColor >> 24) & 0xff)
        
        if abs(colorRed - otherColorRed) > tolorance ||
            abs(colorGreen - otherColorGreen) > tolorance   ||
            abs(colorBlue - otherColorBlue) > tolorance ||
            abs(colorAlpha - otherColorAlpha) > tolorance {
            return false
        }
        return true
    }
    
}


extension UIColor {
    fileprivate var rgbaValue:UInt32 {
        var red:CGFloat = 0
        var green:CGFloat = 0
        var blue:CGFloat = 0
        var alpha:CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return UInt32(red * 255) << 0 | UInt32(green * 255) << 8 | UInt32(blue * 255) << 16 | UInt32(alpha * 255) << 24
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "IR")
        assert(green >= 0 && green <= 255, "IG")
        assert(blue >= 0 && blue <= 255, "IB")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
}
