const express = require('express');

// define environment variables
const PORT = process.env.PORT || 3000;
const HOOK = process.env.HOOK || '/hook123456789';

// create express app
const app = express();

let updateRunning = false;

app.get(HOOK, (req, res) => {
  // avoid to start multiple concurrent updates
  if (!updateRunning) {
    updateRunning = true;
    const { exec } = require('child_process');
    exec('./update.sh', (err, stdout, stderr) => {
      if (err) {
        console.error(err);
      } else {
        console.log(stdout);
      }
      updateRunning = false;
    })
    res.status(200).send('Update started');
  } else {
    res.status(429).send('Update already running');
  }
})

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
  console.log(`Waiting for hook on ${HOOK}`)
})