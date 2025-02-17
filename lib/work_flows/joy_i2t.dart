Map<String, dynamic> joyI2t = {
  "1": {
    "inputs": {"image": "Snipaste_2018-08-24_11-38-46.jpg", "upload": "image"},
    "class_type": "LoadImage",
    "_meta": {"title": "加载图像"}
  },
  "16": {
    "inputs": {"model": "unsloth/Meta-Llama-3.1-8B-Instruct-bnb-4bit"},
    "class_type": "Joy_caption_two_load",
    "_meta": {"title": "加载JoyCaptionTwo"}
  },
  "17": {
    "inputs": {
      "caption_type": "MidJourney",
      "caption_length": "long",
      "low_vram": false,
      "joy_two_pipeline": ["16", 0],
      "image": ["1", 0]
    },
    "class_type": "Joy_caption_two",
    "_meta": {"title": "JoyCaptionTwo"}
  },
  "18": {
    "inputs": {
      "text": "",
      "anything": ["17", 0]
    },
    "class_type": "easy showAnything",
    "_meta": {"title": "展示任何"}
  },
  "19": {
    "inputs": {
      "text": ["18", 0],
      "path": "./ComfyUI/output/[time(%Y-%m-%d)]",
      "filename_prefix": "ComfyUI",
      "filename_delimiter": "_",
      "filename_number_padding": 0,
      "file_extension": ".txt",
      "encoding": "utf-8",
      "filename_suffix": ""
    },
    "class_type": "Save Text File",
    "_meta": {"title": "保存文本"}
  }
};
