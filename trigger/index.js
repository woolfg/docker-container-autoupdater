const express = require('express');
const fs = require('fs');
const path = require('path');

// define environment variables
const PORT = process.env.PORT || 3000;
const HOOK = process.env.HOOK || '/hook123456789';
const TRIGGER_FILE = process.env.TRIGGER_FILE || '/shared/update-trigger';

// create express app
const app = express();

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Webhook endpoint
app.get(HOOK, (req, res) => {
  try {
    // Create trigger file with timestamp
    const timestamp = new Date().toISOString();
    
    // Ensure the shared directory exists
    const triggerDir = path.dirname(TRIGGER_FILE);
    if (!fs.existsSync(triggerDir)) {
      fs.mkdirSync(triggerDir, { recursive: true });
    }
    
    fs.writeFileSync(TRIGGER_FILE, timestamp);
    console.log(`Trigger file created at ${TRIGGER_FILE} with timestamp: ${timestamp}`);
    res.status(200).json({ 
      message: 'Update trigger created',
      timestamp: timestamp,
      triggerFile: TRIGGER_FILE
    });
  } catch (err) {
    console.error('Error creating trigger file:', err);
    res.status(500).json({ 
      error: 'Failed to create update trigger',
      details: err.message
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

app.listen(PORT, () => {
  console.log(`Trigger service listening on port ${PORT}`);
  console.log(`Health check available at /health`);
  console.log(`Webhook endpoint: ${HOOK}`);
  console.log(`Trigger file location: ${TRIGGER_FILE}`);
});
