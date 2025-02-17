Map<String, dynamic> fluxI2I = {
  "8": {
    "inputs": {
      "samples": ["13", 0],
      "vae": ["10", 0]
    },
    "class_type": "VAEDecode",
    "_meta": {"title": "VAE解码"}
  },
  "10": {
    "inputs": {"vae_name": "ae.safetensors"},
    "class_type": "VAELoader",
    "_meta": {"title": "VAE加载器"}
  },
  "11": {
    "inputs": {"clip_name1": "fluxTextencoderT5XxlFp8_v10.safetensors", "clip_name2": "clip_l.safetensors", "type": "flux", "device": "default"},
    "class_type": "DualCLIPLoader",
    "_meta": {"title": "双CLIP加载器"}
  },
  "12": {
    "inputs": {"unet_name": "flux1-dev-fp8-kijai.safetensors", "weight_dtype": "fp8_e4m3fn"},
    "class_type": "UNETLoader",
    "_meta": {"title": "UNET加载器"}
  },
  "13": {
    "inputs": {
      "noise": ["25", 0],
      "guider": ["22", 0],
      "sampler": ["16", 0],
      "sigmas": ["17", 0],
      "latent_image": ["59", 0]
    },
    "class_type": "SamplerCustomAdvanced",
    "_meta": {"title": "自定义采样器(高级)"}
  },
  "16": {
    "inputs": {"sampler_name": "euler"},
    "class_type": "KSamplerSelect",
    "_meta": {"title": "K采样器选择"}
  },
  "17": {
    "inputs": {
      "scheduler": "simple",
      "steps": 20,
      "denoise": 0.8,
      "model": ["12", 0]
    },
    "class_type": "BasicScheduler",
    "_meta": {"title": "基础调度器"}
  },
  "22": {
    "inputs": {
      "model": ["12", 0],
      "conditioning": ["39", 0]
    },
    "class_type": "BasicGuider",
    "_meta": {"title": "基础引导"}
  },
  "25": {
    "inputs": {"noise_seed": 619703667972720},
    "class_type": "RandomNoise",
    "_meta": {"title": "随机噪波"}
  },
  "39": {
    "inputs": {
      "text": ["57", 2],
      "clip": ["11", 0]
    },
    "class_type": "CLIPTextEncode",
    "_meta": {"title": "CLIP文本编码器"}
  },
  "43": {
    "inputs": {
      "pixels": ["49", 0],
      "vae": ["10", 0]
    },
    "class_type": "VAEEncode",
    "_meta": {"title": "VAE编码"}
  },
  "44": {
    "inputs": {"image": "微信图片_20241225170720.jpg", "upload": "image"},
    "class_type": "LoadImage",
    "_meta": {"title": "加载图像"}
  },
  "49": {
    "inputs": {
      "width": 1280,
      "height": 1280,
      "interpolation": "nearest",
      "method": "keep proportion",
      "condition": "always",
      "multiple_of": 0,
      "image": ["44", 0]
    },
    "class_type": "ImageResize+",
    "_meta": {"title": "图像缩放"}
  },
  "57": {
    "inputs": {
      "text_input": "",
      "task": "more_detailed_caption",
      "fill_mask": true,
      "keep_model_loaded": false,
      "max_new_tokens": 1024,
      "num_beams": 3,
      "do_sample": true,
      "output_mask_select": "",
      "seed": 693875878214897,
      "image": ["44", 0],
      "florence2_model": ["58", 0]
    },
    "class_type": "Florence2Run",
    "_meta": {"title": "Florence2 执行"}
  },
  "58": {
    "inputs": {"model": "CogFlorence-2.2-Large", "precision": "fp16", "attention": "sdpa"},
    "class_type": "Florence2ModelLoader",
    "_meta": {"title": "Florence2 模型加载器"}
  },
  "59": {
    "inputs": {
      "batch_size": 1,
      "latent": ["43", 0]
    },
    "class_type": "CR Latent Batch Size",
    "_meta": {"title": "Latent批次大小"}
  },
  "64": {
    "inputs": {
      "output_path": "[time(%Y-%m-%d)]",
      "filename_prefix": "ComfyUI",
      "filename_delimiter": "_",
      "filename_number_padding": 4,
      "filename_number_start": "false",
      "extension": "png",
      "dpi": 300,
      "quality": 100,
      "optimize_image": "true",
      "lossless_webp": "false",
      "overwrite_mode": "false",
      "show_history": "false",
      "show_history_by_prefix": "true",
      "embed_workflow": "true",
      "show_previews": "true",
      "images": ["8", 0]
    },
    "class_type": "Image Save",
    "_meta": {"title": "图像保存"}
  }
};
