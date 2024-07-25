import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../g/types.g.dart' as cvg;
import '../native_lib.dart' show ccore;
import 'base.dart';
import 'cv_vec.dart';
import 'mat_type.dart';
import 'point.dart';
import 'rect.dart';
import 'scalar.dart';
import 'vec.dart';

class Mat extends CvStruct<cvg.Mat> {
  Mat._(cvg.MatPtr ptr, [bool attach = true]) : super.fromPointer(ptr) {
    if (attach) {
      finalizer.attach(this, ptr.cast(), detach: this);
    }
  }

  //SECTION - Constructors

  factory Mat.fromNative(cvg.Mat mat) {
    final p = calloc<cvg.Mat>()..ref = mat;
    return Mat._(p);
  }

  /// Create a Mat from a list of data
  ///
  /// [data] should be raw pixels values with exactly same length of channels * [rows] * [cols]
  ///
  /// Mat (Size size, int type, void *data, size_t step=AUTO_STEP)
  ///
  /// https://docs.opencv.org/4.x/d3/d63/classcv_1_1Mat.html#a9fa74fb14362d87cb183453d2441948f
  factory Mat.fromList(int rows, int cols, MatType type, List<num> data) {
    final p = calloc<cvg.Mat>();
    // copy
    final xdata = switch (type.depth) {
      MatType.CV_8U => VecU8.fromList(data.cast<int>()) as Vec,
      MatType.CV_8S => VecI8.fromList(data.cast<int>()) as Vec,
      MatType.CV_16U => VecU16.fromList(data.cast<int>()) as Vec,
      MatType.CV_16S => VecI16.fromList(data.cast<int>()) as Vec,
      MatType.CV_32S => VecI32.fromList(data.cast<int>()) as Vec,
      MatType.CV_32F => VecF32.fromList(data.cast<double>()) as Vec,
      MatType.CV_64F => VecF64.fromList(data.cast<double>()) as Vec,
      MatType.CV_16F => VecF16.fromList(data.cast<double>()) as Vec,
      _ => throw UnsupportedError("Mat.fromBytes for MatType $type unsupported"),
    };
    // copy
    cvRun(() => ccore.Mat_NewFromBytes(rows, cols, type.value, xdata.asVoid(), p));
    xdata.dispose();
    return Mat._(p);
  }

  /// Create a Mat from a 2D list
  ///
  /// [data] should be a 2D list of numbers with a shape of (rows, cols).
  /// [type] specifies the Mat type.
  factory Mat.from2DList(Iterable<Iterable<num>> data, MatType type) {
    final rows = data.length;
    final cols = data.first.length;
    final flatData = <num>[];
    cvAssert(rows > 0, "The input data must not be empty.");
    cvAssert(
      cols > 0 &&
          data.every((r) {
            flatData.addAll(r);
            return r.length == cols;
          }),
      "All rows must have the same number of columns.",
    );
    return Mat.fromList(rows, cols, type, flatData);
  }

  /// Create a Mat from a 3D list
  ///
  /// [data] should be a 3D list of numbers with a shape of (rows, cols, channels).
  /// [type] specifies the Mat type.
  factory Mat.from3DList(Iterable<Iterable<Iterable<num>>> data, MatType type) {
    final rows = data.length;
    final cols = data.first.length;
    final channels = data.first.first.length;
    final flatData = <num>[];
    cvAssert(rows > 0, "The input data must not be empty.");
    cvAssert(
      cols > 0 &&
          channels > 0 &&
          data.every(
            (r) =>
                r.length == cols &&
                r.every((c) {
                  flatData.addAll(c);
                  return c.length == channels;
                }),
          ),
      "All rows must have the same number of columns.",
    );

    return Mat.fromList(rows, cols, type, flatData);
  }

  /// This method is different from [Mat.fromPtr], will construct from pointer directly
  factory Mat.fromPointer(cvg.MatPtr mat, [bool attach = true]) => Mat._(mat, attach);

