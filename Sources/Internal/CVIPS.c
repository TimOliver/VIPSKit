//
//  CVIPS.c
//  VIPSKit
//
//  Non-variadic C wrappers for libvips variadic functions.
//  Each function is a one-liner calling the variadic original.
//

#include "CVIPS.h"

// =============================================================================
// Loading
// =============================================================================

VipsImage *cvips_image_new_from_file(const char *filename) {
    return vips_image_new_from_file(filename, NULL);
}

VipsImage *cvips_image_new_from_file_sequential(const char *filename) {
    return vips_image_new_from_file(filename, "access", VIPS_ACCESS_SEQUENTIAL, NULL);
}

VipsImage *cvips_image_new_from_buffer(const void *data, size_t length) {
    return vips_image_new_from_buffer(data, length, "", NULL);
}

VipsImage *cvips_image_new_from_buffer_sequential(const void *data, size_t length) {
    return vips_image_new_from_buffer(data, length, "", "access", VIPS_ACCESS_SEQUENTIAL, NULL);
}

int cvips_thumbnail(const char *filename, VipsImage **out, int width, int height) {
    return vips_thumbnail(filename, out, width, "height", height, NULL);
}

int cvips_thumbnail_buffer(const void *data, size_t length, VipsImage **out, int width, int height) {
    return vips_thumbnail_buffer((void *)data, length, out, width, "height", height, NULL);
}

int cvips_thumbnail_image(VipsImage *in, VipsImage **out, int width, int height) {
    return vips_thumbnail_image(in, out, width, "height", height, NULL);
}

// =============================================================================
// Resize
// =============================================================================

int cvips_resize(VipsImage *in, VipsImage **out, double scale, VipsKernel kernel) {
    return vips_resize(in, out, scale, "kernel", kernel, NULL);
}

int cvips_resize_wh(VipsImage *in, VipsImage **out, double hscale, double vscale) {
    return vips_resize(in, out, hscale, "vscale", vscale, NULL);
}

// =============================================================================
// Transform
// =============================================================================

int cvips_crop(VipsImage *in, VipsImage **out, int left, int top, int width, int height) {
    return vips_crop(in, out, left, top, width, height, NULL);
}

int cvips_rot(VipsImage *in, VipsImage **out, VipsAngle angle) {
    return vips_rot(in, out, angle, NULL);
}

int cvips_flip(VipsImage *in, VipsImage **out, VipsDirection direction) {
    return vips_flip(in, out, direction, NULL);
}

int cvips_autorot(VipsImage *in, VipsImage **out) {
    return vips_autorot(in, out, NULL);
}

int cvips_smartcrop(VipsImage *in, VipsImage **out, int width, int height, VipsInteresting interesting) {
    return vips_smartcrop(in, out, width, height, "interesting", interesting, NULL);
}

int cvips_extract_area(VipsImage *in, VipsImage **out, int left, int top, int width, int height) {
    return vips_extract_area(in, out, left, top, width, height, NULL);
}

int cvips_extract_band(VipsImage *in, VipsImage **out, int band, int n) {
    return vips_extract_band(in, out, band, "n", n, NULL);
}

// =============================================================================
// Color
// =============================================================================

int cvips_colourspace(VipsImage *in, VipsImage **out, VipsInterpretation space) {
    return vips_colourspace(in, out, space, NULL);
}

int cvips_flatten(VipsImage *in, VipsImage **out, double r, double g, double b) {
    VipsArrayDouble *background = vips_array_double_newv(3, r, g, b);
    int result = vips_flatten(in, out, "background", background, NULL);
    vips_area_unref(VIPS_AREA(background));
    return result;
}

int cvips_invert(VipsImage *in, VipsImage **out) {
    return vips_invert(in, out, NULL);
}

int cvips_linear(VipsImage *in, VipsImage **out, const double *a, const double *b, int n) {
    return vips_linear(in, out, a, b, n, NULL);
}

int cvips_gamma(VipsImage *in, VipsImage **out, double exponent) {
    return vips_gamma(in, out, "exponent", exponent, NULL);
}

int cvips_cast_uchar(VipsImage *in, VipsImage **out) {
    return vips_cast_uchar(in, out, NULL);
}

// =============================================================================
// Filter
// =============================================================================

int cvips_gaussblur(VipsImage *in, VipsImage **out, double sigma) {
    return vips_gaussblur(in, out, sigma, NULL);
}

int cvips_sharpen(VipsImage *in, VipsImage **out, double sigma) {
    return vips_sharpen(in, out, "sigma", sigma, NULL);
}

