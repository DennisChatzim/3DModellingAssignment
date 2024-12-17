//
//  MainSwiftUIScene.swift
//  Smart-3D-ObjManipulation
//
//  Created by Dionisis Chatzimarkakis on 16/12/24.
//

import SwiftUI
import SceneKit
import Metal
import MetalKit
import Foundation

// This was the first time I have ever tried to build something with Metal and SceneKit so it wasn't possible to make it in 1-2 days
// If I had the time to start learning about 3D modeling and MetalKit technology I would make it but learning all this frameworks in 1-2 days its impossible.
// I finished this project in less than 5 hours without having any experience BUT I spent more than 6 hours to investigate metal shaders and replacing the SceneView with MTKView as you can find inside the commented code of "MetalView.swift" and "MetalRenderer.swift" files but I gave up because its impossible to make my self expert in Metal in less than 2 days, it needs time.
// I did my effort and I would be glad to start reading and learning about 3D modelling and Metal and SheneKit but unfortunately I didn't have the chance to work on such frameworks in the past.


struct MainSwiftUIScene: View {
    
    let welcomeText = "Welcome to Smart-3D-ObjManipulation"

    @State var scene: SCNScene = SCNScene()
    @State private var objectPosition = SCNVector3(0.0, 0.0, 0.0)
    @State private var objectScale: Float = 1.0
    @State private var initialRotation = SCNVector4(0, 1, 0, 0)
    @State private var cameraPosition = SCNVector3(0, 0, 5)
    @State private var camera = SCNCamera()
    @State private var currentInteraction: InteractionType = .translate
    @State private var subInteractionParameter: interactionParameter = .none
    
