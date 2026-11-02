// 005 FR-513~515 — 기기 내 사진 분석 채널(`closetimo/vision`).
// Dart 쪽: lib/core/vision/native_vision.dart
//
// - 배경 제거: Vision `VNGenerateForegroundInstanceMaskRequest`(iOS 17+). 투명 PNG를 임시 폴더에 쓴다.
// - 분류 라벨: Vision `VNClassifyImageRequest`(iOS 13+).
// - 기기 내 AI: Foundation Models 이미지 입력(iOS 27+, Apple Intelligence). 응답은 카탈로그 코드로
//   제한한 구조화 출력이다. 서버 모델(Private Cloud Compute)은 쓰지 않는다.
// 모든 처리는 기기 안에서만 한다(헌법 III). 로그는 영문으로 남긴다.
//
// 카탈로그 코드는 lib/data/models/item_attributes.dart와 같아야 한다
// (가드: test/unit/vision_channel_catalog_test.dart).

import CoreImage
import Flutter
import ImageIO
import UIKit
import Vision

#if canImport(FoundationModels)
  import FoundationModels
#endif

final class ClosetimoVisionChannel {
  static let channelName = "closetimo/vision"

  private static let queue = DispatchQueue(label: "closetimo.vision", qos: .userInitiated)
  /// 배경 제거본의 최대 변 길이. 목록·상세 표시에 충분하고 저장 공간을 아낀다.
  private static let cutoutMaxSide: CGFloat = 1024
  /// 너무 작은 피사체(오검출)는 버린다.
  private static let cutoutMinSide: CGFloat = 48
  /// Dart로 넘길 분류 라벨의 최소 신뢰도. 최종 판정(0.6)은 Dart가 한다.
  private static let labelMinConfidence: Float = 0.3
  private static let ciContext = CIContext()

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "capabilities":
        result(capabilities())
      case "analyze":
        guard let args = call.arguments as? [String: Any], let path = args["path"] as? String
        else {
          result(FlutterError(code: "bad_args", message: "path is required", details: nil))
          return
        }
        let removeBackground = args["removeBackground"] as? Bool ?? false
        queue.async {
          let output = analyze(path: path, removeBackground: removeBackground)
          DispatchQueue.main.async { result(output) }
        }
      case "describe":
        guard let args = call.arguments as? [String: Any], let path = args["path"] as? String
        else {
          result(FlutterError(code: "bad_args", message: "path is required", details: nil))
          return
        }
        describe(path: path, result: result)
      case "prewarm":
        prewarm()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - 기능 확인

  static func capabilities() -> [String: Any] {
    var backgroundRemoval = false
    if #available(iOS 17.0, *) { backgroundRemoval = true }
    return [
      "backgroundRemoval": backgroundRemoval,
      "classification": true,
      "onDeviceAi": onDeviceAiStatus(),
    ]
  }

