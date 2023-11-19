import AsyncDisplayKit

struct FacesVisibilityImageModifer {
  var image: (CGFloat) -> (UIImage, ASTraitCollection) -> UIImage?

  init(facesDetectionClient _: FacesDetectionClient = .init()) {
    image = { _ in
      { image, _ in
        guard let cgImage = image.cgImage else {
          return image
        }

        return image
//        facesDetectionClient.perform(.init(cgImage: cgImage, ratio: ratio)) {}
      }
    }
  }
}
