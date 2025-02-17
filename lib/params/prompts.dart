const Map<String, dynamic> prompts = {
  "real_person_negative_prompt": "Paintings, sketches, negative_hand-neg, (worst quality:2), (low quality:2), (normal quality:2), (deformed iris, deformed pupils, bad eyes, semi-realistic:1.4), "
      "(bad-image-v2-39000, bad_prompt_version2, bad-hands-5, EasyNegative, ng_deepnegative_v1_75t), (worst quality, low quality:1.3), (blurry:1.2),"
      " (greyscale, monochrome:1.1), nose, cropped, lowres, text, jpeg artifacts, signature, watermark, username, blurry, artist name, trademark, watermark, title,"
      " (tan, muscular, child, infant, toddlers, chibi, sd character:1.1), multiple view, Reference sheet, long neck, lowers, normal quality, ((monochrome)), ((grayscales)),"
      " skin spots, acnes, skin blemishes, age spot, glans, (6 more fingers on one hand), (deformity), multiple breasts, (mutated hands and fingers:1.5 ), (long body :1.3),"
      " (mutation, poorly drawn :1.2), bad anatomy, liquid body, liquid tongue, disfigured, malformed, mutated, anatomical nonsense, text font ui, error, malformed hands, "
      "long neck, blurred, lowers, lowres, bad anatomy, bad proportions, bad shadow, uncoordinated body, unnatural body, fused breasts, bad breasts, huge breasts, poorly "
      "drawn breasts, extra breasts, liquid breasts, heavy breasts, missing breasts, huge haunch, huge thighs, huge calf, bad hands, fused hand, missing hand, "
      "disappearing arms, disappearing thigh, disappearing calf, disappearing legs, fused ears, bad ears, poorly drawn ears, extra ears, liquid ears, heavy ears, "
      "missing ears, fused animal ears, bad animal ears, poorly drawn animal ears, extra animal ears, liquid animal ears, heavy animal ears, missing animal ears, text, ui, "
      "error, missing fingers, missing limb, fused fingers, one hand with more than 5 fingers, one hand with less than 5 fingers, one hand with more than 5 digit, "
      "one hand with less than 5 digit, extra digit, fewer digits, fused digit, missing digit, bad digit, liquid digit, colorful tongue, black tongue, cropped, watermark, "
      "username, blurry, JPEG artifacts, signature, 3D, 3D game, 3D game scene, 3D character, malformed feet, extra feet, bad feet, poorly drawn feet, fused feet, "
      "missing feet, extra shoes, bad shoes, fused shoes, more than two shoes, poorly drawn shoes, bad gloves, poorly drawn gloves, fused gloves, bad hairs, "
      "poorly drawn hairs, fused hairs, big muscles, ugly, bad face, fused face, poorly drawn face, cloned face, big face, long face, bad eyes, fused eyes poorly drawn eyes,"
      " extra eyes, malformed limbs, more than 2 nipples, missing nipples, different nipples, fused nipples, bad nipples, poorly drawn nipples, black nipples, colorful nipples, "
      "gross proportions. short arm, (((missing arms))), missing thighs, missing calf, missing legs, mutation, duplicate, morbid, mutilated, poorly drawn hands,"
      " more than 1 left hand, more than 1 right hand, deformed, (blurry), disfigured, missing legs, extra arms, extra thighs, more than 2 thighs, extra calf, fused calf, "
      "extra legs, bad knee, extra knee, more than 2 legs, bad tails, bad mouth, fused mouth, poorly drawn mouth, bad tongue, tongue within mouth, too long tongue, black tongue, "
      "big mouth, cracked mouth, bad mouth, dirty face, dirty teeth, dirty pantie, fused pantie, poorly drawn pantie, fused cloth, poorly drawn cloth, bad pantie, yellow teeth,"
      " thick lips",
  "anime_negative_prompt":
      "(simple background:1.35), lowres, long neck, out of frame, extra fingers, mutated hands, monochrome, ((poorly drawn hands)), ((poorly drawn face)), (((mutation))),"
          " (((deformed))), ((ugly)), blurry, ((bad anatomy)), (((bad proportions))), ((extra limbs)), cloned face, glitchy, bokeh, (((long neck))), ((flat chested)), "
          "((((visible hand)))), ((((ugly)))), (((duplicate))), ((morbid)), ((mutilated)), [out of frame], extra fingers, mutated hands, ((poorly drawn hands)), "
          "((poorly drawn face)), (((mutation))), (((deformed))), ((ugly)), blurry, ((bad anatomy)), (((bad proportions))), ((extra limbs)), cloned face, (((disfigured))), "
          "out of frame, ugly, extra limbs, (bad anatomy), gross proportions, (malformed limbs), ((missing arms)), ((missing legs)), (((extra arms))), (((extra legs))), "
          "mutated hands, (fused fingers), (too many fingers), (((long neck))) red eyes, multiple subjects, extra headsbad-image-v2-39000, bad_prompt_version2, bad-hands-5, "
          "EasyNegative, ng_deepnegative_v1_75t, bad-artist-anime:0.7,  negative_hand-neg",
  "default_prompt":
      "(8k, best quality, masterpiece:1.2), best quality, official art, highres, extremely detailed CG unity 8k wallpaper, extremely detailed,incredibly absurdres, highly "
          "detailed, absurdres, 8k resolution, exquisite facial features, huge filesize, ultra-detailed, ",
  "camera_perspective_prompts": [
    "Depth of field",
    "Panorama",
    "telephoto lens",
    "macro lens",
    "full body",
    "medium shot",
    "cowboy shot",
    "profile picture",
    "close up portrait",
    "POV",
    "partially underwater shot",
    "fisheye"
  ],
  "action_prompts": [
    "smelling",
    "princess carry",
    "hug",
    "back-to-back",
    "peace symbol",
    "adjusting_thighhigh",
    "grabbing",
    "fighting_stance",
    "walking",
    "running",
    "straddling",
    "jump",
    "fly",
    "against wall",
    "lie",
    "hug from behind",
    "walk a dog",
    "skirt lift",
    "half body under water",
    "horse riding",
    "selfie",
    "standing split",
    "salute, pray",
    "doing a meditation",
    "stretch",
    "gill support",
    "holding hands",
    "hand_on_hip",
    "hands_on_hips",
    "waving",
    "kissing forehead",
    "hair scrunchie",
    "hair_pull",
    "grabbing hair",
    "middle_finger",
    "kissing cheek",
    "bent over",
    "tiptoe kiss",
    "fruit on head",
    "glove biting",
    "cheek-to-cheek",
    "hand on hand",
    "crossed arms",
    "spread arms",
    "holding gun",
    "holding cup",
    "holding food",
    "holding book",
    "holding wand",
    "waving arms",
    "outstretched arm",
    "carrying",
    "arm hug",
    "holding knife",
    "holding",
    "holding umbrella",
    "holding flower",
    "holding microphone",
    "object hug",
    "holding heart"
  ],
  "actions_prompts": [
    "yokozuwari",
    "ahirusuwari",
    "indian style",
    "kneeling",
    "arched back",
    "lap pillow",
    "paw pose",
    "one knee",
    "fetal position",
    "on back",
    " on stomach",
    "sitting",
    "hugging own legs",
    "upright straddle",
    "standing",
    "squatting",
    "crucifixion",
    "leg lock",
    "all fours",
    "hand on headphones",
    "ghost pose",
    "turning around",
    "head tilt",
    "leaning forward"
  ],
  "person_prompts": [
    [
      "female",
      "male",
      "girl",
      "boy",
      "shota",
      "loli",
      "bishoujo",
      "bishounen",
      "gyaru",
      "ojousama",
      "chibi",
      "fat man",
      "crossdressing",
      "angel",
      "devil",
      "minigirl",
      "no_humans",
      "mesugaki",
      "monster",
      "elder",
      "princess",
      "rich man",
      "beggar",
      "titans",
      "dwarf",
      "clown",
      "slave",
      "yukiwo",
      "sheik",
      "queen",
      "goddess",
      "prince",
      "bride",
      "bridegroom",
      "muscle man",
      "idol",
      "bunny girl",
      "monster girl",
      "fox girl",
      "wolf girl",
      "cat girl",
      "marionette",
      "nendoroid"
    ],
    ["solo", "multiple girls", "twins", "triplets", "brother and sister"]
  ],
  "career_prompts": [
    "lifeguard",
    "boxer",
    "scientist",
    "athletes",
    "office lady",
    "monk",
    "crobat",
    "nun",
    "nurse",
    "stewardess",
    "student",
    "waitress",
    "teacher",
    "racer",
    "police",
    "soldier",
    "cheerleader",
    "actor",
    "actress",
    "spy",
    "agent",
    "assassin",
    "poet",
    "samurai",
    "dancing girl",
    "motorcyclist",
    "hacker",
    "magician",
    "detective",
    "doll",
    "maid",
    "pilot",
    "diver",
    "bar censor",
    "missionary",
    "firefighter",
    "goalkeeper",
    "chef",
    "astronaut",
    "cashier",
    "mailman",
    "barista",
    "the hermit",
    "makihitsuji"
  ],
  "anime_characters_prompts": [
    "pokemon",
    "teddy bear",
    "mario",
    "pikachu",
    "neon genesis evangelion",
    "hatsune miku",
    "harry potter",
    "doraemon",
    "saint seiya",
    "gojou satoru",
    "avengers",
    "mazinger",
    "captain america",
    "crayon shin-chan",
    "slam dunk",
    "sun wukong",
    "witch",
    "ninja",
    "vampire",
    "knight",
    "magical_girl",
    "orc",
    "druid",
    "elf",
    "fairy",
    "furry",
    "mermaid",
    "kamen rider",
    "magister",
    "spider-man",
    " santa alter"
  ],
  "facial_features_prompts": [
    ["thick eyebrows", "cocked eyebrow", "short eyebrows", "v-shaped eyebrows"],
    [
      "empty eyes",
      "wide eyes",
      "one eye closed",
      "half-closed eyes",
      "gradient_eyes",
      "aqua eyes",
      "rolling eyes",
      "cross-eyed",
      "slit pupils",
      "bloodshot eyes",
      "glowing eyes",
      "tsurime",
      "tareme",
      "devil eyes",
      "constricted pupils",
      "devil pupils",
      "snake pupils",
      "pupils sparkling",
      "flower-shaped pupils",
      "heart-shaped pupils",
      "heterochromia",
      "color contact lenses",
      "longeyelashes",
      "colored eyelashes",
      "mole under eye"
    ],
    [
      "chestnut mouth",
      "thick lips",
      "puffy lips",
      "lipstick",
      "heart-shaped mouth",
      "pout",
      "open mouth",
      "closed mouth",
      "shark mouth",
      ":p",
      "parted lips",
      "mole under mouth",
      ":3"
    ],
    ["fake animal ears", "cat ears", "dog ears", "fox ears", "bunny ears", "bear ears"],
    ["fangs", "canine teeth"]
  ],
  "expression_prompts": [
    "expressionless",
    "turn pale",
    "blush stickers",
    "blush",
    "blank stare",
    "anger vein",
    "embarrassed",
    "hubrael",
    "depressed",
    "wince",
    "kilesha",
    "shaded face",
    "pain",
    "screaming",
    "sigh",
    "nervous",
    "confused",
    "scared",
    "drunk",
    "tears",
    "sad",
    "angry",
    "nose blush",
    "serious",
    "jitome",
    "crazy",
    "dark_persona",
    "smug",
    "thinking",
    "raised eyebrow",
    "light frown",
    "frown",
    "naughty face",
    "eyeid pull",
    "nosebleed",
    "sleepy",
    "zzz",
    "drooling",
    "light smile",
    "false smile",
    "seductive smile",
    "crazy smile",
    "evil smile",
    "smirk",
    "seductive smile",
    "grin",
    "laughing",
    ":d"
  ],
  "hair_prompts": [
    ["short hair", "medium hair", "long hair", "hair over shoulder"],
    [
      "white hair",
      "blonde hair",
      "silver hair",
      "grey hair",
      "brown hair",
      "black hair",
      "purple hair",
      "red hair",
      "blue hair",
      "green hair",
      "pink hair",
      "orange hair",
      "streaked hair",
      "multicolored hair",
      "rainbow-like hair"
    ],
    [
      "bangs",
      "crossed bang",
      "hair between eye",
      "blunt bangs",
      "diagonal bangs",
      "asymmetrical bangs",
      "braided bangs"
    ],
    [
      "short ponytail",
      "side ponytail",
      "front ponytail",
      "split ponytail",
      "low twintails",
      "short twintails",
      "side braid",
      "braid",
      "twin braids",
      "ponytail",
      "braided ponytail",
      "french braid",
      "twists",
      "high ponytail"
    ],
    [
      "tied hair",
      "single side bun",
      "curly hair",
      "straight hair",
      "wavy hair",
      "bob hair",
      "heart ahoge",
      "slicked-back",
      "Reggae hair",
      "pompadour",
      "Mohawk",
      "bowl cut",
      "ahoge",
      "antenna hair",
      "drill hair",
      "hair wings",
      "disheveled hair",
      "messy hair",
      "chignon",
      "braided bun",
      "hime_cut",
      " bob cut",
      "spiked hair",
      "updo",
      "pixie cut",
      "dreadlocks",
      "afro",
      "bald",
      "double bun",
      "buzz cut",
      "big hair",
      "shiny hair",
      "glowing hair",
      "hair between eyes",
      "hair behind ear"
    ]
  ],
  "decoration_prompts": [
    [
      "hair ribbon",
      "head scarf",
      "animal hood",
      "hair bow",
      "crescent hair ornament",
      "lolita hairband",
      "feather hair ornament",
      "hair flower",
      "hair bun",
      "hairclip",
      "hair scrunchie",
      "hair rings",
      "hair ornament",
      "hair stick",
      "heart hair ornament"
    ],
    [
      "bracelet",
      "choker",
      "metal collar",
      "ring",
      "wristband",
      "pendant",
      "brooch",
      "hoop earrings",
      "bangle",
      "stud earrings",
      "sunburst",
      "pearl bracelet",
      "drop earrings",
      "puppet rings",
      "corsage",
      "sapphire brooch",
      "jewelry",
      "necklace"
    ],
    [
      "ribbon",
      "ribbon trim",
      "lace trim",
      "skirt lift",
      "gauntlets",
      "neckerchief",
      "red neckerchief",
      "pauldrons",
      "arm strap",
      "armlet",
      "spaghetti strap",
      "Prajna in mask",
      "veil",
      "bridal veil",
      "mini crown",
      "tiara",
      "ear covers",
      "aviator sunglasses",
      "semi-rimless eyewear",
      "semi-rimless eyewear",
      "sunglasses",
      "goggles",
      "eyepatch",
      "black blindfold",
      "metal thorns",
      "halo",
      "mouth mask",
      "bandaid hair ornament",
      "nail polish",
      "doll joints",
      "cybernetic prosthesis",
      "mechanical legs",
      "beach towel,poncho",
      "make up"
    ]
  ],
  "clothes_prompts": [
    [
      "sleeves_past_fingers",
      "tank top",
      "white shirt",
      "sailor shirt",
      "T-shirt",
      "sweater",
      "summer dress",
      "hoodie",
      "fur trimmed colla",
      "hooded cloak",
      "jacket",
      "leather jacket",
      "safari jacket",
      "hood",
      "denim jacket",
      "turtleneck jacket",
      "firefighter jacket",
      "see-through jacket",
      "trench coat",
      "lab coat",
      "Down Jackets",
      "body armor",
      "flak jacket",
      "overcoat",
      "duffel coat"
    ],
    [
      "denim shorts",
      "pleated skirt",
      "short shorts",
      "pencil skirt",
      "leather skirt",
      "black leggings",
      "skirt under kimono"
    ]
  ],
  "clothes_prompts2": [
    "transparent clothes",
    "tailcoat",
    "Victoria black maid dress",
    "sailor suit",
    "school uniform",
    "bussiness suit",
    "suit",
    "military uniform",
    "lucency full dress",
    "hanfu",
    "cheongsam",
    "japanses clothes, sportswear",
    "dungarees",
    "wedding dress",
    "silvercleavage dress",
    "robe",
    "apron",
    "fast food uniform",
    "JK",
    "gym_uniform",
    "miko attire",
    "SWAT uniform",
    "sleeveless dress,raincoat",
    "mech suit",
    "wizard robe",
    "assassin-style",
    "frills",
    "lace",
    "gothic",
    "lolita fashion",
    "western",
    "wet clothes",
    "off_shoulder",
    "bare_shoulders",
    "tartan",
    "striped",
    "armored skirt",
    "armor",
    "metal armor",
    "berserker armor",
    "scarf",
    "belt",
    "cape",
    "fur shawl"
  ],
  "hat_prompts": [
    "Baseball cap",
    "Beanie",
    "Bicorne",
    "Boater hat",
    "Visor cap",
    "Bowler hat",
    "Cabbie hat",
    "Bucket hat",
    "Fedora",
    "Cowboy hat",
    "Chef hat",
    "Military hat",
    "Santa hat",
    "Party hat",
    "Jester cap",
    "Hardhat",
    "Baseball helmet",
    "Football helmet",
    "animal helmet",
    "witch hat",
    "beret",
    "peaked cap",
    "Straw hat"
  ],
  "shoes_prompts": [
    "bare_legs",
    "boots",
    "knee boots",
    "ankle boots",
    "cross-laced_footwear",
    "combat boots",
    "armored boots",
    "knee boots",
    "rubber boots",
    "leather boots",
    "snow boots",
    "santa boots",
    "shoes",
    "platform footwear",
    "pointy footwear",
    "sneakers",
    "ballet slippers",
    "roller skates",
    "ice skates",
    "spiked shoes",
    "high heels",
    "mary janes",
    "loafers",
    "uwabaki",
    "sandals",
    "geta",
    "slippers",
    "flip-flops"
  ],
  "socks_prompts": [
    "no socks",
    "socks",
    "tabi",
    "stockings",
    "christmas stocking",
    "leg warmers",
    "frilled socks",
    "ribbon-trimmed legwear",
    " shiny legwear",
    "frilled thighhighs",
    "thighhighs",
    "fishnet stockings",
    "loose socks",
    "leggings",
    "lace legwear",
    "ribbed legwear",
    " wet pantyhose",
    "plaid legwear",
    "see-through legwear",
    "pantyhose",
    "torn pantyhose",
    "single leg pantyhose",
    "frilled pantyhose",
    "studded garter belt",
    "sock dangle",
    "thigh strap",
    "leg_garter",
    "bandaged leg"
  ],
  "gesture_prompt": [
    "shushing",
    "thumbs up",
    "arms behind head",
    "arms behind back",
    "hand in pocket",
    "hands in pocket",
    "interlocked fingers",
    "victory pose",
    "hand on floor",
    "hand on forehead",
    "hand on own stomach",
    "arm over shoulder",
    "hand on another\"s leg",
    "hand on another\"s waist",
    "own hands clasped",
    "wide open arms",
    "hand to mouth",
    "finger gun",
    "cat pose"
  ],
  "sight_prompts": [
    "looking afar",
    "looking at mirror",
    "looking at phone",
    "looking away",
    "visible through hair",
    "looking over glasses",
    "look at viewer",
    "close to viewer",
    "dynamic angle",
    "dramatic angle",
    "stare",
    "looking up",
    "looking down",
    "looking away",
    "looking to the side"
  ],
  "environment_prompts": [
    [
      "in spring",
      "in summer",
      "in autumn",
      "in winter",
      "dusk",
      "night",
      "(autumn maple forest:1.3)",
      "(very few fallen leaves), (path)",
      "day"
    ],
    [
      "sun",
      "sunset",
      "moon",
      "full_moon",
      "stars",
      "sky",
      "cloudy",
      "rain",
      "snow",
      "ice",
      "snowflakes",
      "lighting",
      "rainbow",
      "meteor shower",
      "universe"
    ],
    [
      "sea",
      "hills",
      "in a meadow",
      "on the beach",
      "underwater",
      "over the sea",
      "grove",
      "on a desert",
      "plateau",
      "cliff",
      "canyon",
      "oasis",
      "bamboo forest",
      "glacier",
      "floating island",
      "volcano",
      "savanna",
      "waterfall",
      "stream",
      "wasteland",
      "rice paddy",
      "wheat field",
      "flower field",
      "flower sea",
      "indoor",
      "curtain",
      "bed",
      "bathroom",
      "toilet stall",
      "otaku room",
      "cafeteria",
      "classroom",
      "clubroom",
      "salon",
      "bar",
      "izakaya",
      "cafe",
      "bakery",
      "convenience store",
      "supermarket",
      "bookstore",
      "pharmacy",
      "theater",
      "movie theater",
      "greenhouse",
      "dungeon",
      "gym",
      "infirmary",
      "laboratory",
      "library",
      "workshop",
      "stage",
      "courtroom",
      "castle",
      "city",
      "waterpark",
      "carousel",
      "ferris wheel",
      "aquarium",
      "zoo",
      "bowling alley",
      "art gallery",
      "museum",
      "planetarium",
      "swimming pool",
      "stadium",
      "temple",
      "bus stop",
      " train station",
      "fountain",
      "playground",
      "market stall",
      "phone booth",
      "railroad tracks",
      "airport",
      "tunnel"
    ],
    [
      "new year",
      "year of the rabbit",
      "valentine",
      "lantern festival",
      "summer festival",
      "tanabata",
      "mid-autumn festival",
      "halloween",
      "christmas",
      "explosion",
      "water vapor",
      "fireworks",
      "ceiling window",
      "colourful glass",
      "stain glass",
      "Graffiti wall",
      "mosaic background",
      "liquid background",
      "Sputtered water",
      "magic circles",
      "fluorescent mushroom forests background",
      "(((colorful bubble)))"
    ]
  ],
  "light_prompts": [
    "rim light",
    "Volumetric Lighting",
    "glowing neon lights",
    "Cinematic Lighting",
    "lens flare",
    "metallic luster",
    "moody lighting",
    "Tyndall effect",
    "light leaks",
    "background light",
    "available light"
  ],
  "style_prompts": [
    "8 Bit Game",
    "1980s anime",
    "disney movie",
    "goth",
    "80s movie",
    "bubble bobble",
    "style of Pixar",
    " Polaroid art",
    "Kaleidoscope Photography",
    "opal render",
    "chemigram",
    "Studio Ghibli",
    "dreamlike",
    "(faux traditional media)",
    "genshin impact",
    "azur lane",
    "kantai collection",
    "rebecca (cyberpunk)",
    "((dieselpunk))",
    "4koma",
    "magazine scan",
    "album cover",
    "synthwave",
    "(illustration),(paper figure),(lococo),((impasto)),(shiny skin)",
    "Collage",
    "Dalle de verre",
    "pixel art",
    "Encaustic painting",
    "Ink wash painting",
    "Mezzotint",
    "silhouette",
    "illustration",
    "(((ink))), ((watercolor))",
    "illustration,(((ukiyoe))),((sketch)),((japanese_art))",
    "((wash painting)),((ink splashing)),((color splashing)),((((dyeing)))),((chinese style))",
    "((dyeing)),((oil painting)),((impasto))",
    "((art nouveau))",
    "((classicism))",
    "((futurism))",
    "((Dadaism))",
    "((abstract art))",
    "((ASCII art))",
    "((alphonse mucha))",
    "((Monet style))"
  ]
};
