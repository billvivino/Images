import SwiftUI
import PencilKit


struct DrawingView: View {
    @Environment(\.undoManager) private var undoManager
    @EnvironmentObject var viewModel: AppViewModel
    
    var image: Image
//    private let canvasView = PKCanvasView()
    @State var canvasView = PKCanvasView()

    var body: some View {
        VStack {
            
                GeometryReader{proxy -> AnyView in
                    
                    let size = proxy.frame(in: .global)
                    
                    DispatchQueue.main.async {
                        if viewModel.rect == .zero {
                            viewModel.rect = size
                        }
                    }
                    
                    return AnyView (
                        ZoomableScrollView {
                        ZStack {
                            image
                                .resizable()
                                .scaledToFit()
                            MyCanvas(canvasView: $canvasView, picker: $viewModel.toolPicker)
                            
                            ForEach(viewModel.textBoxes) { box in
                                
                                Text(viewModel.textBoxes[viewModel.currentIndex].id == box.id && viewModel.addNewBox ? "" : box.text)
                                    .font(.system(size: 30))
                                    .fontWeight(box.isBold ? .bold : .none)
                                    .foregroundColor(box.textColor)
                                    .offset(box.offset)
                                    .gesture(DragGesture().onChanged({ (value) in
                                        
                                        let current = value.translation
                                        let lastOffset = box.lastOffset
                                        let newTranslation = CGSize(width: lastOffset.width+current.width, height: lastOffset.height+current.height)
                                        
                                        viewModel.textBoxes[getIndex(textBox: box)].offset = newTranslation
                                        
                                    }).onEnded({ (value) in
                                        
                                        viewModel.textBoxes[getIndex(textBox: box)].lastOffset = value.translation
                                        
                                    }))
                                    .onLongPressGesture (minimumDuration: 1.0) {
                                        viewModel.isDrawing = false
                                        viewModel.currentIndex = getIndex(textBox: box)
                                        withAnimation {
                                            viewModel.addNewBox = true
                                        }
                                    }
                            }
                        }
                        }
                    )
                
            }
            
            if viewModel.isDrawing {
                HStack(alignment: .bottom, spacing: 20) {
                    Button("Undo") {
                        undoManager?.undo()
                    }.padding()
                    Spacer()
                    Button("Clear") {
                        canvasView.drawing = PKDrawing()
                    }.padding()
                    Spacer()
                    Button("Redo") {
                        undoManager?.redo()
                    }.padding()
                }
            }
        }.onChange(of: viewModel.saveImageBool) { saveImageTrue in
            if saveImageTrue {
                saveImage()
            }
        }
    }
    
    func getIndex(textBox: TextBox) -> Int {
        let index = viewModel.textBoxes.firstIndex { (box) -> Bool in
            return textBox.id == box.id
        } ?? 0
        
        return index
    }
    
    func saveImage() {
        
        UIGraphicsBeginImageContextWithOptions(viewModel.rect.size, false, 0)
        
        let SwiftUIImageView = ZStack {
            image
                .resizable()
                .scaledToFit()
        }
        
        let imgController = UIHostingController(rootView: SwiftUIImageView).view!
        imgController.frame = viewModel.rect
        imgController.backgroundColor = .clear
        imgController.drawHierarchy(in: CGRect(origin: .zero, size: viewModel.rect.size), afterScreenUpdates: true)
        
        canvasView.drawHierarchy(in: CGRect(origin: .zero, size: viewModel.rect.size), afterScreenUpdates: true)
        
        let SwiftUIView = ZStack {
            
            ForEach(viewModel.textBoxes) { box in
                
                Text(viewModel.textBoxes[viewModel.currentIndex].id == box.id && viewModel.addNewBox ? "" : box.text)
                    .font(.system(size: 30))
                    .fontWeight(box.isBold ? .bold : .none)
                    .foregroundColor(box.textColor)
                    .offset(box.offset)
            }
        }
        
        let controller = UIHostingController(rootView: SwiftUIView).view!
        controller.frame = viewModel.rect
        controller.backgroundColor = .clear
        canvasView.backgroundColor = .clear
        
        controller.drawHierarchy(in: CGRect(origin: .zero, size: viewModel.rect.size), afterScreenUpdates: true)
        
        let generatedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        if let image = generatedImage?.pngData() {
            UIImageWriteToSavedPhotosAlbum(UIImage(data: image)!, nil, nil, nil)
            viewModel.message = "Image saved successfully."
            viewModel.showAlert.toggle()
        } else {
            viewModel.message = "Error saving photo to photo library."
            viewModel.showAlert.toggle()
        }
        
        if let imageJPGDAta = generatedImage?.jpegData(compressionQuality: 0.5) {
            uploadImage(imageData: imageJPGDAta)
        } else {
            viewModel.message = "Error uploading photo to Eulerity."
            viewModel.showAlert.toggle()
        }
        
        viewModel.saveImageBool = false
    }
    