    @State var boxNode = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.2))
    @State private var skewFactor: Float = 0.1
    @State private var nearFactor: Float = 5.0
    @State private var currentFOV: Float = 10.0
    @State var isSceneInitialized = false
    
    enum InteractionType {
        case none, translate, rotate, scale, cameraPosition
    }
    
    enum interactionParameter {
        case none, rotateX, rotateY, rotateZ, scaleX, scaleY, scaleZ
    }
    
    var body: some View {
        
        ZStack {
            
            Color.black
            
            VStack {
                
                Text(welcomeText)
                    .font(.title3.bold())
                    .padding()
                    .padding(.top, 30)
                
                VStack {
                    
                    mainModes
                    
                    if currentInteraction == .rotate {
                        
                        rotateAxisView
                        
                    }
                    
                    if currentInteraction == .scale {
                        
                        scaleAxisView
                        
                    }
                    
                    slidersFOV
                    
                }
                
                // Scene itself with custom gesture handling
                SceneView(
                    scene: scene,
                    options: [.autoenablesDefaultLighting] // Disable camera control to avoid conflict
                )
                .frame(width: 900, height: 900)
                .simultaneousGesture(DragGesture()
                    .onChanged { gesture in
                        if currentInteraction == .translate {
                            
                            handleTranslation(gesture: gesture)
                            
                        } else if currentInteraction == .scale {
                            
                            handleScale(gesture: gesture)
                            
                        } else if currentInteraction == .rotate {
                            
                            handleRotate(gesture: gesture)
                            
                        } else if currentInteraction == .cameraPosition {
                            
                            handleCamera(gesture: gesture)
                        }
                    }
                )
                Spacer()
            }
        }
        .onAppear {
            setupScene()
        }
    }
    
    var mainModes: some View {
        
        HStack {
            
            Button("Translate") {
                currentInteraction = .translate
            }
            .padding()
            .background(currentInteraction == .translate ? Color.blue : Color.gray)
            .cornerRadius(8)
            
            Button("Rotate") {
                currentInteraction = .rotate
                subInteractionParameter = .rotateY
            }
            .padding()
            .background(currentInteraction == .rotate ? Color.blue : Color.gray)
            .cornerRadius(8)
            
            Button("Scale") {
                currentInteraction = .scale
                subInteractionParameter = .scaleX
            }
            .padding()
            .background(currentInteraction == .scale ? Color.blue : Color.gray)
            .cornerRadius(8)
            
            
            Button("Apply custom transformations") {
                applyCompositeTransformations()
            }
            .padding()
            .background(Color.gray)
            .cornerRadius(8)
            
            Button("Reset") {
                resetNode()
            }
            .padding()
            .background(Color.gray)
            .cornerRadius(8)
            
        }
        
    }
    
    var rotateAxisView: some View {
        
        HStack {
            
            Button("Rotate on X axis") {
                subInteractionParameter = .rotateX
            }
            .padding()
            .background(subInteractionParameter == .rotateX ? Color.blue : Color.gray)
            .cornerRadius(8)
            
            Button("Rotate on Y axis") {
                subInteractionParameter = .rotateY
            }
            .padding()
            .background(subInteractionParameter == .rotateY ? Color.blue : Color.gray)
            .cornerRadius(8)
            
            Button("Rotate on Z axis") {
                subInteractionParameter = .rotateZ
            }
            .padding()
            .background(subInteractionParameter == .rotateZ ? Color.blue : Color.gray)
            .cornerRadius(8)
            
        }
        
    }
    
    var scaleAxisView: some View {
        
        HStack {
            
            Button("Scale on X axis") {
                subInteractionParameter = .scaleX
            }
            .padding()
            .background(subInteractionParameter == .scaleX ? Color.blue : Color.gray)
            .cornerRadius(8)
            
            Button("Scale on Y axis") {
                subInteractionParameter = .scaleY
            }
            .padding()
            .background(subInteractionParameter == .scaleY ? Color.blue : Color.gray)
            .cornerRadius(8)
            
            Button("Scale on Z axis") {
                subInteractionParameter = .scaleZ
            }
            .padding()
            .background(subInteractionParameter == .scaleZ ? Color.blue : Color.gray)
            .cornerRadius(8)
            
        }
    }
    
    var slidersFOV: some View {
        
        VStack {
            
            // Slider for Zoom Parameter
            VStack {
                Text("Zoom factor: \(String(format: "%.2f", nearFactor))")
                    .font(.caption)
                Slider(value: $nearFactor, in: 0.4...8.0, step: 0.1)
                    .padding()
                    .onChange(of: nearFactor) { _, newValue in
                        debugPrint("newValue of nearFactor = \(nearFactor)")
                        applyCustomProjection(to: camera, newSkewFactor: CGFloat(newValue),
                                              newNear: CGFloat(nearFactor),
                                              newFOV: CGFloat(currentFOV))
                    }
            }
            .padding()
            
            // Slider for Slew Parameter
            VStack {
                Text("Horizontal FOV(Skew): \(String(format: "%.2f", skewFactor))")
                    .font(.caption)
                Slider(value: $skewFactor, in: 0.1...200.0, step: 0.1)
                    .padding()
                    .onChange(of: skewFactor) { _, newValue in
                        debugPrint("newValue of skewFactor = \(skewFactor)")
                        applyCustomProjection(to: camera,
                                              newSkewFactor: CGFloat(newValue),
                                              newNear: CGFloat(nearFactor),
                                              newFOV: CGFloat(currentFOV))
                    }
            }
            .padding()
            
            // Slider for FOV Parameter
            VStack {
                Text("FOV: \(String(format: "%.2f", currentFOV))")
                    .font(.caption)
                Slider(value: $currentFOV, in: 1...70.0, step: 0.1)
                    .padding()
                    .onChange(of: currentFOV) { _, newValue in
                        debugPrint("newValue of currentFOV = \(currentFOV)")
                        applyCustomProjection(to: camera,
                                              newSkewFactor: CGFloat(newValue),
                                              newNear: CGFloat(nearFactor),
                                              newFOV: CGFloat(currentFOV))
                    }
            }
            .padding()
        }
    }
    
    func handleTranslation(gesture: DragGesture.Value) {
        
        // Create a custom translation matrix
        let translationMatrix = SCNMatrix4MakeTranslation(
            CGFloat(Float(gesture.translation.width)) * 0.0001,
            CGFloat(Float(-gesture.translation.height)) * 0.0003,
            0.0
        )
        
        boxNode.transform = SCNMatrix4Mult(boxNode.transform, translationMatrix)
        
    }
    
    func handleScale(gesture: DragGesture.Value) {
        
        let scaleFactor = (gesture.translation.width + gesture.translation.height) * 0.0005
        if subInteractionParameter == .scaleX {
            objectScale = Float(boxNode.scale.x)
            debugPrint("Current boxNode.scale.x = \(boxNode.scale.x)")
            objectScale = max(0.1, min(5.0, objectScale + Float(scaleFactor))) // Min and max scale bounds
            boxNode.scale = SCNVector3(CGFloat(objectScale), boxNode.scale.y, boxNode.scale.z)
        } else  if subInteractionParameter == .scaleY {
            objectScale = Float(boxNode.scale.y)
            debugPrint("Current boxNode.scale.y = \(boxNode.scale.y)")
            objectScale = max(0.1, min(5.0, objectScale + Float(scaleFactor))) // Min and max scale bounds
            boxNode.scale = SCNVector3(boxNode.scale.x, CGFloat(objectScale), boxNode.scale.z)
        } else if subInteractionParameter == .scaleZ {
            objectScale = Float(boxNode.scale.z)
            debugPrint("Current boxNode.scale.z = \(boxNode.scale.z)")
            objectScale = max(0.1, min(5.0, objectScale + Float(scaleFactor))) // Min and max scale bounds
            boxNode.scale = SCNVector3(boxNode.scale.x, boxNode.scale.y, CGFloat(objectScale))
        }
        
        // Apply dynamic color change based on scale
        let normalizedScale = min(boxNode.scale.x, boxNode.scale.y, boxNode.scale.z)
        
        // Change color based on scale
        boxNode.geometry?.firstMaterial?.diffuse.contents = NSColor(
            red: CGFloat(1.0 - normalizedScale / 5.0),
            green: CGFloat(normalizedScale / 5.0),
            blue: 0.0,
            alpha: 1.0
        )
        
        // Apply glow effect based on scale
        boxNode.geometry?.firstMaterial?.emission.contents = NSColor(
            red: CGFloat(normalizedScale / 5.0),
            green: CGFloat(1.0 - normalizedScale / 5.0),
            blue: 0.0,
            alpha: 1.0
        )
        
    }
    
    func handleRotate(gesture: DragGesture.Value) {
        
        // Only update initial rotation when the gesture starts
        if initialRotation.x == 0 && initialRotation.y == 0 {
            initialRotation = SCNVector4(Float(boxNode.eulerAngles.y), Float(boxNode.eulerAngles.x), 0, 0)
        }
        
        // Update the rotation only when rotating
        let radiansX = initialRotation.x + gesture.translation.width * 0.01
        let radiansY = initialRotation.y + gesture.translation.height * 0.01
        let avgMovement = radiansX + radiansY / 2.0
        
        if subInteractionParameter == .rotateX {
            boxNode.eulerAngles = SCNVector3(-avgMovement, boxNode.eulerAngles.y, boxNode.eulerAngles.z)
        } else  if subInteractionParameter == .rotateY {
            boxNode.eulerAngles = SCNVector3(boxNode.eulerAngles.x, avgMovement, boxNode.eulerAngles.z)
        } else if subInteractionParameter == .rotateZ {
            boxNode.eulerAngles = SCNVector3(boxNode.eulerAngles.x, boxNode.eulerAngles.y, avgMovement)
        }
        
        // Apply dynamic color change based on rotation angle
         let rotationAngle = Float(abs(avgMovement)) //boxNode.eulerAngles.y))
         let normalizedRotation = min(rotationAngle / Float.pi, 1.0)  // Normalize the rotation to [0, 1]
         
         // Change color based on rotation
         boxNode.geometry?.firstMaterial?.diffuse.contents = NSColor(
             red: CGFloat(1.0 - normalizedRotation),
             green: CGFloat(normalizedRotation),
             blue: 0.0,
             alpha: 1.0
         )
         
         // Apply glow effect based on rotation
         boxNode.geometry?.firstMaterial?.emission.contents = NSColor(
             red: CGFloat(normalizedRotation),
             green: CGFloat(1.0 - normalizedRotation),
             blue: 0.0,
             alpha: 1.0
         )
    }
    
    func handleCamera(gesture: DragGesture.Value) {
        
        // Camera position control logic
        cameraPosition.x -= (gesture.translation.width * 0.0001)
        cameraPosition.y -= (gesture.translation.height * 0.0001)
        
    }
    
    func resetNode() {
        
        currentInteraction = .translate
        boxNode.eulerAngles =  SCNVector3(0, 0, 0)
        objectPosition = SCNVector3(0.0, 0.0, 0.0)
        objectScale = 1.0
        initialRotation = SCNVector4(0, 1, 0, 0)
        cameraPosition = SCNVector3(0, 0, 5)
        subInteractionParameter = .none
        boxNode.scale = SCNVector3(1.0, 1.0, 1.0)
        boxNode.transform = SCNMatrix4Identity
        
        skewFactor = 0.1
        nearFactor = 2.0
        currentFOV = 10.0
        
    }
        
    func setupScene() {
        
        guard !isSceneInitialized else { return }
        
        debugPrint("Inside setupScene")
        
        isSceneInitialized = true
        scene.background.contents = NSColor.black
        skewFactor = 0.1
        nearFactor = 2.0
        currentFOV = 10.0
        
        boxNode.position = objectPosition
        boxNode.scale = SCNVector3(1, 1, 1)
        boxNode.rotation =  SCNVector4(0, 1, 0, 0)
        
        // Create custom material for the boxNode
        let boxMaterial = SCNMaterial()
        
        // Set diffuse color to blue
        boxMaterial.diffuse.contents = NSColor.blue
        
        //let stripePattern = NSImage(named: "tigerSkin") // Create or load a red/blue striped pattern image
        //boxMaterial.diffuse.contents = stripePattern ?? NSColor.blue // Default to blue if pattern isn't found
        
        // Set the boxNode material to the custom material
        boxNode.geometry?.materials = [boxMaterial]
        
        // Apply reflection mapping (environment map)
        let reflectionTexture = NSImage(named: "tigerSkin") // Your reflection map texture
        boxMaterial.reflective.contents = reflectionTexture
        
        // Set the diffuse material (base color) of the object
        boxMaterial.diffuse.contents = NSColor.red // Example base color
        
        // Set the specular material to simulate shiny surfaces
        boxMaterial.specular.contents = NSColor.white
                
        // Add the box node to the scene
        scene.rootNode.addChildNode(boxNode)
        
        // Add a Camera
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = cameraPosition
                
        scene.rootNode.addChildNode(cameraNode)
        
        let light = SCNLight()
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0, 5, 5)
        scene.rootNode.addChildNode(lightNode)
        
        resetNode()

        applyCompositeTransformations()
                
    }
    
    //    Matrix Compositions:
    //    ◦ Combine multiple transformations (translation, rotation, scaling) into a single
    //    transformation matrix, ensuring the proper sequence of operations.
    func applyCompositeTransformations() {
        // Create individual matrices
        let translationMatrix = SCNMatrix4MakeTranslation(objectPosition.x, objectPosition.y, objectPosition.z)
        let scaleMatrix = SCNMatrix4MakeScale(CGFloat(objectScale), CGFloat(objectScale), CGFloat(objectScale))
        let rotationMatrixX = SCNMatrix4MakeRotation(initialRotation.x, 1, 0, 0)
        let rotationMatrixY = SCNMatrix4MakeRotation(initialRotation.y, 0, 1, 0)
        let rotationMatrixZ = SCNMatrix4MakeRotation(initialRotation.z, 0, 0, 1)
        
        // Combine the transformations in the proper order: Scale -> Rotate -> Translate
        let combinedMatrix = SCNMatrix4Mult(SCNMatrix4Mult(SCNMatrix4Mult(scaleMatrix, rotationMatrixX), rotationMatrixY), rotationMatrixZ)
        let finalMatrix = SCNMatrix4Mult(combinedMatrix, translationMatrix)
        
        // Apply to the boxNode
        boxNode.transform = finalMatrix
    }
    
    // Function to apply a custom projection matrix
    func applyCustomProjection(to camera: SCNCamera,
                               newSkewFactor: CGFloat,
                               newNear: CGFloat,
                               newFOV: CGFloat) {
        
        debugPrint("applyCustomProjection")
        // Define a skewed perspective projection matrix
        //let fov: CGFloat = 30.0 // Field of view in degrees
        let aspectRatio: CGFloat = 1.0 // Aspect ratio (width / height)
        
        let far: CGFloat = 200.0
        //let skewFactor: CGFloat = 0.1 // Introduces a skew in the field of view
        
        let top = newNear * CGFloat(tanf(Float(newFOV) * 0.5 * .pi / 180.0))
        let bottom = -top
        let right = top * aspectRatio
        let left = -right
        
        // Skew matrix for perspective distortion
        let skewMatrix = SCNMatrix4(
            m11: 1.0, m12: 0.0, m13: 0.0, m14: newSkewFactor,
            m21: 0.0, m22: 1.0, m23: 0.0, m24: 0.0,
            m31: 0.0, m32: 0.0, m33: 1.0, m34: 0.0,
            m41: 0.0, m42: 0.0, m43: 0.0, m44: 1.0
        )
        
        // Perspective matrix
        let perspectiveMatrix = SCNMatrix4(
            m11: 2.0 * newNear / (right - left), m12: 0.0, m13: (right + left) / (right - left), m14: 0.0,
            m21: 0.0, m22: 2.0 * newNear / (top - bottom), m23: (top + bottom) / (top - bottom), m24: 0.0,
            m31: 0.0, m32: 0.0, m33: -(far + newNear) / (far - newNear), m34: -2.0 * far * newNear / (far - newNear),
            m41: 0.0, m42: 0.0, m43: -1.0, m44: 0.0
        )
        
        // Combine the skew and perspective matrices
        let customMatrix = SCNMatrix4Mult(skewMatrix, perspectiveMatrix)
        
        // Apply the custom projection matrix to the camera
        camera.usesOrthographicProjection = true // Ensure perspective mode is used
        camera.projectionTransform = customMatrix
    }
    
}

#Preview {
    MainSwiftUIScene()
}
