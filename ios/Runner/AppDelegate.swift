import Foundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerICloudPluginIfNeeded(with: engineBridge.pluginRegistry)
  }

  private func registerICloudPluginIfNeeded(with registry: FlutterPluginRegistry) {
    let pluginKey = "ICloudResumePlugin"
    guard !registry.hasPlugin(pluginKey) else {
      return
    }
    guard let registrar = registry.registrar(forPlugin: pluginKey) else {
      return
    }
    ICloudResumePlugin.register(with: registrar)
  }
}

private final class ICloudResumePlugin: NSObject, FlutterPlugin {
  private static let channelName = "resume_app/icloud_resumes"
  private static let containerIdentifier = "iCloud.com.quickresume"

  private let fileManager = FileManager.default
  private let isoFormatter = ISO8601DateFormatter()

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = ICloudResumePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        switch call.method {
        case "isAvailable":
          self.finish(result, value: self.resumeDirectoryURL(createIfNeeded: false) != nil)
        case "listResumes":
          self.finish(result, value: try self.listResumes())
        case "uploadResumes":
          let arguments = call.arguments as? [String: Any]
          let resumeMaps = arguments?["resumes"] as? [[String: Any]] ?? []
          self.finish(result, value: try self.uploadResumes(resumeMaps))
        case "uploadCoverLetters":
          let arguments = call.arguments as? [String: Any]
          let maps = arguments?["coverLetters"] as? [[String: Any]] ?? []
          self.finish(result, value: try self.uploadCoverLetters(maps))
        case "downloadResume":
          let arguments = call.arguments as? [String: Any]
          let id = arguments?["id"] as? String ?? ""
          let isCoverLetter = arguments?["isCoverLetter"] as? Bool ?? false
          self.finish(result, value: try self.downloadResume(id: id, isCoverLetter: isCoverLetter))
        default:
          self.finish(result, notImplemented: true)
        }
      } catch let error as ICloudResumePluginError {
        self.finish(
          result,
          error: FlutterError(code: error.code, message: error.message, details: nil)
        )
      } catch {
        self.finish(
          result,
          error: FlutterError(
            code: "icloud_error",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }

  private func listResumes() throws -> [[String: Any]] {
    var rows: [[String: Any]] = []
    if let url = resumeDirectoryURL(createIfNeeded: false), fileManager.fileExists(atPath: url.path) {
      rows.append(contentsOf: try listJSONSummaries(in: url, isCoverLetter: false))
    }
    if let url = coverLetterDirectoryURL(createIfNeeded: false), fileManager.fileExists(atPath: url.path) {
      rows.append(contentsOf: try listJSONSummaries(in: url, isCoverLetter: true))
    }
    return rows
  }

  private func listJSONSummaries(in directoryURL: URL, isCoverLetter: Bool) throws -> [[String: Any]] {
    let urls = try fileManager.contentsOfDirectory(
      at: directoryURL,
      includingPropertiesForKeys: [.ubiquitousItemDownloadingStatusKey],
      options: [.skipsHiddenFiles]
    ).filter { $0.pathExtension.lowercased() == "json" }

    return urls.compactMap { url in
      let payload = try? readJSON(from: url, waitForDownload: false)
      let id = (payload?["id"] as? String) ?? url.deletingPathExtension().lastPathComponent
      let title: String
      if isCoverLetter {
        title = coverLetterDisplayTitle(from: payload)
      } else {
        title = (payload?["title"] as? String) ?? "Untitled Resume"
      }
      let updatedAt = (payload?["updatedAt"] as? String) ?? isoFormatter.string(from: Date())
      let createdAt = (payload?["createdAt"] as? String) ?? updatedAt
      let isDownloaded = isFileDownloaded(url)

      return [
        "id": id,
        "title": title,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
        "isDownloaded": isDownloaded,
        "isCoverLetter": isCoverLetter
      ]
    }
  }

  private func coverLetterDisplayTitle(from payload: [String: Any]?) -> String {
    guard let payload else {
      return "Untitled Cover Letter"
    }
    if let t = payload["title"] as? String, !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return t
    }
    let role = (payload["role"] as? String) ?? ""
    let company = (payload["company"] as? String) ?? ""
    let joined = [role, company].filter { !$0.isEmpty }.joined(separator: " · ")
    return joined.isEmpty ? "Untitled Cover Letter" : joined
  }

  private func uploadResumes(_ resumeMaps: [[String: Any]]) throws -> [String] {
    guard let directoryURL = resumeDirectoryURL(createIfNeeded: true) else {
      throw ICloudResumePluginError.unavailable
    }

    var uploadedIds: [String] = []
    for resumeMap in resumeMaps {
      guard let id = resumeMap["id"] as? String, !id.isEmpty else {
        continue
      }
      let fileURL = directoryURL.appendingPathComponent("\(id).json")
      let data = try JSONSerialization.data(
        withJSONObject: resumeMap,
        options: [.prettyPrinted, .sortedKeys]
      )
      try data.write(to: fileURL, options: .atomic)
      uploadedIds.append(id)
    }
    return uploadedIds
  }

  private func uploadCoverLetters(_ maps: [[String: Any]]) throws -> [String] {
    guard let directoryURL = coverLetterDirectoryURL(createIfNeeded: true) else {
      throw ICloudResumePluginError.unavailable
    }

    var uploadedIds: [String] = []
    for map in maps {
      guard let id = map["id"] as? String, !id.isEmpty else {
        continue
      }
      let fileURL = directoryURL.appendingPathComponent("\(id).json")
      let data = try JSONSerialization.data(
        withJSONObject: map,
        options: [.prettyPrinted, .sortedKeys]
      )
      try data.write(to: fileURL, options: .atomic)
      uploadedIds.append(id)
    }
    return uploadedIds
  }

  private func downloadResume(id: String, isCoverLetter: Bool) throws -> [String: Any] {
    guard !id.isEmpty else {
      throw ICloudResumePluginError.missingResumeID
    }
    let directoryURL = isCoverLetter
      ? coverLetterDirectoryURL(createIfNeeded: false)
      : resumeDirectoryURL(createIfNeeded: false)
    guard let directoryURL else {
      throw ICloudResumePluginError.unavailable
    }
    let fileURL = directoryURL.appendingPathComponent("\(id).json")
    guard fileManager.fileExists(atPath: fileURL.path) else {
      throw ICloudResumePluginError.resumeNotFound
    }
    return try readJSON(from: fileURL, waitForDownload: true)
  }

  private func readJSON(from url: URL, waitForDownload: Bool) throws -> [String: Any] {
    try ensureFileDownloadedIfNeeded(url, waitForDownload: waitForDownload)
    let data = try Data(contentsOf: url)
    guard
      let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      throw ICloudResumePluginError.invalidPayload
    }
    return object
  }

  private func ensureFileDownloadedIfNeeded(_ url: URL, waitForDownload: Bool) throws {
    let isDownloaded = isFileDownloaded(url)
    guard waitForDownload, !isDownloaded else {
      return
    }

    try? fileManager.startDownloadingUbiquitousItem(at: url)
    for _ in 0..<20 {
      if isFileDownloaded(url) {
        return
      }
      Thread.sleep(forTimeInterval: 0.15)
    }
  }

  private func isFileDownloaded(_ url: URL) -> Bool {
    let values = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
    switch values?.ubiquitousItemDownloadingStatus {
    case .current, .downloaded:
      return true
    default:
      return false
    }
  }

  private func resumeDirectoryURL(createIfNeeded: Bool) -> URL? {
    guard
      let containerURL = fileManager.url(
        forUbiquityContainerIdentifier: Self.containerIdentifier
      )
    else {
      return nil
    }

    let directoryURL = containerURL
      .appendingPathComponent("Documents", isDirectory: true)
      .appendingPathComponent("Resumes", isDirectory: true)

    if createIfNeeded, !fileManager.fileExists(atPath: directoryURL.path) {
      try? fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
      )
    }

    return directoryURL
  }

  private func coverLetterDirectoryURL(createIfNeeded: Bool) -> URL? {
    guard
      let containerURL = fileManager.url(
        forUbiquityContainerIdentifier: Self.containerIdentifier
      )
    else {
      return nil
    }

    let directoryURL = containerURL
      .appendingPathComponent("Documents", isDirectory: true)
      .appendingPathComponent("CoverLetters", isDirectory: true)

    if createIfNeeded, !fileManager.fileExists(atPath: directoryURL.path) {
      try? fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
      )
    }

    return directoryURL
  }

  private func finish(
    _ result: @escaping FlutterResult,
    value: Any? = nil,
    error: FlutterError? = nil,
    notImplemented: Bool = false
  ) {
    DispatchQueue.main.async {
      if notImplemented {
        result(FlutterMethodNotImplemented)
      } else if let error {
        result(error)
      } else {
        result(value)
      }
    }
  }
}

private enum ICloudResumePluginError: Error {
  case unavailable
  case missingResumeID
  case resumeNotFound
  case invalidPayload

  var code: String {
    switch self {
    case .unavailable:
      return "icloud_unavailable"
    case .missingResumeID:
      return "missing_resume_id"
    case .resumeNotFound:
      return "resume_not_found"
    case .invalidPayload:
      return "invalid_payload"
    }
  }

  var message: String {
    switch self {
    case .unavailable:
      return "iCloud is not available on this device."
    case .missingResumeID:
      return "A resume id is required."
    case .resumeNotFound:
      return "The selected resume was not found in iCloud."
    case .invalidPayload:
      return "The iCloud resume file could not be decoded."
    }
  }
}
