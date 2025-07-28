import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = [
    "container", "progressBar", "transcriptContainer", "transcriptCount", "suggestionCount", "replayButton"
  ]
  static values = { incidentId: Number }

  connect() {
    console.log("Suggestions controller connected for incident", this.incidentIdValue);
    this.totalMessages = 0; // We'll get this from the first transcript message
    this.connectToActionCable();
    // This is a global function, which is not ideal. We'll leave it for now but it's a candidate for refactoring.
    window.updateSuggestion = this.updateSuggestionStatus.bind(this);
    
    // Apply initial filter on page load
    this.applyInitialFilter();
    this.initializeModals();
  }

  connectToActionCable() {
    this.consumer = createConsumer();
    this.subscription = this.consumer.subscriptions.create(
      { 
        channel: "SuggestionsChannel", 
        incident_id: this.incidentIdValue 
      },
      {
        received: (data) => {
          console.log("Received data:", data);
          this.handleMessage(data);
        },
        
        connected: () => {
          console.log("Connected to suggestions channel");
        },
        
        disconnected: () => {
          console.log("Disconnected from suggestions channel");
        }
      }
    );
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.consumer) {
      this.consumer.disconnect()
    }
  }

  // Start replay action
  startReplay(event) {
    const button = this.replayButtonTarget;
    button.disabled = true;
    button.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Starting...';

    fetch(`/incidents/${this.incidentIdValue}/start_replay`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.message) {
        button.innerHTML = '<i class="bi bi-check me-1"></i>Replay Running';
        button.classList.replace('btn-primary', 'btn-success');
      } else {
        button.disabled = false;
        button.innerHTML = 'Start Replay';
        alert('Error: ' + (data.error || 'Unknown error'));
      }
    })
    .catch(error => {
      console.error('Error starting replay:', error);
      button.disabled = false;
      button.innerHTML = 'Start Replay';
    });
  }

  // Central message handler
  handleMessage(data) {
    console.log("Received data:", data);
    switch (data.type) {
      case 'transcript_message':
        this.addTranscriptMessage(data.data);
        break;
      case 'ai_suggestion':
        this.addSuggestion(data.data.suggestion);
        break;
      case 'replay_complete':
        this.showCompletionMessage();
        break;
    }
  }

  // Add transcript message to the view
  addTranscriptMessage(message) {
    if (!this.totalMessages) {
      this.totalMessages = message.total;
    }

    const placeholder = this.transcriptContainerTarget.querySelector('#transcript-placeholder');
    if (placeholder) placeholder.remove();

    const messageElement = document.createElement('div');
    messageElement.classList.add('mb-2', 'small', 'transcript-message');
    messageElement.innerHTML = `<strong>${message.speaker}:</strong> ${message.text}`;
    this.transcriptContainerTarget.appendChild(messageElement);
    this.transcriptContainerTarget.scrollTop = this.transcriptContainerTarget.scrollHeight;

    // Update count and progress bar
    this.transcriptCountTarget.textContent = message.sequence;
    const progress = (message.sequence / this.totalMessages) * 100;
    this.progressBarTarget.style.width = `${progress}%`;
  }

  addSuggestion(suggestion) {
    // Remove "no suggestions" message if it exists
    const noSuggestions = document.getElementById('no-suggestions');
    if (noSuggestions) {
      noSuggestions.remove();
    }

    // Create suggestion element
    const suggestionHtml = this.createSuggestionHTML(suggestion);
    
    // Add to container (at the top)
    this.containerTarget.insertAdjacentHTML('afterbegin', suggestionHtml);
    
    // Animate the new suggestion
    const newElement = this.containerTarget.firstElementChild;
    this.animateNewSuggestion(newElement);
    
    // Update counter
    this.updateSuggestionCount();
  }

  createSuggestionHTML(suggestion) {
    const categoryConfigs = {
      'action_item': { color: 'primary', icon: 'check-square' },
      'timeline_event': { color: 'success', icon: 'clock-history' },
      'root_cause': { color: 'warning', icon: 'search' },
      'missing_info': { color: 'info', icon: 'info-circle' }
    }
    
    const config = categoryConfigs[suggestion.category] || { color: 'secondary', icon: 'question' }
    const isImportant = suggestion.importance_score >= 70
    
    return `
      <div class="suggestion-card border-start border-${config.color} border-3 bg-white m-3 p-3 rounded shadow-sm" 
           id="suggestion-${suggestion.id}"
           data-suggestion-id="${suggestion.id}"
           data-category="${suggestion.category}"
           data-important="${isImportant}"
           style="opacity: 0; transform: translateY(-20px);">
        
        <div class="d-flex justify-content-between align-items-start mb-2">
          <div>
            <span class="badge bg-${config.color} bg-opacity-10 text-${config.color} border border-${config.color}">
              <i class="bi bi-${config.icon} me-1"></i>
              ${suggestion.category.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
            </span>
            ${isImportant ? '<span class="badge bg-danger bg-opacity-10 text-danger border border-danger ms-1" title="Important"><i class="bi bi-exclamation-triangle-fill"></i></span>' : ''}
          </div>
          
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
        
        ${suggestion.confidence_score ? `
          <div class="mt-2">
            <small class="text-muted">
              <i class="bi bi-speedometer me-1"></i>
              Confidence: ${suggestion.confidence_score}%
            </small>
          </div>
        ` : ''}
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
    const count = this.containerTarget.querySelectorAll('.suggestion-card').length;
    this.suggestionCountTarget.textContent = count;
  }

  showCompletionMessage() {
    this.progressBarTarget.style.width = '100%';
    this.progressBarTarget.classList.add('bg-success');

    // Update button state
    const button = this.replayButtonTarget;
    if(button) {
      button.innerHTML = '<i class="bi bi-check-circle me-1"></i>Complete';
    }
    // Other completion logic...
  }

  applyFilter(event) {
    const filterValue = event.target.id;
    const suggestions = this.containerTarget.querySelectorAll('.suggestion-card');
    let visibleCount = 0;

    suggestions.forEach(suggestion => {
      const shouldShow = filterValue === 'all' || 
                        (filterValue === 'important' && suggestion.dataset.important === 'true') ||
                        (filterValue !== 'important' && suggestion.dataset.category === filterValue);

      suggestion.style.display = shouldShow ? 'block' : 'none';
      if (shouldShow) visibleCount++;
    });

    // Update visible suggestion count
    this.suggestionCountTarget.textContent = visibleCount;
  }

  applyInitialFilter() {
    // Apply 'important' filter on initial load
    const importantFilter = document.getElementById('important');
    if (importantFilter && importantFilter.checked) {
      this.applyFilter({ target: importantFilter });
    }
  }

  async updateSuggestionStatus(suggestionId, status) {
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
      });
      
      if (response.ok) {
        const card = document.querySelector(`[data-suggestion-id="${suggestionId}"]`);
        if (card) {
          // Update the card to show the new status
          card.style.opacity = '0.7';
          
          // Remove action buttons
          const btnGroup = card.querySelector('.btn-group');
          if (btnGroup) {
            btnGroup.innerHTML = `
              <span class="badge bg-${status === 'accepted' ? 'success' : 'secondary'}">
                <i class="bi bi-${status === 'accepted' ? 'check' : 'x'} me-1"></i>
                ${status.toUpperCase()}
              </span>
            `;
          }
        }
      }
    } catch (error) {
      console.error('Error updating suggestion:', error);
      alert('Failed to update suggestion. Please try again.');
    }
  }

  initializeModals() {
    // Create modals dynamically
    this.createTaskModal();
    this.createFlagModal();
  }

  createTaskModal() {
    const modalHtml = `
      <div class="modal fade" id="assignTaskModal" tabindex="-1">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">Assign Task</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
              <form id="taskForm">
                <div class="mb-3">
                  <label class="form-label">Assignee</label>
                  <input type="text" class="form-control" id="taskAssignee" required>
                </div>
                <div class="mb-3">
                  <label class="form-label">Task Description</label>
                  <textarea class="form-control" id="taskDescription" rows="3" required></textarea>
                </div>
              </form>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
              <button type="button" class="btn btn-primary" onclick="window.submitTask()">Create Task</button>
            </div>
          </div>
        </div>
      </div>
    `;
    document.body.insertAdjacentHTML('beforeend', modalHtml);
    window.submitTask = this.submitTask.bind(this);
  }

  createFlagModal() {
    const modalHtml = `
      <div class="modal fade" id="flagModal" tabindex="-1">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">Flag Unusual Behavior</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
              <form id="flagForm">
                <div class="mb-3">
                  <label class="form-label">What's the issue?</label>
                  <select class="form-select" id="flagType" required>
                    <option value="">Select issue type...</option>
                    <option value="misbehavior">Participant misbehavior</option>
                    <option value="technical">Technical issue with analysis</option>
                    <option value="transcript">Transcript loading issue</option>
                    <option value="ai_error">AI analysis error</option>
                    <option value="other">Other</option>
                  </select>
                </div>
                <div class="mb-3">
                  <label class="form-label">Description</label>
                  <textarea class="form-control" id="flagDescription" rows="3" required></textarea>
                </div>
                <div class="mb-3">
                  <label class="form-label">Your Name (optional)</label>
                  <input type="text" class="form-control" id="flagReporter">
                </div>
              </form>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
              <button type="button" class="btn btn-warning" onclick="window.submitFlag()">Submit Flag</button>
            </div>
          </div>
        </div>
      </div>
    `;
    document.body.insertAdjacentHTML('beforeend', modalHtml);
    window.submitFlag = this.submitFlag.bind(this);
  }

  assignTask() {
    const modal = new bootstrap.Modal(document.getElementById('assignTaskModal'));
    modal.show();
  }

  flagUnusual() {
    const modal = new bootstrap.Modal(document.getElementById('flagModal'));
    modal.show();
  }

  exportSummary() {
    window.location.href = `/incidents/${this.incidentIdValue}/export`;
  }

  async submitTask() {
    const assignee = document.getElementById('taskAssignee').value;
    const description = document.getElementById('taskDescription').value;

    try {
      const response = await fetch(`/incidents/${this.incidentIdValue}/tasks`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          task: { assignee, description }
        })
      });

      const data = await response.json();
      if (data.success) {
        bootstrap.Modal.getInstance(document.getElementById('assignTaskModal')).hide();
        document.getElementById('taskForm').reset();
        alert('Task created successfully!');
      } else {
        alert('Error: ' + (data.errors || ['Unknown error']).join(', '));
      }
    } catch (error) {
      console.error('Error creating task:', error);
      alert('Failed to create task. Please try again.');
    }
  }

  async submitFlag() {
    const flagType = document.getElementById('flagType').value;
    const description = document.getElementById('flagDescription').value;
    const reporter = document.getElementById('flagReporter').value || 'Anonymous';

    try {
      const response = await fetch(`/incidents/${this.incidentIdValue}/flags`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          flag: { flag_type: flagType, description, reporter }
        })
      });

      const data = await response.json();
      if (data.success) {
        bootstrap.Modal.getInstance(document.getElementById('flagModal')).hide();
        document.getElementById('flagForm').reset();
        alert('Flag submitted successfully!');
      } else {
        alert('Error: ' + (data.errors || ['Unknown error']).join(', '));
      }
    } catch (error) {
      console.error('Error creating flag:', error);
      alert('Failed to submit flag. Please try again.');
    }
  }

  scrollToMessage(event) {
    const sequence = event.currentTarget.dataset.sequence;
    const messages = this.transcriptContainerTarget.querySelectorAll('.transcript-message');
    
    if (messages[sequence - 1]) {
      messages[sequence - 1].scrollIntoView({ behavior: 'smooth', block: 'center' });
      messages[sequence - 1].classList.add('bg-warning', 'bg-opacity-25');
      setTimeout(() => {
        messages[sequence - 1].classList.remove('bg-warning', 'bg-opacity-25');
      }, 2000);
    }
  }
}
