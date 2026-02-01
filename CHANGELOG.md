# Changelog

## [3.0.0](https://github.com/bis-code/claw/compare/v2.0.0...v3.0.0) (2026-02-01)


### ⚠ BREAKING CHANGES

* Claw is now an external orchestrator that wraps Claude Code instead of copying templates into projects.

### Features

* add --yolo flag to skip permission prompts ([#6](https://github.com/bis-code/claw/issues/6)) ([b0862c4](https://github.com/bis-code/claw/commit/b0862c4a9f93d661aa7a71ee713a69d770aa8025))
* add /benchmark-search command for measuring index efficiency ([c2241b1](https://github.com/bis-code/claw/commit/c2241b1a794de3723e8e8dcf63a9ab15e2075c82))
* add /index command and efficient-search rule ([3cac3dd](https://github.com/bis-code/claw/commit/3cac3ddf02a133afe966c4200c4738e48f3fb39a))
* add /search command for efficient codebase exploration ([82df43c](https://github.com/bis-code/claw/commit/82df43cacfd3e9d7497a95e6b46e2816983a7b3f))
* add /summary skill for daily work tracking ([#7](https://github.com/bis-code/claw/issues/7)) ([eb58e5a](https://github.com/bis-code/claw/commit/eb58e5a2f514bf8506d7bf54e53c4028cdd4d76e))
* add automated release workflow ([2ea79e6](https://github.com/bis-code/claw/commit/2ea79e6a38890538667d89fef86c051f3ef90134))
* add autonomous self-improvement system ([a3bd13f](https://github.com/bis-code/claw/commit/a3bd13fda787927081796be3890b44217cdeac00))
* add autonomous self-improvement with workflow generation ([57bb59e](https://github.com/bis-code/claw/commit/57bb59ebe0bf5c34fad6da6f241686608aa9de1a))
* add brainstorming agents for /agents command ([9ad8544](https://github.com/bis-code/claw/commit/9ad854411a976d260fb007b5698036d1620e26ce))
* add brew install testing to release pipeline ([606720c](https://github.com/bis-code/claw/commit/606720cbc7863176f8d8fcceb5d7f9ada1f83d6d))
* add GitHub issue templates command ([#5](https://github.com/bis-code/claw/issues/5)) ([ded1a5e](https://github.com/bis-code/claw/commit/ded1a5e3d9ce9c5447b21557e99b7243ea497671))
* add hook to detect stale project index ([11c6759](https://github.com/bis-code/claw/commit/11c6759d8c71c140cada4ccff4b22aadc8689e4c))
* add multi-repo tracking and simplify README ([19ac704](https://github.com/bis-code/claw/commit/19ac70425584334545bc68ed8b72a15fb4a55cfe))
* add Release Drafter for auto-generated release notes ([0790be8](https://github.com/bis-code/claw/commit/0790be849d66efa09b9dfd1c100f3d51d98a47c4))
* add slim preset for minimal token usage ([7830e2f](https://github.com/bis-code/claw/commit/7830e2fbba385052f509fa340294bf24c28bb44b))
* add TDD structure for autonomous execution ([c5bde7e](https://github.com/bis-code/claw/commit/c5bde7ec56d9b1820a931e06c9383d9547d53859))
* add teal startup banner with status info ([8ff3957](https://github.com/bis-code/claw/commit/8ff3957e00c22c155665543b3b5b3cf0d11199f8))
* add version tracking and smart upgrades ([2e46833](https://github.com/bis-code/claw/commit/2e46833b5f15f06c8ed070e4de30f59490422277))
* add visual feedback for setup and better error handling ([c2fc463](https://github.com/bis-code/claw/commit/c2fc463704a3ffab12ed3c1aa474cfce304bc21c))
* auto-check index on every session start ([bcfdc89](https://github.com/bis-code/claw/commit/bcfdc897f0f84452fca0df03266e59b60e307191))
* auto-create LEANN index on search if missing ([7cbc890](https://github.com/bis-code/claw/commit/7cbc8902f34979f2ff367a43f786830d15052cff))
* auto-index on /plan-day + multi-repo/monorepo support ([51b8094](https://github.com/bis-code/claw/commit/51b8094d1d293834f22222217879fd290186523e))
* auto-index projects for leann semantic search ([5bd1506](https://github.com/bis-code/claw/commit/5bd15065dc3940db845a65faf75c4f3f59b24628))
* auto-install leann MCP on first run with progress display ([f4df078](https://github.com/bis-code/claw/commit/f4df07894ede58452dd97e7960eb10bcd7abbd3e))
* auto-install LEANN on claw leann build ([d639ead](https://github.com/bis-code/claw/commit/d639ead6bbda1cb8d568f44be53cb1fbaedb1555))
* **auto-update:** implement automatic configuration sync ([#35](https://github.com/bis-code/claw/issues/35)) ([e2670a1](https://github.com/bis-code/claw/commit/e2670a13762af9116fe256040c7aeec0d8c8ef8d))
* **auto:** add Ralph Wiggum-inspired iteration loop ([#34](https://github.com/bis-code/claw/issues/34)) ([3546fd0](https://github.com/bis-code/claw/commit/3546fd0b8234874078ca4c5fb23ce1ab8cd1f859))
* **auto:** consolidate commands + token optimization ([#29](https://github.com/bis-code/claw/issues/29)) ([0399641](https://github.com/bis-code/claw/commit/0399641ed42ed54b3fd03749aac7c84c297478d8))
* **autonomous:** complete autonomous execution system with 66 passing tests ([38660aa](https://github.com/bis-code/claw/commit/38660aa0e05a549c323e53435c961031bec015d6))
* claw v2 - Complete TypeScript CLI with Epics 1-6 ([#41](https://github.com/bis-code/claw/issues/41)) ([616cb94](https://github.com/bis-code/claw/commit/616cb9492fbfbb7391d3b7be5ea6c1b129504092))
* **cli:** add bug capture and optional GitHub issue export ([#48](https://github.com/bis-code/claw/issues/48)) ([33560ce](https://github.com/bis-code/claw/commit/33560ce6868278a6268af57d846b09593be40e50))
* **cli:** add migrate and new commands ([#43](https://github.com/bis-code/claw/issues/43)) ([588362e](https://github.com/bis-code/claw/commit/588362efd5e8a36de0e5d2e4e11acf5b8f9e9511))
* **cli:** improve claw new with account selection and flexible scaffolding ([#45](https://github.com/bis-code/claw/issues/45)) ([11fd082](https://github.com/bis-code/claw/commit/11fd0824e71bb0f21b73ad99270f71c1549079d1))
* external orchestrator architecture (breaking change) ([6d78726](https://github.com/bis-code/claw/commit/6d7872615e56296cbdfdcde901347f364ebe35e6))
* improve multi-repo detection with smarter strategies ([73aa4ee](https://github.com/bis-code/claw/commit/73aa4ee4edf9a12d3d60629ab2e18ac114a6f88f))
* initial claude-setup CLI tool ([73d22aa](https://github.com/bis-code/claw/commit/73d22aa75f2a274de07dcba198d50afb93917833))
* instruct Claude to always use /search command ([46f9887](https://github.com/bis-code/claw/commit/46f98878c134de88fc794731bef3d0b809efaeed))
* integrate OAuth authentication for self-improvement workflows ([d1fa300](https://github.com/bis-code/claw/commit/d1fa3005a699a1cbd5c302fd2e7d0c43b691dc00))
* major claw rewrite with testing and CI ([d80687a](https://github.com/bis-code/claw/commit/d80687adf38e9a4d73dfde7ccbab9c142a569b20))
* **monitor:** add live status dashboard and automatic versioning ([7adf708](https://github.com/bis-code/claw/commit/7adf70884ae53586f576aa124c8c6fd87bbd23c2))
* **projects:** add project-based multi-repo management ([ad95587](https://github.com/bis-code/claw/commit/ad955877eab1f6b86abf913a0e210f60503a321a))
* **setup:** add automated setup script and git hook for auto-sync ([#36](https://github.com/bis-code/claw/issues/36)) ([e41ed71](https://github.com/bis-code/claw/commit/e41ed7154f5d931caabda363b120e2bedce025b3))
* **templates:** add --project flag to install to all repos ([b22327f](https://github.com/bis-code/claw/commit/b22327fa3300f1b5a654a1f9d32bae1b5a66cea0))
* **test:** add comprehensive Homebrew integration testing ([1eef2e3](https://github.com/bis-code/claw/commit/1eef2e350f43ce1e0597ac43f799d1af8600cdcb))
* **workflow:** implement PR-per-issue workflow ([787a328](https://github.com/bis-code/claw/commit/787a328818347bf82ef6e48840b1553a39b51e8e))
* **workflow:** implement PR-per-issue workflow ([62479c2](https://github.com/bis-code/claw/commit/62479c20b27970da2effa35d4ae2926cb8691393))


### Bug Fixes

* add bin/claw to release-please extra-files ([e96e5cc](https://github.com/bis-code/claw/commit/e96e5cc7a1f9a3f25e01fe70d70f7afe581fe5ea))
* add LIB_DIR variable for homebrew compatibility ([003308e](https://github.com/bis-code/claw/commit/003308ed8f84a284581298c56575007af25b080c))
* add repository URL to version output ([63d1d1f](https://github.com/bis-code/claw/commit/63d1d1f83a3f36e8254e15a86f4abbd3aff9a4f4))
* align banner columns and fix ANSI color rendering ([56660af](https://github.com/bis-code/claw/commit/56660af17e79c9aa26b68b4c095f76341368ac56))
* align success banner box borders ([7a30347](https://github.com/bis-code/claw/commit/7a30347ad0b8aec77ba9566ed600813abb6891c8))
* auto-sync VERSION in source files after release ([50fca2a](https://github.com/bis-code/claw/commit/50fca2aab33667c8b7af13e2cefc063f73c5dfc3))
* Auto-sync VERSION in source files after release ([e4be4c7](https://github.com/bis-code/claw/commit/e4be4c75cba233177025f2822c34221439b838ad))
* **ci:** configure release-please to target main branch ([928c200](https://github.com/bis-code/claw/commit/928c20014108f1a0845ac6153bee37898333222e))
* **ci:** disable all automatic workflows to stop costs ([#32](https://github.com/bis-code/claw/issues/32)) ([3a29725](https://github.com/bis-code/claw/commit/3a29725bddf564460c5e97d35ae0fedd1c4c446d))
* **claw:** respect CLAUDE_HOME environment variable ([157bad7](https://github.com/bis-code/claw/commit/157bad7e22f2e4615959744684f9463952c67a1c))
* combine release workflows for autonomous releases ([40de9af](https://github.com/bis-code/claw/commit/40de9afe5a914d69a86498fb513dc090514401e6))
* **home:** handle empty rules array with set -u ([13fe1d0](https://github.com/bis-code/claw/commit/13fe1d03b153ee5bb355e3bc1851a1c6e52e27bc))
* index_exists now handles leann list emoji formatting ([cce15a2](https://github.com/bis-code/claw/commit/cce15a2212589205624635790a0f16a16d9582e8))
* install full Claude configuration (skills, rules, agents, etc.) ([79ec37e](https://github.com/bis-code/claw/commit/79ec37eebe8b74f95d09ee76418672575e3f0c98))
* leann_status always returns 0 ([6dfb940](https://github.com/bis-code/claw/commit/6dfb940e3b55f4f26561e53aeb0614363e7a7473))
* **leann:** align success banner with dynamic padding ([503879e](https://github.com/bis-code/claw/commit/503879e29014fa51d8b35f97939a9e37aa562161))
* make install.sh portable for Linux and macOS ([1114c43](https://github.com/bis-code/claw/commit/1114c435c98867c8c06622192af9f005fdd07e12))
* **release:** add checkout step before tagging ([2d73d7d](https://github.com/bis-code/claw/commit/2d73d7d9a605892c7f0b6abf382bca02588aac15))
* **release:** sync install.sh version to manifest ([cab2f98](https://github.com/bis-code/claw/commit/cab2f98d02305628a56bab1b9028e5a2c9add897))
* **release:** use block annotation format for version ([8c0991c](https://github.com/bis-code/claw/commit/8c0991cc17667a828c7ab8557f802f4269b9fc1a))
* **release:** use generic updater for bin/claw version ([557ca24](https://github.com/bis-code/claw/commit/557ca24c445b834df0ea95205fc2a5fe0fa82317))
* **release:** use inline version marker for release-please ([b1e7687](https://github.com/bis-code/claw/commit/b1e76875d30835139d4b0c4bea6b60b2da60adee))
* remove obsolete claw agents CLI tests ([9e153fb](https://github.com/bis-code/claw/commit/9e153fb7227d2e76d0b33de3349f495e21073f96))
* **repos:** skip interactive prompts in non-TTY mode ([af252ba](https://github.com/bis-code/claw/commit/af252ba2c8bd9589e6b896e015dd4ef703f05621))
* templates path for Homebrew and complete help documentation ([cedd8d2](https://github.com/bis-code/claw/commit/cedd8d21313ac7f237e6ae7eb182c1a33ca27ec8))
* **templates:** fix exit code when installing templates ([cb6fa49](https://github.com/bis-code/claw/commit/cb6fa49604da45afd43f5cae41303d2e1ae793ff))
* **templates:** fix interactive selection output capture ([93415d8](https://github.com/bis-code/claw/commit/93415d8107c472994ce7be13ce9679898b29896b))
* **templates:** resolve path for Homebrew installation ([d895885](https://github.com/bis-code/claw/commit/d8958856af8fd910e09e9e5aa5526003773eb123))
* **templates:** support --project &lt;name&gt; syntax ([51c6ca8](https://github.com/bis-code/claw/commit/51c6ca887939a16ef6f531c87573311c973f772b))
* **tests:** add mock claude and skip leann in CI tests ([34ef33b](https://github.com/bis-code/claw/commit/34ef33b254f4e26751c78c9d670d0a3ba6bcb2fb))
* **tests:** remove obsolete CLI command tests ([b8d5213](https://github.com/bis-code/claw/commit/b8d52135dcc51f1c3c5948f3283e346086b01dd8))
* **tests:** skip flaky blocker test on macOS ([0d0f96e](https://github.com/bis-code/claw/commit/0d0f96e48a17c431b237a530a47b2c2ce2a84761))
* **tests:** skip LEANN in CI, use dynamic version check ([9ec006a](https://github.com/bis-code/claw/commit/9ec006aac25ba6cdb674c84d1f0b870bc159d833))
* update integration tests for simplified claw architecture ([7d73caa](https://github.com/bis-code/claw/commit/7d73caa57bf0ba6785793300d06cba6b66053bca))
* update LIB_DIR and TEMPLATES_DIR paths during install ([58d9817](https://github.com/bis-code/claw/commit/58d98172ba1de1082a27f1e8ec0d4c6ac2641ff0))
* update test files for simplified claw architecture ([d192bf2](https://github.com/bis-code/claw/commit/d192bf2234aad59499a81f29f817d7465d46c3a9))
* use ANSI-C quoting for color codes in banner ([55830ff](https://github.com/bis-code/claw/commit/55830ffe6e35cb93f3887a8b426670a1c034e61c))
* use Bash 3.x compatible preset rules ([85d43cf](https://github.com/bis-code/claw/commit/85d43cff48c80be60d933482d1618a67e8d26565))

## [2.0.0](https://github.com/bis-code/claw/compare/v1.7.0...v2.0.0) (2026-02-01)


### ⚠ BREAKING CHANGES

* Claw is now an external orchestrator that wraps Claude Code instead of copying templates into projects.

### Features

* add --yolo flag to skip permission prompts ([#6](https://github.com/bis-code/claw/issues/6)) ([b0862c4](https://github.com/bis-code/claw/commit/b0862c4a9f93d661aa7a71ee713a69d770aa8025))
* add /benchmark-search command for measuring index efficiency ([c2241b1](https://github.com/bis-code/claw/commit/c2241b1a794de3723e8e8dcf63a9ab15e2075c82))
* add /index command and efficient-search rule ([3cac3dd](https://github.com/bis-code/claw/commit/3cac3ddf02a133afe966c4200c4738e48f3fb39a))
* add /search command for efficient codebase exploration ([82df43c](https://github.com/bis-code/claw/commit/82df43cacfd3e9d7497a95e6b46e2816983a7b3f))
* add /summary skill for daily work tracking ([#7](https://github.com/bis-code/claw/issues/7)) ([eb58e5a](https://github.com/bis-code/claw/commit/eb58e5a2f514bf8506d7bf54e53c4028cdd4d76e))
* add automated release workflow ([2ea79e6](https://github.com/bis-code/claw/commit/2ea79e6a38890538667d89fef86c051f3ef90134))
* add autonomous self-improvement system ([a3bd13f](https://github.com/bis-code/claw/commit/a3bd13fda787927081796be3890b44217cdeac00))
* add autonomous self-improvement with workflow generation ([57bb59e](https://github.com/bis-code/claw/commit/57bb59ebe0bf5c34fad6da6f241686608aa9de1a))
* add brainstorming agents for /agents command ([9ad8544](https://github.com/bis-code/claw/commit/9ad854411a976d260fb007b5698036d1620e26ce))
* add brew install testing to release pipeline ([606720c](https://github.com/bis-code/claw/commit/606720cbc7863176f8d8fcceb5d7f9ada1f83d6d))
* add GitHub issue templates command ([#5](https://github.com/bis-code/claw/issues/5)) ([ded1a5e](https://github.com/bis-code/claw/commit/ded1a5e3d9ce9c5447b21557e99b7243ea497671))
* add hook to detect stale project index ([11c6759](https://github.com/bis-code/claw/commit/11c6759d8c71c140cada4ccff4b22aadc8689e4c))
* add multi-repo tracking and simplify README ([19ac704](https://github.com/bis-code/claw/commit/19ac70425584334545bc68ed8b72a15fb4a55cfe))
* add Release Drafter for auto-generated release notes ([0790be8](https://github.com/bis-code/claw/commit/0790be849d66efa09b9dfd1c100f3d51d98a47c4))
* add slim preset for minimal token usage ([7830e2f](https://github.com/bis-code/claw/commit/7830e2fbba385052f509fa340294bf24c28bb44b))
* add TDD structure for autonomous execution ([c5bde7e](https://github.com/bis-code/claw/commit/c5bde7ec56d9b1820a931e06c9383d9547d53859))
* add teal startup banner with status info ([8ff3957](https://github.com/bis-code/claw/commit/8ff3957e00c22c155665543b3b5b3cf0d11199f8))
* add version tracking and smart upgrades ([2e46833](https://github.com/bis-code/claw/commit/2e46833b5f15f06c8ed070e4de30f59490422277))
* add visual feedback for setup and better error handling ([c2fc463](https://github.com/bis-code/claw/commit/c2fc463704a3ffab12ed3c1aa474cfce304bc21c))
* auto-check index on every session start ([bcfdc89](https://github.com/bis-code/claw/commit/bcfdc897f0f84452fca0df03266e59b60e307191))
* auto-create LEANN index on search if missing ([7cbc890](https://github.com/bis-code/claw/commit/7cbc8902f34979f2ff367a43f786830d15052cff))
* auto-index on /plan-day + multi-repo/monorepo support ([51b8094](https://github.com/bis-code/claw/commit/51b8094d1d293834f22222217879fd290186523e))
* auto-index projects for leann semantic search ([5bd1506](https://github.com/bis-code/claw/commit/5bd15065dc3940db845a65faf75c4f3f59b24628))
* auto-install leann MCP on first run with progress display ([f4df078](https://github.com/bis-code/claw/commit/f4df07894ede58452dd97e7960eb10bcd7abbd3e))
* auto-install LEANN on claw leann build ([d639ead](https://github.com/bis-code/claw/commit/d639ead6bbda1cb8d568f44be53cb1fbaedb1555))
* **auto-update:** implement automatic configuration sync ([#35](https://github.com/bis-code/claw/issues/35)) ([e2670a1](https://github.com/bis-code/claw/commit/e2670a13762af9116fe256040c7aeec0d8c8ef8d))
* **auto:** add Ralph Wiggum-inspired iteration loop ([#34](https://github.com/bis-code/claw/issues/34)) ([3546fd0](https://github.com/bis-code/claw/commit/3546fd0b8234874078ca4c5fb23ce1ab8cd1f859))
* **auto:** consolidate commands + token optimization ([#29](https://github.com/bis-code/claw/issues/29)) ([0399641](https://github.com/bis-code/claw/commit/0399641ed42ed54b3fd03749aac7c84c297478d8))
* **autonomous:** complete autonomous execution system with 66 passing tests ([38660aa](https://github.com/bis-code/claw/commit/38660aa0e05a549c323e53435c961031bec015d6))
* claw v2 - Complete TypeScript CLI with Epics 1-6 ([#41](https://github.com/bis-code/claw/issues/41)) ([616cb94](https://github.com/bis-code/claw/commit/616cb9492fbfbb7391d3b7be5ea6c1b129504092))
* **cli:** add migrate and new commands ([#43](https://github.com/bis-code/claw/issues/43)) ([588362e](https://github.com/bis-code/claw/commit/588362efd5e8a36de0e5d2e4e11acf5b8f9e9511))
* **cli:** improve claw new with account selection and flexible scaffolding ([#45](https://github.com/bis-code/claw/issues/45)) ([11fd082](https://github.com/bis-code/claw/commit/11fd0824e71bb0f21b73ad99270f71c1549079d1))
* external orchestrator architecture (breaking change) ([6d78726](https://github.com/bis-code/claw/commit/6d7872615e56296cbdfdcde901347f364ebe35e6))
* improve multi-repo detection with smarter strategies ([73aa4ee](https://github.com/bis-code/claw/commit/73aa4ee4edf9a12d3d60629ab2e18ac114a6f88f))
* initial claude-setup CLI tool ([73d22aa](https://github.com/bis-code/claw/commit/73d22aa75f2a274de07dcba198d50afb93917833))
* instruct Claude to always use /search command ([46f9887](https://github.com/bis-code/claw/commit/46f98878c134de88fc794731bef3d0b809efaeed))
* integrate OAuth authentication for self-improvement workflows ([d1fa300](https://github.com/bis-code/claw/commit/d1fa3005a699a1cbd5c302fd2e7d0c43b691dc00))
* major claw rewrite with testing and CI ([d80687a](https://github.com/bis-code/claw/commit/d80687adf38e9a4d73dfde7ccbab9c142a569b20))
* **monitor:** add live status dashboard and automatic versioning ([7adf708](https://github.com/bis-code/claw/commit/7adf70884ae53586f576aa124c8c6fd87bbd23c2))
* **projects:** add project-based multi-repo management ([ad95587](https://github.com/bis-code/claw/commit/ad955877eab1f6b86abf913a0e210f60503a321a))
* **setup:** add automated setup script and git hook for auto-sync ([#36](https://github.com/bis-code/claw/issues/36)) ([e41ed71](https://github.com/bis-code/claw/commit/e41ed7154f5d931caabda363b120e2bedce025b3))
* **templates:** add --project flag to install to all repos ([b22327f](https://github.com/bis-code/claw/commit/b22327fa3300f1b5a654a1f9d32bae1b5a66cea0))
* **test:** add comprehensive Homebrew integration testing ([1eef2e3](https://github.com/bis-code/claw/commit/1eef2e350f43ce1e0597ac43f799d1af8600cdcb))
* **workflow:** implement PR-per-issue workflow ([787a328](https://github.com/bis-code/claw/commit/787a328818347bf82ef6e48840b1553a39b51e8e))
* **workflow:** implement PR-per-issue workflow ([62479c2](https://github.com/bis-code/claw/commit/62479c20b27970da2effa35d4ae2926cb8691393))


### Bug Fixes

* add bin/claw to release-please extra-files ([e96e5cc](https://github.com/bis-code/claw/commit/e96e5cc7a1f9a3f25e01fe70d70f7afe581fe5ea))
* add LIB_DIR variable for homebrew compatibility ([003308e](https://github.com/bis-code/claw/commit/003308ed8f84a284581298c56575007af25b080c))
* add repository URL to version output ([63d1d1f](https://github.com/bis-code/claw/commit/63d1d1f83a3f36e8254e15a86f4abbd3aff9a4f4))
* align banner columns and fix ANSI color rendering ([56660af](https://github.com/bis-code/claw/commit/56660af17e79c9aa26b68b4c095f76341368ac56))
* align success banner box borders ([7a30347](https://github.com/bis-code/claw/commit/7a30347ad0b8aec77ba9566ed600813abb6891c8))
* auto-sync VERSION in source files after release ([50fca2a](https://github.com/bis-code/claw/commit/50fca2aab33667c8b7af13e2cefc063f73c5dfc3))
* Auto-sync VERSION in source files after release ([e4be4c7](https://github.com/bis-code/claw/commit/e4be4c75cba233177025f2822c34221439b838ad))
* **ci:** configure release-please to target main branch ([928c200](https://github.com/bis-code/claw/commit/928c20014108f1a0845ac6153bee37898333222e))
* **ci:** disable all automatic workflows to stop costs ([#32](https://github.com/bis-code/claw/issues/32)) ([3a29725](https://github.com/bis-code/claw/commit/3a29725bddf564460c5e97d35ae0fedd1c4c446d))
* **claw:** respect CLAUDE_HOME environment variable ([157bad7](https://github.com/bis-code/claw/commit/157bad7e22f2e4615959744684f9463952c67a1c))
* combine release workflows for autonomous releases ([40de9af](https://github.com/bis-code/claw/commit/40de9afe5a914d69a86498fb513dc090514401e6))
* **home:** handle empty rules array with set -u ([13fe1d0](https://github.com/bis-code/claw/commit/13fe1d03b153ee5bb355e3bc1851a1c6e52e27bc))
* index_exists now handles leann list emoji formatting ([cce15a2](https://github.com/bis-code/claw/commit/cce15a2212589205624635790a0f16a16d9582e8))
* install full Claude configuration (skills, rules, agents, etc.) ([79ec37e](https://github.com/bis-code/claw/commit/79ec37eebe8b74f95d09ee76418672575e3f0c98))
* leann_status always returns 0 ([6dfb940](https://github.com/bis-code/claw/commit/6dfb940e3b55f4f26561e53aeb0614363e7a7473))
* **leann:** align success banner with dynamic padding ([503879e](https://github.com/bis-code/claw/commit/503879e29014fa51d8b35f97939a9e37aa562161))
* make install.sh portable for Linux and macOS ([1114c43](https://github.com/bis-code/claw/commit/1114c435c98867c8c06622192af9f005fdd07e12))
* **release:** add checkout step before tagging ([2d73d7d](https://github.com/bis-code/claw/commit/2d73d7d9a605892c7f0b6abf382bca02588aac15))
* **release:** sync install.sh version to manifest ([cab2f98](https://github.com/bis-code/claw/commit/cab2f98d02305628a56bab1b9028e5a2c9add897))
* **release:** use block annotation format for version ([8c0991c](https://github.com/bis-code/claw/commit/8c0991cc17667a828c7ab8557f802f4269b9fc1a))
* **release:** use generic updater for bin/claw version ([557ca24](https://github.com/bis-code/claw/commit/557ca24c445b834df0ea95205fc2a5fe0fa82317))
* **release:** use inline version marker for release-please ([b1e7687](https://github.com/bis-code/claw/commit/b1e76875d30835139d4b0c4bea6b60b2da60adee))
* remove obsolete claw agents CLI tests ([9e153fb](https://github.com/bis-code/claw/commit/9e153fb7227d2e76d0b33de3349f495e21073f96))
* **repos:** skip interactive prompts in non-TTY mode ([af252ba](https://github.com/bis-code/claw/commit/af252ba2c8bd9589e6b896e015dd4ef703f05621))
* templates path for Homebrew and complete help documentation ([cedd8d2](https://github.com/bis-code/claw/commit/cedd8d21313ac7f237e6ae7eb182c1a33ca27ec8))
* **templates:** fix exit code when installing templates ([cb6fa49](https://github.com/bis-code/claw/commit/cb6fa49604da45afd43f5cae41303d2e1ae793ff))
* **templates:** fix interactive selection output capture ([93415d8](https://github.com/bis-code/claw/commit/93415d8107c472994ce7be13ce9679898b29896b))
* **templates:** resolve path for Homebrew installation ([d895885](https://github.com/bis-code/claw/commit/d8958856af8fd910e09e9e5aa5526003773eb123))
* **templates:** support --project &lt;name&gt; syntax ([51c6ca8](https://github.com/bis-code/claw/commit/51c6ca887939a16ef6f531c87573311c973f772b))
* **tests:** add mock claude and skip leann in CI tests ([34ef33b](https://github.com/bis-code/claw/commit/34ef33b254f4e26751c78c9d670d0a3ba6bcb2fb))
* **tests:** remove obsolete CLI command tests ([b8d5213](https://github.com/bis-code/claw/commit/b8d52135dcc51f1c3c5948f3283e346086b01dd8))
* **tests:** skip flaky blocker test on macOS ([0d0f96e](https://github.com/bis-code/claw/commit/0d0f96e48a17c431b237a530a47b2c2ce2a84761))
* **tests:** skip LEANN in CI, use dynamic version check ([9ec006a](https://github.com/bis-code/claw/commit/9ec006aac25ba6cdb674c84d1f0b870bc159d833))
* update integration tests for simplified claw architecture ([7d73caa](https://github.com/bis-code/claw/commit/7d73caa57bf0ba6785793300d06cba6b66053bca))
* update LIB_DIR and TEMPLATES_DIR paths during install ([58d9817](https://github.com/bis-code/claw/commit/58d98172ba1de1082a27f1e8ec0d4c6ac2641ff0))
* update test files for simplified claw architecture ([d192bf2](https://github.com/bis-code/claw/commit/d192bf2234aad59499a81f29f817d7465d46c3a9))
* use ANSI-C quoting for color codes in banner ([55830ff](https://github.com/bis-code/claw/commit/55830ffe6e35cb93f3887a8b426670a1c034e61c))
* use Bash 3.x compatible preset rules ([85d43cf](https://github.com/bis-code/claw/commit/85d43cff48c80be60d933482d1618a67e8d26565))

## [1.7.0](https://github.com/bis-code/claw/compare/v1.6.0...v1.7.0) (2026-02-01)


### Features

* **cli:** add migrate and new commands ([#43](https://github.com/bis-code/claw/issues/43)) ([588362e](https://github.com/bis-code/claw/commit/588362efd5e8a36de0e5d2e4e11acf5b8f9e9511))

## [1.6.0](https://github.com/bis-code/claw/compare/v1.5.0...v1.6.0) (2026-01-31)


### Features

* **auto-update:** implement automatic configuration sync ([#35](https://github.com/bis-code/claw/issues/35)) ([e2670a1](https://github.com/bis-code/claw/commit/e2670a13762af9116fe256040c7aeec0d8c8ef8d))
* **auto:** add Ralph Wiggum-inspired iteration loop ([#34](https://github.com/bis-code/claw/issues/34)) ([3546fd0](https://github.com/bis-code/claw/commit/3546fd0b8234874078ca4c5fb23ce1ab8cd1f859))
* claw v2 - Complete TypeScript CLI with Epics 1-6 ([#41](https://github.com/bis-code/claw/issues/41)) ([616cb94](https://github.com/bis-code/claw/commit/616cb9492fbfbb7391d3b7be5ea6c1b129504092))
* **setup:** add automated setup script and git hook for auto-sync ([#36](https://github.com/bis-code/claw/issues/36)) ([e41ed71](https://github.com/bis-code/claw/commit/e41ed7154f5d931caabda363b120e2bedce025b3))


### Bug Fixes

* **ci:** disable all automatic workflows to stop costs ([#32](https://github.com/bis-code/claw/issues/32)) ([3a29725](https://github.com/bis-code/claw/commit/3a29725bddf564460c5e97d35ae0fedd1c4c446d))

## [1.5.0](https://github.com/bis-code/claw/compare/v1.4.1...v1.5.0) (2026-01-10)


### Features

* **auto:** consolidate commands + token optimization ([#29](https://github.com/bis-code/claw/issues/29)) ([0399641](https://github.com/bis-code/claw/commit/0399641ed42ed54b3fd03749aac7c84c297478d8))


### Bug Fixes

* **ci:** configure release-please to target main branch ([928c200](https://github.com/bis-code/claw/commit/928c20014108f1a0845ac6153bee37898333222e))

## [1.2.0](https://github.com/bis-code/claw/compare/v1.1.5...v1.2.0) (2026-01-07)


### Features

* **workflow:** implement PR-per-issue workflow ([787a328](https://github.com/bis-code/claw/commit/787a328818347bf82ef6e48840b1553a39b51e8e))
* **workflow:** implement PR-per-issue workflow ([62479c2](https://github.com/bis-code/claw/commit/62479c20b27970da2effa35d4ae2926cb8691393))


### Bug Fixes

* auto-sync VERSION in source files after release ([50fca2a](https://github.com/bis-code/claw/commit/50fca2aab33667c8b7af13e2cefc063f73c5dfc3))
* Auto-sync VERSION in source files after release ([e4be4c7](https://github.com/bis-code/claw/commit/e4be4c75cba233177025f2822c34221439b838ad))

## [1.1.5](https://github.com/bis-code/claw/compare/v1.1.4...v1.1.5) (2026-01-07)


### Bug Fixes

* **release:** sync install.sh version to manifest ([cab2f98](https://github.com/bis-code/claw/commit/cab2f98d02305628a56bab1b9028e5a2c9add897))
* **release:** use block annotation format for version ([8c0991c](https://github.com/bis-code/claw/commit/8c0991cc17667a828c7ab8557f802f4269b9fc1a))
* **release:** use generic updater for bin/claw version ([557ca24](https://github.com/bis-code/claw/commit/557ca24c445b834df0ea95205fc2a5fe0fa82317))
* **release:** use inline version marker for release-please ([b1e7687](https://github.com/bis-code/claw/commit/b1e76875d30835139d4b0c4bea6b60b2da60adee))

## [1.1.4](https://github.com/bis-code/claw/compare/v1.1.3...v1.1.4) (2026-01-07)


### Bug Fixes

* **tests:** skip LEANN in CI, use dynamic version check ([9ec006a](https://github.com/bis-code/claw/commit/9ec006aac25ba6cdb674c84d1f0b870bc159d833))

## [1.1.3](https://github.com/bis-code/claw/compare/v1.1.2...v1.1.3) (2026-01-07)


### Bug Fixes

* **repos:** skip interactive prompts in non-TTY mode ([af252ba](https://github.com/bis-code/claw/commit/af252ba2c8bd9589e6b896e015dd4ef703f05621))

## [1.1.2](https://github.com/bis-code/claw/compare/v1.1.1...v1.1.2) (2026-01-07)


### Bug Fixes

* **release:** add checkout step before tagging ([2d73d7d](https://github.com/bis-code/claw/commit/2d73d7d9a605892c7f0b6abf382bca02588aac15))

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
