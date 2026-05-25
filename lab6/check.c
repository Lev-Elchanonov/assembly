#include <stdio.h>
#include <stdlib.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

int main(int argc, char* argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <image1.jpg> <image2.jpg>\n", argv[0]);
        return 1;
    }

    int w1, h1, c1;
    int w2, h2, c2;

    unsigned char* img1 = stbi_load(argv[1], &w1, &h1, &c1, 1);
    unsigned char* img2 = stbi_load(argv[2], &w2, &h2, &c2, 1);

    if (!img1) {
        fprintf(stderr, "Error loading %s\n", argv[1]);
        return 1;
    }
    if (!img2) {
        fprintf(stderr, "Error loading %s\n", argv[2]);
        stbi_image_free(img1);
        return 1;
    }

    if (w1 != w2 || h1 != h2) {
        fprintf(stderr, "Images have different sizes: %dx%d vs %dx%d\n", w1, h1, w2, h2);
        stbi_image_free(img1);
        stbi_image_free(img2);
        return 1;
    }

    FILE* f = fopen("diff.txt", "w");
    if (!f) {
        fprintf(stderr, "Cannot create diff.txt\n");
        stbi_image_free(img1);
        stbi_image_free(img2);
        return 1;
    }

    int total_diff = 0;
    int total_pixels = w1 * h1;

    fprintf(f, "Comparing %s and %s\n", argv[1], argv[2]);
    fprintf(f, "Size: %dx%d, Total pixels: %d\n", w1, h1, total_pixels);
    fprintf(f, "========================================\n");

    for (int i = 0; i < total_pixels; i++) {
        if (img1[i] != img2[i]) {
            if (total_diff < 100) {
                int x = i % w1;
                int y = i / w1;
                fprintf(f, "pixel[%d](%d,%d): img1=%d img2=%d diff=%d\n",
                        i, x, y, img1[i], img2[i], abs(img1[i] - img2[i]));
            }
            total_diff++;
        }
    }

    fprintf(f, "========================================\n");
    fprintf(f, "Total different pixels: %d / %d (%.2f%%)\n",
            total_diff, total_pixels, 100.0 * total_diff / total_pixels);

    if (total_diff == 0) {
        fprintf(f, "Images are IDENTICAL!\n");
    }

    fclose(f);
    stbi_image_free(img1);
    stbi_image_free(img2);

    printf("Done. %d diffs out of %d pixels. See diff.txt\n", total_diff, total_pixels);
    return 0;
}