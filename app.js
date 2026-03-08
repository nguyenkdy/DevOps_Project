const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('<h1>Chào mừng đến với Web App High Availability cua Nguyen Khanh Duy trên Linux!</h1><p>Phiên bản: 1.0.0</p>');
});

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

app.listen(port, () => {
  console.log(`Web app đang chạy tại http://localhost:${port}`);
});
