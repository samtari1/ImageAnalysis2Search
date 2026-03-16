//
//  ContentView.swift
//  ImageAnalysis2Search
//
//  Created by Quanpeng Yang on 3/16/26.
//
import SwiftUI

struct ContentView: View {

    let appData = ApplicationData.shared

    @State private var searchTerm = ""

    var body: some View {

        NavigationStack {

            List(appData.filteredImages) { image in

                VStack {

                    if let img = image.image {

                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                    }

                    Text(image.showCategories)
                        .font(.caption)
                }
            }
        }

        .navigationTitle("Image Search")

        .task {
            await appData.recognizeImages()
        }

        .searchable(text: $searchTerm, prompt: "Search image")

        .onChange(of: searchTerm) { oldValue, newValue in

            let search = newValue
                .trimmingCharacters(in: .whitespacesAndNewlines)

            appData.filterValues(search: search)
        }
    }
}
