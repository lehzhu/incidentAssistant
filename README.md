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

## Decisions Made
- Used Ruby on Rails for fast development with PostgreSQL
- Integrated Google Gemini for AI-powered suggestions
- Used Bootstrap 5 for responsive design
- Gemini 1.5 Flash AI insights for best speed and cost

## Improvements and Time Spent
I spent 6 hours on this project as I wanted enough time to learn Rails but still timeboxed and focused on a straightforward MVP

With more time, I'd focus on a better analytics engine. I would use Mem0 and/or a more robust Agent framework that understands semantic knowledge better. I could even implement graph based knowledge systems like Neo4j that would represent the knowledge relationships that occur during the incident. 

Capturing tacit knowledge and temporal understanding is extremely important, and I've worked on these key issues for the past year, so it would be very fun to integrate them into this! 
