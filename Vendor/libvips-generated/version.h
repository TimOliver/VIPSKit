/* Macros for the header version.
 */

#ifndef VIPS_VERSION_H
#define VIPS_VERSION_H

#define VIPS_VERSION "8.18.0"
#define VIPS_VERSION_STRING "8.18.0"
#define VIPS_MAJOR_VERSION (8)
#define VIPS_MINOR_VERSION (18)
#define VIPS_MICRO_VERSION (0)

/* The ABI version, as used for library versioning.
 */
#define VIPS_LIBRARY_CURRENT (62)
#define VIPS_LIBRARY_REVISION (0)
#define VIPS_LIBRARY_AGE (20)

#define VIPS_CONFIG "enable debug: false\nenable deprecated: false\nenable modules: false\nenable C++ binding: true\nenable RAD load/save: true\nenable Analyze7 load: true\nenable PPM load/save: true\nenable GIF load: true\nFFTs with fftw: false\nSIMD support with libhwy: true\nICC profile support with lcms2: false\ndeflate compression with zlib: true\ntext rendering with pangocairo: false\nfont file support with fontconfig: false\nEXIF metadata support with libexif: false\nJPEG load/save with libjpeg: true\nUHDR load/save with libuhdr: false\nJXL load/save with libjxl: true (dynamic module: false)\nJPEG2000 load/save with OpenJPEG: false\nPNG load/save with libpng: true\nimage quantisation with imagequant or quantizr: false\nTIFF load/save with libtiff: false\nimage pyramid save with libarchive: false\nHEIC/AVIF load/save with libheif: true (dynamic module: false)\nWebP load/save with libwebp: true\nPDF load with PDFium or Poppler: false (dynamic module: false)\nSVG load with librsvg: false\nEXR load with OpenEXR: false\nWSI load with OpenSlide: false (dynamic module: false)\nMatlab load with Matio: false\nNIfTI load/save with libnifti: false\nFITS load/save with cfitsio: false\nGIF save with cgif: false\nRAW load with libraw: false\nMagick load/save with MagickCore: false (dynamic module: false)"

/* Not really anything to do with versions, but this is a handy place to put
 * it.
 */
#define VIPS_ENABLE_DEPRECATED 0

#endif /*VIPS_VERSION_H*/