  factory Mat.empty() {
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Mat_New(p));
    final mat = Mat._(p);
    return mat;
  }

  factory Mat.fromScalar(int rows, int cols, MatType type, Scalar s) {
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Mat_NewFromScalar(s.ref, rows, cols, type.value, p));
    final mat = Mat._(p);
    return mat;
  }

  factory Mat.fromVec(Vec vec, {int? rows, int? cols, MatType? type}) {
    final p = calloc<cvg.Mat>();
    switch (vec) {
      case VecPoint():
        cvRun(() => ccore.Mat_NewFromVecPoint(vec.ref, p));
      case VecPoint2f():
        cvRun(() => ccore.Mat_NewFromVecPoint2f(vec.ref, p));
      case VecPoint3f():
        cvRun(() => ccore.Mat_NewFromVecPoint3f(vec.ref, p));
      case VecPoint3i():
        cvRun(() => ccore.Mat_NewFromVecPoint3i(vec.ref, p));
      case VecU8() when rows != null && cols != null && type != null:
      case VecI8() when rows != null && cols != null && type != null:
      case VecU16() when rows != null && cols != null && type != null:
      case VecI16() when rows != null && cols != null && type != null:
      case VecI32() when rows != null && cols != null && type != null:
      case VecF32() when rows != null && cols != null && type != null:
      case VecF64() when rows != null && cols != null && type != null:
      case VecF16() when rows != null && cols != null && type != null:
        cvRun(() => ccore.Mat_NewFromBytes(rows, cols, type.value, vec.asVoid(), p));
      default:
        throw UnsupportedError("Unsupported Vec type ${vec.runtimeType}");
    }
    vec.dispose();
    return Mat._(p);
  }

  factory Mat.create({int rows = 0, int cols = 0, int r = 0, int g = 0, int b = 0, MatType? type}) {
    type = type ?? MatType.CV_8UC3;
    final scalar = Scalar(b.toDouble(), g.toDouble(), r.toDouble(), 0);
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Mat_NewFromScalar(scalar.ref, rows, cols, type!.value, p));
    final mat = Mat._(p);
    return mat;
  }

  /// Create [Mat] from another [Mat] with range
  ///
  /// Returns a reference of [Mat]
  factory Mat.fromRange(Mat mat, int rowStart, int rowEnd, {int colStart = 0, int? colEnd}) {
    final p = calloc<cvg.Mat>();
    colEnd ??= mat.cols;
    cvRun(() => ccore.Mat_FromRange(mat.ref, rowStart, rowEnd, colStart, colEnd!, p));
    return Mat._(p);
  }

  factory Mat.eye(int rows, int cols, MatType type) {
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Eye(rows, cols, type.value, p));
    final mat = Mat._(p);
    return mat;
  }

  factory Mat.zeros(int rows, int cols, MatType type) {
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Zeros(rows, cols, type.value, p));
    final mat = Mat._(p);
    return mat;
  }

  factory Mat.ones(int rows, int cols, MatType type) {
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Ones(rows, cols, type.value, p));
    final mat = Mat._(p);
    return mat;
  }

  factory Mat.randn(int rows, int cols, MatType type, {Scalar? mean, Scalar? std}) {
    mean ??= Scalar.all(0);
    std ??= Scalar.all(1);
    final mat = Mat.create(rows: rows, cols: cols, type: type);
    cvRun(() => ccore.RandN(mat.ref, mean!.ref, std!.ref));
    return mat;
  }

  factory Mat.randu(int rows, int cols, MatType type, {Scalar? low, Scalar? high}) {
    low ??= Scalar.all(0);
    high ??= Scalar.all(256);
    final mat = Mat.create(rows: rows, cols: cols, type: type);
    cvRun(() => ccore.RandU(mat.ref, low!.ref, high!.ref));
    return mat;
  }

  /// this constructor is a wrapper of cv::Mat::ptr
  factory Mat.fromPtr(
    cvg.Mat m,
    int rows,
    int cols,
    int type,
    int prows,
    int pcols,
  ) {
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Mat_FromPtr(m, rows, cols, type, prows, pcols, p));
    final mat = Mat._(p);
    return mat;
  }

  //!SECTION Constructors

  //SECTION - Properties
  MatType get type => MatType(ccore.Mat_Type(ref));

  int get flags => ccore.Mat_Flags(ref);

  int get width => cols;
  int get height => rows;
  int get cols => ccore.Mat_Cols(ref);
  int get rows => ccore.Mat_Rows(ref);
  int get channels => ccore.Mat_Channels(ref);
  int get total => ccore.Mat_Total(ref);
  bool get isEmpty => ccore.Mat_Empty(ref);
  bool get isContinus => ccore.Mat_IsContinuous(ref);
  (int, int, int) get step {
    final ms = ccore.Mat_Step(ref);
    return (ms.p[0], ms.p[1], ms.p[2]);
  }

  int get elemSize => ccore.Mat_ElemSize(ref);
  int get dims => ccore.Mat_Dims(ref);

  /// Get  a view of native data, and will be GCed when the Mat is GCed.
  Uint8List get data => dataPtr.$1.asTypedList(dataPtr.$2);

  /// Get the data pointer of the Mat
  ///
  /// DO NOT free the pointer, the native memory is managed by [Mat]
  (ffi.Pointer<ffi.Uint8> ptr, int len) get dataPtr =>
      (ccore.Mat_Data(ref).cast<ffi.Uint8>(), total * elemSize);

  /// Mat.size
  VecI32 get size => VecI32.fromPointer(ccore.Mat_Size(ref));

  /// ([rows], [cols], [channels])
  List<int> get shape => [rows, cols, channels];

  /// only for [channels] == 1
  int get countNoneZero {
    cvAssert(channels == 1, "countNoneZero only for channels == 1");
    return cvRunArena<int>((arena) {
      final p = arena<ffi.Int>();
      cvRun(() => ccore.Mat_CountNonZero(ref, p));
      return p.value;
    });
  }

  //!SECTION - Properties

  //SECTION - At Set

  /// wrapper of cv::Mat::at()
  ///
  num atNum(int i0, int i1, [int? i2]) {
    final pdata = dataPtr.$1;
    final step = this.step;
    final type = this.type;

    if (i2 == null) {
      // https://github.com/opencv/opencv/blob/71d3237a093b60a27601c20e9ee6c3e52154e8b1/modules/core/include/opencv2/core/mat.inl.hpp#L894
      final pp = pdata + i0 * step.$1;
      return switch (type.depth) {
        MatType.CV_8U => (pp.cast<ffi.Uint8>() + i1).value,
        MatType.CV_8S => (pp.cast<ffi.Int8>() + i1).value,
        MatType.CV_16U => (pp.cast<ffi.Uint16>() + i1).value,
        MatType.CV_16S => (pp.cast<ffi.Int16>() + i1).value,
        MatType.CV_32S => (pp.cast<ffi.Int>() + i1).value,
        MatType.CV_32F => (pp.cast<ffi.Float>() + i1).value,
        MatType.CV_64F => (pp.cast<ffi.Double>() + i1).value,
        MatType.CV_16F => float16((pp.cast<ffi.Uint16>() + i1).value),
        _ => throw UnsupportedError("Unsupported type: $type")
      };
    }
    // https://github.com/opencv/opencv/blob/71d3237a093b60a27601c20e9ee6c3e52154e8b1/modules/core/include/opencv2/core/mat.inl.hpp#L968
    return switch (type.depth) {
      MatType.CV_8U => ptrAt<ffi.Uint8>(i0, i1, i2).value,
      MatType.CV_8S => ptrAt<ffi.Int8>(i0, i1, i2).value,
      MatType.CV_16U => ptrAt<ffi.Uint16>(i0, i1, i2).value,
      MatType.CV_16S => ptrAt<ffi.Int16>(i0, i1, i2).value,
      MatType.CV_32S => ptrAt<ffi.Int>(i0, i1, i2).value,
      MatType.CV_32F => ptrAt<ffi.Float>(i0, i1, i2).value,
      MatType.CV_64F => ptrAt<ffi.Double>(i0, i1, i2).value,
      MatType.CV_16F => float16(ptrAt<ffi.Uint16>(i0, i1, i2).value),
      _ => throw UnsupportedError("Unsupported type: $type")
    };
  }

  /// Get pixel value via [row], [col], returns a view of native data
  ///
  /// Note: No bound check under **release** mode
  List<num> atPixel(int row, int col) {
    assert(0 <= row && row < rows, "row must be less than $rows");
    assert(0 <= col && col < cols, "col must be less than $cols");

    final p = ptrAt<ffi.Uint8>(row, col);
    switch (type.depth) {
      case MatType.CV_8U:
        return p.cast<ffi.Uint8>().asTypedList(channels);
      case MatType.CV_8S:
        return p.cast<ffi.Int8>().asTypedList(channels);
      case MatType.CV_16U:
        return p.cast<ffi.Uint16>().asTypedList(channels);
      case MatType.CV_16S:
        return p.cast<ffi.Int16>().asTypedList(channels);
      case MatType.CV_32S:
        return p.cast<ffi.Int32>().asTypedList(channels);
      case MatType.CV_32F:
        return p.cast<ffi.Float>().asTypedList(channels);
      case MatType.CV_64F:
        return p.cast<ffi.Double>().asTypedList(channels);
      // TODO: support CV_16F
      // case MatType.CV_16F:
      //   return p.cast<ffi.Uint16>().asTypedList(channels).map(float16).toList(growable: false);
      case _:
        throw UnsupportedError("Unsupported type: $type");
    }
  }

  T atVec<T>(int row, int col) {
    // Vec2b, Vec3b, Vec4b
    if (T == Vec2b) {
      final p = calloc<cvg.Vec2b>();
      cvRun(() => ccore.Mat_GetVec2b(ref, row, col, p));
      return Vec2b.fromPointer(p) as T;
    } else if (T == Vec3b) {
      final p = calloc<cvg.Vec3b>();
      cvRun(() => ccore.Mat_GetVec3b(ref, row, col, p));
      return Vec3b.fromPointer(p) as T;
    } else if (T == Vec4b) {
      final p = calloc<cvg.Vec4b>();
      cvRun(() => ccore.Mat_GetVec4b(ref, row, col, p));
      return Vec4b.fromPointer(p) as T;
    }
    // Vec2w, Vec3w, Vec4w
    else if (T == Vec2w) {
      final p = calloc<cvg.Vec2w>();
      cvRun(() => ccore.Mat_GetVec2w(ref, row, col, p));
      return Vec2w.fromPointer(p) as T;
    } else if (T == Vec3w) {
      final p = calloc<cvg.Vec3w>();
      cvRun(() => ccore.Mat_GetVec3w(ref, row, col, p));
      return Vec3w.fromPointer(p) as T;
    } else if (T == Vec4w) {
      final p = calloc<cvg.Vec4w>();
      cvRun(() => ccore.Mat_GetVec4w(ref, row, col, p));
      return Vec4w.fromPointer(p) as T;
    }
    // Vec2s, Vec3s, Vec4s
    else if (T == Vec2s) {
      final p = calloc<cvg.Vec2s>();
      cvRun(() => ccore.Mat_GetVec2s(ref, row, col, p));
      return Vec2s.fromPointer(p) as T;
    } else if (T == Vec3s) {
      final p = calloc<cvg.Vec3s>();
      cvRun(() => ccore.Mat_GetVec3s(ref, row, col, p));
      return Vec3s.fromPointer(p) as T;
    } else if (T == Vec4s) {
      final p = calloc<cvg.Vec4s>();
      cvRun(() => ccore.Mat_GetVec4s(ref, row, col, p));
      return Vec4s.fromPointer(p) as T;
    }
    // Vec2i, Vec3i, Vec4i, Vec6i, Vec8i
    else if (T == Vec2i) {
      final p = calloc<cvg.Vec2i>();
      cvRun(() => ccore.Mat_GetVec2i(ref, row, col, p));
      return Vec2i.fromPointer(p) as T;
    } else if (T == Vec3i) {
      final p = calloc<cvg.Vec3i>();
      cvRun(() => ccore.Mat_GetVec3i(ref, row, col, p));
      return Vec3i.fromPointer(p) as T;
    } else if (T == Vec4i) {
      final p = calloc<cvg.Vec4i>();
      cvRun(() => ccore.Mat_GetVec4i(ref, row, col, p));
      return Vec4i.fromPointer(p) as T;
    } else if (T == Vec6i) {
      final p = calloc<cvg.Vec6i>();
      cvRun(() => ccore.Mat_GetVec6i(ref, row, col, p));
      return Vec6i.fromPointer(p) as T;
    } else if (T == Vec8i) {
      final p = calloc<cvg.Vec8i>();
      cvRun(() => ccore.Mat_GetVec8i(ref, row, col, p));
      return Vec8i.fromPointer(p) as T;
    }
    // Vec2f, Vec3f, Vec4f, Vec6f
    else if (T == Vec2f) {
      final p = calloc<cvg.Vec2f>();
      cvRun(() => ccore.Mat_GetVec2f(ref, row, col, p));
      return Vec2f.fromPointer(p) as T;
    } else if (T == Vec3f) {
      final p = calloc<cvg.Vec3f>();
      cvRun(() => ccore.Mat_GetVec3f(ref, row, col, p));
      return Vec3f.fromPointer(p) as T;
    } else if (T == Vec4f) {
      final p = calloc<cvg.Vec4f>();
      cvRun(() => ccore.Mat_GetVec4f(ref, row, col, p));
      return Vec4f.fromPointer(p) as T;
    } else if (T == Vec6f) {
      final p = calloc<cvg.Vec6f>();
      cvRun(() => ccore.Mat_GetVec6f(ref, row, col, p));
      return Vec6f.fromPointer(p) as T;
    }
    // Vec2d, Vec3d, Vec4d, Vec6d
    else if (T == Vec2d) {
      final p = calloc<cvg.Vec2d>();
      cvRun(() => ccore.Mat_GetVec2d(ref, row, col, p));
      return Vec2d.fromPointer(p) as T;
    } else if (T == Vec3d) {
      final p = calloc<cvg.Vec3d>();
      cvRun(() => ccore.Mat_GetVec3d(ref, row, col, p));
      return Vec3d.fromPointer(p) as T;
    } else if (T == Vec4d) {
      final p = calloc<cvg.Vec4d>();
      cvRun(() => ccore.Mat_GetVec4d(ref, row, col, p));
      return Vec4d.fromPointer(p) as T;
    } else if (T == Vec6d) {
      final p = calloc<cvg.Vec6d>();
      cvRun(() => ccore.Mat_GetVec6d(ref, row, col, p));
      return Vec6d.fromPointer(p) as T;
    } else {
      throw UnsupportedError("at<$T>() for $type is not supported!");
    }
  }

  /// cv::Mat::at\<T\>(i0, i1, i2) of cv::Mat
  ///
  /// example:
  /// ```dart
  /// var m = cv.Mat.fromScalar(cv.Scalar(2, 4, 1, 0), cv.MatType.CV_32FC3);
  /// m.at<double>(0, 0); // 2.0
  /// m.at<cv.Vec3f>(0, 0); // cv.Vec3f(2, 4, 1)
  /// ```
  ///
  /// https://docs.opencv.org/4.x/d3/d63/classcv_1_1Mat.html#a7a6d7e3696b8b19b9dfac3f209118c40
  T at<T>(int i0, int i1, [int? i2]) {
    if (T == int || T == double || T == num) {
      return atNum(i0, i1, i2) as T;
    } else if (isSubtype<T, CvVec>()) {
      return atVec<T>(i0, i1);
    } else {
      throw UnsupportedError("T must be num or CvVec(e.g., Vec3b), but got $T");
    }
  }

  //!SECTION At

  //SECTION - Set
  void setVec<T extends CvVec>(int row, int col, T val) {
    switch (val) {
      // Vec2b, Vec3b, Vec4b
      case Vec2b():
        cvRun(() => ccore.Mat_SetVec2b(ref, row, col, val.ref));
      case Vec3b():
        cvRun(() => ccore.Mat_SetVec3b(ref, row, col, val.ref));
      case Vec4b():
        cvRun(() => ccore.Mat_SetVec4b(ref, row, col, val.ref));
      // Vec2w, Vec3w, Vec4w
      case Vec2w():
        cvRun(() => ccore.Mat_SetVec2w(ref, row, col, val.ref));
      case Vec3w():
        cvRun(() => ccore.Mat_SetVec3w(ref, row, col, val.ref));
      case Vec4w():
        cvRun(() => ccore.Mat_SetVec4w(ref, row, col, val.ref));
      // Vec2s, Vec3s, Vec4s
      case Vec2s():
        cvRun(() => ccore.Mat_SetVec2s(ref, row, col, val.ref));
      case Vec3s():
        cvRun(() => ccore.Mat_SetVec3s(ref, row, col, val.ref));
      case Vec4s():
        cvRun(() => ccore.Mat_SetVec4s(ref, row, col, val.ref));
      // Vec2i, Vec3i, Vec4i, Vec6i, Vec8i
      case Vec2i():
        cvRun(() => ccore.Mat_SetVec2i(ref, row, col, val.ref));
      case Vec3i():
        cvRun(() => ccore.Mat_SetVec3i(ref, row, col, val.ref));
      case Vec4i():
        cvRun(() => ccore.Mat_SetVec4i(ref, row, col, val.ref));
      case Vec6i():
        cvRun(() => ccore.Mat_SetVec6i(ref, row, col, val.ref));
      case Vec8i():
        cvRun(() => ccore.Mat_SetVec8i(ref, row, col, val.ref));
      // Vec2f, Vec3f, Vec4f, Vec6f
      case Vec2f():
        cvRun(() => ccore.Mat_SetVec2f(ref, row, col, val.ref));
      case Vec3f():
        cvRun(() => ccore.Mat_SetVec3f(ref, row, col, val.ref));
      case Vec4f():
        cvRun(() => ccore.Mat_SetVec4f(ref, row, col, val.ref));
      case Vec6f():
        cvRun(() => ccore.Mat_SetVec6f(ref, row, col, val.ref));
      // Vec2d, Vec3d, Vec4d, Vec6d
      case Vec2d():
        cvRun(() => ccore.Mat_SetVec2d(ref, row, col, val.ref));
      case Vec3d():
        cvRun(() => ccore.Mat_SetVec3d(ref, row, col, val.ref));
      case Vec4d():
        cvRun(() => ccore.Mat_SetVec4d(ref, row, col, val.ref));
      case Vec6d():
        cvRun(() => ccore.Mat_SetVec6d(ref, row, col, val.ref));
      default:
        throw UnsupportedError("setVec<$T>() for $type is not supported!");
    }
  }

  void setNum(int i0, int i1, num val, [int? i2]) {
    final pdata = dataPtr.$1;
    final step = this.step;
    final type = this.type;

    final pp = pdata + i0 * step.$1;
    switch (type.depth) {
      case MatType.CV_8U:
        i2 == null
            ? (pp.cast<ffi.Uint8>() + i1).value = val.toInt()
            : ptrAt<ffi.Uint8>(i0, i1, i2).value = val.toInt();
      case MatType.CV_8S:
        i2 == null
            ? (pp.cast<ffi.Int8>() + i1).value = val.toInt()
            : ptrAt<ffi.Int8>(i0, i1, i2).value = val.toInt();
      case MatType.CV_16U:
        i2 == null
            ? (pp.cast<ffi.Uint16>() + i1).value = val.toInt()
            : ptrAt<ffi.Uint16>(i0, i1, i2).value = val.toInt();
      case MatType.CV_16S:
        i2 == null
            ? (pp.cast<ffi.Int16>() + i1).value = val.toInt()
            : ptrAt<ffi.Int16>(i0, i1, i2).value = val.toInt();
      case MatType.CV_32S:
        i2 == null
            ? (pp.cast<ffi.Int>() + i1).value = val.toInt()
            : ptrAt<ffi.Int>(i0, i1, i2).value = val.toInt();
      case MatType.CV_32F:
        i2 == null
            ? (pp.cast<ffi.Float>() + i1).value = val.toDouble()
            : ptrAt<ffi.Float>(i0, i1, i2).value = val.toDouble();
      case MatType.CV_64F:
        i2 == null
            ? (pp.cast<ffi.Double>() + i1).value = val.toDouble()
            : ptrAt<ffi.Double>(i0, i1, i2).value = val.toDouble();
      case MatType.CV_16F:
        i2 == null
            ? (pp.cast<ffi.Uint16>() + i1).value = val.toDouble().fp16
            : ptrAt<ffi.Uint16>(i0, i1, i2).value = val.toDouble().fp16;
      case _:
        throw UnsupportedError("Unsupported type: $type");
    }
  }

  /// equivalent to Mat::at\<T\>(i0, i1, i2) = val;
  /// where T might be int, double, or cv::Vec<> like cv::Vec3b
  ///
  /// example
  /// ```dart
  /// var m = cv.Mat.fromScalar(cv.Scalar(2, 4, 1, 0), cv.MatType.CV_32FC3);
  /// m.at<cv.Vec3f>(0, 0); // cv.Vec3f(2, 4, 1)
  /// m.set<cv.Vec3f>(0, 0, cv.Vec3f(9, 9, 9));
  /// m.at<cv.Vec3f>(0, 0); // cv.Vec3f(9, 9, 9)
  /// ```
  void set<T>(int i0, int i1, T val, [int? i2]) {
    switch (val) {
      case num():
        setNum(i0, i1, val, i2);
      case CvVec():
        setVec<CvVec>(i0, i1, val);
      default:
        throw UnsupportedError("Unsupported type ${val.runtimeType}");
    }
  }

  // https://github.com/dart-lang/sdk/issues/43390#issuecomment-690993957
  bool isSubtype<S, T>() => <S>[] is List<T>;

  //!SECTION Set

  /// equivalent to Mat::ptr\<T\>(i0, i1, i2)
  ///
  /// **DANGEROUS**
  ///
  /// returns a pointer to operate Mat directly and effectively, use with caution!
  ///
  /// Example:
  /// ```dart
  /// final mat = cv.Mat.ones(3, 3, cv.MatType.CV_8UC1);
  /// mat.set<int>(0, 0, 99);
  ///
  /// final ptr = mat.ptrAt<cv.U8>(0, 0);
  /// print(ptr[0]); // 99
  ///
  /// ptr[0] = 21;
  /// // Mat::ptr(i, j)
  /// print(mat.at<int>(0, 0)); // 21
  /// print(ptr[0]); // 21
  ///
  /// final ptr1 = mat.ptrAt<cv.U8>(0);
  /// print(ptr1[0]); // 21
  /// print(List.generate(mat.cols, (i)=>ptr1[i]); // [21, 1, 1]
  /// ```
  ///
  /// https://docs.opencv.org/4.x/d3/d63/classcv_1_1Mat.html#a8b2912f6a6f5d55a3c9a7aae9134d862
  ffi.Pointer<T> ptrAt<T extends ffi.NativeType>(int i0, [int? i1, int? i2]) {
    final pdata = dataPtr.$1;
    final step = this.step;

    ffi.Pointer<ffi.Uint8> pp = pdata + i0 * step.$1;
    if (i1 != null) {
      pp += i1 * step.$2;
      if (i2 != null) pp += i2 * step.$3;
    }
    return pp.cast<T>();
  }

  List<num> _ptrAsTypedList(ffi.Pointer<ffi.Uint8> p, int count, int depth) {
    switch (depth) {
      case MatType.CV_8U:
        return p.cast<ffi.Uint8>().asTypedList(count);
      case MatType.CV_8S:
        return p.cast<ffi.Int8>().asTypedList(count);
      case MatType.CV_16U:
        return p.cast<ffi.Uint16>().asTypedList(count);
      case MatType.CV_16S:
        return p.cast<ffi.Int16>().asTypedList(count);
      case MatType.CV_32S:
        return p.cast<ffi.Int32>().asTypedList(count);
      case MatType.CV_32F:
        return p.cast<ffi.Float>().asTypedList(count);
      case MatType.CV_64F:
        return p.cast<ffi.Double>().asTypedList(count);
      // TODO: for now, dart has no `Float16` type, so this will create a new list, which
      // is different from the above
      // case MatType.CV_16F:
      //   callback(pp.cast<ffi.Uint16>().asTypedList(count).map(float16).toList(growable: false));
      case _:
        throw UnsupportedError("Unsupported type: $type");
    }
  }

  /// Iterate over all pixels in the Mat.
  ///
  /// [callback] is called for each pixel in the Mat, the parameter `pixel`
  /// of [callback] is a view of the pixel at every (row, col), which means
  /// it can be modified and will be reflected in the Mat.
  ///
  /// Example:
  /// ```dart
  /// final mat = cv.Mat.ones(3, 3, cv.MatType.CV_8UC3);
  /// mat.iterPixel((row, col, pixel) {
  ///   print(pixel); // [1, 1, 1]
  ///   pixel[0] = 2;
  /// });
  /// print(mat.atPixel(0, 0)); // [2, 1, 1]
  /// ```
  void iterPixel(void Function(int row, int col, List<num> pixel) callback) {
    // cache necessary props, they will be only get once
    final depth = type.depth;
    final pdata = dataPtr.$1;
    final step = this.step;
    final channels = this.channels;
    final rows = this.rows;
    final cols = this.cols;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final pp = pdata + row * step.$1 + col * step.$2;
        callback(row, col, _ptrAsTypedList(pp, channels, depth));
      }
    }
  }

  /// Iterate over all rows in the Mat.
  ///
  /// Similar to [iterPixel], the parameter `values` of [callback] is a view of
  /// the row at every `row`, which means it can be modified and the original values
  /// in the Mat will be changed too.
  void iterRow(void Function(int row, List<num> values) callback) {
    // cache necessary props, they will be only get once
    final depth = type.depth;
    final pdata = dataPtr.$1;
    final step = this.step;
    final channels = this.channels;
    final rows = this.rows;
    final cols = this.cols;

    for (int row = 0; row < rows; row++) {
      final pp = pdata + row * step.$1;
      callback(row, _ptrAsTypedList(pp, channels * cols, depth));
    }
  }

  // TODO: for now, dart do not support operator overloading
  // https://github.com/dart-lang/language/issues/2456
  // waiting for it's implementation and add more methods
  // operator +(int v) {
  //   ccore.Mat_AddUChar(ref, v);
  // }

  //SECTION - Add

  /// add
  Mat add<T>(T val, {bool inplace = false}) {
    if (T == Mat) {
      return addMat(val as Mat, inplace: inplace);
    } else if (T == double) {
      switch (type.depth) {
        case MatType.CV_32F:
          return addF32(val as double, inplace: inplace);
        case MatType.CV_64F:
          return addF64(val as double, inplace: inplace);
        default:
          throw UnsupportedError("add float to $type is not supported!");
      }
    } else if (T == int) {
      switch (type.depth) {
        case MatType.CV_8U:
          return addU8(val as int, inplace: inplace);
        case MatType.CV_8S:
          return addI8(val as int, inplace: inplace);
        case MatType.CV_32S:
          return addI32(val as int, inplace: inplace);
        default:
          throw UnimplementedError();
      }
    } else {
      throw UnsupportedError("Type $T is not supported");
    }
  }

  Mat addMat(Mat other, {bool inplace = false}) {
    cvAssert(other.type == type, "$type != ${other.type}");
    if (inplace) {
      cvRun(() => ccore.Mat_Add(ref, other.ref, ref));
      return this;
    } else {
      final dst = Mat.empty();
      cvRun(() => ccore.Mat_Add(ref, other.ref, dst.ref));
      return dst;
    }
  }

  Mat addU8(int val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_8U && val >= CV_U8_MIN && val <= CV_U8_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_AddUChar(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_AddUChar(dst.ref, val));
      return dst;
    }
  }

  Mat addI8(int val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_8S && val >= CV_I8_MIN && val <= CV_I8_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_AddSChar(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_AddSChar(dst.ref, val));
      return dst;
    }
  }

  Mat addI32(int val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_32S && val >= CV_I32_MIN && val <= CV_I32_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_AddI32(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_AddI32(dst.ref, val));
      return dst;
    }
  }

  Mat addF32(double val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_32F && val <= CV_F32_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_AddFloat(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_AddFloat(dst.ref, val));
      return dst;
    }
  }

  Mat addF64(double val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_64F && val <= CV_F64_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_AddF64(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_AddF64(dst.ref, val));
      return dst;
    }
  }

  //!SECTION ADD

  //SECTION - Subtract

  /// subtract
  Mat subtract<T>(T val, {bool inplace = false}) {
    if (T == Mat) {
      return subtractMat(val as Mat, inplace: inplace);
    } else if (T == double) {
      switch (type.depth) {
        case MatType.CV_32F:
          return subtractF32(val as double, inplace: inplace);
        case MatType.CV_64F:
          return subtractF64(val as double, inplace: inplace);
        default:
          throw UnsupportedError("subtract float to $type is not supported!");
      }
    } else if (T == int) {
      switch (type.depth) {
        case MatType.CV_8U:
          return subtractU8(val as int, inplace: inplace);
        case MatType.CV_8S:
          return subtractI8(val as int, inplace: inplace);
        case MatType.CV_32S:
          return subtractI32(val as int, inplace: inplace);
        default:
          throw UnimplementedError();
      }
    } else {
      throw UnsupportedError("Type $T is not supported");
    }
  }

  Mat subtractMat(Mat other, {bool inplace = false}) {
    cvAssert(other.type == type, "$type != ${other.type}");
    if (inplace) {
      cvRun(() => ccore.Mat_Subtract(ref, other.ref, ref));
      return this;
    } else {
      final dst = Mat.empty();
      cvRun(() => ccore.Mat_Subtract(ref, other.ref, dst.ref));
      return dst;
    }
  }

  Mat subtractU8(int val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_8U && val >= CV_U8_MIN && val <= CV_U8_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_SubtractUChar(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_SubtractUChar(dst.ref, val));
      return dst;
    }
  }

  Mat subtractI8(int val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_8S && val >= CV_I8_MIN && val <= CV_I8_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_SubtractSChar(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_SubtractSChar(dst.ref, val));
      return dst;
    }
  }

  Mat subtractI32(int val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_32S && val >= CV_I32_MIN && val <= CV_I32_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_SubtractI32(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_SubtractI32(dst.ref, val));
      return dst;
    }
  }

  Mat subtractF32(double val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_32F && val <= CV_F32_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_SubtractFloat(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_SubtractFloat(dst.ref, val));
      return dst;
    }
  }

  Mat subtractF64(double val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_64F && val <= CV_F64_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_SubtractF64(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_SubtractF64(dst.ref, val));
      return dst;
    }
  }

  //!SECTION - Subtract

  //SECTION - multiply
  /// multiply
  Mat multiply<T>(T val, {bool inplace = false}) {
    if (T == Mat) {
      return multiplyMat(val as Mat, inplace: inplace);
    } else if (T == double) {
      switch (type.depth) {
        case MatType.CV_32F:
          return multiplyF32(val as double, inplace: inplace);
        case MatType.CV_64F:
          return multiplyF64(val as double, inplace: inplace);
        default:
          throw UnsupportedError("multiply float to $type is not supported!");
      }
    } else if (T == int) {
      switch (type.depth) {
        case MatType.CV_8U:
          return multiplyU8(val as int, inplace: inplace);
        case MatType.CV_8S:
          return multiplyI8(val as int, inplace: inplace);
        case MatType.CV_32S:
          return multiplyI32(val as int, inplace: inplace);
        default:
          throw UnimplementedError();
      }
    } else {
      throw UnsupportedError("Type $T is not supported");
    }
  }

  Mat multiplyMat(Mat other, {bool inplace = false}) {
    cvAssert(other.type == type, "$type != ${other.type}");
    if (inplace) {
      cvRun(() => ccore.Mat_Multiply(ref, other.ref, ref));
      return this;
    } else {
      final dst = Mat.empty();
      cvRun(() => ccore.Mat_Multiply(ref, other.ref, dst.ref));
      return dst;
    }
  }

  Mat multiplyU8(int val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_8U && val >= CV_U8_MIN && val <= CV_U8_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_MultiplyUChar(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_MultiplyUChar(dst.ref, val));
      return dst;
    }
  }

  Mat multiplyI8(int val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_8S && val >= CV_I8_MIN && val <= CV_I8_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_MultiplySChar(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_MultiplySChar(dst.ref, val));
      return dst;
    }
  }

  Mat multiplyI32(int val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_32S && val >= CV_I32_MIN && val <= CV_I32_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_MultiplyI32(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_MultiplyI32(dst.ref, val));
      return dst;
    }
  }

  Mat multiplyF32(double val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_32F && val <= CV_F32_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_MultiplyFloat(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_MultiplyFloat(dst.ref, val));
      return dst;
    }
  }

  Mat multiplyF64(double val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_64F && val <= CV_F64_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_MultiplyF64(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_MultiplyF64(dst.ref, val));
      return dst;
    }
  }

  //!SECTION - multiply

  //SECTION - divide
  /// divide
  Mat divide<T>(T val, {bool inplace = false}) {
    if (T == Mat) {
      return divideMat(val as Mat, inplace: inplace);
    } else if (T == double) {
      switch (type.depth) {
        case MatType.CV_32F:
          return divideF32(val as double, inplace: inplace);
        case MatType.CV_64F:
          return divideF64(val as double, inplace: inplace);
        default:
          throw UnsupportedError("divide float to $type is not supported!");
      }
    } else if (T == int) {
      switch (type.depth) {
        case MatType.CV_8U:
          return divideU8(val as int, inplace: inplace);
        case MatType.CV_8S:
          return divideI8(val as int, inplace: inplace);
        case MatType.CV_32S:
          return divideI32(val as int, inplace: inplace);
        default:
          throw UnimplementedError();
      }
    } else {
      throw UnsupportedError("Type $T is not supported");
    }
  }

  Mat divideMat(Mat other, {bool inplace = false}) {
    cvAssert(other.type == type, "$type != ${other.type}");
    if (inplace) {
      cvRun(() => ccore.Mat_Divide(ref, other.ref, ref));
      return this;
    } else {
      final dst = Mat.empty();
      cvRun(() => ccore.Mat_Divide(ref, other.ref, dst.ref));
      return dst;
    }
  }

  Mat divideU8(int val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_8U && val >= CV_U8_MIN && val <= CV_U8_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_DivideUChar(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_DivideUChar(dst.ref, val));
      return dst;
    }
  }

  Mat divideI8(int val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_8S && val >= CV_I8_MIN && val <= CV_I8_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_DivideSChar(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_DivideSChar(dst.ref, val));
      return dst;
    }
  }

  Mat divideI32(int val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_32S && val >= CV_I32_MIN && val <= CV_I32_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_DivideI32(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_DivideI32(dst.ref, val));
      return dst;
    }
  }

  Mat divideF32(double val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_32F && val <= CV_F32_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_DivideFloat(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_DivideFloat(dst.ref, val));
      return dst;
    }
  }

  Mat divideF64(double val, {bool inplace = false}) {
    cvAssert(type.depth == MatType.CV_64F && val <= CV_F64_MAX);
    if (inplace) {
      cvRun(() => ccore.Mat_DivideF64(ref, val));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Mat_DivideF64(dst.ref, val));
      return dst;
    }
  }
  //!SECTION - divide

  Mat transpose({bool inplace = false}) {
    final dst = inplace ? this : Mat.empty();
    cvRun(() => ccore.Mat_Transpose(ref, dst.ref));
    return dst;
  }

  Mat clone() {
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Mat_Clone(ref, p));
    final dst = Mat._(p);
    return dst;
  }

  void copyTo(Mat dst, {Mat? mask}) => mask == null
      ? cvRun(() => ccore.Mat_CopyTo(ref, dst.ref))
      : cvRun(() => ccore.Mat_CopyToWithMask(ref, dst.ref, mask.ref));

  @Deprecated("use copyTo instead")
  void copyToWithMask(Mat dst, Mat mask) {
    cvRun(() => ccore.Mat_CopyToWithMask(ref, dst.ref, mask.ref));
  }

  Mat convertTo(MatType type, {double alpha = 1, double beta = 0}) {
    final dst = Mat.empty();
    cvRun(() => ccore.Mat_ConvertToWithParams(ref, dst.ref, type.value, alpha, beta));
    return dst;
  }

  Mat region(Rect rect) {
    cvAssert(rect.x + rect.width <= width && rect.y + rect.height <= height);
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Mat_Region(ref, rect.ref, p));
    final dst = Mat._(p);
    return dst;
  }

  Mat reshape(int cn, int rows) {
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Mat_Reshape(ref, cn, rows, p));
    final dst = Mat._(p);
    return dst;
  }

  Mat rotate(int rotationCode, {bool inplace = false}) {
    if (inplace) {
      cvRun(() => ccore.Rotate(ref, ref, rotationCode));
      return this;
    } else {
      final dst = clone();
      cvRun(() => ccore.Rotate(ref, dst.ref, rotationCode));
      return dst;
    }
  }

  Mat rowRange(int start, int end) {
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Mat_rowRange(ref, start, end, p));
    final dst = Mat._(p);
    return dst;
  }

  Mat colRange(int start, int end) {
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Mat_colRange(ref, start, end, p));
    final dst = Mat._(p);
    return dst;
  }

  @Deprecated("Use convertTo instead")
  Mat convertToFp16() {
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Mat_ConvertFp16(ref, p));
    final dst = Mat._(p);
    return dst;
  }

  Scalar mean({Mat? mask}) {
    return cvRunArena<Scalar>((arena) {
      final s = calloc<cvg.Scalar>();
      if (mask == null) {
        cvRun(() => ccore.Mat_Mean(ref, s));
      } else {
        cvRun(() => ccore.Mat_MeanWithMask(ref, mask.ref, s));
      }
      return Scalar.fromPointer(s);
    });
  }

  /// Calculates standard deviation, per channel.
  /// [Scalar] order is same as [Mat], i.e., BGR -> BGR
  Scalar stdDev() {
    return cvRunArena<Scalar>((arena) {
      final mean = calloc<cvg.Scalar>();
      final sd = calloc<cvg.Scalar>();
      cvRun(() => ccore.Mat_MeanStdDev(ref, mean, sd));
      return Scalar.fromPointer(sd);
    });
  }

  /// Similar to [stdDev]
  Scalar variance() => stdDev().pow(2);

  /// Calculates a square root of array elements.
  Mat sqrt() {
    cvAssert(type.depth == MatType.CV_32F || type.depth == MatType.CV_64F);
    final p = calloc<cvg.Mat>();
    cvRun(() => ccore.Mat_Sqrt(ref, p));
    final dst = Mat._(p);
    return dst;
  }

  /// Sum calculates the per-channel pixel sum of an image.
  Scalar sum() {
    return cvRunArena<Scalar>((arena) {
      final s = calloc<cvg.Scalar>();
      cvRun(() => ccore.Mat_Sum(ref, s));
      return Scalar.fromPointer(s);
    });
  }

  /// PatchNaNs converts NaN's to zeros.
  void patchNaNs({double val = 0}) => cvRun(() => ccore.Mat_PatchNaNs(ref, val));

  Mat setTo(Scalar s) {
    cvRun(() => ccore.Mat_SetTo(ref, s.ref));
    return this;
  }

  /// This Method converts single-channel Mat to 2D List
  List<List<num>> toList() => List.generate(rows, (row) => List.generate(cols, (col) => atNum(row, col)));

  /// Returns a 3D list of the mat, only for multi-channel mats.
  /// The list is ordered as [row][col][channels].
  ///
  /// [T]: The type of the elements in the mat.
  ///
  /// Example:
  /// ```dart
  /// final mat = Mat.fromBytes(width: 3, height: 3, type: MatType.CV_8UC3, bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8]);
  /// final list = mat.toList3D<Vec3b>();
  /// print(list); // [[[0, 1, 2], [3, 4, 5], [6, 7, 8]]]
  /// ```
  List<List<List<num>>> toList3D() {
    cvAssert(channels >= 2, "toList3D() only for channels >= 2, but this.channels=$channels");
    return List.generate(
      rows,
      (row) => List.generate(cols, (col) => atPixel(row, col)),
    );
  }

  String toFmtString({
    int fmtType = FMT_NUMPY,
    int f16Precision = 4,
    int f32Precision = 8,
    int f64Precision = 16,
    bool multiLine = true,
  }) {
    final p = calloc<ffi.Pointer<ffi.Char>>();
    cvRun(() => ccore.Mat_toString(ref, fmtType, f16Precision, f32Precision, f64Precision, multiLine, p));
    final rval = p.value.toDartString();
    calloc.free(p);
    return rval;
  }

  @override
  String toString() => toFmtString();

  static final finalizer = OcvFinalizer<cvg.MatPtr>(ccore.addresses.Mat_Close);

  @Deprecated("NOT recommended, call [dispose] instead")
  void release() => cvRun(() => ccore.Mat_Release(ptr));

  void dispose() {
    finalizer.detach(this);
    ccore.Mat_Close(ptr);
  }

  @override
  cvg.Mat get ref => ptr.ref;

  static const int FMT_DEFAULT = 0;
  static const int FMT_MATLAB = 1;
  static const int FMT_CSV = 2;
  static const int FMT_PYTHON = 3;
  static const int FMT_NUMPY = 4;
  static const int FMT_C = 5;
}

