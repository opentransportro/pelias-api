FROM opentransport/libpostal:latest

ENV PORT=8080
EXPOSE ${PORT}

RUN echo 'APT::Acquire::Retries "20";' >> /etc/apt/apt.conf

# Where the app is built and run inside the docker fs
ENV WORK=/opt/pelias/api

# Used indirectly for saving yarn logs etc.
ENV HOME=/opt/pelias/api

WORKDIR ${WORK}
ADD . ${WORK}

# Build and set permissions for arbitrary non-root user
RUN yarn install && chmod -R a+rwX .

ADD pelias.json.docker pelias.json

CMD yarn start
