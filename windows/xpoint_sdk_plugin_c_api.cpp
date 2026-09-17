#include "include/xpoint_sdk/xpoint_sdk_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "xpoint_sdk_plugin.h"

void XpointSdkPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  xpoint_sdk::XpointSdkPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
