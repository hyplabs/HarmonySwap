# build command: docker build --tag harmony_swap .
# run command: docker run -i -t harmony_swap:latest

FROM ubuntu:20.04

# install system dependencies
RUN apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl git npm python3 python3-pip nodejs

RUN python3 -m pip install vyper==0.2.2
RUN npm install -g truffle@5.1.34 || true

# install app dependencies
COPY ./package.json /app/package.json
RUN cd /app && npm install

COPY . /app
WORKDIR /app

ENTRYPOINT [ "/bin/bash" ]
