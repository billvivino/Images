//
//  ImageRow.swift
//  Images
//
//  Created by Bill Vivino on 5/2/22.
//

import SwiftUI

struct ImageRow: View {
    let image: ImageDataStruct
    var body: some View {
        HStack (spacing: 20) {
            if let url = URL(string: image.url) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 130, height: 100)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 70, alignment: .center)
                    .padding()
                    .foregroundColor(Color.blue)
            }
            ZStack {
                VStack(alignment: .leading, spacing: 5) {
                    
                        Text("Created:")
                            .bold()
                        Text("\(image.created) \n")
                            
                        Text("Updated")
                            .bold()
                        Text("\(image.updated)")
                            
                        Spacer()
                }
            }
        }.frame(height: 100)
            .onAppear {
                
            }
    }
}

struct ImageRow_Previews: PreviewProvider {
    static var previews: some View {
        ImageRow(image: ImageDataStruct(url: "", created: "", updated: ""))
    }
}
