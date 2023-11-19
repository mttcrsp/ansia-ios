import Vision

final class FaceObservationsClient {
  private enum UnexpectedError: Swift.Error {
    case mismatchingRequestType
    case missingResults
  }

  var faceObservations: (CGImage, Float) throws -> [VNFaceObservation]

  init() {
    faceObservations = { cgImage, _ in
      var result: Result<[VNFaceObservation], Error>?
      let resultSemaphore = DispatchSemaphore(value: 0)
      let request = VNDetectFaceRectanglesRequest { request, error in
        defer { resultSemaphore.signal() }
        switch (error, request) {
        case let (error?, _):
          result = .failure(error)
        case (nil, let request as VNDetectFaceRectanglesRequest):
          if let results = request.results {
            result = .success(results)
          } else {
            result = .failure(UnexpectedError.missingResults)
          }
        case (nil, _):
          result = .failure(UnexpectedError.mismatchingRequestType)
        }
      }
      #if targetEnvironment(simulator)
      request.usesCPUOnly = true
      #endif

      let handler = VNImageRequestHandler(cgImage: cgImage)
      try handler.perform([request])
      resultSemaphore.wait()

      switch result {
      case let .success(observations):
        return observations
      case let .failure(error):
        throw error
      case .none:
        return []
      }
    }
  }
}
