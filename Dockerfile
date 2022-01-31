FROM ruby:2.5

WORKDIR /usr/src/app

COPY Gemfile minimal-mistakes-jekyll.gemspec ./

RUN bundle install

VOLUME /usr/src/app

EXPOSE 4000

CMD ["jekyll", "serve"]
