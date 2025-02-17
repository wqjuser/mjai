import 'dart:ui' as ui;

class ControlNetUnit {
  ui.Image? inputImage;
  ui.Image? mask;
  String module;
  String model;
  double weight;
  int resizeMode;
  String controlType;
  bool isEnable;
  bool lowvram;
  int processorRes;
  double thresholdA;
  double thresholdB;
  double guidance;
  double guidanceStart;
  double guidanceEnd;
  int controlMode;
  bool pixelPerfect;

  ControlNetUnit({
    this.inputImage,
    this.mask,
    this.module = "无",
    this.model = "无",
    this.weight = 1.0,
    this.resizeMode = 1,
    this.controlType = 'All',
    this.isEnable = false,
    this.lowvram = false,
    this.processorRes = 512,
    this.thresholdA = 64,
    this.thresholdB = 64,
    this.guidance = 1.0,
    this.guidanceStart = 0.0,
    this.guidanceEnd = 1.0,
    this.controlMode = 0,
    this.pixelPerfect = true,
  });

  Map<String, dynamic> toJson() {
    return {
      "input_image": inputImage != null ? inputImage! : "",
      "mask": mask,
      "module": module,
      "model": model,
      "weight": weight,
      "resize_mode": resizeMode,
      "lowvram": lowvram,
      "processor_res": processorRes,
      "threshold_a": thresholdA,
      "threshold_b": thresholdB,
      "guidance": guidance,
      "guidance_start": guidanceStart,
      "guidance_end": guidanceEnd,
      "control_mode": controlMode,
      "pixel_perfect": pixelPerfect,
      "is_enable": isEnable
    };
  }
}