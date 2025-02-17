Map<String, dynamic> promptsStyles = {
  "None": "",
  "default_negative_prompts": "Paintings, sketches, negative_hand-neg, (worst quality:2), (low quality:2), (normal quality:2), (deformed iris, "
      "deformed pupils, bad eyes, semi-realistic:1.4), (bad-image-v2-39000, bad_prompt_version2, bad-hands-5, EasyNegative, "
      "ng_deepnegative_v1_75t, bad-artist-anime:0.7), (worst quality, low quality:1.3), (blurry:1.2), "
      "(greyscale, monochrome:1.1), nose, cropped, text, jpeg artifacts, signature, watermark, username,"
      " blurry, artist name, trademark, watermark, title, (tan, muscular, child, infant, toddlers, chibi, sd character:1.1), "
      "multiple view, Reference sheet, long neck, lowers, normal quality, ((monochrome)), ((grayscales)), skin spots, acnes, "
      "skin blemishes, age spot, glans, (6 more fingers on one hand), (deformity), multiple breasts, "
      "(mutated hands and fingers:1.5 ), (long body :1.3), (mutation, poorly drawn :1.2), bad anatomy, liquid body,"
      " liquid tongue, disfigured, malformed, mutated, anatomical nonsense, text font ui, error, malformed hands,"
      " long neck, blurred, lowers,  bad anatomy, bad proportions, bad shadow, uncoordinated body, unnatural body, "
      "fused breasts, bad breasts, huge breasts, poorly drawn breasts, extra breasts, liquid breasts, heavy breasts, "
      "missing breasts, huge haunch, huge thighs, huge calf, bad hands, fused hand, missing hand, disappearing arms,"
      " disappearing thigh, disappearing calf, disappearing legs, fused ears, bad ears, poorly drawn ears, extra ears,"
      " liquid ears, heavy ears, missing ears, fused animal ears, bad animal ears, poorly drawn animal ears, "
      "extra animal ears, liquid animal ears, heavy animal ears, missing animal ears, text, ui, error, missing fingers, "
      "missing limb, fused fingers, one hand with more than 5 fingers, one hand with less than 5 fingers,"
      " one hand with more than 5 digit, one hand with less than 5 digit, extra digit, fewer digits, fused digit, "
      "missing digit, bad digit, liquid digit, colorful tongue, black tongue, cropped, watermark, username, blurry, "
      "JPEG artifacts, signature, 3D, 3D game, 3D game scene, 3D character, malformed feet, extra feet, bad feet,"
      " poorly drawn feet, fused feet, missing feet, extra shoes, bad shoes, fused shoes, more than two shoes, "
      "poorly drawn shoes, bad gloves, poorly drawn gloves, fused gloves, bad hairs, poorly drawn hairs, fused hairs, "
      "big muscles, ugly, bad face, fused face, poorly drawn face, cloned face, big face, long face, bad eyes, "
      "fused eyes poorly drawn eyes, extra eyes, malformed limbs, more than 2 nipples, missing nipples, different nipples, "
      "fused nipples, bad nipples, poorly drawn nipples, black nipples, colorful nipples, gross proportions. short arm, "
      "(((missing arms))), missing thighs, missing calf, missing legs, mutation, duplicate, morbid, mutilated, "
      "poorly drawn hands, more than 1 left hand, more than 1 right hand, deformed, (blurry), disfigured, missing legs, "
      "extra arms, extra thighs, more than 2 thighs, extra calf, fused calf, extra legs, bad knee, extra knee, "
      "more than 2 legs, bad tails, bad mouth, fused mouth, poorly drawn mouth, bad tongue, tongue within mouth, "
      "too long tongue, black tongue, big mouth, cracked mouth, bad mouth, dirty face, dirty teeth, dirty pantie, "
      "fused pantie, poorly drawn pantie, fused cloth, poorly drawn cloth, bad pantie, yellow teeth, thick lips",
  "anime_negative_prompt":
      "NSFW, Paintings, sketches, negative_hand-neg, (worst quality:2), (low quality:2), (normal quality:2), "
          "extra heads, bad-image-v2-39000, bad_prompt_version2, bad-hands-5, "
          "EasyNegative, ng_deepnegative_v1_75t, (bad-artist-anime:0.7), "
          "(simple background:1.35), lowers, long neck, out of frame, extra fingers, mutated hands, monochrome, "
          "text, jpeg artifacts, signature, watermark, username, ",
  "default_prompts":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, high resolution, ",
  "default_prompts_fix_hands":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, <lora:GoodHands-beta2:1>, ",
  "default_prompts_add_details_1":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, <lora:add_detail:1>, ",
  "default_prompts_add_details_2":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, <lora:more_details:1>, ",
  "default_prompts_fairy_tale":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, animie, delicate scene, <lora:FairyTaleV20_SD1.5:0.7>, ",
  "default_prompts_for_girl":
      "(8k, best quality, masterpiece:1.2), (realistic, photo-realistic:1.37), unity, an extremely delicate and beautiful, "
          "amazing, finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, extremely detailed,"
          " beautiful detailed girl, extremely detailed eyes and face, beautiful detailed eyes, light on face, Kpop idol, mix4, "
          "<lora:koreandolllikenessV20_v20:0.3>, <lora:taiwanDollLikeness_v20:0.1>, <lora:japanesedolllikenessV1_v15:0.1>, "
          "<lora:cuteGirlMix4_v10:0.5>, <lyco:GoodHands-beta2:1>, ",
  "default_prompts_colorful":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, dazzling bursts of light, vibrant color explosions, glittering rays of light, shimmering reflections,"
          " luminous beams of light, radiant glow, prismatic hues, twinkling lights, cyberpunk background, "
          "glowing neon lights, (science fiction:1.5), (Colorful flash:1.2), (light on the clothes:1.2), "
          "sparkling illuminations, spectacular lighting display, glistening highlights, bold flashes of light,"
          " shining brilliance, dynamic light patterns, intense luminosity，Mosaic of colors, "
          "bursting with vibrancy, kaleidoscope of hues, eclectic blend of colors, swirling patterns, "
          "rich texture, intricate designs, stunning backdrop, dynamic contrast, playful composition,"
          " mesmerizing symmetry, harmonious interplay, bold color scheme, lively energy, captivating patterns,",
  "default_prompts_gundam":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, gundam(rx78), robot, science fiction, <lora:RX78_V1:1>",
  "default_prompts_gundam_clothes":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, gundam(rx78), robot, science fiction, mecha armor, <lora:RX78_V1:1>",
  "default_prompts_candy":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, braid, white background, bow, teddy bear, solo, dress, twin braids, frills, long sleeves, "
          "glasses, animal ears, stuffed toy, hair bow, stuffed animal, food, earrings, red nails, jewelry, "
          "food-themed hair ornament, hair ornament, simple background, shoes, full body, frilled dress, "
          "red bow, standing on one leg, bangs, looking at viewer, blush, red dress, book, nail polish, fruit,"
          " pink eyes, socks, food print, ribbon, strawberry, strawberry hair ornament, bear ears, hairclip,"
          " polka dot, standing, long hair, footwear bow, strawberry print, food-themed earrings, brown footwear,"
          " heart, round eyewear, <lora:candyStyle:1:MIDD>, ",
  "default_prompts_blind_box":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, full body, chibi, <lora:blindbox_V1Mix:1>, ",
  "default_prompts_hanfu_tang":
      "(8k, best quality, masterpiece:1.2), (realistic, photo-realistic:1.37), unity, an extremely delicate and beautiful, "
          "amazing, finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, extremely detailed,"
          " beautiful detailed girl, extremely detailed eyes and face, beautiful detailed eyes, light on face, Kpop idol, mix4, "
          "<lora:koreandolllikenessV20_v20:0.3>, <lora:taiwanDollLikeness_v20:0.1>, <lora:japanesedolllikenessV1_v15:0.1>, "
          "<lora:cuteGirlMix4_v10:0.5>, <lyco:GoodHands-beta2:1>, hanfu, tang style, <lora:hanfu40-beta-3:0.6>, ",
  "default_prompts_hanfu_ming":
      "(8k, best quality, masterpiece:1.2), (realistic, photo-realistic:1.37), unity, an extremely delicate and beautiful, "
          "amazing, finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, extremely detailed,"
          " beautiful detailed girl, extremely detailed eyes and face, beautiful detailed eyes, light on face, Kpop idol, mix4, "
          "<lora:koreandolllikenessV20_v20:0.3>, <lora:taiwanDollLikeness_v20:0.1>, <lora:japanesedolllikenessV1_v15:0.1>, "
          "<lora:cuteGirlMix4_v10:0.5>, <lyco:GoodHands-beta2:1>, hanfu, ming style, <lora:hanfu40-beta-3:0.6>, ",
  "default_prompts_hanfu_song":
      "(8k, best quality, masterpiece:1.2), (realistic, photo-realistic:1.37), unity, an extremely delicate and beautiful, "
          "amazing, finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, extremely detailed,"
          " beautiful detailed girl, extremely detailed eyes and face, beautiful detailed eyes, light on face, Kpop idol, mix4, "
          "<lora:koreandolllikenessV20_v20:0.3>, <lora:taiwanDollLikeness_v20:0.1>, <lora:japanesedolllikenessV1_v15:0.1>, "
          "<lora:cuteGirlMix4_v10:0.5>, <lyco:GoodHands-beta2:1>, hanfu, song style, <lora:hanfu40-beta-3:0.6>, ",
  "default_prompts_hanfu_jin":
      "(8k, best quality, masterpiece:1.2), (realistic, photo-realistic:1.37), unity, an extremely delicate and beautiful, "
          "amazing, finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, extremely detailed,"
          " beautiful detailed girl, extremely detailed eyes and face, beautiful detailed eyes, light on face, Kpop idol, mix4, "
          "<lora:koreandolllikenessV20_v20:0.3>, <lora:taiwanDollLikeness_v20:0.1>, <lora:japanesedolllikenessV1_v15:0.1>, "
          "<lora:cuteGirlMix4_v10:0.5>, <lyco:GoodHands-beta2:1>, hanfu, jin style, <lora:hanfu40-beta-3:0.6>, ",
  "default_prompts_hanfu_han":
      "(8k, best quality, masterpiece:1.2), (realistic, photo-realistic:1.37), unity, an extremely delicate and beautiful, "
          "amazing, finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, extremely detailed,"
          " beautiful detailed girl, extremely detailed eyes and face, beautiful detailed eyes, light on face, Kpop idol, mix4, "
          "<lora:koreandolllikenessV20_v20:0.3>, <lora:taiwanDollLikeness_v20:0.1>, <lora:japanesedolllikenessV1_v15:0.1>, "
          "<lora:cuteGirlMix4_v10:0.5>, <lyco:GoodHands-beta2:1>, hanfu, han style, <lora:hanfu40-beta-3:0.6>, ",
  "default_prompts_fashion_girl":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, <lora:fashigirl-v5.4-lora-64dim-naivae:0.5>, ",
  "default_prompts_film_girl":
      "(8k, best quality, masterpiece:1.2), (realistic, photo-realistic:1.37), unity, an extremely delicate and beautiful, "
          "amazing, finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, extremely detailed,"
          " beautiful detailed girl, extremely detailed eyes and face, beautiful detailed eyes, light on face, Kpop idol, mix4, "
          "<lora:koreandolllikenessV20_v20:0.3>, <lora:taiwanDollLikeness_v20:0.1>, <lora:japanesedolllikenessV1_v15:0.1>, "
          "<lora:cuteGirlMix4_v10:0.5>, <lyco:GoodHands-beta2:1>, filmg, <lora:FilmG3:0.6>, ",
  "default_prompts_pixel":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, pixel, <lora:pixel_f2:0.5>, ",
  "default_prompts_dunhuang":
      "(8k, best quality, masterpiece:1.2), (realistic, photo-realistic:1.37), unity, an extremely delicate and beautiful, "
          "amazing, finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, extremely detailed,"
          " beautiful detailed girl, extremely detailed eyes and face, beautiful detailed eyes, light on face, Kpop idol, mix4, "
          "<lora:koreandolllikenessV20_v20:0.3>, <lora:taiwanDollLikeness_v20:0.1>, <lora:japanesedolllikenessV1_v15:0.1>, "
          "<lora:cuteGirlMix4_v10:0.5>, <lyco:GoodHands-beta2:1>, dunhuang_cloths, dunhuang_style, dunhuang_background, dunhuang_dress, "
          "dunhuang_fan, <lora:dunhuang_v20:0.8>, ",
  "default_prompts_A_Mecha_REN":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, mecha musume, mechanical parts, robot joints, headgear, full armor. <lora:A-Mecha-REN:0.6>, ",
  "default_prompts_Lucy_Cyberpunk":
      "(8k, best quality, masterpiece:1.2), finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, "
          "extremely detailed, perfect face, high resolution, lucy (cyberpunk), <lora:lucyCyberpunk_35Epochs:0.6>, ",
  "default_prompts_jk":
      "(8k, best quality, masterpiece:1.2), (realistic, photo-realistic:1.37), unity, an extremely delicate and beautiful, "
          "amazing, finely detail, official art, incredibly absurdres, huge filesize, ultra-detailed, highres, extremely detailed,"
          " beautiful detailed girl, extremely detailed eyes and face, beautiful detailed eyes, light on face, Kpop idol, mix4, "
          "<lora:koreandolllikenessV20_v20:0.3>, <lora:taiwanDollLikeness_v20:0.1>, <lora:japanesedolllikenessV1_v15:0.1>, "
          "<lora:cuteGirlMix4_v10:0.5>, <lyco:GoodHands-beta2:1>, JK_style, short-sleeved JK_shirt, short-sleeved JK_sailor, JK_suit, JK_tie, <lora:jk_uniform:0.6>, ",
};
