//
//  CustomScheneWithMetal.swift
//  Smart-3D-ObjManipulation
//
//  Created by Dionisis Chatzimarkakis on 16/12/24.
//

import SwiftUI
import Metal
import SceneKit
import MetalKit

// Define SceneView using NSViewRepresentable for macOS
struct CustomSceneWithMetal: NSViewRepresentable {
    var scene: SCNScene
    
    // Metal setup
    private var device: MTLDevice!
    private var renderer: SCNRenderer!
    
    init(scene: SCNScene) {
        self.scene = scene
        
        // Initialize Metal device
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = metalDevice
        
        // Initialize SCNRenderer with Metal device
        self.renderer = SCNRenderer(device: self.device, options: nil)
        self.renderer.scene = scene
        
        applyCustomShaders(to: scene)
    }
    
    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.delegate = context.coordinator
        scnView.autoenablesDefaultLighting = true
        return scnView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        // Update logic if needed
    }
    
    // Apply custom Metal shaders using SCNProgram
    private func applyCustomShaders(to scene: SCNScene) {

        let program = SCNProgram()
        program.fragmentFunctionName = "myFragment"
        program.vertexFunctionName = "myVertex"

        // Apply the program to all geometries in the scene
        for node in scene.rootNode.childNodes {
            if let geometry = node.geometry {
                for material in geometry.materials {
                    material.program = program
                }
            }
        }
    }
    
    class Coordinator: NSObject, SCNSceneRendererDelegate {
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            // Update logic can go here if needed
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
            // Handle animation updates if needed
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
}

