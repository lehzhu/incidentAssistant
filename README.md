# AI-Powered Incident Management System

A real-time incident management system with AI-generated suggestions powered by Google Gemini. Built with Ruby on Rails 8, Bootstrap 5, and Action Cable for WebSocket communication.

## 🚀 Features

- **Real-time Transcript Streaming**: Messages appear one-by-one simulating live incident response
- **AI-Powered Suggestions**: Google Gemini analyzes conversations and generates actionable insights
- **Live Updates**: WebSocket-based real-time updates using Action Cable
- **Categorized Suggestions**: Action items, timeline events, root causes, and missing information
- **Responsive Design**: Modern Bootstrap 5 interface optimized for all devices
- **Background Processing**: Rails jobs handle message streaming and AI analysis

## 📋 Prerequisites

- **Ruby**: 3.2.0 or higher
- **Rails**: 8.0.2
- **PostgreSQL**: Running instance
- **Google AI API Key**: For Gemini integration

## 🛠 Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/lehzhu/incidentAssistant.git
cd incidentAssistant
```

### 2. Install Dependencies
```bash
bundle install
```

### 3. Database Setup
```bash
rails db:create
rails db:migrate
```

### 4. Configure Google AI API Key
Add your Google API key to Rails encrypted credentials:
```bash
EDITOR="nano" rails credentials:edit
```
Add this line:
```yaml
google_api_key: YOUR_ACTUAL_GOOGLE_API_KEY
```

### 5. Seed Sample Data
```bash
rails db:seed
```

### 6. Start the Server
```bash
rails server
```

Visit `http://localhost:3000` to see the application.

## 🎯 How to Use

1. **View Incidents**: Browse the incident list on the homepage
2. **Start Replay**: Click "Start Replay" on an active incident
3. **Watch Live Analysis**: See messages stream in real-time with AI suggestions appearing automatically
4. **Review Suggestions**: AI categorizes findings into action items, timeline events, root causes, and missing info

## 🏗 Architecture

### Models
- **Incident**: Main incident with status tracking
- **TranscriptMessage**: Individual conversation messages with sequencing
- **Suggestion**: AI-generated suggestions with categories and workflow status

### Controllers
- **IncidentsController**: Handles incident listing, viewing, and replay initiation
- **SuggestionsController**: Manages suggestion status updates

### Services
- **AiAnalyzer**: Integrates with Google Gemini for conversation analysis

### Jobs
- **StreamTranscriptJob**: Processes message streaming and triggers AI analysis

### Real-time Features
- **Action Cable**: WebSocket communication for live updates
- **Turbo Streams**: Server-side rendering of real-time content

## 🔧 Configuration

### Environment Variables
- Google API key is stored in Rails encrypted credentials
- Database configuration in `config/database.yml`
- Cable configuration for WebSocket connections

### Background Jobs
The app uses Rails' built-in job processing. For production, consider:
- Sidekiq for Redis-backed job processing
- Solid Queue (included) for database-backed jobs

## 🎨 UI Components

- **Bootstrap 5**: Modern responsive framework
- **Custom SCSS**: Enhanced styling for suggestion cards and layouts
- **Real-time Updates**: Smooth animations and auto-scrolling

## 📦 Key Dependencies

- `rails` (8.0.2) - Web framework
- `pg` - PostgreSQL adapter
- `bootstrap` (~> 5.3) - UI framework
- `sassc-rails` - SCSS processing
- `gemini-ai` - Google Gemini integration
- `turbo-rails` - Real-time features
- `stimulus-rails` - JavaScript framework

## 🚨 Troubleshooting

### Common Issues

**Database Connection Error**
- Ensure PostgreSQL is running
- Check `config/database.yml` settings

**AI Analysis Not Working**
- Verify Google API key is correctly set in credentials
- Check Rails logs for API errors

**Real-time Updates Not Appearing**
- Ensure Action Cable is properly configured
- Check browser console for WebSocket connection errors

**Asset Loading Issues**
- Run `rails assets:precompile` if needed
- Check `app/assets/config/manifest.js` includes required assets

## 📈 Future Enhancements

- [ ] User authentication and authorization
- [ ] Incident templates and categories
- [ ] Advanced AI prompt customization
- [ ] Integration with ticketing systems
- [ ] Real-time collaboration features
- [ ] Metrics and analytics dashboard

## 🤝 Contributing

Feel free to submit issues and pull requests to improve the system!

## 📄 License

This project is available as open source under the terms of the MIT License.
