# Changelog
All notable changes to this project will be documented in this file. See [conventional commits](https://www.conventionalcommits.org/) for commit guidelines.

- - -
## 0.5.10 - 2025-01-31
#### Bug Fixes
- system_libs is now properly being created in recipes - (f935f75) - Ezekiel Warren
#### Miscellaneous Chores
- **(deps)** update dependency ecsact_cli to v0.3.22 (#73) - (5990b9c) - renovate[bot]
- **(deps)** update dependency ecsact_cli to v0.3.21 (#72) - (b0a4e4d) - renovate[bot]

- - -

## 0.5.9 - 2024-11-30
#### Bug Fixes
- use preferred and interface lib for extensions - (b9cc274) - Kelwan
#### Features
- Tracy (#71) - (eebb5fb) - Austin Kelway
#### Miscellaneous Chores
- **(deps)** update dependency ecsact_cli to v0.3.19 (#70) - (902da1c) - renovate[bot]
- **(deps)** update dependency ecsact_cli to v0.3.17 (#69) - (53493d5) - renovate[bot]

- - -

## 0.5.8 - 2024-09-23
#### Features
- add system libs support to build recipe rule (#68) - (cdbca4e) - Ezekiel Warren
- better cc dep support on Windows (#67) - (b11471a) - Ezekiel Warren
- allow adding cc deps to recipe rule (#65) - (4f9b35e) - Ezekiel Warren

- - -

## 0.5.7 - 2024-08-26
#### Features
- Allow explicit file outputs vs extensions in codegen rule (#64) - (1cba698) - Austin Kelway
#### Miscellaneous Chores
- **(deps)** update dependency ecsact_cli to v0.3.16 (#63) - (1303f78) - renovate[bot]

- - -

## 0.5.6 - 2024-08-09
#### Features
- new ecsact_binary attr to allow unresolved imports (#62) - (ca7f1b1) - Ezekiel Warren
- recipe bundles now provide recipe info (#61) - (c6e02b5) - Ezekiel Warren
#### Miscellaneous Chores
- **(deps)** update dependency ecsact_cli to v0.3.15 (#60) - (ae1f5f0) - renovate[bot]
- **(deps)** update dependency ecsact_cli to v0.3.14 (#58) - (9f91544) - renovate[bot]
- update readme logo - (9b072b9) - Ezekiel Warren

- - -

## 0.5.5 - 2024-07-03
#### Bug Fixes
- allow host environment variables in recipe bundle rule (#57) - (c947eb9) - Ezekiel Warren

- - -

## 0.5.3 - 2024-07-02
#### Bug Fixes
- add missing recipe data to bundle rule - (ab0b3c0) - Ezekiel Warren
- remove debug print - (459fff3) - Ezekiel Warren
#### Features
- add rules for recipe bundles (#56) - (6afde02) - Austin Kelway
- support ecsact_cli --debug flag (#54) - (6aacd8b) - Ezekiel Warren
#### Miscellaneous Chores
- **(deps)** update ecsact repositories (#55) - (a8dd8a3) - renovate[bot]
- ignore bazel lock files - (fdea8b0) - Ezekiel Warren
- add curl registry override - (0663960) - Ezekiel Warren
- add curl registry override - (7929f24) - Ezekiel Warren

- - -

## 0.5.2 - 2024-05-15
#### Features
- ecsact_binary provides CcInfo (#53) - (5de3cb1) - Ezekiel Warren

- - -

## 0.5.1 - 2024-04-22
#### Bug Fixes
- **(bazel)** target exec for ecsact_cli tool (#47) - (e3fb7d2) - Ezekiel Warren
#### Miscellaneous Chores
- **(deps)** update dependency ecsact_cli to v0.3.4 (#46) - (da52101) - renovate[bot]

- - -

## 0.5.0 - 2024-04-04
#### Features
- configurable ecsact build report filter (#45) - (1f8fd04) - Ezekiel Warren
- new toolchain bzlmod extension (#43) - (f4ec81e) - Ezekiel Warren
#### Miscellaneous Chores
- **(deps)** update dependency ecsact_cli to v0.3.2 (#44) - (7447686) - renovate[bot]
- **(deps)** update dependency bazel to v7.1.1 (#42) - (1f4bf3f) - renovate[bot]

- - -

## 0.4.9 - 2024-03-14
#### Bug Fixes
- treat plugin as string not path - (241d709) - Ezekiel Warren

- - -

## 0.4.8 - 2024-03-13
#### Bug Fixes
- dont declare folder same name as target (#41) - (d9aafaf) - Ezekiel Warren
#### Miscellaneous Chores
- bzlmod updates - (3787dd2) - Ezekiel Warren

- - -

## 0.4.7 - 2023-10-24
#### Bug Fixes
- add missing plugin to recipe data (#34) - (9bede79) - Ezekiel Warren

- - -

## 0.4.6 - 2023-10-23
#### Bug Fixes
- error with codegen plugin path (#33) - (d717cb1) - Ezekiel Warren
#### Miscellaneous Chores
- **(deps)** update dependency bazel to v6.4.0 (#32) - (1836a0b) - renovate[bot]

- - -

## 0.4.5 - 2023-10-06
#### Bug Fixes
- add missing C++ runfiles for ecsact_binary (#31) - (be6a6d0) - Ezekiel Warren

- - -

## 0.4.4 - 2023-10-05
#### Bug Fixes
- remove hard coded .dll extension (#30) - (e085741) - Ezekiel Warren

- - -

## 0.4.3 - 2023-10-05
#### Features
- ecsact_binary and ecsact_library (#29) - (227d9d0) - Ezekiel Warren

- - -

## 0.4.2 - 2023-09-21
#### Bug Fixes
- target tool path was incorrect (#28) - (f5d3e50) - Ezekiel Warren

- - -

## 0.4.1 - 2023-09-21
#### Features
- allow plugin binary label (#27) - (2be7c29) - Ezekiel Warren
#### Miscellaneous Chores
- add windows test (#25) - (770124c) - Ezekiel Warren

- - -

## 0.4.0 - 2023-09-19
#### Features
- bzlmodify rules_ecsact (#24) - (c994774) - Ezekiel Warren
#### Miscellaneous Chores
- **(deps)** update dependency io_bazel_rules_go to v0.41.0 (#2) - (b32f5f6) - renovate[bot]
- **(deps)** update build_bazel_integration_testing digest to 7d3e9ae (#8) - (b797e4c) - renovate[bot]
- **(deps)** update dependency io_bazel_stardoc to v0.5.6 (#7) - (f008f96) - renovate[bot]
- **(deps)** update dependency bazel to v6.3.0 (#16) - (4ac4ef5) - renovate[bot]
- add cog.toml - (b887ba0) - Ezekiel Warren
- auto create bzlmod archive - (f21647f) - Ezekiel Warren

- - -

Changelog generated by [cocogitto](https://github.com/cocogitto/cocogitto).