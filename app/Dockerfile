FROM ruby:3.2-alpine

# Install dependencies
RUN apk add --no-cache build-base

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile .
RUN bundle install --jobs 4 --retry 3

# Copy application code
COPY app.rb .
COPY views/ views/

# Expose port 8080
EXPOSE 8080

# Start the application
CMD ["ruby", "app.rb"]
