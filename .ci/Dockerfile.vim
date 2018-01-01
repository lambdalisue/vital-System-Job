ARG TAG="latest"
FROM lambdalisue/vim-themis:${TAG}
MAINTAINER lambdalisue <lambdalisue@hashnote.net>

RUN apk add --no-cache --virtual build-deps git \
 && apk add --no-cache python3 \
 && git clone --depth 1 --single-branch https://github.com/vim-jp/vital.vim /opt/github.com/vim-jp/vital.vim \
 && apk del build-deps

CMD ["--runtimepath", "/opt/github.com/vim-jp/vital.vim"]
