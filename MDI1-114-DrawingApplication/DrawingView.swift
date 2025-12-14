//
//  DrawingView.swift
//  MDI1-114-DrawingApplication
//
//  Created by Christian Bonilla on 13/12/25.
//

import SwiftUI
import PencilKit // UIKit

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        canvasView.isUserInteractionEnabled = true

        // Drag interaction
        let dragInteraction = UIDragInteraction(delegate: context.coordinator)
        canvasView.addInteraction(dragInteraction)

        // Pinch to Zoom
        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )

        // Rotate
        let rotateGesture = UIRotationGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleRotate(_:))
        )

        pinchGesture.delegate = context.coordinator
        rotateGesture.delegate = context.coordinator

        canvasView.addGestureRecognizer(pinchGesture)
        canvasView.addGestureRecognizer(rotateGesture)

        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject,
                      PKCanvasViewDelegate,
                      UIDragInteractionDelegate,
                      UIGestureRecognizerDelegate {
        var parent: CanvasView
        
        init(_ parent: CanvasView) {
            self.parent = parent
        }
        
        // MARK: - PencilKit
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Optional
        }
        
        // MARK: - Drag Interaction
        func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
            let image = parent.canvasView.drawing.image(
                from: parent.canvasView.bounds,
                scale: 2.0
            )
            
            let provider = NSItemProvider(object: image)
            return [UIDragItem(itemProvider: provider)]
        }
        
        // MARK: - Gesture Recognizer Delegate
            func gestureRecognizer(
                _ gestureRecognizer: UIGestureRecognizer,
                shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
            ) -> Bool {
                return true
            }
        
        // MARK: - Pinch Gesture (Zoom)
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let view = gesture.view else { return }

            let currentScale = view.frame.size.width / view.bounds.size.width
            let minScale: CGFloat = 0.5
            let maxScale: CGFloat = 3.0

            var newScale = currentScale * gesture.scale
            newScale = min(max(newScale, minScale), maxScale)

            let scale = newScale / currentScale
            view.transform = view.transform.scaledBy(x: scale, y: scale)
            gesture.scale = 1
        }

        // MARK: - Rotate Gesture
        @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) {
            guard let view = gesture.view else { return }

            if gesture.state == .changed || gesture.state == .ended {
                view.transform = view.transform.rotated(by: gesture.rotation)
                gesture.rotation = 0
            }
        }

        
    }
}

// SwiftUI
struct DrawingView: View {
    @State private var canvasView = PKCanvasView() // UI Kit Components
    @State private var toolPicker = PKToolPicker() // UI Kit Components
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Is taking UI Kit Components (two) and returning
                CanvasView(
                    canvasView: $canvasView,
                    toolPicker: $toolPicker
                )
                .navigationBarTitle("Drawing Pad", displayMode: .inline)
                .toolbar {
                    // LEADING
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack {
                            Button(action: clearDrawing) {
                                Label("Clear", systemImage: "trash")
                            }
                            .keyboardShortcut("k", modifiers: .command)
                        }
                    }

                    // TRAILING
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 20) {
                            Button(action: undoAction) {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                            }
                            .keyboardShortcut("z", modifiers: .command)

                            Button(action: redoAction) {
                                Label("Redo", systemImage: "arrow.uturn.forward")
                            }
                            .keyboardShortcut("z", modifiers: [.command, .shift])
                        }
                    }
                }
                .onAppear(perform: setUpToolPicker)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func clearDrawing() {
        canvasView.drawing = PKDrawing()
    }
    
    func undoAction() {
        canvasView.undoManager?.undo()
    }
    
    func redoAction() {
        canvasView.undoManager?.redo()
    }
    
    private func setUpToolPicker() {
        DispatchQueue.main.async {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }
    }
}
