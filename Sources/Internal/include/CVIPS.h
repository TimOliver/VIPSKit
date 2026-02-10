//
//  CVIPS.h
//  VIPSKit
//
//  Non-variadic C wrappers for libvips functions.
//  Swift cannot call variadic C functions, so this thin shim provides
//  non-variadic equivalents that Swift calls instead.
//

#ifndef CVIPS_H
#define CVIPS_H

#include <vips/vips.h>

// =============================================================================
// Loading
// =============================================================================

VipsImage *cvips_image_new_from_file(const char *filename);
VipsImage *cvips_image_new_from_file_sequential(const char *filename);
VipsImage *cvips_image_new_from_buffer(const void *data, size_t length);
VipsImage *cvips_image_new_from_buffer_sequential(const void *data, size_t length);
int cvips_thumbnail(const char *filename, VipsImage **out, int width, int height);
int cvips_thumbnail_buffer(const void *data, size_t length, VipsImage **out, int width, int height);
int cvips_thumbnail_image(VipsImage *in, VipsImage **out, int width, int height);

// =============================================================================
// Resize
// =============================================================================

int cvips_resize(VipsImage *in, VipsImage **out, double scale, VipsKernel kernel);
int cvips_resize_wh(VipsImage *in, VipsImage **out, double hscale, double vscale);

// =============================================================================
// Transform
// =============================================================================

int cvips_crop(VipsImage *in, VipsImage **out, int left, int top, int width, int height);
int cvips_rot(VipsImage *in, VipsImage **out, VipsAngle angle);
int cvips_flip(VipsImage *in, VipsImage **out, VipsDirection direction);
int cvips_autorot(VipsImage *in, VipsImage **out);
int cvips_smartcrop(VipsImage *in, VipsImage **out, int width, int height, VipsInteresting interesting);
int cvips_extract_area(VipsImage *in, VipsImage **out, int left, int top, int width, int height);
int cvips_extract_band(VipsImage *in, VipsImage **out, int band, int n);

// =============================================================================
// Color
// =============================================================================

int cvips_colourspace(VipsImage *in, VipsImage **out, VipsInterpretation space);
int cvips_flatten(VipsImage *in, VipsImage **out, double r, double g, double b);
int cvips_invert(VipsImage *in, VipsImage **out);
int cvips_linear(VipsImage *in, VipsImage **out, const double *a, const double *b, int n);
int cvips_gamma(VipsImage *in, VipsImage **out, double exponent);
int cvips_cast_uchar(VipsImage *in, VipsImage **out);

// =============================================================================
// Filter
// =============================================================================

int cvips_gaussblur(VipsImage *in, VipsImage **out, double sigma);
int cvips_sharpen(VipsImage *in, VipsImage **out, double sigma);
int cvips_sobel(VipsImage *in, VipsImage **out);
int cvips_canny(VipsImage *in, VipsImage **out, double sigma);

// =============================================================================
// Composite
// =============================================================================

int cvips_composite2(VipsImage *base, VipsImage *overlay, VipsImage **out, VipsBlendMode mode, int x, int y);

// =============================================================================
// Analysis
// =============================================================================

int cvips_find_trim(VipsImage *in, int *left, int *top, int *width, int *height, double threshold);
int cvips_find_trim_bg(VipsImage *in, int *left, int *top, int *width, int *height, double threshold, double *background, int bg_count);
int cvips_min(VipsImage *in, double *out);
int cvips_max(VipsImage *in, double *out);
int cvips_avg(VipsImage *in, double *out);
int cvips_deviate(VipsImage *in, double *out);
int cvips_stats(VipsImage *in, VipsImage **out);
int cvips_subtract(VipsImage *in, VipsImage *other, VipsImage **out);
int cvips_abs(VipsImage *in, VipsImage **out);
int cvips_join(VipsImage *in1, VipsImage *in2, VipsImage **out, VipsDirection direction);

// =============================================================================
// Save to file
// =============================================================================

int cvips_write_to_file(VipsImage *in, const char *filename);
int cvips_jpegsave(VipsImage *in, const char *filename, int quality);
int cvips_pngsave(VipsImage *in, const char *filename);
int cvips_webpsave(VipsImage *in, const char *filename, int quality);
int cvips_webpsave_lossless(VipsImage *in, const char *filename);
int cvips_jxlsave(VipsImage *in, const char *filename, int quality);
int cvips_jxlsave_lossless(VipsImage *in, const char *filename);
int cvips_gifsave(VipsImage *in, const char *filename);

// =============================================================================
// Histogram
// =============================================================================

int cvips_hist_equal(VipsImage *in, VipsImage **out);

// =============================================================================
// Arbitrary rotation
// =============================================================================

int cvips_rotate(VipsImage *in, VipsImage **out, double angle);

// =============================================================================
// Embed / Pad
// =============================================================================

int cvips_embed(VipsImage *in, VipsImage **out, int x, int y, int width, int height, VipsExtend extend);
int cvips_gravity(VipsImage *in, VipsImage **out, VipsCompassDirection direction, int width, int height, VipsExtend extend);

// =============================================================================
// Band manipulation
// =============================================================================

int cvips_bandjoin2(VipsImage *in1, VipsImage *in2, VipsImage **out);
int cvips_bandjoin_const1(VipsImage *in, VipsImage **out, double c);
int cvips_addalpha(VipsImage *in, VipsImage **out);

// =============================================================================
// Premultiplied alpha
// =============================================================================

int cvips_premultiply(VipsImage *in, VipsImage **out);
int cvips_unpremultiply(VipsImage *in, VipsImage **out);

// =============================================================================
// Canvas creation
// =============================================================================

int cvips_black(VipsImage **out, int width, int height, int bands);

// =============================================================================
// Drawing (mutate in-place)
// =============================================================================

int cvips_draw_rect(VipsImage *image, double *ink, int n, int left, int top, int width, int height, int fill);
int cvips_draw_line(VipsImage *image, double *ink, int n, int x1, int y1, int x2, int y2);
int cvips_draw_circle(VipsImage *image, double *ink, int n, int cx, int cy, int radius, int fill);
int cvips_draw_flood(VipsImage *image, double *ink, int n, int x, int y);

// =============================================================================
// Pixel reading
// =============================================================================

int cvips_getpoint(VipsImage *in, double **vector, int *n, int x, int y);

// =============================================================================
// TIFF I/O
// =============================================================================

int cvips_tiffsave(VipsImage *in, const char *filename);
int cvips_tiffsave_buffer(VipsImage *in, void **buf, size_t *len);

// =============================================================================
// Save to buffer
// =============================================================================

int cvips_jpegsave_buffer(VipsImage *in, void **buf, size_t *len, int quality);
int cvips_pngsave_buffer(VipsImage *in, void **buf, size_t *len);
int cvips_webpsave_buffer(VipsImage *in, void **buf, size_t *len, int quality);
int cvips_webpsave_buffer_lossless(VipsImage *in, void **buf, size_t *len);
int cvips_jxlsave_buffer(VipsImage *in, void **buf, size_t *len, int quality);
int cvips_jxlsave_buffer_lossless(VipsImage *in, void **buf, size_t *len);
int cvips_gifsave_buffer(VipsImage *in, void **buf, size_t *len);

#endif /* CVIPS_H */
