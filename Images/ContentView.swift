//
//  ContentView.swift
//  Images
//
//  Created by Bill Vivino on 5/2/22.
//

import SwiftUI
import UIKit
import PencilKit
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

class AppViewModel: ObservableObject {
    @Published var decodedImages: [ImageDataStruct]?
    @Published var selectedImage: ImageDataStruct?
    @Published var isEditingImage = false
    @Published var isDrawing = false
    @Published var showFilterSheet = false
    @Published var canvas = PKCanvasView()
    @Published var toolPicker = PKToolPicker()
    @Published var textBoxes : [TextBox] = []
    @Published var currentIndex : Int = 0
    @Published var rect: CGRect = .zero
    
    @Published var addNewBox = false
    @Published var saveImageBool = false
    
    @Published var showAlert = false
    @Published var message = ""
    
    func cancelImageEditing() {
        cancelDrawing()
        textBoxes.removeAll()
    }
    
    func cancelDrawing() {
        isDrawing = false
//        toolPicker.setVisible(false, forFirstResponder: canvas)
        canvas = PKCanvasView()
    }
    
    func cancelTextView() {
//        toolPicker.setVisible(true, forFirstResponder: canvas)
//        canvas.becomeFirstResponder()
        
        withAnimation {
            addNewBox = false
        }
        
        if !textBoxes[currentIndex].isAdded {
            textBoxes.removeLast()
        }
        
    }
    
    func saveImage() {
        
        saveImageBool = true
        
//        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1)
        
//        canvas.drawHierarchy(in: CGRect(origin: .zero, size: rect.size), afterScreenUpdates: true)
        
//        let generatedImage = UIGraphicsGetImageFromCurrentImageContext()
//
//        UIGraphicsEndImageContext()
//
//        if let image = generatedImage {
//            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
//        }
    }
}

struct ContentView: View {
    @StateObject var viewModel: AppViewModel
    @State var showingAlert = false
    @State var alertTitle = "Error"
    @State var alertText = ""
    @State var decodedImages: [ImageDataStruct] = []
    
    var body: some View {
        if viewModel.decodedImages == nil {
            NavigationView {
                Text("Loading Images...")
                    .padding()
                
            }.alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertText), dismissButton: .default(Text("Got it!")))
            }
            .onAppear {
                if let url = URL(string: "https://eulerity-hackathon.appspot.com/image") {
                    
                    let dataTask = URLSession.shared.dataTask(with: url) { data, _, error in
                        if error != nil {
                            alertText = "Error loading JSON data."
                            showingAlert = true
                            
                        } else {
                            guard let data = data else { return }
                            DispatchQueue.main.async {
                                do {
                                    decodedImages = try JSONDecoder().decode([ImageDataStruct].self, from: data)
                                    print(decodedImages)
                                } catch let error {
                                    print("Error decoding: ", error)
                                }
                            }
                            print(data.count)
                        }
                    }
                    
                    dataTask.resume()
                    
                } else {
                    alertText = "URL invalid or not found."
                    showingAlert = true
                }
            }.onChange(of: decodedImages.count) { _ in
                viewModel.decodedImages = decodedImages
            }
        } else if viewModel.showFilterSheet {
            EditImageSheet()
                .environmentObject(viewModel)
        } else {
            ImageSelectView(viewModel: viewModel)
        }
    }
}

struct ImageSelectView: View {
    @StateObject var viewModel: AppViewModel
    
    @State var alertText = ""
    @State private var query = ""
    @State var showFilterSheet = false
    @State private var scale: CGFloat = 1
    
