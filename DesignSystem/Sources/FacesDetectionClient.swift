import CoreGraphics
import Vision

/// Leverages the `VNDetectFaceRectanglesRequest` API to whether an images
/// contains faces and determine the best way to crop it to a given aspect ratio.
public struct FacesDetectionClient {
  public struct Request {
    /// The image you plan on cropping.
    public var cgImage: CGImage
    /// The aspect ratio to which you plan cropping `image` to. (width / height)
    public var ratio: CGFloat
    /// Face observation with a lesser confidence will be ignored. Defaults to `0.6`.
    public var minimumConfidence: Float

    public init(cgImage: CGImage, ratio: CGFloat, minimumConfidence: Float = 0.6) {
      self.cgImage = cgImage
      self.ratio = ratio
      self.minimumConfidence = minimumConfidence
    }
  }

  public struct Response {
    /// A rect that can be used to crop the image in the specified aspect
    /// ratio while ensuring that the subject or subjects faces are
    /// as visible as possible.
    public var smartCroppingRect: CGRect
    /// `true` when default cropping would leave out part of the subject face.
    public var isSmartCroppingNecessary: Bool
    /// A rect that reports the center area of the image that would be
    /// visible when applying standard `.scaleAspectFill` like cropping.
    /// Especially useful for debug purposes.
    public var defaultCroppingRect: CGRect
    /// A rect that encompasses all faces detected in the image. Especially
    /// useful for debug purposes.
    public var facesBoundingRect: CGRect
  }

  public enum Error: Swift.Error {
    /// No faces were detected in the provided image
    case noFaceFound
    /// No cropping necessary
    case noCroppingNecessary
  }

  public var perform: (Request, @escaping (CGRect?) -> Void) -> Void

  public init() {
    perform = { request, completion in

      do {
        let facesRequest = VNDetectFaceRectanglesRequest { facesRequest, _ in
          if let facesRequest = facesRequest as? VNDetectFaceRectanglesRequest {
            if let results = facesRequest.results?.filter({ $0.confidence > 0.6 }), !results.isEmpty {
              let boundingBoxes = results.map(\.boundingBox)
                // Bounding boxes are relative to the lower-left corner of
                // an image. You need to flip them vertically to match
                // UIKit's coordinates system.
                  .map { rect in
                    let y = 1 - rect.minY - rect.height
                    return CGRect(x: rect.minX, y: y, width: rect.width, height: rect.height)
                  }
                  // Adjust the bounding box to encompass the whole head
                  // of the subject rather than just core facial features
                  .map { rect in
                    var adjusted = rect
                    adjusted.size.height = rect.height * faceToHeadRatio
                    adjusted.origin.y -= adjusted.height - rect.height
                    // Ensure that you don't end up outside of the image
                    // bounds while adjusting
                    adjusted = adjusted.intersection(.init(x: 0, y: 0, width: 1, height: 1))
                    return adjusted
                  }

              // Multiple faces might be present in a single picture, compute
              // the smallest possible rect that includes them all.
              let minX = boundingBoxes.map(\.minX).min() ?? 0
              let minY = boundingBoxes.map(\.minY).min() ?? 0
              let maxX = boundingBoxes.map(\.maxX).max() ?? 0
              let maxY = boundingBoxes.map(\.maxY).max() ?? 0
              let facesBoundingBox = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

              var defaultCropRect = CGRect.zero
              if request.ratio > 1 { // horizontal (width > height)
                defaultCropRect.size.width = 1
                defaultCropRect.size.height = 1 / request.ratio
                defaultCropRect.origin.y = defaultCropRect.height / 2
              } else { // vertical or square (height > width)
                defaultCropRect.size.height = 1
                defaultCropRect.size.width = 1 * request.ratio
                defaultCropRect.origin.x = defaultCropRect.width / 2
              }

              guard !defaultCropRect.contains(facesBoundingBox) else {
                completion(nil)
                return
              }

              var smartCropRect = defaultCropRect
              if request.ratio > 1 {
                // When there's no way to crop the image to fit the entire
                // subject's face in the specified aspect ratio, align the
                // smart cropping rect with the bottom of the detected faces
                // rect. This yields much better results for portraits as it
                // ensures that the bottom portion of the subject face - the
                // one that encompasses the most important facial features -
                // is as visible as possible.
                if facesBoundingBox.height > defaultCropRect.height {
                  smartCropRect.origin.y -= (defaultCropRect.maxY - facesBoundingBox.maxY)
                } else {
                  // On the other hand, When you can fit the whole subject
                  // face, align the cropping rect with the top of the
                  // detected faces rect. This is because - in most cases
                  // - whatever is below the subject face (typically the
                  // body) is more interesting that what's above the
                  // subject.
                  smartCropRect.origin.y = facesBoundingBox.minY
                }
              } else {
                // When provided with a vertical aspect ratio, align the
                // smart cropping rect to the center of the detected faces
                // rect to maximise the face visible area.
                smartCropRect.origin.x = max(0, facesBoundingBox.midX - (smartCropRect.width / 2))
              }

              completion(smartCropRect)
              return
            }
          }
          completion(nil)
        }
        facesRequest.preferBackgroundProcessing = true
        #if targetEnvironment(simulator)
        facesRequest.usesCPUOnly = true
        #endif

        let handler = VNImageRequestHandler(cgImage: request.cgImage)
        try handler.perform([facesRequest])
      } catch {
        completion(nil)
      }
    }
  }
}

/// "avg. Menton to top of head" to "avg. Menton-crinion length" ratio (see
/// [Wikipedia - Human head](https://en.wikipedia.org/wiki/Human_head#Average_head_sizes))
/// + an artificial increase to account for the subject's hair.
private let faceToHeadRatio: CGFloat = 1.213 + 0.25