  /// 이미지 입력은 iOS 27 SDK(Swift 6.4+ 툴체인)로 빌드했을 때만 컴파일한다.
  /// 그 전 툴체인에서 빌드한 앱은 항상 "unsupported"를 돌려 설정을 숨긴다.
  static func onDeviceAiStatus() -> String {
    #if canImport(FoundationModels) && compiler(>=6.4)
      if #available(iOS 27.0, *) {
        switch SystemLanguageModel.default.availability {
        case .available:
          return "available"
        case .unavailable(.appleIntelligenceNotEnabled):
          return "notEnabled"
        case .unavailable(.modelNotReady):
          return "notReady"
        default:
          return "unsupported"
        }
      }
    #endif
    return "unsupported"
  }

  // MARK: - 배경 제거 + 분류

  static func analyze(path: String, removeBackground: Bool) -> [String: Any] {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
      NSLog("Vision: cannot decode image at %@", path)
      return ["labels": []]
    }
    let handler = VNImageRequestHandler(
      cgImage: cgImage, orientation: orientation(of: source), options: [:])
    var output: [String: Any] = [:]

    // 분류와 배경 제거를 따로 실행해 한쪽 실패가 다른 쪽을 막지 않게 한다.
    let classify = VNClassifyImageRequest()
    do {
      try handler.perform([classify])
    } catch {
      NSLog("Vision: classification failed: %@", "\(error)")
    }
    output["labels"] = (classify.results ?? [])
      .filter { $0.confidence >= labelMinConfidence }
      .prefix(12)
      .map { ["identifier": $0.identifier, "confidence": Double($0.confidence)] }

    if removeBackground, #available(iOS 17.0, *) {
      if let cutout = writeCutout(handler: handler) { output["cutoutPath"] = cutout }
    }
    return output
  }

  @available(iOS 17.0, *)
  private static func writeCutout(handler: VNImageRequestHandler) -> String? {
    let request = VNGenerateForegroundInstanceMaskRequest()
    do {
      try handler.perform([request])
      guard let observation = request.results?.first, !observation.allInstances.isEmpty else {
        return nil
      }
      let buffer = try observation.generateMaskedImage(
        ofInstances: observation.allInstances, from: handler, croppedToInstancesExtent: true)
      var image = CIImage(cvPixelBuffer: buffer)
      let longest = max(image.extent.width, image.extent.height)
      guard longest >= cutoutMinSide else { return nil }
      if longest > cutoutMaxSide, let scaled = scaled(image, by: cutoutMaxSide / longest) {
        image = scaled
      }
      let target = FileManager.default.temporaryDirectory
        .appendingPathComponent("closetimo_cutout_\(UUID().uuidString).png")
      guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
      try ciContext.writePNGRepresentation(
        of: image, to: target, format: .RGBA8, colorSpace: sRGB)
      return target.path
    } catch {
      NSLog("Vision: background removal failed: %@", "\(error)")
      return nil
    }
  }

  /// Lanczos로 축소하고 extent를 정수 픽셀로 맞춘다(아핀 변환 축소의 계단 현상 방지).
  private static func scaled(_ image: CIImage, by scale: CGFloat) -> CIImage? {
    guard let filter = CIFilter(name: "CILanczosScaleTransform") else { return nil }
    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(scale, forKey: kCIInputScaleKey)
    filter.setValue(1.0, forKey: kCIInputAspectRatioKey)
    guard let output = filter.outputImage else { return nil }
    // 바깥으로 올림하는 integral 대신 안쪽 정수 픽셀로 자른다(가장자리는 투명).
    let e = output.extent
    let x0 = e.minX.rounded(.up), y0 = e.minY.rounded(.up)
    let x1 = e.maxX.rounded(.down), y1 = e.maxY.rounded(.down)
    guard x1 > x0, y1 > y0 else { return output }
    return output.cropped(to: CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0))
  }

  private static func orientation(of source: CGImageSource) -> CGImagePropertyOrientation {
    guard
      let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let raw = props[kCGImagePropertyOrientation] as? UInt32,
      let value = CGImagePropertyOrientation(rawValue: raw)
    else { return .up }
    return value
  }

  // MARK: - 기기 내 AI (Foundation Models)

  /// 예열한 세션을 붙잡아 두어 모델 자원이 바로 해제되지 않게 한다. 분석은 매번 새 세션으로
  /// 하므로(컨텍스트 누적 방지) 이 세션은 예열 전용이다.
  private static var warmSession: AnyObject?

  /// 첫 호출 지연(모델 적재)을 줄이려고 등록 화면 진입 시 미리 깨운다.
  static func prewarm() {
    #if canImport(FoundationModels) && compiler(>=6.4)
      if #available(iOS 27.0, *), case .available = SystemLanguageModel.default.availability {
        let session = LanguageModelSession(instructions: GarmentPrompt.instructions)
        session.prewarm()
        warmSession = session
      }
    #endif
  }

  static func describe(path: String, result: @escaping FlutterResult) {
    #if canImport(FoundationModels) && compiler(>=6.4)
      if #available(iOS 27.0, *), case .available = SystemLanguageModel.default.availability {
        Task {
          do {
            let session = LanguageModelSession(instructions: GarmentPrompt.instructions)
            let response = try await session.respond(generating: GarmentDescription.self) {
              GarmentPrompt.request
              Attachment(imageURL: URL(fileURLWithPath: path))
            }
            let output = response.content.dictionary
            await MainActor.run { result(output) }
          } catch {
            NSLog("Vision: on-device AI failed: %@", "\(error)")
            await MainActor.run {
              result(FlutterError(code: "failed", message: "\(error)", details: nil))
            }
          }
        }
        return
      }
    #endif
    result(
      FlutterError(
        code: "unsupported",
        message: "On-device image input requires iOS 27 and Apple Intelligence",
        details: nil))
  }
}

