#!/usr/bin/swift

import AppKit
import Foundation

struct IconSpec {
  let filename: String
  let pixels: Int
}

let specs: [IconSpec] = [
  .init(filename: "Icon-App-20x20@1x.png", pixels: 20),
  .init(filename: "Icon-App-20x20@2x.png", pixels: 40),
  .init(filename: "Icon-App-20x20@3x.png", pixels: 60),
  .init(filename: "Icon-App-29x29@1x.png", pixels: 29),
  .init(filename: "Icon-App-29x29@2x.png", pixels: 58),
  .init(filename: "Icon-App-29x29@3x.png", pixels: 87),
  .init(filename: "Icon-App-40x40@1x.png", pixels: 40),
  .init(filename: "Icon-App-40x40@2x.png", pixels: 80),
  .init(filename: "Icon-App-40x40@3x.png", pixels: 120),
  .init(filename: "Icon-App-60x60@2x.png", pixels: 120),
  .init(filename: "Icon-App-60x60@3x.png", pixels: 180),
  .init(filename: "Icon-App-76x76@1x.png", pixels: 76),
  .init(filename: "Icon-App-76x76@2x.png", pixels: 152),
  .init(filename: "Icon-App-83.5x83.5@2x.png", pixels: 167),
  .init(filename: "Icon-App-1024x1024@1x.png", pixels: 1024),
]

let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  .appendingPathComponent("ios/Runner/Assets.xcassets/AppIcon.appiconset")

let orangeTop = NSColor(calibratedRed: 1.0, green: 0.67, blue: 0.34, alpha: 1.0)
let orangeBottom = NSColor(calibratedRed: 0.99, green: 0.57, blue: 0.24, alpha: 1.0)
let paperWhite = NSColor(calibratedRed: 1.0, green: 0.985, blue: 0.965, alpha: 1.0)
let accentDark = NSColor(calibratedRed: 0.18, green: 0.16, blue: 0.17, alpha: 1.0)
let accentWarm = NSColor(calibratedRed: 0.98, green: 0.59, blue: 0.24, alpha: 1.0)
let shadowColor = NSColor(calibratedRed: 0.40, green: 0.20, blue: 0.08, alpha: 0.20)

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
  let rect = CGRect(x: 0, y: 0, width: size, height: size)
  let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size),
    pixelsHigh: Int(size),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  )!
  bitmap.size = NSSize(width: size, height: size)

  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

  let backgroundPath = NSBezierPath(
    roundedRect: rect,
    xRadius: size * 0.225,
    yRadius: size * 0.225
  )
  let backgroundGradient = NSGradient(starting: orangeTop, ending: orangeBottom)!
  backgroundGradient.draw(in: backgroundPath, angle: -90)

  let glowRect = CGRect(
    x: size * 0.10,
    y: size * 0.60,
    width: size * 0.50,
    height: size * 0.34
  )
  let glowPath = NSBezierPath(ovalIn: glowRect)
  NSGraphicsContext.saveGraphicsState()
  glowPath.addClip()
  let glowGradient = NSGradient(
    colorsAndLocations:
      (NSColor(calibratedWhite: 1.0, alpha: 0.22), 0.0),
      (NSColor(calibratedWhite: 1.0, alpha: 0.0), 1.0)
  )!
  glowGradient.draw(in: glowPath, relativeCenterPosition: .zero)
  NSGraphicsContext.restoreGraphicsState()

  let backCard = NSBezierPath(
    roundedRect: CGRect(
      x: size * 0.30,
      y: size * 0.28,
      width: size * 0.42,
      height: size * 0.50
    ),
    xRadius: size * 0.08,
    yRadius: size * 0.08
  )
  accentDark.withAlphaComponent(0.14).setFill()
  backCard.fill()

  let paperRect = CGRect(
    x: size * 0.21,
    y: size * 0.17,
    width: size * 0.58,
    height: size * 0.68
  )
  let paperPath = NSBezierPath(
    roundedRect: paperRect,
    xRadius: size * 0.09,
    yRadius: size * 0.09
  )

  NSGraphicsContext.saveGraphicsState()
  let shadow = NSShadow()
  shadow.shadowOffset = NSSize(width: 0, height: -size * 0.01)
  shadow.shadowBlurRadius = size * 0.045
  shadow.shadowColor = shadowColor
  shadow.set()
  paperWhite.setFill()
  paperPath.fill()
  NSGraphicsContext.restoreGraphicsState()

  let headerBar = NSBezierPath(
    roundedRect: CGRect(
      x: paperRect.minX + size * 0.07,
      y: paperRect.maxY - size * 0.18,
      width: paperRect.width - size * 0.14,
      height: size * 0.095
    ),
    xRadius: size * 0.04,
    yRadius: size * 0.04
  )
  accentDark.setFill()
  headerBar.fill()

  let lineRects: [CGRect] = [
    CGRect(
      x: paperRect.minX + size * 0.09,
      y: paperRect.minY + size * 0.33,
      width: paperRect.width * 0.58,
      height: size * 0.05
    ),
    CGRect(
      x: paperRect.minX + size * 0.09,
      y: paperRect.minY + size * 0.23,
      width: paperRect.width * 0.46,
      height: size * 0.05
    ),
    CGRect(
      x: paperRect.minX + size * 0.09,
      y: paperRect.minY + size * 0.13,
      width: paperRect.width * 0.52,
      height: size * 0.05
    ),
  ]
  for (index, lineRect) in lineRects.enumerated() {
    let path = NSBezierPath(
      roundedRect: lineRect,
      xRadius: size * 0.02,
      yRadius: size * 0.02
    )
    (index == 0 ? accentWarm : accentDark.withAlphaComponent(0.82)).setFill()
    path.fill()
  }

  NSGraphicsContext.restoreGraphicsState()

  return bitmap
}

func writePNG(bitmap: NSBitmapImageRep, to url: URL, pixels: Int) throws {
  guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    throw NSError(domain: "IconGeneration", code: 1)
  }

  try pngData.write(to: url)
  print("Wrote \(url.lastPathComponent) (\(pixels)x\(pixels))")
}

for spec in specs {
  let bitmap = drawIcon(size: CGFloat(spec.pixels))
  let url = outputDirectory.appendingPathComponent(spec.filename)
  try writePNG(bitmap: bitmap, to: url, pixels: spec.pixels)
}
