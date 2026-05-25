import AppKit
import MetalKit

public final class EDROverlayView: MTKView, MTKViewDelegate {
    private var commandQueue: MTLCommandQueue?

    public init(frame: CGRect) {
        super.init(frame: frame, device: MTLCreateSystemDefaultDevice())

        guard let device else {
            fatalError("No Metal device available")
        }

        commandQueue = device.makeCommandQueue()
        delegate = self
        autoResizeDrawable = false
        drawableSize = CGSize(width: 1, height: 1)
        colorPixelFormat = .rgba16Float
        colorspace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        clearColor = MTLClearColorMake(16.0, 16.0, 16.0, 1.0)
        preferredFramesPerSecond = 5
        framebufferOnly = false

        if let layer = self.layer as? CAMetalLayer {
            layer.wantsExtendedDynamicRangeContent = true
            layer.isOpaque = false
            layer.pixelFormat = .rgba16Float
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func draw(in view: MTKView) {
        guard let commandQueue,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let drawable = view.currentDrawable else {
            return
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

public final class EDROverlayWindowController: NSWindowController, NSWindowDelegate {
    private let screen: NSScreen

    public init(screen: NSScreen) {
        self.screen = screen
        let rect = NSRect(x: screen.frame.origin.x, y: screen.frame.maxY - 1, width: 1, height: 1)
        let window = NSWindow(contentRect: rect, styleMask: [], backing: .buffered, defer: false)
        window.title = "ExtraBrightness EDR Overlay"
        window.collectionBehavior = [.stationary, .ignoresCycle, .canJoinAllSpaces]
        window.level = .screenSaver
        window.isOpaque = false
        window.hasShadow = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.contentView = EDROverlayView(frame: rect)
        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func show() {
        window?.orderFrontRegardless()
        reposition()
    }

    public func reposition() {
        window?.setFrameOrigin(CGPoint(x: screen.frame.origin.x, y: screen.frame.maxY - 1))
    }
}