int cvips_sobel(VipsImage *in, VipsImage **out) {
    return vips_sobel(in, out, NULL);
}

int cvips_canny(VipsImage *in, VipsImage **out, double sigma) {
    return vips_canny(in, out, "sigma", sigma, NULL);
}

// =============================================================================
// Composite
// =============================================================================

int cvips_composite2(VipsImage *base, VipsImage *overlay, VipsImage **out, VipsBlendMode mode, int x, int y) {
    return vips_composite2(base, overlay, out, mode, "x", x, "y", y, NULL);
}

// =============================================================================
// Analysis
// =============================================================================

int cvips_find_trim(VipsImage *in, int *left, int *top, int *width, int *height, double threshold) {
    return vips_find_trim(in, left, top, width, height, "threshold", threshold, NULL);
}

int cvips_find_trim_bg(VipsImage *in, int *left, int *top, int *width, int *height, double threshold, double *background, int bg_count) {
    VipsArrayDouble *bgArray = vips_array_double_new(background, bg_count);
    int result = vips_find_trim(in, left, top, width, height,
                                "threshold", threshold,
                                "background", bgArray,
                                NULL);
    vips_area_unref(VIPS_AREA(bgArray));
    return result;
}

int cvips_min(VipsImage *in, double *out) {
    return vips_min(in, out, NULL);
}

int cvips_max(VipsImage *in, double *out) {
    return vips_max(in, out, NULL);
}

int cvips_avg(VipsImage *in, double *out) {
    return vips_avg(in, out, NULL);
}

int cvips_deviate(VipsImage *in, double *out) {
    return vips_deviate(in, out, NULL);
}

int cvips_stats(VipsImage *in, VipsImage **out) {
    return vips_stats(in, out, NULL);
}

int cvips_subtract(VipsImage *in, VipsImage *other, VipsImage **out) {
    return vips_subtract(in, other, out, NULL);
}

int cvips_abs(VipsImage *in, VipsImage **out) {
    return vips_abs(in, out, NULL);
}

int cvips_join(VipsImage *in1, VipsImage *in2, VipsImage **out, VipsDirection direction) {
    return vips_join(in1, in2, out, direction, NULL);
}

// =============================================================================
// Save to file
// =============================================================================

int cvips_write_to_file(VipsImage *in, const char *filename) {
    return vips_image_write_to_file(in, filename, NULL);
}

int cvips_jpegsave(VipsImage *in, const char *filename, int quality) {
    return vips_jpegsave(in, filename, "Q", quality, NULL);
}

int cvips_pngsave(VipsImage *in, const char *filename) {
    return vips_pngsave(in, filename, NULL);
}

int cvips_webpsave(VipsImage *in, const char *filename, int quality) {
    return vips_webpsave(in, filename, "Q", quality, NULL);
}

int cvips_webpsave_lossless(VipsImage *in, const char *filename) {
    return vips_webpsave(in, filename, "lossless", TRUE, NULL);
}

int cvips_heifsave(VipsImage *in, const char *filename, int quality) {
    return vips_heifsave(in, filename, "Q", quality, NULL);
}

int cvips_avifsave(VipsImage *in, const char *filename, int quality) {
    return vips_heifsave(in, filename, "Q", quality, "compression", VIPS_FOREIGN_HEIF_COMPRESSION_AV1, NULL);
}

int cvips_jxlsave(VipsImage *in, const char *filename, int quality) {
    return vips_jxlsave(in, filename, "Q", quality, NULL);
}

int cvips_jxlsave_lossless(VipsImage *in, const char *filename) {
    return vips_jxlsave(in, filename, "lossless", TRUE, NULL);
}

int cvips_gifsave(VipsImage *in, const char *filename) {
    return vips_gifsave(in, filename, NULL);
}

// =============================================================================
// Histogram
// =============================================================================

int cvips_hist_equal(VipsImage *in, VipsImage **out) {
    return vips_hist_equal(in, out, NULL);
}

// =============================================================================
// Arbitrary rotation
// =============================================================================

int cvips_rotate(VipsImage *in, VipsImage **out, double angle) {
    return vips_rotate(in, out, angle, NULL);
}

// =============================================================================
// Embed / Pad
// =============================================================================

int cvips_embed(VipsImage *in, VipsImage **out, int x, int y, int width, int height, VipsExtend extend) {
    return vips_embed(in, out, x, y, width, height, "extend", extend, NULL);
}

