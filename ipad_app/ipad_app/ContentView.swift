import SwiftUI

enum DrawingMode {
    case freehand
    case straightLine
    case rectangle
}

enum DrawingEffect {
    case normal
    case rainbow
    case sprinkles
}

struct ContentView: View {
    @State private var currentColor: Color = .black
    @State private var lines: [Line] = []
    @State private var lineWidth: CGFloat = 2.0
    @State private var isEraserMode: Bool = false
    @State private var drawingMode: DrawingMode = .freehand
    @State private var drawingEffect: DrawingEffect = .normal
    @State private var isDarkMode: Bool = false
    @State private var isFilterApplied: Bool = false
    
    private let colorPalette: [Color] = [.black, .red, .green, .blue, .yellow, .purple, .orange]
    
    var body: some View {
        VStack {
            Text("Sofi & Stefi")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Slider(value: $lineWidth, in: 1...10, step: 1) {
                Text("Line Width")
            }
            .padding()
            
            DrawingView(currentColor: $currentColor, lines: $lines, lineWidth: $lineWidth, isEraserMode: $isEraserMode, drawingMode: $drawingMode, drawingEffect: $drawingEffect)
                .background(isDarkMode ? Color.black : Color.white)
                .border(isDarkMode ? Color.white : Color.black, width: 1)
                .padding()
            
            HStack {
                Button(action: {
                    if !lines.isEmpty {
                        lines.removeLast()
                    }
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    isEraserMode.toggle()
                }) {
                    Image(systemName: isEraserMode ? "pencil" : "eraser")
                        .padding()
                        .background(isEraserMode ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    switch drawingMode {
                    case .freehand:
                        drawingMode = .straightLine
                    case .straightLine:
                        drawingMode = .rectangle
                    case .rectangle:
                        drawingMode = .freehand
                    }
                }) {
                    Image(systemName: drawingModeIcon)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    isDarkMode.toggle()
                }) {
                    Image(systemName: isDarkMode ? "sun.max" : "moon")
                        .padding()
                        .background(isDarkMode ? Color.white : Color.black)
                        .foregroundColor(isDarkMode ? .black : .white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    switch drawingEffect {
                    case .normal:
                        drawingEffect = .rainbow
                    case .rainbow:
                        drawingEffect = .sprinkles
                    case .sprinkles:
                        drawingEffect = .normal
                    }
                }) {
                    Image(systemName: drawingEffectIcon)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    applyFilter()
                }) {
                    Image(systemName: "wand.and.stars")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            
            ColorPaletteView(colors: colorPalette, selectedColor: $currentColor)
                .padding()
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    private var drawingModeIcon: String {
        switch drawingMode {
        case .freehand:
            return "scribble"
        case .straightLine:
            return "line.diagonal"
        case .rectangle:
            return "rectangle"
        }
    }
    
    private var drawingEffectIcon: String {
        switch drawingEffect {
        case .normal:
            return "paintbrush"
        case .rainbow:
            return "rainbow"
        case .sprinkles:
            return "sparkles"
        }
    }
    
    private func applyFilter() {
        // Implement your predefined filter logic here
        isFilterApplied.toggle()
        // Example: Change all lines to a specific color
        if isFilterApplied {
            lines = lines.map { line in
                var newLine = line
                newLine.color = .gray
                return newLine
            }
        } else {
            // Revert the filter if needed
        }
    }
}

struct DrawingView: View {
    @Binding var currentColor: Color
    @Binding var lines: [Line]
    @Binding var lineWidth: CGFloat
    @Binding var isEraserMode: Bool
    @Binding var drawingMode: DrawingMode
    @Binding var drawingEffect: DrawingEffect
    @State private var currentLine: Line = Line(points: [], color: .black, lineWidth: 2.0)
    @State private var startPoint: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Canvas { context, size in
                    for line in lines {
                        drawLine(line, in: context)
                    }
                    drawLine(currentLine, in: context)
                }
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newPoint = value.location
                        switch drawingMode {
                        case .freehand:
                            currentLine.points.append(newPoint)
                        case .straightLine:
                            if currentLine.points.isEmpty {
                                currentLine.points.append(startPoint)
                            }
                            currentLine.points = [startPoint, newPoint]
                        case .rectangle:
                            if currentLine.points.isEmpty {
                                currentLine.points.append(startPoint)
                            }
                            currentLine.points = [startPoint, CGPoint(x: newPoint.x, y: startPoint.y), newPoint, CGPoint(x: startPoint.x, y: newPoint.y), startPoint]
                        }
                        currentLine.color = isEraserMode ? .white : getColor(for: newPoint)
                        currentLine.lineWidth = lineWidth
                    }
                    .onEnded { value in
                        lines.append(currentLine)
                        currentLine = Line(points: [], color: isEraserMode ? .white : currentColor, lineWidth: lineWidth)
                        startPoint = value.location
                    }
                )
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: {
                lines.removeAll()
            }) {
                Image(systemName: "trash")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
    
    private func drawLine(_ line: Line, in context: GraphicsContext) {
        var path = Path()
        for (i, point) in line.points.enumerated() {
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        context.stroke(path, with: .color(line.color), lineWidth: line.lineWidth)
    }
    
    private func getColor(for point: CGPoint) -> Color {
        switch drawingEffect {
        case .normal:
            return currentColor
        case .rainbow:
            let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
            return colors.randomElement() ?? currentColor
        case .sprinkles:
            return Color(hue: Double.random(in: 0...1), saturation: 1, brightness: 1)
        }
    }
}

struct Line: Identifiable {
    var id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
}

struct ColorPaletteView: View {
    let colors: [Color]
    @Binding var selectedColor: Color
    
    var body: some View {
        HStack {
            ForEach(colors, id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .onTapGesture {
                        selectedColor = color
                    }
                    .overlay(
                        Circle()
                            .stroke(selectedColor == color ? Color.black : Color.clear, lineWidth: 2)
                    )
            }
        }
    }
}

#Preview {
    ContentView()
}
