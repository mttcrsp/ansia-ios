import AsyncDisplayKit

public struct FacesVisibilityImageModifer {
  public var image: (CGFloat) -> (UIImage, ASPrimitiveTraitCollection) -> UIImage?

  public init() {
    let facesDetectionClient = FacesDetectionClient()
    image = { ratio in
      { image, _ in
        guard let cgImage = image.cgImage else {
          return image
        }

        let facesRequest = FacesDetectionClient.Request(cgImage: cgImage, ratio: ratio)
        if let response = try? facesDetectionClient.perform(facesRequest) {
          if let cgImage = cgImage.cropping(to: response.smartCroppingRect) {
            return .init(cgImage: cgImage)
          }
        }

        return image
      }
    }
  }
}
