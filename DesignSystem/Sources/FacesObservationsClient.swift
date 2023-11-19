import Vision

final class FaceObservationsClient {
  private enum UnexpectedError: Swift.Error {
    case mismatchingRequestType
  }

  struct Task {
    var cancel: () -> Void = {}
  }

  var faceObservations: (CGImage, Float, @escaping (Result<[CGRect], Error>) -> Void) -> Task

  init() {
    faceObservations = { cgImage, minimumConfidence, completion in
      do {
        let request = VNDetectFaceRectanglesRequest { request, error in
          switch (error, request) {
          case let (error?, _):
            completion(.failure(error))
          case (nil, let request as VNDetectFaceRectanglesRequest):
            let results = request.results?
              .filter { $0.confidence >= minimumConfidence }
              .map(\.boundingBox)
            completion(.success(results ?? []))
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
        return Task(cancel: request.cancel)
      } catch {
        completion(.failure(error))
        return Task()
      }
    }
  }
}
