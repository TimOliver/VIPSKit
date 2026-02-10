#!/usr/bin/env swift
//
//  generate-test-images.swift
//  VIPSKit
//
//  Generates test images for the test suite using CoreGraphics/ImageIO.
//  Run from the repo root: swift Scripts/generate-test-images.swift
//
//  Note: WebP encoding is not supported by ImageIO. After running this script,
//  generate test.webp manually:
//    cwebp -q 85 Tests/TestResources/test-rgb.png -o Tests/TestResources/test.webp
//

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MARK: - Output Directory

let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0])
let repoRoot = scriptPath.deletingLastPathComponent().deletingLastPathComponent()
let outputDir = repoRoot.appendingPathComponent("Tests/TestResources")

print("Output directory: \(outputDir.path)")

// MARK: - UTType Helpers

func utType(for format: String) -> CFString {
    switch format {
    case "png":  return UTType.png.identifier as CFString
    case "jpeg": return UTType.jpeg.identifier as CFString
    case "tiff": return UTType.tiff.identifier as CFString
    case "gif":  return UTType.gif.identifier as CFString
    default:     return UTType.png.identifier as CFString
    }
}

// MARK: - Image Creation Helpers

func createContext(width: Int, height: Int, hasAlpha: Bool = false) -> CGContext? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo: CGBitmapInfo = hasAlpha
        ? CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        : CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)

    return CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    )
}

func createGrayscaleContext(width: Int, height: Int) -> CGContext? {
    let colorSpace = CGColorSpaceCreateDeviceGray()
    return CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.none.rawValue
    )
}

// MARK: - Test Pattern Generators

/// Creates a colorful gradient test pattern
func drawGradientPattern(in ctx: CGContext, width: Int, height: Int) {
    // Red-to-blue horizontal gradient
    for x in 0..<width {
        let t = CGFloat(x) / CGFloat(width - 1)
        ctx.setFillColor(red: 1.0 - t, green: 0.2, blue: t, alpha: 1.0)
        ctx.fill(CGRect(x: x, y: 0, width: 1, height: height))
    }

    // Add a white rectangle in the center
    ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
    let centerRect = CGRect(
        x: width / 4,
        y: height / 4,
        width: width / 2,
        height: height / 2
    )
    ctx.fill(centerRect)

    // Add a black circle
    ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
    let circleRect = CGRect(
        x: width / 3,
        y: height / 3,
        width: width / 3,
        height: height / 3
    )
    ctx.fillEllipse(in: circleRect)
}

/// Creates a pattern with transparency
func drawAlphaPattern(in ctx: CGContext, width: Int, height: Int) {
    // Checkerboard with varying alpha
    let tileSize = width / 8
    for row in 0..<8 {
        for col in 0..<8 {
            let isLight = (row + col) % 2 == 0
            let alpha = CGFloat(row + 1) / 8.0
            if isLight {
                ctx.setFillColor(red: 1, green: 0, blue: 0, alpha: alpha)
            } else {
                ctx.setFillColor(red: 0, green: 0, blue: 1, alpha: alpha)
            }
            ctx.fill(CGRect(x: col * tileSize, y: row * tileSize, width: tileSize, height: tileSize))
        }
    }
}

/// Creates a grayscale gradient
func drawGrayscalePattern(in ctx: CGContext, width: Int, height: Int) {
    for x in 0..<width {
        let gray = CGFloat(x) / CGFloat(width - 1)
        ctx.setFillColor(gray: gray, alpha: 1.0)
        ctx.fill(CGRect(x: x, y: 0, width: 1, height: height))
    }
}

/// Creates a simple solid color (for tiny test)
func drawSolidColor(in ctx: CGContext, width: Int, height: Int, r: CGFloat, g: CGFloat, b: CGFloat) {
    ctx.setFillColor(red: r, green: g, blue: b, alpha: 1.0)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
}

/// Creates an asymmetric pattern useful for testing rotation
func drawAsymmetricPattern(in ctx: CGContext, width: Int, height: Int) {
    // White background
    ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

    // Red rectangle in top-left quadrant
    ctx.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
    ctx.fill(CGRect(x: 0, y: height / 2, width: width / 2, height: height / 2))

    // Blue rectangle in bottom-right quadrant
    ctx.setFillColor(red: 0, green: 0, blue: 1, alpha: 1)
    ctx.fill(CGRect(x: width / 2, y: 0, width: width / 2, height: height / 2))

    // Green triangle pointing right (to show orientation)
    ctx.setFillColor(red: 0, green: 0.8, blue: 0, alpha: 1)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: width / 4, y: height / 4))
    ctx.addLine(to: CGPoint(x: width * 3 / 4, y: height / 2))
    ctx.addLine(to: CGPoint(x: width / 4, y: height * 3 / 4))
    ctx.closePath()
    ctx.fillPath()
}

// MARK: - Image Saving

