import Vision

public final class FaceObservationsClient {
  private enum UnexpectedError: Swift.Error {
    case mismatchingRequestType
    case missingResults
  }

  public var faceObservations: (CGImage, @escaping (Result<[VNFaceObservation], Error>) -> Void) -> Void

  public init() {
    faceObservations = { cgImage, completion in
      do {
        let request = VNDetectFaceRectanglesRequest { request, error in
          switch (error, request) {
          case let (error?, _):
            completion(.failure(error))
          case (nil, let request as VNDetectFaceRectanglesRequest):
            if let results = request.results {
              completion(.success(results))
            } else {
              completion(.failure(UnexpectedError.missingResults))
            }
          case (nil, _):
            completion(.failure(UnexpectedError.mismatchingRequestType))
          }
        }
        request.preferBackgroundProcessing = true
        #if targetEnvironment(simulator)
        request.usesCPUOnly = true
        #endif

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])
      } catch {
        completion(.failure(error))
      }
    }
  }
}
