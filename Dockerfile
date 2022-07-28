FROM ubuntu:rolling as artifact

RUN apt update && \
  apt install -y unzip curl

ARG VERSION
ARG ARCHIVE_PREFIX="bedrock-server-"
ARG ARCHIVE_SUFFIX=".zip"
ARG ARCHIVE_BASE_URL="https://minecraft.azureedge.net/bin-linux/"

WORKDIR "/tmp"

RUN curl -O ${ARCHIVE_BASE_URL}${ARCHIVE_PREFIX}${VERSION}${ARCHIVE_SUFFIX} && \
    unzip ${ARCHIVE_PREFIX}${VERSION}${ARCHIVE_SUFFIX} -d bedrock_server && \
    mkdir bedrock_server/default && \
    mkdir bedrock_server/bin && \
    rm bedrock_server/server.properties && \
    for i in permissions.json whitelist.json behavior_packs resource_packs;do mv bedrock_server/$i bedrock_server/default/$i;done && \
    chmod -R g=u bedrock_server

COPY entrypoint.sh /tmp/bedrock_server/bin/entrypoint.sh
COPY startup.sh /tmp/bedrock_server/bin/startup.sh

FROM ubuntu:focal

ENV SERVER_DIR="/opt/minecraft_bedrock" \
  DATA_DIR="/data" \
  PATH=$PATH:/opt/minecraft_bedrock/bin:/opt/minecraft_bedrock \
  LD_LIBRARY_PATH=/opt/minecraft_bedrock

COPY --chown=1001:0 --from=artifact /tmp/bedrock_server ${SERVER_DIR}

RUN apt update && \
    apt install --no-install-recommends -y libssl1.1 libcurl4  && \
    apt clean autoclean && \
    rm -Rf /var/lib/apt/lists/* && \
    mkdir ${DATA_DIR} && \
    chown 1001:0 ${DATA_DIR} && \
    chmod ug+w ${DATA_DIR} && \
    chmod ug+w ${SERVER_DIR}

    
USER 1001:0

VOLUME "${DATA_DIR}"

EXPOSE "19132/udp"
EXPOSE "19133/udp"
EXPOSE "60977/udp"
EXPOSE "36964/udp"

WORKDIR "${SERVER_DIR}"

ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "startup.sh" ]

ENV MCPROP_LEVEL_NAME="Bedrock level"