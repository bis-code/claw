# Changelog

## [1.1.1](https://github.com/bis-code/claw/compare/v1.1.0...v1.1.1) (2026-01-07)


### Bug Fixes

* add bin/claw to release-please extra-files ([e96e5cc](https://github.com/bis-code/claw/commit/e96e5cc7a1f9a3f25e01fe70d70f7afe581fe5ea))
* combine release workflows for autonomous releases ([40de9af](https://github.com/bis-code/claw/commit/40de9afe5a914d69a86498fb513dc090514401e6))

## [1.1.0](https://github.com/bis-code/claw/compare/v1.0.1...v1.1.0) (2026-01-07)


### Features

* add --yolo flag to skip permission prompts ([#6](https://github.com/bis-code/claw/issues/6)) ([b0862c4](https://github.com/bis-code/claw/commit/b0862c4a9f93d661aa7a71ee713a69d770aa8025))
* add /summary skill for daily work tracking ([#7](https://github.com/bis-code/claw/issues/7)) ([eb58e5a](https://github.com/bis-code/claw/commit/eb58e5a2f514bf8506d7bf54e53c4028cdd4d76e))
* add GitHub issue templates command ([#5](https://github.com/bis-code/claw/issues/5)) ([ded1a5e](https://github.com/bis-code/claw/commit/ded1a5e3d9ce9c5447b21557e99b7243ea497671))


### Bug Fixes

* add LIB_DIR variable for homebrew compatibility ([003308e](https://github.com/bis-code/claw/commit/003308ed8f84a284581298c56575007af25b080c))

## [1.0.0](https://github.com/bis-code/claw/compare/v0.4.1...v1.0.0) (2026-01-07)


### ⚠ BREAKING CHANGES

* Claw is now an external orchestrator that wraps Claude Code instead of copying templates into projects.

### Features

* add brew install testing to release pipeline ([606720c](https://github.com/bis-code/claw/commit/606720cbc7863176f8d8fcceb5d7f9ada1f83d6d))
* add multi-repo tracking and simplify README ([19ac704](https://github.com/bis-code/claw/commit/19ac70425584334545bc68ed8b72a15fb4a55cfe))
* add TDD structure for autonomous execution ([c5bde7e](https://github.com/bis-code/claw/commit/c5bde7ec56d9b1820a931e06c9383d9547d53859))
* add teal startup banner with status info ([8ff3957](https://github.com/bis-code/claw/commit/8ff3957e00c22c155665543b3b5b3cf0d11199f8))
* add version tracking and smart upgrades ([2e46833](https://github.com/bis-code/claw/commit/2e46833b5f15f06c8ed070e4de30f59490422277))
* auto-create LEANN index on search if missing ([7cbc890](https://github.com/bis-code/claw/commit/7cbc8902f34979f2ff367a43f786830d15052cff))
* auto-install leann MCP on first run with progress display ([f4df078](https://github.com/bis-code/claw/commit/f4df07894ede58452dd97e7960eb10bcd7abbd3e))
* auto-install LEANN on claw leann build ([d639ead](https://github.com/bis-code/claw/commit/d639ead6bbda1cb8d568f44be53cb1fbaedb1555))
* **autonomous:** complete autonomous execution system with 66 passing tests ([38660aa](https://github.com/bis-code/claw/commit/38660aa0e05a549c323e53435c961031bec015d6))
* external orchestrator architecture (breaking change) ([6d78726](https://github.com/bis-code/claw/commit/6d7872615e56296cbdfdcde901347f364ebe35e6))
* improve multi-repo detection with smarter strategies ([73aa4ee](https://github.com/bis-code/claw/commit/73aa4ee4edf9a12d3d60629ab2e18ac114a6f88f))
* **monitor:** add live status dashboard and automatic versioning ([7adf708](https://github.com/bis-code/claw/commit/7adf70884ae53586f576aa124c8c6fd87bbd23c2))


### Bug Fixes

* align banner columns and fix ANSI color rendering ([56660af](https://github.com/bis-code/claw/commit/56660af17e79c9aa26b68b4c095f76341368ac56))
* align success banner box borders ([7a30347](https://github.com/bis-code/claw/commit/7a30347ad0b8aec77ba9566ed600813abb6891c8))
* **claw:** respect CLAUDE_HOME environment variable ([157bad7](https://github.com/bis-code/claw/commit/157bad7e22f2e4615959744684f9463952c67a1c))
* **home:** handle empty rules array with set -u ([13fe1d0](https://github.com/bis-code/claw/commit/13fe1d03b153ee5bb355e3bc1851a1c6e52e27bc))
* index_exists now handles leann list emoji formatting ([cce15a2](https://github.com/bis-code/claw/commit/cce15a2212589205624635790a0f16a16d9582e8))
* leann_status always returns 0 ([6dfb940](https://github.com/bis-code/claw/commit/6dfb940e3b55f4f26561e53aeb0614363e7a7473))
* **leann:** align success banner with dynamic padding ([503879e](https://github.com/bis-code/claw/commit/503879e29014fa51d8b35f97939a9e37aa562161))
* make install.sh portable for Linux and macOS ([1114c43](https://github.com/bis-code/claw/commit/1114c435c98867c8c06622192af9f005fdd07e12))
* remove obsolete claw agents CLI tests ([9e153fb](https://github.com/bis-code/claw/commit/9e153fb7227d2e76d0b33de3349f495e21073f96))
* **tests:** add mock claude and skip leann in CI tests ([34ef33b](https://github.com/bis-code/claw/commit/34ef33b254f4e26751c78c9d670d0a3ba6bcb2fb))
* **tests:** remove obsolete CLI command tests ([b8d5213](https://github.com/bis-code/claw/commit/b8d52135dcc51f1c3c5948f3283e346086b01dd8))
* **tests:** skip flaky blocker test on macOS ([0d0f96e](https://github.com/bis-code/claw/commit/0d0f96e48a17c431b237a530a47b2c2ce2a84761))
* update integration tests for simplified claw architecture ([7d73caa](https://github.com/bis-code/claw/commit/7d73caa57bf0ba6785793300d06cba6b66053bca))
* update LIB_DIR and TEMPLATES_DIR paths during install ([58d9817](https://github.com/bis-code/claw/commit/58d98172ba1de1082a27f1e8ec0d4c6ac2641ff0))
* update test files for simplified claw architecture ([d192bf2](https://github.com/bis-code/claw/commit/d192bf2234aad59499a81f29f817d7465d46c3a9))
* use ANSI-C quoting for color codes in banner ([55830ff](https://github.com/bis-code/claw/commit/55830ffe6e35cb93f3887a8b426670a1c034e61c))
* use Bash 3.x compatible preset rules ([85d43cf](https://github.com/bis-code/claw/commit/85d43cff48c80be60d933482d1618a67e8d26565))

## [1.0.0](https://github.com/bis-code/claw/compare/v0.5.0...v1.0.0) (2026-01-06)


### ⚠ BREAKING CHANGES

* Claw is now an external orchestrator that wraps Claude Code instead of copying templates into projects.

### Features

* add multi-repo tracking and simplify README ([5dac781](https://github.com/bis-code/claw/commit/5dac7816a68b791de57d69b38860f4562c81a88f))
* add teal startup banner with status info ([d8da42e](https://github.com/bis-code/claw/commit/d8da42e2796be4a2c7dd5fa671924218c7960153))
* external orchestrator architecture (breaking change) ([98ec489](https://github.com/bis-code/claw/commit/98ec48920fa8b91d21d022d3de86fde5a0585438))
* **monitor:** add live status dashboard and automatic versioning ([e4469f3](https://github.com/bis-code/claw/commit/e4469f328acc04643b7d49c055a616a72a585c2a))


### Bug Fixes

* align banner columns and fix ANSI color rendering ([27b94e5](https://github.com/bis-code/claw/commit/27b94e5ca9d2dd59c7b5cc8e88e1daf5280771e7))
* remove obsolete claw agents CLI tests ([d44554e](https://github.com/bis-code/claw/commit/d44554e81679042cbd060e58acc41477380aa5d2))
* update integration tests for simplified claw architecture ([320c725](https://github.com/bis-code/claw/commit/320c725facfdfb8cfeee0a1a10576cba2a8b1817))
* update test files for simplified claw architecture ([e897d7f](https://github.com/bis-code/claw/commit/e897d7ff3689883be823193ab04aba78f512decb))
* use ANSI-C quoting for color codes in banner ([c7dacdf](https://github.com/bis-code/claw/commit/c7dacdfc31cf0b0470d5314d1bd178a9683e4fc4))
