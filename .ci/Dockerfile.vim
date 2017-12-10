ARG TAG="latest"
FROM lambdalisue/vim-themis:${TAG}
MAINTAINER lambdalisue <lambdalisue@hashnote.net>

RUN apk add --no-cache git python3 \
 && git config --global user.name "docker" \
 && git config --global user.email docker@example.com \
 && git clone --depth 1 --single-branch https://github.com/vim-jp/vital.vim /opt/github.com/vim-jp/vital.vim \
 && rm -rf /opt/github.com/thinca/vim-themis \
 && git clone --depth 1 --single-branch --branch 1.5.4dev https://github.com/thinca/vim-themis /opt/github.com/thinca/vim-themis

CMD ["--runtimepath", "/opt/github.com/vim-jp/vital.vim"]
