{{flutter_js}}
{{flutter_build_config}}

// Simple, optimized Flutter bootstrap
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    
    // Notify that the app is ready
    window.dispatchEvent(new Event('flutter-first-frame'));
  }
}); 