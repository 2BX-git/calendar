require('dotenv').config();
const express = require('express');
const { google } = require('googleapis');
const fs = require('fs');
const app = express();
const port = process.env.PORT || 3001;

// Configuração do Google OAuth2
const oauth2Client = new google.auth.OAuth2(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET,
  process.env.GOOGLE_REDIRECT_URI
);

// Endpoint SSE para MCP
app.get('/sse', (req, res) => {
  oauth2Client.setCredentials({
    refresh_token: process.env.GOOGLE_REFRESH_TOKEN,
  });

  const calendar = google.calendar({ version: 'v3', auth: oauth2Client });

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  const sendEvent = (data) => {
    res.write(`data: ${JSON.stringify(data)}\n\n`);
  };

  calendar.events.list(
    {
      calendarId: 'primary',
      timeMin: new Date().toISOString(),
      maxResults: 10,
      singleEvents: true,
      orderBy: 'startTime',
    },
    (err, response) => {
      if (err) {
        sendEvent({ error: err.message });
        return;
      }
      const events = response.data.items.map(event => ({
        id: event.id,
        summary: event.summary,
        start: event.start.dateTime || event.start.date,
        end: event.end.dateTime || event.end.date,
      }));
      sendEvent({ events });
    }
  );

  req.on('close', () => {
    res.end();
  });
});

// Endpoint para autenticação
app.get('/auth', (req, res) => {
  const url = oauth2Client.generateAuthUrl({
    scope: ['https://www.googleapis.com/auth/calendar.readonly'],
  });
  res.redirect(url);
});

// Endpoint de callback que salva o code
app.get('/auth/callback', async (req, res) => {
  const { code } = req.query;
  // Salva o code em um arquivo temporário
  fs.writeFileSync('/tmp/auth_code', code);
  res.send('Código de autorização obtido! Você pode fechar esta janela.');
});

app.listen(port, () => {
  console.log(`Servidor MCP rodando na porta ${port}`);
});