func saveImage(_ image: CGImage, to url: URL, format: String, quality: CGFloat? = nil) -> Bool {
    let type = utType(for: format)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, type, 1, nil) else {
        print("  Failed to create destination for \(url.lastPathComponent)")
        return false
    }

    var options: [CFString: Any] = [:]
    if let quality = quality {
        options[kCGImageDestinationLossyCompressionQuality] = quality
    }

    CGImageDestinationAddImage(dest, image, options.isEmpty ? nil : options as CFDictionary)

    if CGImageDestinationFinalize(dest) {
        print("  Created: \(url.lastPathComponent)")
        return true
    } else {
        print("  Failed to write: \(url.lastPathComponent)")
        return false
    }
}

func saveImageWithOrientation(_ image: CGImage, to url: URL, format: String, orientation: Int) -> Bool {
    let type = utType(for: format)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, type, 1, nil) else {
        print("  Failed to create destination for \(url.lastPathComponent)")
        return false
    }

    let options: [CFString: Any] = [
        kCGImagePropertyOrientation: orientation
    ]

    CGImageDestinationAddImage(dest, image, options as CFDictionary)

    if CGImageDestinationFinalize(dest) {
        print("  Created: \(url.lastPathComponent) (orientation=\(orientation))")
        return true
    } else {
        print("  Failed to write: \(url.lastPathComponent)")
        return false
    }
}

// MARK: - Generate Images

print("\nGenerating test images...\n")

// 1. RGB PNG (256x256)
print("1. RGB PNG")
if let ctx = createContext(width: 256, height: 256) {
    drawGradientPattern(in: ctx, width: 256, height: 256)
    if let image = ctx.makeImage() {
        _ = saveImage(image, to: outputDir.appendingPathComponent("test-rgb.png"), format: "png")
    }
}

// 2. RGBA PNG with transparency (256x256)
print("2. RGBA PNG with alpha")
if let ctx = createContext(width: 256, height: 256, hasAlpha: true) {
    drawAlphaPattern(in: ctx, width: 256, height: 256)
    if let image = ctx.makeImage() {
        _ = saveImage(image, to: outputDir.appendingPathComponent("test-rgba.png"), format: "png")
    }
}

// 3. Grayscale JPEG (256x256)
print("3. Grayscale JPEG")
if let ctx = createGrayscaleContext(width: 256, height: 256) {
    drawGrayscalePattern(in: ctx, width: 256, height: 256)
    if let image = ctx.makeImage() {
        _ = saveImage(image, to: outputDir.appendingPathComponent("grayscale.jpg"), format: "jpeg", quality: 0.9)
    }
}

// 4. Tiny PNG (8x8)
print("4. Tiny PNG (8x8)")
if let ctx = createContext(width: 8, height: 8) {
    drawSolidColor(in: ctx, width: 8, height: 8, r: 0.2, g: 0.6, b: 1.0)
    if let image = ctx.makeImage() {
        _ = saveImage(image, to: outputDir.appendingPathComponent("tiny.png"), format: "png")
    }
}

// 5. JPEG with EXIF orientation 6 (90° CW)
print("5. JPEG with orientation=6")
if let ctx = createContext(width: 256, height: 256) {
    drawAsymmetricPattern(in: ctx, width: 256, height: 256)
    if let image = ctx.makeImage() {
        _ = saveImageWithOrientation(image, to: outputDir.appendingPathComponent("rotated-6.jpg"), format: "jpeg", orientation: 6)
    }
}

// 6. JPEG with EXIF orientation 3 (180°)
print("6. JPEG with orientation=3")
if let ctx = createContext(width: 256, height: 256) {
    drawAsymmetricPattern(in: ctx, width: 256, height: 256)
    if let image = ctx.makeImage() {
        _ = saveImageWithOrientation(image, to: outputDir.appendingPathComponent("rotated-3.jpg"), format: "jpeg", orientation: 3)
    }
}

// 7. TIFF (256x256)
print("7. TIFF")
if let ctx = createContext(width: 256, height: 256) {
    drawGradientPattern(in: ctx, width: 256, height: 256)
    if let image = ctx.makeImage() {
        _ = saveImage(image, to: outputDir.appendingPathComponent("test.tiff"), format: "tiff")
    }
}

// 8. GIF (simple static)
print("8. GIF")
if let ctx = createContext(width: 64, height: 64) {
    // Simple pattern for GIF (limited color palette)
    drawSolidColor(in: ctx, width: 64, height: 64, r: 1.0, g: 0.5, b: 0.0)
    // Add a contrasting rectangle
    ctx.setFillColor(red: 0, green: 0.5, blue: 1, alpha: 1)
    ctx.fill(CGRect(x: 16, y: 16, width: 32, height: 32))
    if let image = ctx.makeImage() {
        _ = saveImage(image, to: outputDir.appendingPathComponent("test.gif"), format: "gif")
    }
}

// 9. High-quality JPEG for general testing (512x512)
print("9. Standard test JPEG (512x512)")
if let ctx = createContext(width: 512, height: 512) {
    drawGradientPattern(in: ctx, width: 512, height: 512)
    if let image = ctx.makeImage() {
        _ = saveImage(image, to: outputDir.appendingPathComponent("test.jpg"), format: "jpeg", quality: 0.92)
    }
}

print("""

Done!

Note: WebP encoding is not supported by ImageIO. Generate test.webp manually:
  cwebp -q 85 Tests/TestResources/test-rgb.png -o Tests/TestResources/test.webp
""")
