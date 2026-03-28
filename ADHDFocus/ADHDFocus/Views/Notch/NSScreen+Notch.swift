import AppKit

extension NSScreen {
    var hasNotch: Bool {
        safeAreaInsets.top > 0
    }

    var notchSize: CGSize {
        guard hasNotch else {
            return CGSize(width: 224, height: 38)
        }
        let fullWidth = frame.width
        let leftPadding = auxiliaryTopLeftArea?.width ?? 0
        let rightPadding = auxiliaryTopRightArea?.width ?? 0
        let notchWidth = fullWidth - leftPadding - rightPadding + 4
        let menuBarHeight = frame.maxY - visibleFrame.maxY
        let notchHeight = max(safeAreaInsets.top, menuBarHeight)
        return CGSize(width: notchWidth, height: notchHeight)
    }

    var notchFrame: CGRect {
        let size = notchSize
        let originX = frame.origin.x + (frame.width - size.width) / 2
        let originY = frame.maxY - size.height
        return CGRect(x: originX, y: originY, width: size.width, height: size.height)
    }
}
