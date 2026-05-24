#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"


extern void sobel_c(unsigned char* input, unsigned char* output, int width, int height, int channels);
extern void sobel_asm(unsigned char* input, unsigned char* output, int width, int height, int channels);
extern void sobel_simd(unsigned char* input, unsigned char* output, int width, int height, int channels);

int main(int argc, char* argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <input_file.jpg> <output_file.jpg>\n", argv[0]);
        return 1;
    }
    const char* input_filename = argv[1];
    const char* output_filename = argv[2];

    int width_, height_, channels_;
    unsigned char* image = stbi_load(input_filename, &width_, &height_, &channels_, 3);

    if (!image) {
        fprintf(stderr, "Error loading image '%s'\n", input_filename);
        fprintf(stderr, "Reason: %s\n", stbi_failure_reason());
        return 1;
    }
    channels_ = 3;

    printf("Image loaded: %dx%d, channels: %d\n", width_, height_, channels_);
    printf("Version: ");
#ifdef USE_ASM
    printf("ASM (no SIMD)\n");
#elif defined(USE_SIMD)
    printf("ASM with SSE2\n");
#else
    printf("C\n");
#endif

    unsigned char* output_image = (unsigned char*)malloc(width_ * height_ * channels_);
    if (!output_image) {
        fprintf(stderr, "Memory allocation error\n");
        stbi_image_free(image);
        return 1;
    }

    clock_t start, end;
    double time_used;

    start = clock();

#ifdef USE_ASM
    sobel_asm(image, output_image, width_, height_, channels_);
#elif defined(USE_SIMD)
    sobel_simd(image, output_image, width_, height_, channels_);
#else
    sobel_c(image, output_image, width_, height_, channels_);
#endif

    end = clock();

    time_used = ((double)(end - start)) / CLOCKS_PER_SEC;
    printf("Processing time: %.4f s\n", time_used);

    if (!stbi_write_jpg(output_filename, width_, height_, channels_, output_image, 95)) {
        fprintf(stderr, "Error saving image '%s'\n", output_filename);
        free(output_image);
        stbi_image_free(image);
        return 1;
    }

    printf("Successfully saved to '%s'\n", output_filename);

    stbi_image_free(image);
    free(output_image);
    return 0;
}