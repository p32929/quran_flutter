'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "56ccf9063c6f5382c089a10cdb8e170c",
"version.json": "14f9fcda440f740301db42689fa7188c",
"index.html": "388a0f2620adc8bf72b69bc3d360e0af",
"/": "388a0f2620adc8bf72b69bc3d360e0af",
"main.dart.js": "b4a9e368c940a3a5e92fc00c057e624d",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"spinner_animation.svg": "5c5ddcb7a4cd4414f2b2eb95fa981b9e",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "c88da2327a2c57049b9b4314ce0321cb",
"assets/NOTICES": "3dcf10ff2d5fd5240c47cf96cdb22cbe",
"assets/FontManifest.json": "53d157a169ceeaeb4963a0928d1c4466",
"assets/AssetManifest.bin.json": "d71d524356dbf5e72d55384b3c6e8f5d",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "0e8c1eb4c2da51e5e4243324b6741ef3",
"assets/fonts/MaterialIcons-Regular.otf": "546147077f9d5ca3a6fc54eb7a8adfd7",
"assets/assets/icons/app_icon.png": "7033e2d8ea7a4221bee357a42e6f8312",
"assets/assets/fonts/indopak.ttf": "35701970dda795662a4a1bb7f740d387",
"assets/assets/data/surah_49.json": "234f644e8ab8c85021945832a5f4ed76",
"assets/assets/data/surah_3.json": "d5134e6592fa0d550bd4a8f7a989e3d9",
"assets/assets/data/surah_32.json": "9738f4b197eb48f0875d610a05aad75b",
"assets/assets/data/surah_65.json": "2ae6183699c8ecc0c36ae5890fb7fd8e",
"assets/assets/data/surah_73.json": "5ce2262d90d050ff17af5d7f5fdd6d24",
"assets/assets/data/surah_24.json": "b257ae6e61a00a27df23b5cbb3eda2db",
"assets/assets/data/surah_101.json": "acc6392240931184115e4313390fb76a",
"assets/assets/data/surah_53.json": "02e1fba365349bd0f7886b4c1b40dfa0",
"assets/assets/data/surah_12.json": "e6f7c0efe10407a2cd198297b1ee48f0",
"assets/assets/data/surah_45.json": "194b249f8db0515e3496fabc3aeac187",
"assets/assets/data/surah_86.json": "b4618241637785681f11f0367766768a",
"assets/assets/data/surah_69.json": "ad5277ca23a7f1285f58de53fef07776",
"assets/assets/data/surah_90.json": "87ce064b37f5cb66b7745b751ebf6a7b",
"assets/assets/data/surah_28.json": "22959a445bfe20b050e7fbac25e7ef0b",
"assets/assets/data/surah_29.json": "c8d46cfadedea6fe2148e9301df97e30",
"assets/assets/data/surah_91.json": "5ebc42d948836989303b98adb1348ea6",
"assets/assets/data/surah_87.json": "a814e7e2291bff6a84c11f781e9214ed",
"assets/assets/data/surah_68.json": "5f48621f41e38ad6157f2df0013a80db",
"assets/assets/data/surah_44.json": "c01ae8692f0b88f96970fb11cafadd32",
"assets/assets/data/surah_13.json": "4db24794b323d435de50bb5c08e93f39",
"assets/assets/data/surah_52.json": "c3d24eb1c0cc2a0f38ee9e8a0c27e2c2",
"assets/assets/data/surah_25.json": "d912563d57871d45dbb72776ae853148",
"assets/assets/data/surah_100.json": "d723c0569772d77ee1e0b2338a481275",
"assets/assets/data/surah_72.json": "a11c4fe0d4045d785edf72f73f29aa17",
"assets/assets/data/surah_64.json": "e43867fdbb1e8452972e4e0c9c3ecfbb",
"assets/assets/data/surah_33.json": "2d0d3d7d28720f51fcd1964ff902da6b",
"assets/assets/data/surah_2.json": "da76233f508ee8ac306e80e1c1c20a97",
"assets/assets/data/surah_48.json": "f11e76affacad3438a39120ed891aaa8",
"assets/assets/data/surah_55.json": "8d27aa61bdc46125576141e98948e460",
"assets/assets/data/surah_14.json": "958a44905612108953ea2f6fb895c929",
"assets/assets/data/surah_43.json": "caa28efcacde2db6c3656c65318c83fc",
"assets/assets/data/surah_38.json": "63a3cbc3b6820de6353cf59ea35b869a",
"assets/assets/data/surah_9.json": "3a2246c7719872fc9717bbc9bc146573",
"assets/assets/data/surah_80.json": "31ff922f10e08a50a9476fd73a8a91a4",
"assets/assets/data/surah_96.json": "6b8c4e6d6c7d0bfc446d179fa35dbaaf",
"assets/assets/data/surah_79.json": "20c246fd2dea190274d31d5a193330aa",
"assets/assets/data/surah_59.json": "9d670074a89590f5daf1d9c002f342f2",
"assets/assets/data/surah_18.json": "4986f410365249b1c33138e42952f3e0",
"assets/assets/data/surah_5.json": "7d92320407a04246a956ae17dbe94520",
"assets/assets/data/surah_111.json": "cb53625283edf6cc684b25dbcd018efd",
"assets/assets/data/surah_34.json": "589b5bf572746ee4d722f50ff64ddb4a",
"assets/assets/data/surah_63.json": "22d8ebbe5ee0ae6fec28ea7631028999",
"assets/assets/data/surah_75.json": "ae606836436303283887a6f5e20b4876",
"assets/assets/data/surah_22.json": "2c3e1d6e39946199b2312af3f90a8d7c",
"assets/assets/data/surah_107.json": "d91d01f41b18afbf45c31ce88c026da0",
"assets/assets/data/surah_23.json": "14447edd1d4e861ae25bce726ad951ec",
"assets/assets/data/surah_106.json": "b3e7759de1da82332f136cfd9eb89876",
"assets/assets/data/surah_74.json": "a7b7efb8765ac10e4dfb93977d000e09",
"assets/assets/data/surah_62.json": "5fc9f84850fb142e742f29fd42c2c9db",
"assets/assets/data/surah_110.json": "53dc5fc76d5cc5add0560b3cbb29f679",
"assets/assets/data/surah_35.json": "2ef39f8a155baf4a3081cbcc7b514ff5",
"assets/assets/data/surah_4.json": "e6aeedd55274d152527d7a840341963a",
"assets/assets/data/surah_19.json": "30734bf1e74de6df543c55c6bc972248",
"assets/assets/data/surah_58.json": "d60ae7528b2935fd842fd1d2d35c2c7a",
"assets/assets/data/surah_97.json": "366d45d8aca6376627ac60d325cda2d5",
"assets/assets/data/surah_78.json": "3a3ea4cbc91045c648997f6a1d3d820b",
"assets/assets/data/surah_81.json": "e28674e4a499223f0c3cab650a0fe026",
"assets/assets/data/surah_8.json": "617b2476c08fa76efc04240d784c8574",
"assets/assets/data/surah_39.json": "147e2f9edd73f8a2f135c42536e9743b",
"assets/assets/data/surah_42.json": "c3ac4bab9e94287afd10432693603d46",
"assets/assets/data/surah_15.json": "ef061168114f410d2171b5c59777806b",
"assets/assets/data/surah_54.json": "b1f3a3f443ed69dbe58786a9cadd7594",
"assets/assets/data/surah_109.json": "6a5084a885a90041a82d8285668a971c",
"assets/assets/data/surah_94.json": "a90c437fb0449ec94bbad6ccad68ecb3",
"assets/assets/data/surah_82.json": "32c8ab482f2afb5044211c716c27c342",
"assets/assets/data/surah_41.json": "ada9d95295c3b96bbca48588fecbfe8f",
"assets/assets/data/surah_16.json": "7ea4cbdc9fbbaefa4ee545c0eae552dc",
"assets/assets/data/surah_57.json": "bf23af737ba70eb1ac9790f2bf5c2099",
"assets/assets/data/surah_20.json": "a4d8cd5b2e448fbe1e64c439390f3ae3",
"assets/assets/data/surah_105.json": "69245cdb420f5c99b3b26c13bfe688e3",
"assets/assets/data/surah_77.json": "4428dc284864d684a47576c17be4af60",
"assets/assets/data/surah_98.json": "24ec76303c4ce89fdeb4638ea0ad8821",
"assets/assets/data/surah_61.json": "d256364df53c2b50c7c83e676f084da4",
"assets/assets/data/surah_113.json": "7751ddd6548ba1e53a4e916c28435046",
"assets/assets/data/surah_36.json": "3f33d8a171d4dfb5cca5970bbdd98d36",
"assets/assets/data/surah_7.json": "8b6f25d0a6de3d02cb0078f4b5f36625",
"assets/assets/data/surah_6.json": "e8884d054bf722ba1b13e288b7f16e5b",
"assets/assets/data/surah_112.json": "6896b2715e0d879e0c9ec9a7ad170ad2",
"assets/assets/data/surah_37.json": "97ac055039758a4d4eedf957f1ba6106",
"assets/assets/data/surah_60.json": "c4e42b33bc0f2c5376c62949aa5da0d2",
"assets/assets/data/surah_76.json": "45b2ebbbc5189eb752c0cd346f52aa8d",
"assets/assets/data/surah_99.json": "10e8412407e466ed2c3c3ef9cc875b8d",
"assets/assets/data/surah_21.json": "9ec0251a3634d1053d823e7ad339754c",
"assets/assets/data/surah_104.json": "3a2417258b4f5f529d0bb335effee620",
"assets/assets/data/surah_56.json": "f4ed82f6c4e11d590d5f86d98a81a7e6",
"assets/assets/data/surah_17.json": "4a7e48f72195c23a59e71222fe9d694d",
"assets/assets/data/surah_40.json": "df5dd40b2208bb3e747b4265bbe8799b",
"assets/assets/data/surah_83.json": "38745efbebd443540798d3b507bc13eb",
"assets/assets/data/surah_95.json": "4ffd7608e32dbd0346bd6f6a4039fb99",
"assets/assets/data/surah_108.json": "83186efaf4c30c5ffcfff2d503cab70c",
"assets/assets/data/surah_26.json": "b54e957eac6e8a18132f0bcd01d6fd42",
"assets/assets/data/surah_103.json": "159fc682aa73cdfd2b41b3d23090a86e",
"assets/assets/data/surah_71.json": "abb06ba8f3f4a4d96d1d76f61a52a363",
"assets/assets/data/surah_67.json": "5a9f4e451d287566bfc5f8e4f332fa4c",
"assets/assets/data/surah_88.json": "22b4bb61799f00a6049be2fb5baaf788",
"assets/assets/data/surah_30.json": "4fb6411265f63f38171b53b564553189",
"assets/assets/data/surah_1.json": "549a3272cef2258a7557cabb55d7261a",
"assets/assets/data/version.txt": "c81e728d9d4c2f636f067f89cc14862c",
"assets/assets/data/surah_92.json": "87b360eba7dcc14c0b7131c7905563f3",
"assets/assets/data/surah_84.json": "3d6f4d51a19255cffd5928bf80569581",
"assets/assets/data/surah_47.json": "6a2704e2de97dc9d1b7da776b9c40fde",
"assets/assets/data/surah_10.json": "78f2079007962eef0457a9777f7cc685",
"assets/assets/data/surah_51.json": "c1f2fcefa81150d735c5b153c9885cff",
"assets/assets/data/surah_50.json": "dcc5dee3dfee18ffba018b1005809bd3",
"assets/assets/data/surah_11.json": "21bf6f27e492803abc9ae15659a9dcf9",
"assets/assets/data/surah_46.json": "8c8cf40660bcd7c675e192e5c875754e",
"assets/assets/data/surah_85.json": "13a8ab4dfff82e9812a8543910baa15d",
"assets/assets/data/translations/urd-fatehmuhammadja.json": "4417314c4a87756172a24db9157bc127",
"assets/assets/data/translations/urd-ahmedali.json": "8f10cd53481b9041ff5e3deffac693c8",
"assets/assets/data/translations/ben-muhiuddinkhan.json": "dec790ab5bb5a5d2c0953db07c183dbd",
"assets/assets/data/translations/editions.json": "cfdbdf1cb5fd2f715aac22ea6bf60c47",
"assets/assets/data/translations/urd-muhammadtaqiusm.json": "c6e6a61f3e23dd928a30d5c48f70affd",
"assets/assets/data/translations/urd-abulaalamaududi.json": "6533ecaf14d9f4600929f1065f45bb57",
"assets/assets/data/translations/urd-syedzeeshanhaid.json": "89029474d4d9bb79f4b637dfe38f564d",
"assets/assets/data/translations/urd-muhammadjunagar.json": "7df6c5844631740a7bed43aa9fab2e71",
"assets/assets/data/translations/available_editions.json": "d9fee591efb973e3050eba6f28c0643c",
"assets/assets/data/translations/eng-khattab.json": "da649d10de7f81fd485775d0a319abbb",
"assets/assets/data/translations/urd-muhammadhussain.json": "6d74c958a90ab74c223d7d494b5c4273",
"assets/assets/data/translations/ben-zohurulhoque.json": "800b7ccb175ad619dc0294f91611ce2f",
"assets/assets/data/translations/urd-mahmoodulhassan.json": "f775b89b3efa72e1a846109094d43a4a",
"assets/assets/data/translations/urd-muhammadkaramsh.json": "ee5a5fc8357b512bd955c9cb35ddeeb6",
"assets/assets/data/translations/ben-abubakrzakaria.json": "afc32d5a5a8b92a125df5a8db8058430",
"assets/assets/data/translations/urd-muhammadtahirul.json": "60ca432f1d641f322a8237183dd6fc2f",
"assets/assets/data/surah_93.json": "d9d46cc94ca4f4882c795323ff680e74",
"assets/assets/data/surah_114.json": "5aeb5d89b1def162911701e94091575d",
"assets/assets/data/surah_31.json": "90f9a69816842549f10111b6bdab8ed3",
"assets/assets/data/surahs.json": "a745dcf4dc4385f6347713d637578565",
"assets/assets/data/surah_66.json": "0ec76b65e76af214bcb6eb107c3a6bc5",
"assets/assets/data/surah_89.json": "0819656055fc25eb9d25a4e3cef60967",
"assets/assets/data/surah_70.json": "0300e8fd09c1a23ef0577cfeaf5a49cd",
"assets/assets/data/surah_27.json": "7cec7a89752d761480236da32440f2d0",
"assets/assets/data/surah_102.json": "b3f936122a9c814e85c224f177f2054d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
