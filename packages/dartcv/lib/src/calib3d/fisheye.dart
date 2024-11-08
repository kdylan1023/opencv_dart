// Copyright (c) 2024, rainyl and all contributors. All rights reserved.
// Use of this source code is governed by a Apache-2.0 license
// that can be found in the LICENSE file.

library cv.calib3d.fisheye;

import 'dart:ffi' as ffi;

import '../core/base.dart';
import '../core/mat.dart';
import '../core/size.dart';
import '../native_lib.dart' show ccalib3d;

class Fisheye {
  /// FisheyeUndistortImage transforms an image to compensate for fisheye lens distortion
  /// https://docs.opencv.org/3.4/db/d58/group__calib3d__fisheye.html#ga167df4b00a6fd55287ba829fbf9913b9
  static Mat undistortImage(
    InputArray distorted,
    InputArray K,
    InputArray D, {
    OutputArray? undistorted,
    InputArray? knew,
    (int, int) newSize = (0, 0),
  }) {
    knew ??= Mat.empty();
    undistorted ??= Mat.empty();
    cvRun(
      () => ccalib3d.cv_fisheye_undistortImage_1(
        distorted.ref,
        undistorted!.ref,
        K.ref,
        D.ref,
        knew!.ref,
        newSize.cvd.ref,
        ffi.nullptr,
      ),
    );
    return undistorted;
  }

  /// async version of [undistortImage]
  static Future<Mat> undistortImageAsync(
    InputArray distorted,
    InputArray K,
    InputArray D, {
    OutputArray? undistorted,
    InputArray? knew,
    (int, int) newSize = (0, 0),
  }) async {
    knew ??= Mat.empty();
    undistorted ??= Mat.empty();
    return cvRunAsync0<Mat>(
      (callback) => ccalib3d.cv_fisheye_undistortImage_1(
        distorted.ref,
        undistorted!.ref,
        K.ref,
        D.ref,
        knew!.ref,
        newSize.cvd.ref,
        callback,
      ),
      (c) => c.complete(undistorted),
    );
  }

  /// FisheyeUndistortPoints transforms points to compensate for fisheye lens distortion
  ///
  /// For further details, please see:
  /// https://docs.opencv.org/master/db/d58/group__calib3d__fisheye.html#gab738cdf90ceee97b2b52b0d0e7511541
  static Mat undistortPoints(
    InputArray distorted,
    InputArray K,
    InputArray D, {
    OutputArray? undistorted,
    InputArray? R,
    InputArray? P,
  }) {
    R ??= Mat.empty();
    P ??= Mat.empty();
    undistorted ??= Mat.empty();
    cvRun(
      () => ccalib3d.cv_fisheye_undistortPoints(
        distorted.ref,
        undistorted!.ref,
        K.ref,
        D.ref,
        R!.ref,
        P!.ref,
        ffi.nullptr,
      ),
    );
    return undistorted;
  }

  /// async version of [undistortPoints]
  static Future<Mat> undistortPointsAsync(
    InputArray distorted,
    InputArray K,
    InputArray D, {
    OutputArray? undistorted,
    InputArray? R,
    InputArray? P,
  }) async {
    R ??= Mat.empty();
    P ??= Mat.empty();
    undistorted ??= Mat.empty();
    return cvRunAsync0<Mat>(
      (callback) => ccalib3d.cv_fisheye_undistortPoints(
        distorted.ref,
        undistorted!.ref,
        K.ref,
        D.ref,
        R!.ref,
        P!.ref,
        callback,
      ),
      (c) => c.complete(undistorted),
    );
  }

  /// EstimateNewCameraMatrixForUndistortRectify estimates new camera matrix for undistortion or rectification.
  ///
  /// For further details, please see:
  /// https://docs.opencv.org/master/db/d58/group__calib3d__fisheye.html#ga384940fdf04c03e362e94b6eb9b673c9
  static Mat estimateNewCameraMatrixForUndistortRectify(
    InputArray K,
    InputArray D,
    (int, int) imageSize,
    InputArray R, {
    OutputArray? P,
    double balance = 0.0,
    (int, int) newSize = (0, 0),
    double fovScale = 1.0,
  }) {
    P ??= Mat.empty();
    cvRun(
      () => ccalib3d.cv_fisheye_estimateNewCameraMatrixForUndistortRectify(
        K.ref,
        D.ref,
        imageSize.cvd.ref,
        R.ref,
        P!.ref,
        balance,
        newSize.cvd.ref,
        fovScale,
        ffi.nullptr,
      ),
    );
    return P;
  }

  /// async version of [estimateNewCameraMatrixForUndistortRectify]
  static Future<Mat> estimateNewCameraMatrixForUndistortRectifyAsync(
    InputArray K,
    InputArray D,
    (int, int) imageSize,
    InputArray R, {
    OutputArray? P,
    double balance = 0.0,
    (int, int) newSize = (0, 0),
    double fovScale = 1.0,
  }) async {
    P ??= Mat.empty();
    return cvRunAsync0<Mat>(
      (callback) => ccalib3d.cv_fisheye_estimateNewCameraMatrixForUndistortRectify(
        K.ref,
        D.ref,
        imageSize.cvd.ref,
        R.ref,
        P!.ref,
        balance,
        newSize.cvd.ref,
        fovScale,
        callback,
      ),
      (c) => c.complete(P),
    );
  }
}