typedef OutputArray = Mat;
typedef InputArray = OutputArray;
typedef InputOutputArray = Mat;

class VecMat extends Vec<cvg.VecMat, Mat> {
  VecMat.fromPointer(super.ptr, [bool attach = true]) : super.fromPointer() {
    if (attach) {
      Vec.finalizer.attach(this, ptr.cast<ffi.Void>(), detach: this);
      Vec.finalizer.attach(this, ptr.ref.ptr.cast<ffi.Void>(), detach: this);
    }
  }

  factory VecMat.fromList(List<Mat> mats) => VecMat.generate(mats.length, (i) => mats[i], dispose: false);

  factory VecMat.generate(int length, Mat Function(int i) generator, {bool dispose = true}) {
    final pp = calloc<cvg.VecMat>()..ref.length = length;
    pp.ref.ptr = calloc<cvg.Mat>(length);
    for (var i = 0; i < length; i++) {
      final v = generator(i);
      pp.ref.ptr[i] = v.ref;
      if (dispose) v.dispose();
    }
    return VecMat.fromPointer(pp);
  }

  @override
  VecMat clone() => VecMat.generate(length, (idx) => this[idx], dispose: false);

  @override
  int get length => ref.length;

  @override
  Iterator<Mat> get iterator => VecMatIterator(ref);

