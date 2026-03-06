FROM ruby:3.2-alpine

# Install dependencies
RUN apk add --no-cache build-base

# Set working directory
WORKDIR /sinatra

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

# Install gems
RUN bundle install --jobs 4 --retry 3

# Copy application code
COPY app/ ./app

# Expose port 8080
EXPOSE 8080

# Start the application
CMD ["ruby", "app/app.rb"]