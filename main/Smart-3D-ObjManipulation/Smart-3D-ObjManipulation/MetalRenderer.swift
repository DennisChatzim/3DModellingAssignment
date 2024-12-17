//
//  MetalRenderer.swift
//  Smart-3D-ObjManipulation
//
//  Created by Dionisis Chatzimarkakis on 17/12/24.
//

import Metal
import MetalKit
import simd
import SwiftUI

// Trying to use Metal but it was too hard for the purpose of this assignment and the limited time.
// This was the first time I have ever tried to build something with Metal and SceneKit so it wasn't possible to make it in 1-2 days
// If I had the time to start learning about 3D modeling and MetalKit technology I would make it but learning all this frameworks in 1-2 days its impossible.
// I finished this project in less than 5 hours without having any experience BUT I spent more than 6 hours to investigate metal shaders and replacing the SceneView with MTKView as you can find inside the commented code of "MetalView.swift" and "MetalRenderer.swift" files but I gave up because its impossible to make my self expert in Metal in less than 2 days, it needs time.
// I did my effort and I would be glad to start reading and learning about 3D modelling and Metal and SheneKit but unfortunately I didn't have the chance to work on such frameworks in the past.


/*
struct BoxNode {
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    var modelMatrix: float4x4
}

class MetalRenderer: NSObject, MTKViewDelegate, ObservableObject {
    
    var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var renderPipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var indexBuffer: MTLBuffer!
    
    // Matrices and transformations
    private var modelMatrix: matrix_float4x4 = matrix_identity_float4x4
    private var projectionMatrix: matrix_float4x4 = matrix_identity_float4x4
    private var cameraPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 5)
    
    // Tracking gestures
    private var previousPanTranslation: CGSize = .zero
    private var previousRotationAngle: Float = 0.0
    private var previousScaleFactor: CGFloat = 1.0
    
    var uniformBuffer: MTLBuffer!
    var lightPosition: SIMD3<Float> = [0.0, 1.0, 1.0]
    var lightColor: SIMD3<Float> = [1.0, 1.0, 1.0]
    
    var boxNode: BoxNode!

    func matrix_perspective_left_hand(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
        let tanHalfFovy = tan(fovyRadians / 2.0)
        var matrix = matrix_float4x4(0)
        matrix.columns.0.x = 1.0 / (aspect * tanHalfFovy)
        matrix.columns.1.y = 1.0 / tanHalfFovy
        matrix.columns.2.z = (farZ + nearZ) / (nearZ - farZ)
        matrix.columns.2.w = -1.0
        matrix.columns.3.z = (2.0 * farZ * nearZ) / (nearZ - farZ)
        matrix.columns.3.w = 0.0
        return matrix
    }
    
    func simd_lookAt_leftHand(position: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> matrix_float4x4 {
        let zAxis = normalize(position - target) // Forward vector
        let xAxis = normalize(cross(up, zAxis))  // Right vector
        let yAxis = cross(zAxis, xAxis)          // Up vector

        var matrix = matrix_float4x4(0)
        matrix.columns.0 = SIMD4<Float>(xAxis.x, xAxis.y, xAxis.z, 0)
        matrix.columns.1 = SIMD4<Float>(yAxis.x, yAxis.y, yAxis.z, 0)
        matrix.columns.2 = SIMD4<Float>(-zAxis.x, -zAxis.y, -zAxis.z, 0)
        matrix.columns.3 = SIMD4<Float>(-dot(xAxis, position), -dot(yAxis, position), dot(zAxis, position), 1)

        return matrix
    }
    
    // Function to create a translation matrix
    func matrix_translate(_ matrix: matrix_float4x4, translation: SIMD3<Float>) -> matrix_float4x4 {
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.x = translation.x
        translationMatrix.columns.3.y = translation.y
        translationMatrix.columns.3.z = translation.z
        return matrix * translationMatrix
    }
    
    // Function to create a rotation matrix around the Y-axis
    func matrix_rotation_y(_ angle: Float) -> matrix_float4x4 {
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        
        return matrix_float4x4(columns: (
            SIMD4<Float>(cosAngle, 0, sinAngle, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(-sinAngle, 0, cosAngle, 0),
            SIMD4<Float>(0, 0, 0, 1)
        ))
    }
    
    // Function to create a scale matrix
    func matrix_scale(_ matrix: matrix_float4x4, scale: Float) -> matrix_float4x4 {
        var scaleMatrix = matrix_identity_float4x4
        scaleMatrix.columns.0.x = scale
        scaleMatrix.columns.1.y = scale
        scaleMatrix.columns.2.z = scale
        return matrix * scaleMatrix
    }
    
    func setup() {
        // Initialize Metal device and command queue
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()

        // Shader loading and pipeline setup (same as your current setup)

        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let shaderFileURL = documentsDirectory.appendingPathComponent("BasicShaders.metal")

        do {
            let shaderCode = try String(contentsOf: shaderFileURL, encoding: .utf8)
            let customLibrary = try device.makeLibrary(source: shaderCode, options: nil)
            let vertexFunction = customLibrary.makeFunction(name: "vertex_main")
            let fragmentFunction = customLibrary.makeFunction(name: "fragment_main")

            let vertexDescriptor = createVertexDescriptor()
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.vertexDescriptor = vertexDescriptor
            
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

            print("Shader code loaded: \(shaderCode)")

        } catch {
            print("Error reading shader file: \(error)")
        }

        // Geometry setup (box vertices and indices as before)
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(-0.5, -0.5,  0.5), SIMD3<Float>( 0.5, -0.5,  0.5),
            SIMD3<Float>( 0.5,  0.5,  0.5), SIMD3<Float>(-0.5,  0.5,  0.5),
            SIMD3<Float>(-0.5, -0.5, -0.5), SIMD3<Float>(-0.5,  0.5, -0.5),
            SIMD3<Float>( 0.5,  0.5, -0.5), SIMD3<Float>( 0.5, -0.5, -0.5)
        ]

        let indices: [UInt16] = [
            0, 1, 2, 0, 2, 3, // Front face
            4, 5, 6, 4, 6, 7, // Back face
            4, 5, 3, 4, 3, 0, // Left face
            1, 7, 6, 1, 6, 2, // Right face
            3, 2, 6, 3, 6, 5, // Top face
            0, 1, 7, 0, 7, 4  // Bottom face
        ]

        boxNode = BoxNode(
            vertexBuffer: device.makeBuffer(bytes: vertices, length: MemoryLayout<SIMD3<Float>>.size * vertices.count, options: .storageModeShared),
            indexBuffer: device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.size * indices.count, options: .storageModeShared),
            modelMatrix: matrix_identity_float4x4
        )

        // Update matrices for transformations (translation, rotation, perspective)
        let translationMatrix = matrix_translate(matrix_identity_float4x4, translation: SIMD3<Float>(0, 0, 0)) // Adjust translation as needed
        let rotationMatrix = matrix_rotation_y(Float.pi / 4) // Example rotation by 45 degrees
        let modelMatrix = translationMatrix * rotationMatrix // Combine translation and rotation
        self.modelMatrix = modelMatrix

        // Set up perspective projection matrix
        projectionMatrix = matrix_perspective_left_hand(fovyRadians: Float.pi / 4, aspect: 1.0, nearZ: 0.1, farZ: 100.0)

        // Calculate the view matrix (camera position and target)
        let viewMatrix = simd_lookAt_leftHand(position: SIMD3<Float>(0, 0, 5), target: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))

        // Calculate the Model-View-Projection matrix
        let modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix

        // Update the uniform buffer with the model-view-projection matrix and model matrix
        uniformBuffer = device.makeBuffer(bytes: [modelViewProjectionMatrix, modelMatrix], length: MemoryLayout<matrix_float4x4>.size * 2, options: .storageModeShared)

        // Set up the light position and other properties
        lightPosition = SIMD3<Float>(0.0, 1.0, 1.0)
        lightColor = SIMD3<Float>(1.0, 1.0, 1.0)
    }

    
    func createVertexDescriptor() -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()

        // Position attribute
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // Normal attribute
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = 12 // Assuming position takes 12 bytes (3 floats)
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        // Layout descriptor: How the data is laid out in the buffer
        vertexDescriptor.layouts[0].stride = 24 // Position (3 floats, 12 bytes) + Normal (3 floats, 12 bytes)
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        return vertexDescriptor
    }
    
    func updateCameraPosition() {
        // Update the model matrix (for example, applying rotation or translation)
        let rotatedMatrix = matrix_rotation_y(Float.pi / 4) // Example: rotate 45 degrees around Y-axis
        modelMatrix = matrix_translate(rotatedMatrix, translation: cameraPosition)
        // Update the camera matrix when the camera position changes
        //        modelMatrix = matrix_translate(modelMatrix, translation: cameraPosition)
    }
    
    func draw(in view: MTKView) {
         guard let drawable = view.currentDrawable else { return }
         let commandBuffer = commandQueue.makeCommandBuffer()!
         let renderPassDescriptor = view.currentRenderPassDescriptor!
         
         let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
         
         encoder.setRenderPipelineState(renderPipelineState)
         
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less // Specifies the comparison function
        depthStencilDescriptor.isDepthWriteEnabled = true     // Enables depth writing
        
        // Optional: set up stencil test descriptors if you need to use stencil buffers
        depthStencilDescriptor.frontFaceStencil = MTLStencilDescriptor()
        depthStencilDescriptor.backFaceStencil = MTLStencilDescriptor()
        
        device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        
         //encoder.setDepthStencilState(depthStencilState)
        
         // Set uniforms
         var modelViewProjectionMatrix = projectionMatrix * modelMatrix
         encoder.setVertexBytes(&modelViewProjectionMatrix, length: MemoryLayout<matrix_float4x4>.size, index: 1)
         
         // Set the vertex buffer for the cube (geometry data)
         encoder.setVertexBuffer(boxNode.vertexBuffer, offset: 0, index: 0)
         
         // Set the index buffer for the cube
         encoder.setVertexBuffer(boxNode.indexBuffer, offset: 0, index: 2)
         
         // Bind uniform buffer and lighting information to the fragment shader
         encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
         encoder.setFragmentBytes(&lightPosition, length: MemoryLayout<SIMD3<Float>>.size, index: 1)
         encoder.setFragmentBytes(&lightColor, length: MemoryLayout<SIMD3<Float>>.size, index: 2)
         
         // Draw the indexed primitives (triangles) for the box
         encoder.drawIndexedPrimitives(type: .triangle, indexCount: 36, indexType: .uint16, indexBuffer: boxNode.indexBuffer, indexBufferOffset: 0)
         
         encoder.endEncoding()
         
         commandBuffer.present(drawable)
         commandBuffer.commit()
     }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle resizing (e.g., update projection matrix on resize)
    }
    
    // Gesture Handlers for translation, rotation, and zoom
    func handlePanGesture(gesture: DragGesture.Value) {
        // Pan the camera based on drag movement
        let deltaX = Float(gesture.translation.width - previousPanTranslation.width) * 0.01
        let deltaY = Float(gesture.translation.height - previousPanTranslation.height) * 0.01
        cameraPosition.x -= deltaX
        cameraPosition.y -= deltaY
        updateCameraPosition()
        
        previousPanTranslation = gesture.translation
    }
    
    func endPanGesture() {
        // Reset translation state after drag ends
        previousPanTranslation = .zero
    }
    
    func handleRotateGesture(gesture: DragGesture.Value) {
        let value = gesture.translation.width
        // Rotate the object based on the rotation gesture
        let rotationAmount = Float(value) - previousRotationAngle
        let rotationMatrix = matrix_rotation_y(rotationAmount)
        modelMatrix = rotationMatrix * modelMatrix
        previousRotationAngle = Float(value)
    }
    
    func handleScaleGesture(gesture: DragGesture.Value) {
        
        let value = gesture.translation.width
        // Scale the object based on the pinch gesture
        let scaleFactor = Float(value / previousScaleFactor)
        modelMatrix = matrix_scale(modelMatrix, scale: scaleFactor)
        previousScaleFactor = value
    }
}
*/
