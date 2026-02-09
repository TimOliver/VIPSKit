import Foundation
internal import vips

extension VIPSImage {

    // MARK: - Metadata Subscript

    /// A convenience proxy for reading and writing string metadata by key.
    ///
    /// ```swift
    /// // Read
    /// let artist = image.metadata["exif-ifd0-Artist"]
    ///
    /// // Write
    /// image.metadata["my-custom-field"] = "hello"
    ///
    /// // Remove
    /// image.metadata["my-custom-field"] = nil
    /// ```
    public var metadata: MetadataProxy { MetadataProxy(image: self) }

    /// A lightweight proxy that provides subscript access to string metadata fields.
    public struct MetadataProxy {
        internal let image: VIPSImage

        /// Get or set a string metadata value by key.
        /// Setting `nil` removes the field.
        public subscript(key: String) -> String? {
            get { image.getString(named: key) }
            nonmutating set {
                if let value = newValue {
                    image.setString(named: key, value: value)
                } else {
                    image.removeMetadata(named: key)
                }
            }
        }
    }

    // MARK: - Generic Metadata Access

    /// All metadata field names attached to the image.
    ///
    /// This includes standard fields like `"width"`, `"height"`, and `"bands"`,
    /// as well as format-specific metadata like EXIF tags, ICC profiles, and XMP data.
    public var metadataFields: [String] {
        guard let fields = vips_image_get_fields(pointer) else { return [] }
        defer { g_strfreev(fields) }

        var result: [String] = []
        var i = 0
        while let field = fields[i] {
            result.append(String(cString: field))
            i += 1
        }
        return result
    }

    /// Check whether a metadata field exists on the image.
    /// - Parameter name: The metadata field name
    /// - Returns: `true` if the field exists
    public func hasMetadata(named name: String) -> Bool {
        vips_image_get_typeof(pointer, name) != 0
    }

    /// Get a string metadata value.
    /// - Parameter name: The metadata field name
    /// - Returns: The string value, or `nil` if the field does not exist or is not a string
    public func getString(named name: String) -> String? {
        var value: UnsafePointer<CChar>?
        guard vips_image_get_string(pointer, name, &value) == 0,
              let value else { return nil }
        return String(cString: value)
    }

    /// Get an integer metadata value.
    /// - Parameter name: The metadata field name
    /// - Returns: The integer value, or `nil` if the field does not exist or is not an integer
    public func getInt(named name: String) -> Int? {
        var value: Int32 = 0
        guard vips_image_get_int(pointer, name, &value) == 0 else { return nil }
        return Int(value)
    }

    /// Get a double metadata value.
    /// - Parameter name: The metadata field name
    /// - Returns: The double value, or `nil` if the field does not exist or is not a double
    public func getDouble(named name: String) -> Double? {
        var value: Double = 0
        guard vips_image_get_double(pointer, name, &value) == 0 else { return nil }
        return value
    }

    /// Get binary blob metadata (e.g., raw EXIF, XMP, or ICC data).
    ///
    /// The returned `Data` is a copy of the blob — it remains valid after the image is deallocated.
    /// - Parameter name: The metadata field name
    /// - Returns: The blob data, or `nil` if the field does not exist or is not a blob
    public func getBlob(named name: String) -> Data? {
        var data: UnsafeRawPointer?
        var length: Int = 0
        guard vips_image_get_blob(pointer, name, &data, &length) == 0,
              let data, length > 0 else { return nil }
        return Data(bytes: data, count: length)
    }

    /// Remove a metadata field from the image.
    /// - Parameter name: The metadata field name to remove
    /// - Returns: `true` if the field was found and removed
    @discardableResult
    public func removeMetadata(named name: String) -> Bool {
        vips_image_remove(pointer, name) != 0
    }

    /// Set a string metadata value on the image.
    /// - Parameters:
    ///   - name: The metadata field name
    ///   - value: The string value to set
    public func setString(named name: String, value: String) {
        vips_image_set_string(pointer, name, value)
    }

    /// Set an integer metadata value on the image.
    /// - Parameters:
    ///   - name: The metadata field name
    ///   - value: The integer value to set
    public func setInt(named name: String, value: Int) {
        vips_image_set_int(pointer, name, Int32(value))
    }

    /// Set a double metadata value on the image.
    /// - Parameters:
    ///   - name: The metadata field name
    ///   - value: The double value to set
    public func setDouble(named name: String, value: Double) {
        vips_image_set_double(pointer, name, value)
    }

    // MARK: - High-Level Image Metadata

    /// The EXIF orientation tag (1–8), or `nil` if not present.
    ///
    /// Orientation values follow the EXIF specification:
    /// 1 = normal, 2 = flipped horizontal, 3 = rotated 180°,
    /// 4 = flipped vertical, 5 = transposed, 6 = rotated 90° CW,
    /// 7 = transverse, 8 = rotated 270° CW.
    public var orientation: Int? {
        getInt(named: VIPS_META_ORIENTATION)
    }

    /// The image resolution in pixels per millimeter (X axis).
    public var xResolution: Double {
        Double(vips_image_get_xres(pointer))
    }

    /// The image resolution in pixels per millimeter (Y axis).
    public var yResolution: Double {
        Double(vips_image_get_yres(pointer))
    }

    /// The number of pages in a multi-page image (e.g., animated GIF, multi-page TIFF).
    /// Returns 1 for single-page images.
    public var pageCount: Int {
        getInt(named: VIPS_META_N_PAGES) ?? 1
    }

    /// The height of a single page in a multi-page image, or `nil` for single-page images.
    public var pageHeight: Int? {
        getInt(named: VIPS_META_PAGE_HEIGHT)
    }

    /// The raw EXIF data blob, or `nil` if the image has no EXIF metadata.
    public var exifData: Data? {
        getBlob(named: VIPS_META_EXIF_NAME)
    }

    /// The raw XMP metadata blob, or `nil` if the image has no XMP metadata.
    public var xmpData: Data? {
        getBlob(named: VIPS_META_XMP_NAME)
    }

    /// The ICC color profile data, or `nil` if the image has no ICC profile.
    public var iccProfile: Data? {
        getBlob(named: VIPS_META_ICC_NAME)
    }

    /// Read an individual EXIF string field by tag name.
    ///
    /// libvips exposes parsed EXIF tags as string metadata with prefixes like
    /// `"exif-ifd0-"` and `"exif-ifd2-"`. This method looks up the field under
    /// the standard IFD0 prefix first, then falls back to other common IFDs.
    ///
    /// ```swift
    /// let make = image.exifField("Make")     // e.g., "Canon"
    /// let model = image.exifField("Model")   // e.g., "Canon EOS R5"
    /// ```
    ///
    /// - Parameter name: The EXIF tag name (e.g., `"Make"`, `"Model"`, `"DateTime"`)
    /// - Returns: The string value of the EXIF field, or `nil` if not found
    public func exifField(_ name: String) -> String? {
        // Try IFD0 first (most common), then IFD2 (EXIF sub-IFD), then IFD3 (GPS)
        for prefix in ["exif-ifd0-", "exif-ifd2-", "exif-ifd3-"] {
            if let value = getString(named: "\(prefix)\(name)") {
                return value
            }
        }
        return nil
    }
}
