# Copyright 2018 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################################
# This file is autogenerated by the repository at https://github.com/gocd/gocd.
# Please file any issues or PRs at https://github.com/gocd/gocd
###############################################################################################

FROM alpine:latest as gocd-server-unzip
RUN \
  apk --no-cache upgrade && \
  apk add --no-cache curl && \
  curl --fail --location --silent --show-error "https://download.gocd.org/binaries/19.4.0-9155/generic/go-server-19.4.0-9155.zip" > /tmp/go-server-19.4.0-9155.zip
RUN unzip /tmp/go-server-19.4.0-9155.zip -d /
RUN mv /go-server-19.4.0 /go-server

FROM alpine:3.9
MAINTAINER ThoughtWorks, Inc. <support@thoughtworks.com>

LABEL gocd.version="19.4.0" \
  description="GoCD server based on alpine version 3.9" \
  maintainer="ThoughtWorks, Inc. <support@thoughtworks.com>" \
  url="https://www.gocd.org" \
  gocd.full.version="19.4.0-9155" \
  gocd.git.sha="0f01ab091e85a0d735b8b580eee5f83245fba2e5"

# the ports that go server runs on
EXPOSE 8153 8154

ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini-static-amd64 /usr/local/sbin/tini
ADD https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64 /usr/local/sbin/gosu

# force encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ARG UID=1000
ARG GID=1000

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
  chmod 0755 /usr/local/sbin/gosu && \
  chown root:root /usr/local/sbin/gosu && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
  addgroup -g ${GID} go && \
  adduser -D -u ${UID} -s /bin/bash -G go go && \
  apk --no-cache upgrade && \
  apk add --no-cache nss git mercurial subversion openssh-client bash curl && \
  apk add --no-cache openjdk8-jre-base && \
  mkdir -p /docker-entrypoint.d

COPY --from=gocd-server-unzip /go-server /go-server
# ensure that logs are printed to console output
COPY logback-include.xml /go-server/config/logback-include.xml
COPY install-gocd-plugins /usr/local/sbin/install-gocd-plugins
COPY git-clone-config /usr/local/sbin/git-clone-config

ADD docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