  @override
  cvg.VecMat get ref => ptr.ref;

  @override
  void dispose() {
    Vec.finalizer.detach(this);
    calloc.free(ptr.ref.ptr);
    calloc.free(ptr);
  }

  @override
  ffi.Pointer<ffi.Void> asVoid() => ref.ptr.cast<ffi.Void>();

  @override
  void reattach({ffi.Pointer<cvg.VecMat>? newPtr}) {
    super.reattach(newPtr: newPtr);
    Vec.finalizer.attach(this, ref.ptr.cast<ffi.Void>(), detach: this);
  }

  @override
  void operator []=(int idx, Mat value) => throw UnsupportedError("VecMat is read-only");
}

class VecMatIterator extends VecIterator<Mat> {
  VecMatIterator(this.ref);
  cvg.VecMat ref;

  @override
  int get length => ref.length;

  @override
  Mat operator [](int idx) => Mat.fromPointer(ref.ptr + idx, false);
}

extension ListMatExtension on List<Mat> {
  VecMat get cvd => VecMat.fromList(this);
}

// Completers for async
void matCompleter(Completer<Mat> completer, VoidPtr p) =>
    completer.complete(Mat.fromPointer(p.cast<cvg.Mat>()));
void matCompleter2(Completer<(Mat, Mat)> completer, VoidPtr p, VoidPtr p1) =>
    completer.complete((Mat.fromPointer(p.cast<cvg.Mat>()), Mat.fromPointer(p1.cast<cvg.Mat>())));
void matCompleter3(Completer<(Mat, Mat, Mat)> completer, VoidPtr p, VoidPtr p1, VoidPtr p2) =>
    completer.complete(
      (
        Mat.fromPointer(p.cast<cvg.Mat>()),
        Mat.fromPointer(p1.cast<cvg.Mat>()),
        Mat.fromPointer(p2.cast<cvg.Mat>())
      ),
    );
