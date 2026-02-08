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
int cvips_heifsave(VipsImage *in, const char *filename, int quality);
int cvips_avifsave(VipsImage *in, const char *filename, int quality);
int cvips_jxlsave(VipsImage *in, const char *filename, int quality);
int cvips_jxlsave_lossless(VipsImage *in, const char *filename);
int cvips_gifsave(VipsImage *in, const char *filename);

// =============================================================================
// Save to buffer
// =============================================================================

int cvips_jpegsave_buffer(VipsImage *in, void **buf, size_t *len, int quality);
int cvips_pngsave_buffer(VipsImage *in, void **buf, size_t *len);
int cvips_webpsave_buffer(VipsImage *in, void **buf, size_t *len, int quality);
int cvips_webpsave_buffer_lossless(VipsImage *in, void **buf, size_t *len);
int cvips_heifsave_buffer(VipsImage *in, void **buf, size_t *len, int quality);
int cvips_avifsave_buffer(VipsImage *in, void **buf, size_t *len, int quality);
int cvips_jxlsave_buffer(VipsImage *in, void **buf, size_t *len, int quality);
int cvips_jxlsave_buffer_lossless(VipsImage *in, void **buf, size_t *len);
int cvips_gifsave_buffer(VipsImage *in, void **buf, size_t *len);

#endif /* CVIPS_H */