    func uploadImage(imageData: Data) {
        
        struct UploadURL: Codable {
            var url: String
        }
        
        if let url = URL(string: "https://eulerity-hackathon.appspot.com/upload") {
            
            let dataTask = URLSession.shared.dataTask(with: url) { data, _, error in
                if error != nil {
                    viewModel.message = "Error loading JSON data of website to upload image."
                    viewModel.showAlert.toggle()
                    
                } else {
                    guard let data = data else { return }
                    DispatchQueue.main.async {
                        do {
                            let uploadURLString = try JSONDecoder().decode(UploadURL.self, from: data)
                            print(uploadURLString.url)
                            
                            if let uploadURL = URL(string: uploadURLString.url) {
                                var request = URLRequest(url: uploadURL)
                                request.httpMethod = "POST"
                                
                                let boundary = "Boundary-\(UUID().uuidString)"
                                
                                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                                
                                let mimeType = "image/jpg"
                                
                                guard let selectedImageURLString = viewModel.selectedImage?.url else {return}
                                
                                let fileName = "billvivino_image_\(String.date(from: Date()) ?? Date().ISO8601Format())"
                                
                                let params: [String : String]? = [
                                    "appid" : "billvivino@gmail.com",
                                    "original" : selectedImageURLString
                                ]
                            
                                let lineBreak = "\r\n"
                                var body = Data()
                                
                                if let params = params {
                                    for (key, value) in params {
                                        body.append("--\(boundary + lineBreak)")
                                        body.append( "Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)" )
                                        body.append("\(value + lineBreak)")
                                    }
                                }
                                
                                //MARK: Image data
                                body.append("--\(boundary + lineBreak)")
                                body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(fileName)\"\(lineBreak)")
                                body.append("Content-Type: \(mimeType)\(lineBreak + lineBreak)")
                                body.append(imageData)
                                body.append(lineBreak)
                                
                                body.append("--\(boundary)--\(lineBreak)")
                                
                                request.httpBody = body
                                
                                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                    if let error = error {
                                        print ("error: \(error)")
                                        return
                                    }
                                    guard let response = response as? HTTPURLResponse,
                                        (200...299).contains(response.statusCode) else {
                                        print ("server error")
                                        return
                                    }
                                    if let mimeType = response.mimeType,
                                        mimeType == "application/json",
                                        let data = data,
                                        let dataString = String(data: data, encoding: .utf8) {
                                        print ("got data: \(dataString)")
                                    }
                                }
                                task.resume()
                                
                            } else {
                                viewModel.message = "URL invalid or not found."
                                viewModel.showAlert.toggle()
                            
                            }
                            
                        } catch let error {
                            print("Error decoding: ", error)
                        }
                    }
                    print(data.count)
                }
            }
            
            dataTask.resume()
            
        } else {
            viewModel.message = "Image upload URL invalid or not found."
            viewModel.showAlert.toggle()
        }
    }
}

struct MyCanvas: UIViewRepresentable {
    @EnvironmentObject var viewModel: AppViewModel
    @Binding var canvasView: PKCanvasView
//    var canvasView: PKCanvasView
    @Binding var picker: PKToolPicker
//    let picker = PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        self.canvasView.tool = PKInkingTool(.pen, color: .black, width: 15)
        self.canvasView.becomeFirstResponder()
        self.canvasView.backgroundColor = .clear
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        picker.addObserver(canvasView)
        if viewModel.isDrawing {
            picker.setVisible(true, forFirstResponder: canvasView)
            DispatchQueue.main.async {
                canvasView.becomeFirstResponder()
            }
        } else {
            picker.setVisible(false, forFirstResponder: canvasView)
            DispatchQueue.main.async {
                canvasView.resignFirstResponder()
            }
        }
        

    }
}
