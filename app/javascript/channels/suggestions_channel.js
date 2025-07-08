import consumer from "./consumer";

export function subscribeTo(incidentId, callbacks) {
  return consumer.subscriptions.create(
    { channel: "SuggestionsChannel", incident_id: incidentId },
    {
      connected() {
        console.log('Connected to SuggestionsChannel for incident', incidentId);
      },
      
      disconnected() {
        console.log('Disconnected from SuggestionsChannel');
      },
      
      received(data) {
        console.log('Received data:', data);
        if (callbacks.received) {
          callbacks.received(data);
        }
      }
    }
  );
}
