FROM ruby:3.2-slim

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
  && rm -rf /var/lib/apt/lists/*

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