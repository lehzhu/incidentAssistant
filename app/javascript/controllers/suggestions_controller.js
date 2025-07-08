import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["container"]
  static values = { incidentId: Number }

  connect() {
    console.log("Suggestions controller connected for incident", this.incidentIdValue)
    
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { 
        channel: "SuggestionsChannel", 
        incident_id: this.incidentIdValue 
      },
      {
        received: (data) => {
          console.log("Received data:", data)
          this.handleMessage(data)
        },
        
        connected: () => {
          console.log("Connected to suggestions channel")
        },
        
        disconnected: () => {
          console.log("Disconnected from suggestions channel")
        }
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.consumer) {
      this.consumer.disconnect()
    }
  }

  handleMessage(data) {
    if (data.type === 'new_suggestion') {
      this.addSuggestion(data.suggestion)
    } else if (data.type === 'replay_complete') {
      this.showCompletionMessage()
    }
  }

  addSuggestion(suggestion) {
    // Remove "no suggestions" message if it exists
    const noSuggestions = document.getElementById('no-suggestions')
    if (noSuggestions) {
      noSuggestions.remove()
    }

    // Create suggestion element
    const suggestionHtml = this.createSuggestionHTML(suggestion)
    
    // Add to container (at the top)
    this.containerTarget.insertAdjacentHTML('afterbegin', suggestionHtml)
    
    // Animate the new suggestion
    const newElement = this.containerTarget.firstElementChild
    this.animateNewSuggestion(newElement)
    
    // Update counter
    this.updateSuggestionCount()
  }

  createSuggestionHTML(suggestion) {
    const categoryConfigs = {
      'action_item': { color: 'primary', icon: 'check-square' },
      'timeline_event': { color: 'success', icon: 'clock-history' },
      'root_cause': { color: 'warning', icon: 'search' },
      'missing_info': { color: 'info', icon: 'info-circle' }
    }
    
    const config = categoryConfigs[suggestion.category] || { color: 'secondary', icon: 'question' }
    
    return `
      <div class="suggestion-card border-start border-${config.color} border-3 bg-white m-3 p-3 rounded shadow-sm" 
           id="suggestion-${suggestion.id}"
           data-suggestion-id="${suggestion.id}"
           style="opacity: 0; transform: translateY(-20px);">
        
        <div class="d-flex justify-content-between align-items-start mb-2">
          <span class="badge bg-${config.color} bg-opacity-10 text-${config.color} border border-${config.color}">
            <i class="bi bi-${config.icon} me-1"></i>
            ${suggestion.category.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
          </span>
          
          <div class="btn-group btn-group-sm" role="group">
            <button type="button" 
                    class="btn btn-outline-success btn-sm"
                    onclick="updateSuggestion(${suggestion.id}, 'accepted')"
                    title="Accept suggestion">
              <i class="bi bi-check"></i>
            </button>
            <button type="button" 
                    class="btn btn-outline-danger btn-sm"
                    onclick="updateSuggestion(${suggestion.id}, 'dismissed')"
                    title="Dismiss suggestion">
              <i class="bi bi-x"></i>
            </button>
          </div>
        </div>
        
        <h6 class="fw-bold mb-2 text-dark">${suggestion.title}</h6>
        <p class="text-muted small mb-0 lh-sm">${suggestion.description}</p>
      </div>
    `
  }

  animateNewSuggestion(element) {
    // Smooth slide-in animation
    setTimeout(() => {
      element.style.transition = 'all 0.4s ease-out'
      element.style.opacity = '1'
      element.style.transform = 'translateY(0)'
    }, 50)
  }

  updateSuggestionCount() {
    const counter = document.getElementById('suggestion-count')
    if (counter) {
      const count = this.containerTarget.querySelectorAll('.suggestion-card').length
      counter.textContent = count
    }
  }

  showCompletionMessage() {
    // Show completion notification
    const alert = document.createElement('div')
    alert.className = 'alert alert-success alert-dismissible fade show'
    alert.innerHTML = `
      <i class="bi bi-check-circle me-2"></i>
      <strong>Replay Complete!</strong> All messages have been processed and analyzed.
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `
    
    // Insert before the main content
    const container = document.querySelector('.container-fluid')
    const mainContent = container.querySelector('.row')
    container.insertBefore(alert, mainContent)
  }
}

// Global function for suggestion updates
window.updateSuggestion = async function(suggestionId, status) {
  try {
    const response = await fetch(`/suggestions/${suggestionId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        suggestion: { status: status }
      })
    })
    
    if (response.ok) {
      const card = document.querySelector(`[data-suggestion-id="${suggestionId}"]`)
      if (card) {
        // Update the card to show the new status
        card.style.opacity = '0.7'
        
        // Remove action buttons
        const btnGroup = card.querySelector('.btn-group')
        if (btnGroup) {
          btnGroup.innerHTML = `
            <span class="badge bg-${status === 'accepted' ? 'success' : 'secondary'}">
              <i class="bi bi-${status === 'accepted' ? 'check' : 'x'} me-1"></i>
              ${status.toUpperCase()}
            </span>
          `
        }
      }
    }
  } catch (error) {
    console.error('Error updating suggestion:', error)
    alert('Failed to update suggestion. Please try again.')
  }
}
