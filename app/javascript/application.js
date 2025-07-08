// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { createConsumer } from "@rails/actioncable"

// Initialize ActionCable globally
window.App = {
  cable: createConsumer()
};

console.log('ActionCable initialized:', window.App);
