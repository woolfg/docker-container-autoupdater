const express = require('express');
const fs = require('fs');
const path = require('path');

// define environment variables
const PORT = process.env.PORT || 3000;
const HOOK = process.env.HOOK || '/hook123456';
const TRIGGER_FILE = process.env.TRIGGER_FILE || '/tmp/update-trigger';

// create express app
const app = express();

app.get(HOOK, (req, res) => {
  try {
    // Create trigger file with timestamp
    const timestamp = new Date().toISOString();
    fs.writeFileSync(TRIGGER_FILE, timestamp);
    console.log(`Trigger file created at ${TRIGGER_FILE} with timestamp: ${timestamp}`);
    res.status(200).send('Update trigger created');
  } catch (err) {
    console.error('Error creating trigger file:', err);
    res.status(500).send('Failed to create update trigger');
  }
})

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
  console.log(`Waiting for hook on ${HOOK}`)
})