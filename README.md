akerl/pkgforge-golang-helper
==========

[![Automated Build](https://img.shields.io/docker/build/akerl/pkgforge-golang-helper.svg)](https://hub.docker.com/r/akerl/pkgforge-golang-helper/)
![Build Status](https://img.shields.io/circleci/project/akerl/pkgforge-golang-helper/master.svg)](https://circleci.com/gh/akerl/pkgforge-golang-helper)
[![MIT Licensed](https://img.shields.io/badge/license-MIT-green.svg)](https://tldrlegal.com/license/mit-license)

Helper repo for building golang packages with [pkgforge](https://github.com/akerl/pkgforge)

## Usage

The easiest way is to submodule this into your package and then symlink the Makefile to the root:

```
git submodule add git://github.com/akerl/pkgforge-golang-helper
ln -s pkgforge-golang-helper/Makefile ./
```

Then you'd run `make` to build your thing using [dock0/pkgforge](https://github.com/dock0/pkgforge), or `make manual` to open a bash shell in the container.

In theory you could also pull down the Makefile and just vendor it in as well, if you hate submodules.

## License

pkgforge-golang-helper is released under the MIT License. See the bundled LICENSE file for details.

