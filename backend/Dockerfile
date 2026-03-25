FROM ruby:3.2-alpine

# Install dependencies
RUN apk add --no-cache build-base postgresql-dev

# Set working directory
WORKDIR /sinatra

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

# Install gems
RUN bundle install --jobs 4 --retry 3

# Copy application code
COPY . ./app

# Expose port 8081
EXPOSE 8081

# Start the application
CMD ["ruby", "app/sinatra.rb"]