#include "include/wns_flutter/wns_flutter_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "wns_flutter_plugin.h"

void WnsFlutterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  wns_flutter::WnsFlutterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
