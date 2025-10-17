'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "983e8ce70d4f541961651e121841a3a9",
"assets/AssetManifest.bin.json": "e6d9558d7b4f929be3420764a71a2492",
"assets/AssetManifest.json": "f7cc347bcfd1d49f976d498c79c4a920",
"assets/assets/data/surahs.json": "414c418aaca9e85a212febb1e718faad",
"assets/assets/data/surah_1.json": "03268c8ce7cd2688e0a749b13a5cb294",
"assets/assets/data/surah_10.json": "3b04601b3be6e125b1fcdbddb96370d1",
"assets/assets/data/surah_100.json": "1f8b22dea30689ea5aae5a00d113df7c",
"assets/assets/data/surah_101.json": "2dd4ab2bfb4b63113ea613859922d185",
"assets/assets/data/surah_102.json": "5a37b93ef6d471b95143ffa715c3a52a",
"assets/assets/data/surah_103.json": "caadb2a531caaab8f460896c8bb88ad6",
"assets/assets/data/surah_104.json": "58a241accbd86aa7e681dfed813b4f00",
"assets/assets/data/surah_105.json": "819a36f88e9503431c8957f7a203fb0e",
"assets/assets/data/surah_106.json": "986eb5348d6ad8e44ab32ce7a286c28a",
"assets/assets/data/surah_107.json": "68ff828b40d6de3c5513cc136d6369ca",
"assets/assets/data/surah_108.json": "04afb24e2e319eabbac8b9a6841c7c66",
"assets/assets/data/surah_109.json": "b8140dbc16db5fe7edeb73feffdd1c74",
"assets/assets/data/surah_11.json": "e1eb0ccbea635bf7e51f3b5194f1c7f5",
"assets/assets/data/surah_110.json": "cc2c9f7ac0cfebd5d8b8c9e1b054a618",
"assets/assets/data/surah_111.json": "9d5e940c14deab020ce7dedaf6d40e68",
"assets/assets/data/surah_112.json": "105fc04ef130f0172d40872cde238f5d",
"assets/assets/data/surah_113.json": "7b04aef9110756a5ec885a0a74de5e84",
"assets/assets/data/surah_114.json": "b4e08129716dbed7fd97c5d1d8fd3da9",
"assets/assets/data/surah_12.json": "fcef8b382e440b077bbbe7472fc52cb5",
"assets/assets/data/surah_13.json": "6f53a45c3dd5f5fd4acd95726fc7bd44",
"assets/assets/data/surah_14.json": "f20cf2f2593a08a9df65871cc71949c8",
"assets/assets/data/surah_15.json": "66ecdfc3d029e0da5b5a258c1b5e13f3",
"assets/assets/data/surah_16.json": "33af453d033184955e2fe357ad8db65d",
"assets/assets/data/surah_17.json": "24f4295099acf25ec9192d29bb054b4e",
"assets/assets/data/surah_18.json": "7bed2be27dab2dc7e44469ed65dba907",
"assets/assets/data/surah_19.json": "42359830658831f9c9b2d68eb263a68c",
"assets/assets/data/surah_2.json": "4eb5a31144282ad6fb2536a5ae1c54b3",
"assets/assets/data/surah_20.json": "45323d3d976368fe0c24b28d6e1c7942",
"assets/assets/data/surah_21.json": "d921ca09ce3494bcc440ad737b0b6c54",
"assets/assets/data/surah_22.json": "21579a48f7d28aaee816f2bbcadb5038",
"assets/assets/data/surah_23.json": "e43b3a58b90c42a658510ffc0f818ed7",
"assets/assets/data/surah_24.json": "0a6cd2f8d234474d620c68f2b39161a1",
"assets/assets/data/surah_25.json": "41af723de75380ec9591aac8e1429fdc",
"assets/assets/data/surah_26.json": "5f45aa3036d677b6ae9fce7eec01bcef",
"assets/assets/data/surah_27.json": "c80599620ba9f12d039d580cfb75b1d4",
"assets/assets/data/surah_28.json": "8d93842004d032b7d8d83fe91f528227",
"assets/assets/data/surah_29.json": "58fb89bc6b87f50374210195624ffa76",
"assets/assets/data/surah_3.json": "5bf4be77512223a4bdbaeae85dccc196",
"assets/assets/data/surah_30.json": "327c232cab9b9eee7515c1ac460e8f6a",
"assets/assets/data/surah_31.json": "2925e33938d9616f23b8ea9078e54d4c",
"assets/assets/data/surah_32.json": "a9a8d532f37ab1a77e5359c69dc80b5f",
"assets/assets/data/surah_33.json": "49be710a211e21eef7d7e82c9fc5026f",
"assets/assets/data/surah_34.json": "65d79029dc75bf91208805d4834f584c",
"assets/assets/data/surah_35.json": "f573ee4232bd6723f0a3bb018cdc61b5",
"assets/assets/data/surah_36.json": "216d5ae1f86fabff747302bb4bcf9bf2",
"assets/assets/data/surah_37.json": "33bd52cb6e5b14ce1d87df476e60c397",
"assets/assets/data/surah_38.json": "559fb0e5f9fac859ad3afbebde3eeffd",
"assets/assets/data/surah_39.json": "b9d67235e71ff44f3961c083bbfcf9db",
"assets/assets/data/surah_4.json": "31d24d2dda959bc680c6901f13590466",
"assets/assets/data/surah_40.json": "e7e5f3b1d729a362829d8ffeb06e8313",
"assets/assets/data/surah_41.json": "2fef6b854dcfd089547329b59b6a9ef8",
"assets/assets/data/surah_42.json": "de9f136a6e9ea007c484cde1caa1bbda",
"assets/assets/data/surah_43.json": "c46d42b6a1386c2d71872e86fe5113ae",
"assets/assets/data/surah_44.json": "7c0b53ceb7d1dcd2a321567bf263d831",
"assets/assets/data/surah_45.json": "0948f701a9b2fd281e4402e58b4036d6",
"assets/assets/data/surah_46.json": "5209f9f5e021bcb8cc3635bfc9ebf4d1",
"assets/assets/data/surah_47.json": "b7b81a03e3932b05a9ba9eea33bccb1e",
"assets/assets/data/surah_48.json": "bd74997eb40d1c0218c3aab2d193e1e2",
"assets/assets/data/surah_49.json": "9c03140f75af0da07cb5f0188da28beb",
"assets/assets/data/surah_5.json": "23b6e6ac20aa3c56ba29ca87384a4689",
"assets/assets/data/surah_50.json": "f8dd96db7df58194d0704813707ecdd6",
"assets/assets/data/surah_51.json": "9ff97cac795dcda8b61d841a3160ad20",
"assets/assets/data/surah_52.json": "7eb4230318adfe1e3db1aa7964712ab6",
"assets/assets/data/surah_53.json": "6133f7f32c9baf8d0ec65816779bafdb",
"assets/assets/data/surah_54.json": "9afaa0ffea4e2df568370086e32dc13b",
"assets/assets/data/surah_55.json": "1cd3a73173112c2ee37c129651410c9a",
"assets/assets/data/surah_56.json": "f4f9e13a6fabb514908011963e41efa0",
"assets/assets/data/surah_57.json": "f90f417f78d1f4c61f904a5832df4002",
"assets/assets/data/surah_58.json": "5f485f3ff6244629ef4ee75669b6eb21",
"assets/assets/data/surah_59.json": "1c25fc934344e4ee2c2f36cad2e4a19f",
"assets/assets/data/surah_6.json": "ffd10986b48fff37e50e63af9f8f34a9",
"assets/assets/data/surah_60.json": "786a7e056162305f636391431ad4219d",
"assets/assets/data/surah_61.json": "ebdd15952132a1f40ae082610bd79163",
"assets/assets/data/surah_62.json": "96c9317cc6e1df85a1a1f5214b34911b",
"assets/assets/data/surah_63.json": "4db222ed141a4130c08af08b91ef926b",
"assets/assets/data/surah_64.json": "626a172c516cb71ede8376d6b427921e",
"assets/assets/data/surah_65.json": "4cd462e0fd57ba4942ac621d7a51b9d3",
"assets/assets/data/surah_66.json": "a7ae8f1e2de5163cd1795ed5056071f9",
"assets/assets/data/surah_67.json": "bdbdb43b31b0ad2ae334ee0000d4fa1f",
"assets/assets/data/surah_68.json": "275c14d68977c744dbdaee9dd7971b59",
"assets/assets/data/surah_69.json": "110947e08928d4463ebdfc00d46b21e1",
"assets/assets/data/surah_7.json": "59e2d3244f8e2907a8c644c85cf13403",
"assets/assets/data/surah_70.json": "f69c51aaa38dcf03bf0e112bbf41a6d7",
"assets/assets/data/surah_71.json": "417e8efc9605f00da15cc6a7d54bab18",
"assets/assets/data/surah_72.json": "7beab99bde39466a06a1f3f8d3991b68",
"assets/assets/data/surah_73.json": "611b22db10f2dd3e6632a418a5b00fe4",
"assets/assets/data/surah_74.json": "5eba1cd191c4cbeb18c7d61954e0d433",
"assets/assets/data/surah_75.json": "6880c6dce984dc1bc631c88dd4abc37e",
"assets/assets/data/surah_76.json": "9d758e492c90129a8995ec91696373e6",
"assets/assets/data/surah_77.json": "243eb2b9c82fc74401976fa44c04896a",
"assets/assets/data/surah_78.json": "1a8dcc9d4b072b07899735399696e5f0",
"assets/assets/data/surah_79.json": "d80fc4199e5bf9490387310af4cbb9ad",
"assets/assets/data/surah_8.json": "bf50faf87f17d8b97887e6220924544e",
"assets/assets/data/surah_80.json": "deef96f5241969ce31028f2e440487ce",
"assets/assets/data/surah_81.json": "fe7fa23f946b0bd5c1624ec1f4dd86f9",
"assets/assets/data/surah_82.json": "4d81965ba441eed43c3b694c938c6b14",
"assets/assets/data/surah_83.json": "5593ef06be724a1f7b5c728c47922616",
"assets/assets/data/surah_84.json": "025d8b4242d982dae3dc385b7634d8f4",
"assets/assets/data/surah_85.json": "7052ab20bef262e66cb408188dba196a",
"assets/assets/data/surah_86.json": "faafdba5a2dd98acb358cb3cc2055c76",
"assets/assets/data/surah_87.json": "622b5db3f13a353c3cfd36c543f5253f",
"assets/assets/data/surah_88.json": "29b164346e223c2bf1bf94c0e9b82111",
"assets/assets/data/surah_89.json": "b43e0e53f4fdd72e96e760fb3195af47",
"assets/assets/data/surah_9.json": "1f296024dc7c04af331a2c2f6fb1d119",
"assets/assets/data/surah_90.json": "6bf2636f4f668b4f36f1a39f0fafe01c",
"assets/assets/data/surah_91.json": "5a7d3b957d34f63e92f622d6a8a866e5",
"assets/assets/data/surah_92.json": "dd5224edadf8273aab2d7974ac91c13c",
"assets/assets/data/surah_93.json": "280c1d21baf33b2b5a7551c3b568c0b3",
"assets/assets/data/surah_94.json": "37182e073be7a9a52fa7dcbf933d6a90",
"assets/assets/data/surah_95.json": "f0c627fcaab8cfbd058867e92256f11e",
"assets/assets/data/surah_96.json": "2f663923894aa1e1dfcb0422e77184be",
"assets/assets/data/surah_97.json": "623ab959e5622202824d7a33b80d9cb8",
"assets/assets/data/surah_98.json": "050f6522cd454ec88c461a86df0049cc",
"assets/assets/data/surah_99.json": "8f2e1e59275bc9b7010f21f8838ae6d5",
"assets/assets/data/version.txt": "c4ca4238a0b923820dcc509a6f75849b",
"assets/assets/fonts/indopak.ttf": "35701970dda795662a4a1bb7f740d387",
"assets/assets/icons/app_icon.png": "7033e2d8ea7a4221bee357a42e6f8312",
"assets/FontManifest.json": "53d157a169ceeaeb4963a0928d1c4466",
"assets/fonts/MaterialIcons-Regular.otf": "d6bc83d72d2d06df838f27fd74fa1496",
"assets/NOTICES": "4944a20821dd866f667f1dea9d645a1f",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "27afb026b414c43ee2e7b4e595c17c8f",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "42aec32132f089bd7e0717f680da9c12",
"/": "42aec32132f089bd7e0717f680da9c12",
"main.dart.js": "d78ba7d7982d58af1008794dd06eb818",
"manifest.json": "dbcaedbec00ce20e8e8926134f775724",
"spinner_animation.svg": "cb0391c2c8533a63998b9e94accf68f4",
"version.json": "14f9fcda440f740301db42689fa7188c"};
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
