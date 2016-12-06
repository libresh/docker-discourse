# docker-discourse

discourse image for discourse service

## Discourse plugins

This image supports installing Discourse plugins at build time, via the `DISCOURSE_ADDITIONAL_PLUGINS` [build arg](https://docs.docker.com/engine/reference/builder/#/arg). Set it to a whitespace (space, tab, newline) separated list if valid `git` URLs of plugins to be installed at build time.