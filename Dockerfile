FROM mhart/alpine-node
EXPOSE 8080
COPY server.js package.json yarn.lock readme.md layout.html /src/
COPY libs /src/libs
COPY static /src/static
WORKDIR /src
RUN npm install -g yarn && \
    yarn install --pure-lockfile && \
    yarn cache clean
CMD yarn start
