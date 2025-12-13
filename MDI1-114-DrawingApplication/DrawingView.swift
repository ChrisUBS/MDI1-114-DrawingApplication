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
        
        let dragInteraction = UIDragInteraction(delegate: context.coordinator)
        canvasView.addInteraction(dragInteraction)
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate, UIDragInteractionDelegate {
        var parent: CanvasView
        
        init(_ parent: CanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            
        }
        
        func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
            let image = parent.canvasView.drawing.image(
                from: parent.canvasView.bounds,
                scale: 2.0
            )
            
            let provider = NSItemProvider(object: image)
            return [UIDragItem(itemProvider: provider)]
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