    var body: some View {
        NavigationView {
            List {  //include everyone else except us
                if let images = viewModel.decodedImages {
                    ForEach(images.sorted(by: { DateFormatter.formatter.date(from: $0.updated) ?? Date() < DateFormatter.formatter.date(from: $1.updated) ?? Date() }), id: \.self) { image in
                        HStack {
                            ImageRow(image: image)
                        }.onTapGesture {
                            self.viewModel.isEditingImage = true
                            self.viewModel.selectedImage = self.viewModel.decodedImages?.filter({$0.url == image.url}).first
                            print(self.viewModel.selectedImage ?? "Invalid image selected")
                            viewModel.showFilterSheet = true
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .searchable(text: $query)
//            .navigationBarTitle(Text("Select Image"), displayMode: .large)
            .navigationTitle("Select Image")
        }.onChange(of: self.viewModel.selectedImage) { newValue in
            viewModel.showFilterSheet = true
        }
    }
}

struct EditImageSheet: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    @State var image: Image?
    @State var uiImageData: UIImage?
    @State private var filterIntensity = 0.5
    @State var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State var showingAlert = false
    @State var alertText = ""
    @State var alertTitle = "Error"
    @State private var showingFilterSheet = false
    @State private var showStockImage = false
//    @Binding var canvas: PKCanvasView
    
    let context = CIContext()
    
    var body: some View {
        NavigationView {
            if !showStockImage {
                VStack {
                    
                    if let image = image {
                        ZStack {
//                            if viewModel.isDrawing {
                            DrawingView(image: image)
                                .environmentObject(viewModel)
//                            }
                            
                            if viewModel.addNewBox {
                                
                                Color.black.opacity(0.75)
                                    .ignoresSafeArea()
                                
                                TextField("Tap Here to Type...", text: $viewModel.textBoxes[viewModel.currentIndex].text)
                                    .font(.system(size: 35, weight:
                                            viewModel.textBoxes[viewModel.currentIndex].isBold ? .bold :
                                            .regular))
                                    .colorScheme(.dark)
                                    .foregroundColor(viewModel.textBoxes[viewModel.currentIndex].textColor)
                                    .padding()
                                
                                HStack {
                                    
                                    Button (action: {
                                        viewModel.textBoxes[viewModel.currentIndex].isAdded = true
                                        
//                                        viewModel.isDrawing = true
                                        
                                        withAnimation {
                                            viewModel.addNewBox = false
                                        }
                                        
                                    }, label: {
                                        Text("Add")
                                            .fontWeight(.heavy)
                                            .foregroundColor(.white)
                                            .padding()
                                    })
                                    
                                    Spacer()
                                    
                                    Button (action: {
                                        viewModel.cancelTextView()
                                        
                                        viewModel.currentIndex = viewModel.textBoxes.count - 1
                                    }, label: {
                                        Text("Cancel")
                                            .fontWeight(.heavy)
                                            .foregroundColor(.white)
                                            .padding()
                                    })
                                }
                                .overlay(
                                    HStack(spacing: 15) {
                                        ColorPicker("", selection: $viewModel.textBoxes[viewModel.currentIndex].textColor)
                                            .labelsHidden()
                                        
                                        Button(action: {
                                            viewModel.textBoxes[viewModel.currentIndex].isBold.toggle()
                                        }, label: {
                                            Text(viewModel.textBoxes[viewModel.currentIndex].isBold ?
                                                 "Normal" : "Bold")
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        })
                                    }
                                    
                                )
                                .frame(maxHeight: .infinity, alignment: .top)
                            }
                        }
                        .navigationBarTitle(Text("Edit Image"), displayMode: .inline)
                        .toolbar(content: {
                            ToolbarItem(placement: .navigationBarLeading) {
                                if viewModel.isDrawing {
                                    Button (action: {
                                        viewModel.cancelDrawing()
                                    }, label: {
                                        Image(systemName: "xmark")
                                    })
                                } else {
                                    
                                    Button(action: {
                                        print("Dismissing sheet view...")
                                        viewModel.showFilterSheet = false
                                        viewModel.isEditingImage = false
                                        viewModel.isDrawing = false
                                    }) {
                                        Text("Cancel").bold()
                                    }
                                }
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    viewModel.saveImage()
                                    print("Dismissing sheet view...")
//                                    viewModel.showFilterSheet = false
                                    
                                }) {
                                    Text("Save").bold()
                                }
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    
                                    viewModel.textBoxes.append(TextBox())
                                    viewModel.currentIndex = viewModel.textBoxes.count - 1
                                    
                                    withAnimation {
                                        viewModel.addNewBox.toggle()
                                    }

                                    viewModel.isDrawing = false
//                                    viewModel.toolPicker.setVisible(false, forFirstResponder: viewModel.canvas)
//                                    viewModel.canvas.resignFirstResponder()
                                }, label: {
                                    Image(systemName: "plus")
                                })
                            }
                        })
                    } else {
                        ProgressView()
                    }
                    
                    HStack {
                        Text("Filter type: \(currentFilter.name.replacingOccurrences(of: "CI", with: ""))")
                    }
                    
                    HStack {
                        Text("Intensity:")
                        Slider(value: $filterIntensity)
                            .onChange(of: filterIntensity) { _ in applyProcessing() }
                    }.padding()
                    
                    HStack {
                        Button("Change Filter") {
                            showingFilterSheet = true
            
                        }.padding().padding()
                        
                        Button(action: {
                            viewModel.isDrawing = true
//                            viewModel.toolPicker.setVisible(true, forFirstResponder: viewModel.canvas)
                        }) {
                            HStack {
                                Text("Draw")
                                Image(systemName: "pencil.circle")
                            }
                            
                        }
                    }.confirmationDialog("Select a filter", isPresented: $showingFilterSheet) {
                        //dialog here
                        Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                        Button("Edges") { setFilter(CIFilter.edges()) }
                        Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                        Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                        Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                        Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                        Button("Vignette") { setFilter(CIFilter.vignette()) }
                        Button("Cancel", role: .cancel) { }
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .foregroundColor(Color.blue)
                    .toolbar(content: {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                print("Dismissing sheet view...")
                                viewModel.showFilterSheet = false
                                viewModel.isEditingImage = false
                            }) {
                                Text("Cancel").bold()
                            }
                        }
                    })
            }
        }.onAppear {
            if let urlString = self.viewModel.selectedImage?.url,
               let url = URL(string: urlString) {
                
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    if let error = error {
                        alertText = error.localizedDescription
                        showingAlert = true
                        showStockImage = true
                    } else if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                        
                        alertText = "Bad response from server"
                        showingAlert = true
                        showStockImage = true
                        
                    } else if let data = data, let image = UIImage(data: data) {
                        self.uiImageData = image
//                        let beginImage = CIImage(image: image)
//                        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
//                        applyProcessing()
                        loadImage()
                    } else {
                        alertText = "Unknown error"
                        showingAlert = true
                        showStockImage = true
                    }
                }
                
                task.resume()
                
            } else {
                alertText = "URL invalid or not found."
                showingAlert = true
            }
            
        }.onDisappear() {
            if !viewModel.isEditingImage {
                viewModel.cancelImageEditing()
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertText), dismissButton: .default(Text("Got it!")))
        }.alert(isPresented: $viewModel.showAlert, content: {
            
            Alert(title: Text("Success"), message: Text(viewModel.message), dismissButton: .destructive(Text("OK")))
                
        })
    }
    
    func loadImage() {
        guard let inputImage = uiImageData else { return }

        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        }
        
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey)
        }
        
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey)
        }
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
        }
    }

    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: AppViewModel())
            .environmentObject(AppViewModel())
    }
}
