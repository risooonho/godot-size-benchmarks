# Copyright © 2019 Hugo Locurcio and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.

import os
import osproc
import strformat
import terminal
import cligen

# SCons flags to use for all builds
let sconsFlagsAll = [
  "tools=no",
  "target=release",
  "progress=no",
  "debug_symbols=no",
  "use_lto=yes",
  &"-j{countProcessors() + 1}",
]

# Additional SCons flags to use for each build
const sconsFlagsExtra = {
  "full": @[],

  "micro": @[
    "disable_advanced_gui=yes",
    "module_bmp_enabled=no",
    "module_bullet_enabled=no",
    "module_dds_enabled=no",
    "module_enet_enabled=no",
    "module_etc_enabled=no",
    "module_gdnative_enabled=no",
    "module_hdr_enabled=no",
    "module_mobile_vr_enabled=no",
    "module_pvr_enabled=no",
    "module_regex_enabled=no",
    "module_squish_enabled=no",
    "module_tga_enabled=no",
    "module_thekla_unwrap_enabled=no",
    "module_tinyexr_enabled=no",
    "module_websocket_enabled=no",
  ],

  "pico": @[
    "optimize=size",
    "disable_advanced_gui=yes",
    "module_bmp_enabled=no",
    "module_bullet_enabled=no",
    "module_csg_enabled=no",
    "module_dds_enabled=no",
    "module_enet_enabled=no",
    "module_etc_enabled=no",
    "module_gdnative_enabled=no",
    "module_gridmap_enabled=no",
    "module_hdr_enabled=no",
    "module_mbedtls_enabled=no",
    "module_mobile_vr_enabled=no",
    "module_opus_enabled=no",
    "module_pvr_enabled=no",
    "module_recast_enabled=no",
    "module_regex_enabled=no",
    "module_squish_enabled=no",
    "module_tga_enabled=no",
    "module_thekla_unwrap_enabled=no",
    "module_theora_enabled=no",
    "module_tinyexr_enabled=no",
    "module_vorbis_enabled=no",
    "module_webm_enabled=no",
    "module_websocket_enabled=no",
  ],
}

# Flags to use for 2D-only builds
const sconsFlags2d = [
  "disable_3d=yes",
]

proc main() =
  for buildName, extraSconsFlags in sconsFlagsExtra.items:
    for platform in ["android", "javascript", "x11", "windows"]:
      for is2dBuild in [false, true]:
        let flags2d =
          if is2dBuild: @sconsFlags2d
          else: @[]

        let extraSuffix =
          if is2dBuild: &"{buildName}_2d"
          else: buildName

        let sconsFlags =
          @[&"platform={platform}", &"extra_suffix={extraSuffix}"] &
          @sconsFlagsAll &
          extraSconsFlags &
          flags2d

        styledEcho(
          "Building for ",
          styleBright,
          fgCyan,
          platform,
          resetStyle,
          " (",
          styleBright,
          extraSuffix,
          resetStyle,
          ")…",
        )

        echo execProcess(
          "scons",
          "godot",
          sconsFlags,
          nil,
          {poUsePath, poStdErrToStdOut}
        )

        if platform == "android":
          echo execProcess(
            "./gradlew",
            "godot/platform/android/java",
            ["build"],
            nil,
            {poUsePath, poStdErrToStdOut}
          )

          # Rename the generated APK to contain the extra prefix as it's
          # not done automatically by Gradle
          moveFile(
            "godot/bin/android_release.apk",
            &"godot/bin/android_release.{extraSuffix}.apk"
          )

  # Strip binaries of any remaining debug symbols
  for file in walkFiles("godot/bin/*"):
    echo execProcess(
      "strip",
      "",
      [file],
      nil,
      {poUsePath, poStdErrToStdOut}
    )

when isMainModule:
  dispatch(main)
  system.addQuitProc(resetAttributes)
