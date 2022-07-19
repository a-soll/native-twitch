import SwiftUI
import Foundation
import Cocoa
import Combine

typealias UIImage = NSImage

class ImageCache {
    private init() {}
    
    static let shared = NSCache<NSString, UIImage>()
}

func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
    URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
}

func getImage(from url: URL, completion: @escaping ((UIImage?, Error?)->(Void))) {
    if let cachedImage = ImageCache.shared.object(forKey: url.absoluteString as NSString) {
        completion(cachedImage, nil)
    }
    else if let data = try? Data(contentsOf: url) {
        let imgData = data
        let image = UIImage(data: imgData)
        ImageCache.shared.setObject(image!, forKey: url.absoluteString as NSString)
            completion(image, nil)
        }
}
