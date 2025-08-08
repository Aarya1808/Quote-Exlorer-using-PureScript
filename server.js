const http = require('http');
const url = require('url');

// Our quotes database
const quotes = [
  "Stay hungry, stay foolish.",
  "Code is like humor. When you have to explain it, it's bad.",
  "Simplicity is the soul of efficiency.", 
  "Any fool can write code that a computer can understand. Good programmers write code that humans can understand.",
  "The best way to get a project done faster is to start sooner.",
  "First, solve the problem. Then, write the code.",
  "Experience is the name everyone gives to their mistakes.",
  "In order to be irreplaceable, one must always be different.",
  "Java is to JavaScript what car is to Carpet.",
  "Knowledge is power.",
  "The function of good software is to make the complex appear to be simple.",
  "Before software can be reusable it first has to be usable.",
  "Make it work, make it right, make it fast.",
  "Clean code always looks like it was written by someone who cares.",
  "Programs must be written for people to read, and only incidentally for machines to execute."
];

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type'
};

// Helper to send JSON response
function sendJSON(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    ...corsHeaders
  });
  res.end(JSON.stringify(data));
}

// Helper for CORS preflight
function sendCORS(res) {
  res.writeHead(200, corsHeaders);
  res.end();
}

// Get random quote
function getRandomQuote() {
  const randomIndex = Math.floor(Math.random() * quotes.length);
  return quotes[randomIndex];
}

// Request handler
function handleRequest(req, res) {
  const parsedUrl = url.parse(req.url, true);
  const method = req.method;
  const pathname = parsedUrl.pathname;
  
  console.log(`Received ${method} request to ${pathname}`);
  
  // Handle CORS preflight
  if (method === 'OPTIONS') {
    return sendCORS(res);
  }
  
  // Handle GET requests
  if (method === 'GET') {
    switch (pathname) {
      case '/api/quote':
        const randomQuote = getRandomQuote();
        return sendJSON(res, 200, { quote: randomQuote });
        
      case '/api/quotes':
        return sendJSON(res, 200, { quotes: quotes });
        
      case '/health':
        return sendJSON(res, 200, { status: 'ok' });
        
      default:
        return sendJSON(res, 404, { error: 'Not found' });
    }
  }
  
  // Method not allowed
  sendJSON(res, 405, { error: 'Method not allowed' });
}

// Create and start server
const server = http.createServer(handleRequest);
const port = 3001;

server.listen(port, 'localhost', () => {
  console.log('🚀 Quote API Server running on http://localhost:' + port);
  console.log('Available endpoints:');
  console.log('  GET /api/quote  - Get a random quote');
  console.log('  GET /api/quotes - Get all quotes');
  console.log('  GET /health     - Health check');
});

// Handle server errors
server.on('error', (err) => {
  console.error('Server error:', err);
});