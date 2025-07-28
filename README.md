# Incident Management Demo

## How to Start Your Server
1. **Clone the repository**
   ```
   git clone https://github.com/lehzhu/incidentAssistant.git
   cd incidentAssistant
   ```
2. **Install dependencies and set up the database**
   ```
   bundle install
   rails db:create db:migrate
   ```
3. **Set your Google API Key**
   ```
   EDITOR="nano" rails credentials:edit
   # Add: google_api_key: YOUR_GOOGLE_API_KEY
   ```  
4. **Seed the database**
   ```
   rails db:seed
   ```
5. **Start all services** (Choose one option):

   **Option A: Using Foreman (Recommended - starts all services in one terminal)**
   ```
   bin/dev
   ```
   Press Ctrl+C to stop all services.

   **Option B: Using tmux (separate windows for each service)**
   ```
   bin/dev-tmux      # Start all services
   bin/dev-stop      # Stop all services
   ```
   
   **Option C: Simple script (all services in one terminal)**
   ```
   bin/dev-simple
   ```
   Press Ctrl+C to stop all services.

   **Option D: Manual start (original method - requires 3 terminals)**
   ```
   # Terminal 1:
   redis-server
   
   # Terminal 2:
   bundle exec sidekiq
   
   # Terminal 3:
   rails server
   ```

## How to Simulate the Replay
- Ensure `transcript.json` is in the project root.
- Custom upload of the transcript will be in version 0.3.0-beta

## Decisions Made
- Used Ruby on Rails for fast development with PostgreSQL
- Integrated Google Gemini for AI-powered suggestions
- Used Bootstrap 5 for responsive design
- Gemini 1.5 Flash AI insights for best speed and cost

## Improvements and Time Spent
I spent 6 hours on this project initially as I wanted enough time to learn Rails but still timeboxed and focused on a straightforward MVP. 

There was a lot of issues with both my decisions and my structuring of the backend. I revisited the AI insights functionality a few days later, but it was still unstable. 

A few weeks later, I decided to rewrite the database system using a much more robust system using a lot of what I've learned building other backend systems recently. I spent 5 additional hours on the rewrite and released it as v.0.3.0-beta. 

Planned features are in issues, but the main one is company or team specific histories. Issues that occur consistently across incidents should be flagged, for example. Retrieving this data should be done with ZeroEntropy for maximum speed and specificity. 

Voice agents are also a helpful addition if the reviewing engineer is not in a position to appropriately read the report/dashboard (ie. out and about). 


