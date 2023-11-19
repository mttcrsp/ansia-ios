import CoreGraphics
import Vision

/// Leverages the `VNDetectFaceRectanglesRequest` API to whether an images
/// contains faces and determine the best way to crop it to a given aspect ratio.
struct FacesDetectionClient {
  struct Request {
    /// The image you plan on cropping.
    var cgImage: CGImage
    /// The aspect ratio to which you plan cropping `image` to. (width / height)
    var ratio: CGFloat
    /// Face observation with a lesser confidence will be ignored. Defaults to `0.6`.
    var minimumConfidence: Float = 0.6
  }

  struct Response {
    /// A rect that can be used to crop the image in the specified aspect
    /// ratio while ensuring that the subject or subjects faces are
    /// as visible as possible.
    var smartCroppingRect: CGRect
    /// `true` when default cropping would leave out part of the subject face.
    var isSmartCroppingNecessary: Bool
    /// A rect that reports the center area of the image that would be
    /// visible when applying standard `.scaleAspectFill` like cropping.
    /// Especially useful for debug purposes.
    var defaultCroppingRect: CGRect
    /// A rect that encompasses all faces detected in the image. Especially
    /// useful for debug purposes.
    var facesBoundingRect: CGRect
  }

  enum Error: Swift.Error {
    // No faces were detected in the provided image
    case noFaceFound
  }

  struct Task {
    var cancel: () -> Void
  }

  var perform: (Request, @escaping (Result<Response, Swift.Error>) -> Void) -> Task

  init(facesObservationsClient: FaceObservationsClient = .init()) {
    perform = { request, completion in
      let task = facesObservationsClient.faceObservations(
        request.cgImage,
        request.minimumConfidence
      ) { result in
        switch result {
        case let .failure(error):
          completion(.failure(error))
        case .success([]):
          completion(.failure(Error.noFaceFound))
        case let .success(boundingRects):
          let originalSize = CGSize(width: request.cgImage.width, height: request.cgImage.height)

          let adjustedBoundingRects = boundingRects
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
          let minX = (adjustedBoundingRects.map(\.minX).min() ?? 0) * originalSize.width
          let minY = (adjustedBoundingRects.map(\.minY).min() ?? 0) * originalSize.height
          let maxX = (adjustedBoundingRects.map(\.maxX).max() ?? 0) * originalSize.width
          let maxY = (adjustedBoundingRects.map(\.maxY).max() ?? 0) * originalSize.height
          let facesBoundingRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

          var defaultCroppingRect = CGRect.zero
          if request.ratio > 1 { // horizontal (width > height)
            defaultCroppingRect.size.width = originalSize.width
            defaultCroppingRect.size.height = originalSize.width / request.ratio
            defaultCroppingRect.origin.y = (originalSize.height - defaultCroppingRect.height) / 2
          } else { // vertical or square (height > width)
            defaultCroppingRect.size.height = originalSize.height
            defaultCroppingRect.size.width = originalSize.height * request.ratio
            defaultCroppingRect.origin.x = (originalSize.width - defaultCroppingRect.width) / 2
          }

          let isSmartCroppingNecessary = !defaultCroppingRect.contains(facesBoundingRect)

          var smartCroppingRect = defaultCroppingRect
          if request.ratio > 1 {
            // When there's no way to crop the image to fit the entire
            // subject's face in the specified aspect ratio, align the
            // smart cropping rect with the bottom of the detected faces
            // rect. This yields much better results for portraits as it
            // ensures that the bottom portion of the subject face - the
            // one that encompasses the most important facial features -
            // is as visible as possible.
            if facesBoundingRect.height > defaultCroppingRect.height {
              smartCroppingRect.origin.y -= (defaultCroppingRect.maxY - facesBoundingRect.maxY)
            } else {
              // On the other hand, When you can fit the whole subject
              // face, align the cropping rect with the top of the
              // detected faces rect. This is because - in most cases
              // - whatever is below the subject face (typically the
              // body) is more interesting that what's above the
              // subject.
              smartCroppingRect.origin.y = facesBoundingRect.minY
            }
          } else {
            // When provided with a vertical aspect ratio, align the
            // smart cropping rect to the center of the detected faces
            // rect to maximise the face visible area.
            smartCroppingRect.origin.x = max(0, facesBoundingRect.midX - (smartCroppingRect.width / 2))
          }

          completion(
            .success(
              Response(
                smartCroppingRect: smartCroppingRect,
                isSmartCroppingNecessary: isSmartCroppingNecessary,
                defaultCroppingRect: defaultCroppingRect,
                facesBoundingRect: facesBoundingRect
              )
            )
          )
        }
      }

      return Task(cancel: task.cancel)
    }
  }
}

/// "avg. Menton to top of head" to "avg. Menton-crinion length" ratio (see
/// [Wikipedia - Human head](https://en.wikipedia.org/wiki/Human_head#Average_head_sizes))
/// + an artificial increase to account for the subject's hair.
private let faceToHeadRatio: CGFloat = 1.213 + 0.25
