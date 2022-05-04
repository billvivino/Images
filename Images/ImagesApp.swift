//
//  ImagesApp.swift
//  Images
//
//  Created by Bill Vivino on 5/2/22.
//

import SwiftUI

@main
struct ImagesApp: App {
    let viewModel = AppViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
//                .environmentObject(viewModel)
        }
    }
}
