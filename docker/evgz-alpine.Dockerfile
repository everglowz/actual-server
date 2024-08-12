# [LWL] Need to give the build context as parent of this repo so we can copy
# the local desktop client into the container. e.g.
# actual-server> docker build -t evgz/actual-server -f docker/evgz-alpine.Dockerfile ..
#
FROM alpine:3.17 as base
RUN apk add --no-cache nodejs yarn npm python3 openssl build-base
WORKDIR /app
ADD actual-server/.yarn ./.yarn
ADD actual-server/yarn.lock actual-server/package.json actual-server/.yarnrc.yml ./
ADD actual/packages/desktop-client/ ../actual/packages/desktop-client/
RUN yarn workspaces focus --all --production

FROM alpine:3.17 as prod
RUN apk add --no-cache nodejs tini

ARG USERNAME=actual
ARG USER_UID=1001
ARG USER_GID=$USER_UID
RUN addgroup -S ${USERNAME} -g ${USER_GID} && adduser -S ${USERNAME} -G ${USERNAME} -u ${USER_UID}
RUN mkdir /data && chown -R ${USERNAME}:${USERNAME} /data

WORKDIR /app
COPY --from=base /app/node_modules /app/node_modules
ADD actual-server/package.json actual-server/app.js ./
ADD actual-server/src ./src
ADD actual-server/migrations ./migrations
ENTRYPOINT ["/sbin/tini","-g",  "--"]
EXPOSE 5006
CMD ["node", "app.js"]
