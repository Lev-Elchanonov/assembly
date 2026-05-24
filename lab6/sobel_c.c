#include <math.h>
#include <stdlib.h>
#include <string.h>


static const int Gx[3][3] = {
    {-1, 0, 1},
    {-2, 0, 2},
    {-1, 0, 1}
};


static const int Gy[3][3] = {
    { 1,  2,  1},
    { 0,  0,  0},
    {-1, -2, -1}
};


void sobel_c(unsigned char* input, unsigned char* output, int width, int height, int channels) {
    int padded_width = width + 2;
    int padded_height = height + 2;

    unsigned char* padded = (unsigned char*)malloc(padded_width * padded_height * channels);

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
                padded[(y * padded_width + x) * channels + c] = input[(src_y * width + src_x) * channels + c];
            }
        }
    }


    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            for (int c = 0; c < channels; c++) {
                int sum_x = 0;
                int sum_y = 0;


                for (int ky = 0; ky < 3; ky++) {
                    for (int kx = 0; kx < 3; kx++) {
                        int py = y + ky;
                        int px = x + kx;
                        int pixel = padded[(py * padded_width + px) * channels + c];

                        sum_x += pixel * Gx[ky][kx];
                        sum_y += pixel * Gy[ky][kx];
                    }
                }


                int magnitude = abs(sum_x) + abs(sum_y);

                if (magnitude < 0)
                   magnitude = 0;
                else if (magnitude > 255)
                    magnitude = 255;
                output[(y * width + x) * channels + c] = magnitude;
            }
        }
    }

    free(padded);
}