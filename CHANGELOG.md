# Changelog

## [0.5.1](https://github.com/seuros/rails_lens/compare/rails_lens/v0.5.0...rails_lens/v0.5.1) (2025-12-07)


### Bug Fixes

* add by_source ([f6693f3](https://github.com/seuros/rails_lens/commit/f6693f384761de505eac0e525c7b70f4c053d14c))

## [0.5.0](https://github.com/seuros/rails_lens/compare/rails_lens/v0.3.0...rails_lens/v0.5.0) (2025-12-06)


### ⚠ BREAKING CHANGES

* refactor the extension modules

### Features

* refactor the extension modules ([de80a63](https://github.com/seuros/rails_lens/commit/de80a638f968cc24e1b8c7906054dbb2292df772))

## [0.3.0](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.13...rails_lens/v0.3.0) (2025-11-29)


### Features

* add callback annotations with Rails 8 unified callback chain API ([bcc43f7](https://github.com/seuros/rails_lens/commit/bcc43f783ed207cc57acf7f2d8cf7691c2481484))
* compact TOML annotation format with NoteCodes ([5de557e](https://github.com/seuros/rails_lens/commit/5de557ea209ad7554527e87715d1966a1ea27db2))


### Bug Fixes

* address codex review feedback for callbacks analyzer ([dbcfb1a](https://github.com/seuros/rails_lens/commit/dbcfb1ae0730d813b3e05e4df2f9bb00167bc5a6))
* Merge pull request [#32](https://github.com/seuros/rails_lens/issues/32) from seuros/feat/compact-toml-annotations ([4b9171d](https://github.com/seuros/rails_lens/commit/4b9171d2eabf78409acdeaf3a906f4d0d54cb0c9))

## [0.2.13](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.12...rails_lens/v0.2.13) (2025-11-28)


### Features

* add PostgreSQL trigger and function annotations with extension filtering ([#30](https://github.com/seuros/rails_lens/issues/30)) ([a6d6e27](https://github.com/seuros/rails_lens/commit/a6d6e2715f61842ef3c2c585251ac3bf09ec740a))

## [0.2.12](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.11...rails_lens/v0.2.12) (2025-11-26)


### Bug Fixes

* handle engine/gem dummy app file paths in annotation ([7a3dab8](https://github.com/seuros/rails_lens/commit/7a3dab83570e43cb243b7bac41afc184a27bed2c))

## [0.2.11](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.10...rails_lens/v0.2.11) (2025-11-24)


### Features

* add install command for automatic post-migration annotation ([#28](https://github.com/seuros/rails_lens/issues/28)) ([873fcdc](https://github.com/seuros/rails_lens/commit/873fcdcb4ca481273f71068824d066557f3cc38b))


### Bug Fixes

* replace deprecated ActiveSupport::Configurable and update CI to Rails 8.1 ([#26](https://github.com/seuros/rails_lens/issues/26)) ([b540214](https://github.com/seuros/rails_lens/commit/b540214afd25e0313ee2772e6c65d81bae68cb64))

## [0.2.10](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.9...rails_lens/v0.2.10) (2025-10-17)


### Bug Fixes

* handle PostgreSQL schema-qualified table names in BestPracticesAnalyzer ([#24](https://github.com/seuros/rails_lens/issues/24)) ([607536f](https://github.com/seuros/rails_lens/commit/607536f58d8840a9123bc50eec7878b979cd1891))

## [0.2.9](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.8...rails_lens/v0.2.9) (2025-10-05)


### Features

* support PostgreSQL schema-qualified table names ([#22](https://github.com/seuros/rails_lens/issues/22)) ([478c6cc](https://github.com/seuros/rails_lens/commit/478c6ccb3f0271dd5bbe182e30057528a1639f4f))

## [0.2.8](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.7...rails_lens/v0.2.8) (2025-08-14)


### Bug Fixes

* remove hard dependency of mermaid ([b82ea17](https://github.com/seuros/rails_lens/commit/b82ea17ccb0920321b5ab219bc63b3043d182ad3))

## [0.2.7](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.6...rails_lens/v0.2.7) (2025-08-14)


### Bug Fixes

* use mermaid gem as backend ([#19](https://github.com/seuros/rails_lens/issues/19)) ([2297ecb](https://github.com/seuros/rails_lens/commit/2297ecb1a61ae1c3bb3ea4b1f602f9bea91a5aa8)), closes [#18](https://github.com/seuros/rails_lens/issues/18)

## [0.2.6](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.5...rails_lens/v0.2.6) (2025-08-06)


### Bug Fixes

* improve logger configuration and use ActiveRecord ignore_tables ([#16](https://github.com/seuros/rails_lens/issues/16)) ([cf914b9](https://github.com/seuros/rails_lens/commit/cf914b9a421f2f69328e80733229408c9f362963))

## [0.2.5](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.4...rails_lens/v0.2.5) (2025-07-31)


### Bug Fixes

* change strategy to cover database with hundrends of connections pool ([#12](https://github.com/seuros/rails_lens/issues/12)) ([7054d35](https://github.com/seuros/rails_lens/commit/7054d3582bfee41f0050725c2bd23e80c5898486))

## [0.2.4](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.3...rails_lens/v0.2.4) (2025-07-31)


### Bug Fixes

* centralize connection management to prevent "too many clients" errors ([#10](https://github.com/seuros/rails_lens/issues/10)) ([1f9adf9](https://github.com/seuros/rails_lens/commit/1f9adf9b7dd0648add324492189c1322726da52f))

## [0.2.3](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.2...rails_lens/v0.2.3) (2025-07-31)


### Features

* add database view annotation support ([#7](https://github.com/seuros/rails_lens/issues/7)) ([a42fdcd](https://github.com/seuros/rails_lens/commit/a42fdcdfe4da9e2a086488e0c5e0c72d2f3c5d3d))


### Bug Fixes

* centralize connection management to prevent "too many clients" errors ([#9](https://github.com/seuros/rails_lens/issues/9)) ([c5d85c7](https://github.com/seuros/rails_lens/commit/c5d85c7239d1eff49494a05582cb00a8e7402618))

## [0.2.2](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.1...rails_lens/v0.2.2) (2025-07-31)


### Bug Fixes

* remove from format from the erd visualize ([#5](https://github.com/seuros/rails_lens/issues/5)) ([c2efdc7](https://github.com/seuros/rails_lens/commit/c2efdc7011425fcd8b46dce54d811ce166b0c660))

## [0.2.1](https://github.com/seuros/rails_lens/compare/rails_lens/v0.2.0...rails_lens/v0.2.1) (2025-07-30)


### Bug Fixes

* resolve GitHub issue [#2](https://github.com/seuros/rails_lens/issues/2) CLI and provider errors ([6d92c67](https://github.com/seuros/rails_lens/commit/6d92c679f1da9186ec4f357c243b41bc57eecd94))
* resolve GitHub issue [#2](https://github.com/seuros/rails_lens/issues/2) CLI and provider errors ([a583373](https://github.com/seuros/rails_lens/commit/a583373b40ee7fdde32b3e97295448b1ecaa7ca5))

## [0.2.0](https://github.com/seuros/rails_lens/compare/rails_lens-v0.1.0...rails_lens/v0.2.0) (2025-07-30)


### Features

* release public ([78da92e](https://github.com/seuros/rails_lens/commit/78da92e5c788bbac71b5b2c36b5a1419b04350d2))
