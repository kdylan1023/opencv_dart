/* Created by Abdelaziz Mahdy. Licensed: Apache 2.0 license. Copyright (c) 2024 Abdelaziz Mahdy. */
#include "photo_async.h"
#include "core/types.h"

// Asynchronous functions for ColorChange
CvStatus *ColorChange_Async(Mat src, Mat mask, float red_mul, float green_mul, float blue_mul, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::colorChange(*src.ptr, *mask.ptr, _dst, red_mul, green_mul, blue_mul);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

// Asynchronous functions for SeamlessClone
CvStatus *SeamlessClone_Async(Mat src, Mat dst, Mat mask, Point p, int flags, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _blend;
    cv::seamlessClone(*src.ptr, *dst.ptr, *mask.ptr, cv::Point(p.x, p.y), _blend, flags);
    callback(new Mat{new cv::Mat(_blend)});
    END_WRAP
}

// Asynchronous functions for IlluminationChange
CvStatus *IlluminationChange_Async(Mat src, Mat mask, float alpha, float beta, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::illuminationChange(*src.ptr, *mask.ptr, _dst, alpha, beta);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

// Asynchronous functions for TextureFlattening
CvStatus *TextureFlattening_Async(Mat src, Mat mask, float low_threshold, float high_threshold, int kernel_size, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::textureFlattening(*src.ptr, *mask.ptr, _dst, low_threshold, high_threshold, kernel_size);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

// Asynchronous functions for FastNlMeansDenoisingColoredMulti
CvStatus *FastNlMeansDenoisingColoredMulti_Async(VecMat src, int imgToDenoiseIndex, int temporalWindowSize, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::fastNlMeansDenoisingColoredMulti(*src.ptr, _dst, imgToDenoiseIndex, temporalWindowSize);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

CvStatus *FastNlMeansDenoisingColoredMultiWithParams_Async(VecMat src, int imgToDenoiseIndex, int temporalWindowSize, float h, float hColor, int templateWindowSize, int searchWindowSize, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::fastNlMeansDenoisingColoredMulti(*src.ptr, _dst, imgToDenoiseIndex, temporalWindowSize, h, hColor, templateWindowSize, searchWindowSize);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

// Asynchronous functions for FastNlMeansDenoising
CvStatus *FastNlMeansDenoising_Async(Mat src, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::fastNlMeansDenoising(*src.ptr, _dst);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

CvStatus *FastNlMeansDenoisingWithParams_Async(Mat src, float h, int templateWindowSize, int searchWindowSize, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::fastNlMeansDenoising(*src.ptr, _dst, h, templateWindowSize, searchWindowSize);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

// Asynchronous functions for FastNlMeansDenoisingColored
CvStatus *FastNlMeansDenoisingColored_Async(Mat src, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::fastNlMeansDenoisingColored(*src.ptr, _dst);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

CvStatus *FastNlMeansDenoisingColoredWithParams_Async(Mat src, float h, float hColor, int templateWindowSize, int searchWindowSize, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::fastNlMeansDenoisingColored(*src.ptr, _dst, h, hColor, templateWindowSize, searchWindowSize);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

// Asynchronous functions for MergeMertens
CvStatus *MergeMertens_Create_Async(CvCallback_1 callback) {
    BEGIN_WRAP
    callback(new MergeMertens{new cv::Ptr<cv::MergeMertens>(cv::createMergeMertens())});
    END_WRAP
}

CvStatus *MergeMertens_CreateWithParams_Async(float contrast_weight, float saturation_weight, float exposure_weight, CvCallback_1 callback) {
    BEGIN_WRAP
    callback(new MergeMertens{new cv::Ptr<cv::MergeMertens>(cv::createMergeMertens(contrast_weight, saturation_weight, exposure_weight))});
    END_WRAP
}

CvStatus *MergeMertens_Process_Async(MergeMertens b, VecMat src, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    (*b.ptr)->process(*src.ptr, _dst);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

// Asynchronous functions for AlignMTB
CvStatus *AlignMTB_Create_Async(CvCallback_1 callback) {
    BEGIN_WRAP
    callback(new AlignMTB{new cv::Ptr<cv::AlignMTB>(cv::createAlignMTB())});
    END_WRAP
}

CvStatus *AlignMTB_CreateWithParams_Async(int max_bits, int exclude_range, bool cut, CvCallback_1 callback) {
    BEGIN_WRAP
    callback(new AlignMTB{new cv::Ptr<cv::AlignMTB>(cv::createAlignMTB(max_bits, exclude_range, cut))});
    END_WRAP
}

CvStatus *AlignMTB_Process_Async(AlignMTB b, VecMat src, CvCallback_1 callback) {
    BEGIN_WRAP
    auto vec = std::vector<cv::Mat>();
    (*b.ptr)->process(*src.ptr, vec);
    callback(new VecMat{new std::vector<cv::Mat>(vec)});
    END_WRAP
}

// Asynchronous functions for DetailEnhance
CvStatus *DetailEnhance_Async(Mat src, float sigma_s, float sigma_r, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::detailEnhance(*src.ptr, _dst, sigma_s, sigma_r);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

// Asynchronous functions for EdgePreservingFilter
CvStatus *EdgePreservingFilter_Async(Mat src, int filter, float sigma_s, float sigma_r, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::edgePreservingFilter(*src.ptr, _dst, filter, sigma_s, sigma_r);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

// Asynchronous functions for PencilSketch
CvStatus *PencilSketch_Async(Mat src, Mat dst1, Mat dst2, float sigma_s, float sigma_r, float shade_factor, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::pencilSketch(*src.ptr, *dst1.ptr, *dst2.ptr, sigma_s, sigma_r, shade_factor);
    callback(new Mat{new cv::Mat(*dst1.ptr)}, new Mat{new cv::Mat(*dst2.ptr)});
    END_WRAP
}

// Asynchronous functions for Stylization
CvStatus *Stylization_Async(Mat src, float sigma_s, float sigma_r, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::stylization(*src.ptr, _dst, sigma_s, sigma_r);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}

// Asynchronous functions for PhotoInpaint
CvStatus *PhotoInpaint_Async(Mat src, Mat mask, float inpaint_radius, int algorithm_type, CvCallback_1 callback) {
    BEGIN_WRAP
    cv::Mat _dst;
    cv::inpaint(*src.ptr, *mask.ptr, _dst, inpaint_radius, algorithm_type);
    callback(new Mat{new cv::Mat(_dst)});
    END_WRAP
}
