FROM ruby:2.2.5-alpine
MAINTAINER Jon Moter <jmoter@zendesk.com>

RUN mkdir /app
WORKDIR /app

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
ADD vendor /app/vendor

RUN cd /app && bundle install --quiet --local --jobs 4 || bundle check

ADD . /app

EXPOSE 9292
CMD bundle exec rackup --port 9292 --host 0.0.0.0
