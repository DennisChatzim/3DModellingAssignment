//
//  Untitled.swift
//  Smart-3D-ObjManipulation
//
//  Created by Dionisis Chatzimarkakis on 17/12/24.
//
import SwiftUI
import MetalKit

/*
struct MetalView: NSViewRepresentable {
    
    var renderer: MetalRenderer
    var myCoordinator = RendererCoordinator()
    
    //@Binding var lightPositionX: Float
    
    func makeCoordinator() -> RendererCoordinator {
        myCoordinator.renderer = renderer
        renderer.setup()
        return myCoordinator
    }

    func makeNSView(context: Context) -> MTKView {
        // Create the Metal view
        guard let device = renderer.device else { //MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        let metalView = MTKView(frame: CGRect.init(x: 0, y: 0, width: 700, height: 700), device: device)
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = false
        metalView.device = renderer.device
        metalView.delegate = renderer
        return metalView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        // Update renderer with the new light position when the SwiftUI state changes
        //context.coordinator.renderer?.lightPosition.x = lightPositionX
    }

    class RendererCoordinator: NSObject {

        var renderer: MetalRenderer?
        
    }
    
}
*/
