'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "56ccf9063c6f5382c089a10cdb8e170c",
"version.json": "14f9fcda440f740301db42689fa7188c",
"index.html": "388a0f2620adc8bf72b69bc3d360e0af",
"/": "388a0f2620adc8bf72b69bc3d360e0af",
"main.dart.js": "ac85991d709ca4c49300e510cc1bd179",
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
"assets/AssetManifest.bin.json": "e6d9558d7b4f929be3420764a71a2492",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "983e8ce70d4f541961651e121841a3a9",
"assets/fonts/MaterialIcons-Regular.otf": "d6bc83d72d2d06df838f27fd74fa1496",
"assets/assets/icons/app_icon.png": "7033e2d8ea7a4221bee357a42e6f8312",
"assets/assets/fonts/indopak.ttf": "35701970dda795662a4a1bb7f740d387",
"assets/assets/data/surah_49.json": "278a433524b7e10ccf6283e66bd3e17c",
"assets/assets/data/surah_3.json": "d8b45166571fdeadfccf8fdc1069347a",
"assets/assets/data/surah_32.json": "4144729864a7a1f5d318c193c22e3d81",
"assets/assets/data/surah_65.json": "3290978d797bc2ca49a1a3a7d48cb895",
"assets/assets/data/surah_73.json": "e242bee3e807ddb1fbc749fab2d938ba",
"assets/assets/data/surah_24.json": "48afd9ec626801edfa9cc4bb7e4f7b28",
"assets/assets/data/surah_101.json": "4fd16599f40757662d7bf1bfe86ec199",
"assets/assets/data/surah_53.json": "7b288b65894e51d479e1b02144bd956c",
"assets/assets/data/surah_12.json": "b2c57f7273376c8b4bc23b1759edaf21",
"assets/assets/data/surah_45.json": "592be63a9a34603cf042c62f930004c4",
"assets/assets/data/surah_86.json": "bb8fdcc4adadee78a901e66b304454a4",
"assets/assets/data/surah_69.json": "4c0a96a3a015f24e8daf814a22de28c8",
"assets/assets/data/surah_90.json": "f6abb997a7c2618fc778d50039f9142d",
"assets/assets/data/surah_28.json": "771856b9dc1feaae50505d34b99e7f3d",
"assets/assets/data/surah_29.json": "9a2081d77e0429197700fcd3beb6db81",
"assets/assets/data/surah_91.json": "eaf5717b685c9c09addee7877aaee440",
"assets/assets/data/surah_87.json": "e55ced41f0ee1fbdb004c52fc418a3ce",
"assets/assets/data/surah_68.json": "3ec23d3ee1547d4304527b8c3b80f533",
"assets/assets/data/surah_44.json": "24a98237ec579991186bcf69c27ef748",
"assets/assets/data/surah_13.json": "5e73240690331fd386169bfa4912dd25",
"assets/assets/data/surah_52.json": "a42f7beb40af72c5f4275e1a00bb648a",
"assets/assets/data/surah_25.json": "1ab08e9aab8590880684ba545594c160",
"assets/assets/data/surah_100.json": "72f987620942b7ddc29d7b494dd0d125",
"assets/assets/data/surah_72.json": "48ada0234b3c7c152e43824f4cc95478",
"assets/assets/data/surah_64.json": "d38b2b23b09544935aa3c6d787d1622c",
"assets/assets/data/surah_33.json": "442e93ebc67be6c2ebb8095f20730ef0",
"assets/assets/data/surah_2.json": "4e03bd9bd56401bc1f5a3dbd9e417e9d",
"assets/assets/data/surah_48.json": "ffe92ac234afe3a57a1e55cb3d9f6e92",
"assets/assets/data/surah_55.json": "b77aa5b596b28ed81df78f739e81c458",
"assets/assets/data/surah_14.json": "1fe8ba87cc18a1eca153fa09af196664",
"assets/assets/data/surah_43.json": "045ce4ed9ea7d73e064e63c5d2b9d0dc",
"assets/assets/data/surah_38.json": "afedc98d8b25a39fcd195b7e120bb66a",
"assets/assets/data/surah_9.json": "2fc68a228ffa68b597c3c6a18e4ad1d5",
"assets/assets/data/surah_80.json": "1cd3f65e9b533252322485dbea138fbe",
"assets/assets/data/surah_96.json": "124e24fb20ba11d6f0d8b47a1c131abf",
"assets/assets/data/surah_79.json": "9a798e9fea4dd0e3af40686080dfd3fa",
"assets/assets/data/surah_59.json": "53d8e65d50a9e63705409ffcbdabdd2e",
"assets/assets/data/surah_18.json": "189f4887e0f5a8c24833b952b50ed357",
"assets/assets/data/surah_5.json": "e38469983331b3f246eef65c6938db08",
"assets/assets/data/surah_111.json": "8ad0cfd2994346a189f1f8148d3703a9",
"assets/assets/data/surah_34.json": "a9f1fbbf3998b82541b88fdf14c1a2f1",
"assets/assets/data/surah_63.json": "54bbd352290f44e4824696b757000371",
"assets/assets/data/surah_75.json": "350f108860ed7e5da83e18786734c455",
"assets/assets/data/surah_22.json": "e4784285832435443835e62a41ab6f24",
"assets/assets/data/surah_107.json": "9486dadaf5f62cfba13301b7ad7d4daa",
"assets/assets/data/surah_23.json": "1f9163491bf72c59fb53712af57d544f",
"assets/assets/data/surah_106.json": "6f3b3122552fdb9b2743869aa1710648",
"assets/assets/data/surah_74.json": "96d34978e977b1e1e336ddd270d54377",
"assets/assets/data/surah_62.json": "14d48ca3d36969ec4e45bce99813ba9d",
"assets/assets/data/surah_110.json": "2b133ab0317e2fddb2d02de91722e383",
"assets/assets/data/surah_35.json": "681816235f8ee8310136891f86f25993",
"assets/assets/data/surah_4.json": "9674d38959dd8e2c06a4ad36261a9293",
"assets/assets/data/surah_19.json": "2d15e936021d11d4a1d2dc6e3f22c47d",
"assets/assets/data/surah_58.json": "a9eb9209e4456cca6a0b9a1ef60e72fc",
"assets/assets/data/surah_97.json": "80f53b3e4454dea6b397a6c8198e2e5e",
"assets/assets/data/surah_78.json": "f3f9e91953c1b0a38ba024af77bc183a",
"assets/assets/data/surah_81.json": "ba2ef3f4a1337ac501012da2cd2e8b6c",
"assets/assets/data/surah_8.json": "1c41d44ab511efcc963490d00bcfbe05",
"assets/assets/data/surah_39.json": "0fc2cec408ca2155540b7a77df1f00f0",
"assets/assets/data/surah_42.json": "a2caf16cf646afe731b41b1a300fdbaa",
"assets/assets/data/surah_15.json": "8d5be8e7d56042e69d4104fb43363f60",
"assets/assets/data/surah_54.json": "738c94e2e72882f83a6399dedf87e0ff",
"assets/assets/data/surah_109.json": "c018ef0133c12208666d1874dd9db2dc",
"assets/assets/data/surah_94.json": "9143f6becc4b4d3a7eb8b3ab003f9b50",
"assets/assets/data/surah_82.json": "ed09247da75b9f79f8822de75dfbaf09",
"assets/assets/data/surah_41.json": "d284a7237d00490cf4711d0c6ff2094b",
"assets/assets/data/surah_16.json": "5bd20f0e06aa60fe33a9b360c619650f",
"assets/assets/data/surah_57.json": "d0e6310b1966077f51793ff40f5955d0",
"assets/assets/data/surah_20.json": "30f5633f4019fed260de59368c05202e",
"assets/assets/data/surah_105.json": "1555aada8c4651ac6e9801d1b0ce6001",
"assets/assets/data/surah_77.json": "ab6c5f153a948c8dd698a9228956ecc1",
"assets/assets/data/surah_98.json": "5477f4826353ce1a2914a30bad992a48",
"assets/assets/data/surah_61.json": "3168b1d35d5ded0f07303095602563bc",
"assets/assets/data/surah_113.json": "d5eb3fbf46e6d576f54beaf3d44d98fd",
"assets/assets/data/surah_36.json": "09b2067e8c31d5391ec2b6432aadbf48",
"assets/assets/data/surah_7.json": "8271063339cfc7bce6bb862e96951eaa",
"assets/assets/data/surah_6.json": "4aed3afe455aab4741365c0549e73008",
"assets/assets/data/surah_112.json": "1347fa65ce7d5131afb7c22520fe990f",
"assets/assets/data/surah_37.json": "3625fcc8cd049351141034136e16a441",
"assets/assets/data/surah_60.json": "5654f327e353acb9e119f6c0bb601fc6",
"assets/assets/data/surah_76.json": "7a852ee33678ea57d74ddf3392922d95",
"assets/assets/data/surah_99.json": "1207e612433e9201ee9ab183a38a07fa",
"assets/assets/data/surah_21.json": "e579a85be4318e9f0fa34a025d38bc45",
"assets/assets/data/surah_104.json": "e544871fa425013679c2212a1ee2326b",
"assets/assets/data/surah_56.json": "322dd4338c686d6f9b5f4a86a502e38f",
"assets/assets/data/surah_17.json": "a34cb47895c0fc4c7bf2ce238c241e84",
"assets/assets/data/surah_40.json": "6ba123f479a02509556c15ca3cad8138",
"assets/assets/data/surah_83.json": "30db8ee539f7332e8582d1603ffa0570",
"assets/assets/data/surah_95.json": "472c8273a30c0dbba77acac45a7cb2e1",
"assets/assets/data/surah_108.json": "fcebe452a5a326da564c9f314a524160",
"assets/assets/data/surah_26.json": "3bdac4d8390518317a6fbeec194ca9db",
"assets/assets/data/surah_103.json": "fbcda88811e3ebd25b7e5b62a41c39b6",
"assets/assets/data/surah_71.json": "43f1e9d612e9c8168d3a12ba64a843d4",
"assets/assets/data/surah_67.json": "7e29dfb91bdbee27bec41fdbdb91394a",
"assets/assets/data/surah_88.json": "76cef72f9e24729e541b7a9cb5558fa4",
"assets/assets/data/surah_30.json": "b3b5766c92d55cee4fbfa45629994b84",
"assets/assets/data/surah_1.json": "57c0a0ba82a6af4035c4a3290c0fd6d7",
"assets/assets/data/version.txt": "c4ca4238a0b923820dcc509a6f75849b",
"assets/assets/data/surah_92.json": "fac7cd42a6d792e6fff75b326a99c0c4",
"assets/assets/data/surah_84.json": "71d4ecef153e2721e9b46f4717a9bf7b",
"assets/assets/data/surah_47.json": "e0baf971bf4e9630816c8bb102ea2e67",
"assets/assets/data/surah_10.json": "5b31fd5bc9870b0e96d15958d063d30d",
"assets/assets/data/surah_51.json": "bc54341f7bd3da6ebe7baeae983f7854",
"assets/assets/data/surah_50.json": "3af50d2d24648dba122b054c7a69565b",
"assets/assets/data/surah_11.json": "3414b55002b0fab6cf718079a4e666df",
"assets/assets/data/surah_46.json": "0236363444c92d05dba6e9cada919dfc",
"assets/assets/data/surah_85.json": "6f26533a655b5c72e56244cd6aeb51a9",
"assets/assets/data/surah_93.json": "b62c2555ceee118bb8e34e55e5495959",
"assets/assets/data/surah_114.json": "b236704ab777b65c2a689d8a39553fb8",
"assets/assets/data/surah_31.json": "d44f6beeefdb6da1a363a780e94d8073",
"assets/assets/data/surahs.json": "a745dcf4dc4385f6347713d637578565",
"assets/assets/data/surah_66.json": "cf7d1d49022bce0d81969bc9272a5260",
"assets/assets/data/surah_89.json": "f665ca0196fbc95a40e51c540c739425",
"assets/assets/data/surah_70.json": "860ca5b5d9adadf2677a7a000d28609f",
"assets/assets/data/surah_27.json": "bd909fe4cec56f98c7375ca4261c4761",
"assets/assets/data/surah_102.json": "f427050f57ce3183904d39a915e11c5f",
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
