#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"


extern void edge_detection_c(unsigned char* input, unsigned char* output, int width, int height, int channels);
extern void edge_detection_asm(unsigned char* input, unsigned char* output, int width, int height, int channels);

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
        fprintf(stderr, "Error in opening file %s\n", input_filename);
        fprintf(stderr, "Reason: %s\n", stbi_failure_reason());
        return 1;
    }
    channels_ = 3;

    fprintf(stdout, "Image successfully loaded: %dx%d\n", width_, height_);

    unsigned char* output_image = (unsigned char*)malloc(width_ * height_ * channels_);

    clock_t start, end;
    double time_used;

#ifdef USE_ASM
    start = clock();
    edge_detection_asm(image, output_image, width_, height_, channels_);
    end = clock();
#else
    start = clock();
    edge_detection_c(image, output_image, width_, height_, channels_);
    end = clock();
#endif

    time_used = ((double) (end - start)) / CLOCKS_PER_SEC;
    fprintf(stdout, "time: %f s\n", time_used);

    if (!stbi_write_jpg(output_filename, width_, height_, channels_, output_image, 95)) {
        fprintf(stderr, "Error: Can not safe image '%s'\n", output_filename);
    } else {
        fprintf(stdout, "Success\n");
    }
    stbi_image_free(image);
    free(output_image);
    return 0;
}