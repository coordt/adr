FROM python:3.8-slim-buster

ARG RELEASE
ARG PIP_EXTRA_INDEX_URL

ENV PYTHONUNBUFFERED 1
WORKDIR /app

#RUN apt-get update \
#    # CFFI dependencies
#    && apt-get install -y libffi-dev python3-cffi

# Requirements are installed here to ensure they will be cached.
COPY ./requirements requirements
RUN pip install --no-cache-dir -r requirements/prod.txt

# Add CHR certificates
ADD https://artifactory.chrobinson.com/artifactory/automated-software-storage/ca-certificates/CHR_root.crt /usr/local/share/ca-certificates/
ADD https://artifactory.chrobinson.com/artifactory/automated-software-storage/ca-certificates/CHR_intermediate.crt /usr/local/share/ca-certificates/
RUN cat /usr/local/share/ca-certificates/CHR_*.crt > /usr/local/share/CHR.pem
RUN update-ca-certificates
RUN cat /usr/local/share/CHR.pem >> /usr/local/lib/python3.8/site-packages/certifi/cacert.pem

COPY . .

RUN chmod +x /app/bin/*

ENV RELEASE=${RELEASE:-FORGOT_BUILD_ARG_RELEASE}
RUN echo $RELEASE > RELEASE.txt
RUN python setup.py install

ENTRYPOINT ["/app/bin/entrypoint.sh"]
