//
//  ApplicationData.swift
//  ImageAnalysis2Search
//
//  Created by Quanpeng Yang on 3/16/26.
//

import SwiftUI
import Observation
import Vision

struct ImageData: Identifiable {

    let id: UUID = UUID()
    var fileName: String
    var image: UIImage?
    var categories: [String]

    var showCategories: String {
        return categories.joined(separator: ", ")
    }
}


@Observable
class ApplicationData {

    var listImages: [ImageData]
    var filteredImages: [ImageData]

    static let shared = ApplicationData()

    private init() {

        listImages = []
        filteredImages = []

        let list = [
            "picture1","picture2","picture3"
        ]

        for name in list {

            listImages.append(
                ImageData(
                    fileName: name,
                    image: UIImage(named: name),
                    categories: []
                )
            )
        }

        filteredImages = listImages
    }

    func recognizeImages() async {

        await withTaskGroup(of: (Int, [String]).self) { group in

            for (index, item) in listImages.enumerated() {

                guard let uiImage = item.image,
                      let cgImage = uiImage.cgImage else { continue }

                group.addTask {

                    var categories: [String] = []

                    do {

                        let request = ClassifyImageRequest()
                        var results = try await request.perform(on: cgImage)

                        results = results.filter {
                            $0.hasMinimumPrecision(0.1, forRecall: 0.8)
                            && $0.confidence > 0.1
                        }

                        categories = results.map(\.identifier)

                    } catch {
                        print("Vision error:", error)
                    }

                    return (index, categories)
                }
            }

            for await (index, categories) in group {

                await MainActor.run {
                    self.listImages[index].categories = categories
                }
            }
        }
    }

    func filterValues(search: String) {

        if search.isEmpty {

            filteredImages = listImages

        } else {

            filteredImages = listImages.filter { image in
                image.categories.contains {
                    $0.lowercased().contains(search.lowercased())
                }
            }
        }
    }
}
