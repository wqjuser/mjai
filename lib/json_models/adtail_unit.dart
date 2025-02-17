class ADetailUnit {
  bool? isEnable;
  String? adModel;
  String? adPrompt;
  String? adNegativePrompt;
  double? adConfidence;
  int? adMaskKLargest;
  double? adMaskMinRatio;
  double? adMaskMaxRatio;
  int? adDilateErode;
  int? adXOffset;
  int? adYOffset;
  String? adMaskMergeInvert;
  int? adMaskBlur;
  double? adDenoisingStrength;
  bool? adInpaintOnlyMasked;
  int? adInpaintOnlyMaskedPadding;
  bool? adUseInpaintWidthHeight;
  int? adInpaintWidth;
  int? adInpaintHeight;
  bool? adUseSteps;
  int? adSteps;
  bool? adUseCfgScale;
  double? adCfgScale;
  bool? adUseSampler;
  String? adSampler;
  bool? adUseNoiseMultiplier;
  double? adNoiseMultiplier;
  bool? adUseClipSkip;
  int? adClipSkip;
  bool? adRestoreFace;
  String? adControlnetModel;
  String? adControlnetModule;
  double? adControlnetWeight;
  double? adControlnetGuidanceStart;
  double? adControlnetGuidanceEnd;

  ADetailUnit(
      {this.isEnable = true,
      this.adModel = 'face_yolov8n.pt',
      this.adPrompt = '',
      this.adNegativePrompt = '',
      this.adConfidence = 0.3,
      this.adMaskKLargest = 0,
      this.adMaskMinRatio = 0.0,
      this.adMaskMaxRatio = 1.0,
      this.adDilateErode = 32,
      this.adXOffset = 0,
      this.adYOffset = 0,
      this.adMaskMergeInvert = 'None',
      this.adMaskBlur = 4,
      this.adDenoisingStrength = 0.4,
      this.adInpaintOnlyMasked = true,
      this.adInpaintOnlyMaskedPadding = 32,
      this.adUseInpaintWidthHeight = false,
      this.adInpaintWidth = 512,
      this.adInpaintHeight = 512,
      this.adUseSteps = false,
      this.adSteps = 20,
      this.adUseCfgScale = false,
      this.adCfgScale = 7.0,
      this.adUseSampler = false,
      this.adSampler = 'Euler a',
      this.adUseNoiseMultiplier = false,
      this.adNoiseMultiplier = 1.0,
      this.adUseClipSkip = false,
      this.adClipSkip = 1,
      this.adRestoreFace = false,
      this.adControlnetModel = '无',
      this.adControlnetModule,
      this.adControlnetWeight = 1,
      this.adControlnetGuidanceStart = 0,
      this.adControlnetGuidanceEnd = 1});

  Map<String, dynamic> toJson() {
    return {
      "is_enable": true,
      "ad_model": adModel,
      "ad_prompt": adPrompt,
      "ad_negative_prompt": adNegativePrompt,
      "ad_confidence": adConfidence,
      "ad_mask_k_largest": adMaskKLargest,
      "ad_mask_min_ratio": adMaskMinRatio,
      "ad_mask_max_ratio": adMaskMaxRatio,
      "ad_dilate_erode": adDilateErode,
      "ad_x_offset": adXOffset,
      "ad_y_offset": adYOffset,
      "ad_mask_merge_invert": adMaskMergeInvert,
      "ad_mask_blur": adMaskBlur,
      "ad_denoising_strength": adDenoisingStrength,
      "ad_inpaint_only_masked": adInpaintOnlyMasked,
      "ad_inpaint_only_masked_padding": adInpaintOnlyMaskedPadding,
      "ad_use_inpaint_width_height": adUseInpaintWidthHeight,
      "ad_inpaint_width": adInpaintWidth,
      "ad_inpaint_height": adInpaintHeight,
      "ad_use_steps": adUseSteps,
      "ad_steps": adSteps,
      "ad_use_cfg_scale": adUseCfgScale,
      "ad_cfg_scale": adCfgScale,
      "ad_use_sampler": adUseSampler,
      "ad_sampler": adSampler,
      "ad_use_noise_multiplier": adUseNoiseMultiplier,
      "ad_noise_multiplier": adNoiseMultiplier,
      "ad_use_clip_skip": adUseClipSkip,
      "ad_clip_skip": adClipSkip,
      "ad_restore_face": adRestoreFace,
      "ad_controlnet_model": adControlnetModel,
      "ad_controlnet_module": adControlnetModule,
      "ad_controlnet_weight": adControlnetWeight,
      "ad_controlnet_guidance_start": adControlnetGuidanceStart,
      "ad_controlnet_guidance_end": adControlnetGuidanceEnd
    };
  }
}