int cvips_gravity(VipsImage *in, VipsImage **out, VipsCompassDirection direction, int width, int height, VipsExtend extend) {
    return vips_gravity(in, out, direction, width, height, "extend", extend, NULL);
}

// =============================================================================
// Band manipulation
// =============================================================================

int cvips_bandjoin2(VipsImage *in1, VipsImage *in2, VipsImage **out) {
    return vips_bandjoin2(in1, in2, out, NULL);
}

int cvips_bandjoin_const1(VipsImage *in, VipsImage **out, double c) {
    return vips_bandjoin_const1(in, out, c, NULL);
}

int cvips_addalpha(VipsImage *in, VipsImage **out) {
    return vips_addalpha(in, out, NULL);
}

// =============================================================================
// Premultiplied alpha
// =============================================================================

int cvips_premultiply(VipsImage *in, VipsImage **out) {
    return vips_premultiply(in, out, NULL);
}

int cvips_unpremultiply(VipsImage *in, VipsImage **out) {
    return vips_unpremultiply(in, out, NULL);
}

// =============================================================================
// Canvas creation
// =============================================================================

int cvips_black(VipsImage **out, int width, int height, int bands) {
    return vips_black(out, width, height, "bands", bands, NULL);
}

// =============================================================================
// Drawing (mutate in-place)
// =============================================================================

int cvips_draw_rect(VipsImage *image, double *ink, int n, int left, int top, int width, int height, int fill) {
    return vips_draw_rect(image, ink, n, left, top, width, height, "fill", fill, NULL);
}

int cvips_draw_line(VipsImage *image, double *ink, int n, int x1, int y1, int x2, int y2) {
    return vips_draw_line(image, ink, n, x1, y1, x2, y2, NULL);
}

int cvips_draw_circle(VipsImage *image, double *ink, int n, int cx, int cy, int radius, int fill) {
    return vips_draw_circle(image, ink, n, cx, cy, radius, "fill", fill, NULL);
}

int cvips_draw_flood(VipsImage *image, double *ink, int n, int x, int y) {
    return vips_draw_flood(image, ink, n, x, y, NULL);
}

// =============================================================================
// Pixel reading
// =============================================================================

int cvips_getpoint(VipsImage *in, double **vector, int *n, int x, int y) {
    return vips_getpoint(in, vector, n, x, y, NULL);
}

// =============================================================================
// TIFF I/O
// =============================================================================

int cvips_tiffsave(VipsImage *in, const char *filename) {
    return vips_tiffsave(in, filename, NULL);
}

int cvips_tiffsave_buffer(VipsImage *in, void **buf, size_t *len) {
    return vips_tiffsave_buffer(in, buf, len, NULL);
}

// =============================================================================
// Save to buffer
// =============================================================================

int cvips_jpegsave_buffer(VipsImage *in, void **buf, size_t *len, int quality) {
    return vips_jpegsave_buffer(in, buf, len, "Q", quality, NULL);
}

int cvips_pngsave_buffer(VipsImage *in, void **buf, size_t *len) {
    return vips_pngsave_buffer(in, buf, len, NULL);
}

int cvips_webpsave_buffer(VipsImage *in, void **buf, size_t *len, int quality) {
    return vips_webpsave_buffer(in, buf, len, "Q", quality, NULL);
}

int cvips_webpsave_buffer_lossless(VipsImage *in, void **buf, size_t *len) {
    return vips_webpsave_buffer(in, buf, len, "lossless", TRUE, NULL);
}

int cvips_heifsave_buffer(VipsImage *in, void **buf, size_t *len, int quality) {
    return vips_heifsave_buffer(in, buf, len, "Q", quality, NULL);
}

int cvips_avifsave_buffer(VipsImage *in, void **buf, size_t *len, int quality) {
    return vips_heifsave_buffer(in, buf, len, "Q", quality, "compression", VIPS_FOREIGN_HEIF_COMPRESSION_AV1, NULL);
}

int cvips_jxlsave_buffer(VipsImage *in, void **buf, size_t *len, int quality) {
    return vips_jxlsave_buffer(in, buf, len, "Q", quality, NULL);
}

int cvips_jxlsave_buffer_lossless(VipsImage *in, void **buf, size_t *len) {
    return vips_jxlsave_buffer(in, buf, len, "lossless", TRUE, NULL);
}

int cvips_gifsave_buffer(VipsImage *in, void **buf, size_t *len) {
    return vips_gifsave_buffer(in, buf, len, NULL);
}