#if canImport(FoundationModels)
  /// 기기 내 모델 지시문. 영어로 쓰는 편이 안정적이다(가이드 설명도 영어).
  enum GarmentPrompt {
    static let instructions = """
      You label a single clothing item from a photo for a personal wardrobe app.
      Describe only the garment itself, never the background, skin or hair.
      If a person wears several garments, describe the most prominent one.
      Use only the allowed values and answer none when unsure.
      """
    static let request = "Label the clothing item in this photo."
  }

  @available(iOS 26.0, *)
  @Generable
  enum GarmentColor {
    case black, white, gray, ivory, beige, camel, brown, navy, blue, skyblue, denim, green, khaki,
      red, burgundy, pink, purple, yellow, orange
  }

  @available(iOS 26.0, *)
  @Generable
  enum GarmentSeason {
    case spring, summer, autumn, winter
  }

  /// 카탈로그 코드로 제한한 구조화 응답. iOS 26 SDK에서도 컴파일된다.
  @available(iOS 26.0, *)
  @Generable
  struct GarmentDescription {
    @Guide(
      description: "Main category of the garment",
      .anyOf(["outer", "top", "bottom", "onepiece", "shoes", "bag", "accessory", "etc"]))
    var category: String

    @Guide(
      description: "Specific garment type, or none if unsure",
      .anyOf([
        "tshirt", "shirt", "knit", "sweatshirt", "hoodie", "sleeveless", "polo",
        "jeans", "slacks", "cotton_pants", "shorts", "skirt", "jogger", "leggings",
        "coat", "padding", "jacket", "blazer", "jumper", "cardigan", "vest",
        "dress", "jumpsuit",
        "sneakers", "dress_shoes", "boots", "sandals", "loafers",
        "backpack", "shoulder_bag", "tote_bag", "cross_bag", "clutch",
        "hat", "scarf", "belt", "gloves", "socks", "jewelry", "watch", "eyewear", "tie",
        "none",
      ]))
    var subType: String

    @Guide(
      description: "Up to three dominant colors of the garment itself, most dominant first",
      .maximumCount(3))
    var colors: [GarmentColor]

    @Guide(description: "Seasons the garment is worn in", .maximumCount(4))
    var seasons: [GarmentSeason]

    @Guide(
      description: "Main material, or none if unsure",
      .anyOf([
        "cotton", "wool", "cashmere", "denim", "leather", "linen", "silk", "synthetic", "none",
      ]))
    var material: String

    @Guide(
      description: "Surface pattern, or none if unsure",
      .anyOf(["solid", "stripe", "check", "dot", "graphic", "floral", "none"]))
    var pattern: String

    /// 채널 응답(Dart `OnDeviceDescription.fromMap`).
    var dictionary: [String: Any] {
      [
        "category": category,
        "subType": subType,
        "colors": colors.map { String(describing: $0) },
        "seasons": seasons.map { String(describing: $0) },
        "material": material,
        "pattern": pattern,
      ]
    }
  }
#endif
