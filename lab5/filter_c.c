#include <string.h>
#include <stdlib.h>

void edge_detection_c(unsigned char* input, unsigned char* output, int width, int height, int channels) {
    const int kernel[3][3] = {
        {-1, -1, -1},
        {-1,  8, -1},
        {-1, -1, -1}
    };

    int padded_width = width + 2;
    int padded_height = height + 2;

    unsigned char* padded_img = (unsigned char*)malloc(padded_width * padded_height * channels);

    for (int y = 0; y < padded_height; y++) {
        for (int x = 0; x < padded_width; x++) {
            int src_x = x - 1;
            int src_y = y - 1;

            if (src_x < 0)
                src_x = 0;
            if (src_x >= width)
                src_x = width - 1;
            if (src_y < 0)
                src_y = 0;
            if (src_y >= height)
                src_y = height - 1;

            for (int c = 0; c < channels; c++) {
                padded_img[(y * padded_width + x) * channels + c] = input[(src_y * width + src_x) * channels + c];
            }
        }
    }

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            for (int c = 0; c < channels; c++) {
                int accumulator = 0;

                for (int ky = 0; ky < 3; ky++) {
                    for (int kx = 0; kx < 3; kx++) {
                        int py = y + ky;
                        int px = x + kx;
                        int pixel = padded_img[(py * padded_width + px) * channels + c];
                        accumulator += pixel * kernel[ky][kx];
                    }
                }
                if (accumulator < 0) accumulator = 0;
                if (accumulator > 255) accumulator = 255;

                output[(y * width + x) * channels + c] = (unsigned char)accumulator;
            }
        }
    }

    free(padded_img);
}