const express = require('express');

// Make dotenv optional - it will work in development but not required in Docker
try {
    require('dotenv').config();
} catch (error) {
    console.log('dotenv not available or .env file not found - using environment variables');
}

const { getDocumentDBClient } = require('./database/documentdb');

const app = express();
const PORT = process.env.PORT || 3000;

// Basic middleware
app.use(express.json());

// Initialize DocumentDB connection
let dbClient = null;
let connectionStatus = {
    status: 'not_tested',
    message: 'Connection not tested yet',
    timestamp: null,
    details: null
};

async function testDocumentDBConnection() {
    try {
        console.log('Testing DocumentDB connection...');
        connectionStatus.status = 'testing';
        connectionStatus.message = 'Testing connection...';
        connectionStatus.timestamp = new Date().toISOString();

        dbClient = getDocumentDBClient();
        const result = await dbClient.testConnection();

        if (result.status === 'healthy') {
            connectionStatus.status = 'connected';
            connectionStatus.message = 'DocumentDB connection successful';
            connectionStatus.details = result;
        } else {
            connectionStatus.status = 'failed';
            connectionStatus.message = result.error || 'Connection failed';
            connectionStatus.details = result;
        }

        connectionStatus.timestamp = new Date().toISOString();
        console.log('Connection test completed:', connectionStatus);

    } catch (error) {
        connectionStatus.status = 'error';
        connectionStatus.message = error.message;
        connectionStatus.details = { error: error.toString() };
        connectionStatus.timestamp = new Date().toISOString();
        console.error('Connection test error:', error);
    }
}

// Create API router
const apiRouter = express.Router();

// Main endpoint to display connection status (moved to /api)
apiRouter.get('/', (req, res) => {
    const statusHtml = `
    <!DOCTYPE html>
    <html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>DocumentDB Connection Status</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                max-width: 800px;
                margin: 0 auto;
                padding: 20px;
                background-color: #f5f5f5;
            }
            .container {
                background: white;
                border-radius: 10px;
                padding: 30px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            .header {
                text-align: center;
                margin-bottom: 30px;
            }
            .status-card {
                border: 2px solid #ddd;
                border-radius: 8px;
                padding: 20px;
                margin-bottom: 20px;
                text-align: center;
            }
            .status-connected {
                border-color: #28a745;
                background-color: #d4edda;
                color: #155724;
            }
            .status-failed, .status-error {
                border-color: #dc3545;
                background-color: #f8d7da;
                color: #721c24;
            }
            .status-testing {
                border-color: #ffc107;
                background-color: #fff3cd;
                color: #856404;
            }
            .status-not_tested {
                border-color: #6c757d;
                background-color: #e2e3e5;
                color: #383d41;
            }
            .status-icon {
                font-size: 48px;
                margin-bottom: 10px;
            }
            .details {
                background: #f8f9fa;
                border-radius: 5px;
                padding: 15px;
                margin-top: 20px;
                text-align: left;
            }
            .test-button {
                background-color: #007bff;
                color: white;
                border: none;
                padding: 12px 24px;
                border-radius: 5px;
                font-size: 16px;
                cursor: pointer;
                margin: 10px;
            }
            .test-button:hover {
                background-color: #0056b3;
            }
            .test-button:disabled {
                background-color: #6c757d;
                cursor: not-allowed;
            }
            pre {
                background: #f1f3f4;
                padding: 10px;
                border-radius: 4px;
                overflow-x: auto;
                font-size: 12px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔗 DocumentDB Connection Test</h1>
                <p>Kiểm tra trạng thái kết nối đến AWS DocumentDB</p>
            </div>

            <div class="status-card status-${connectionStatus.status}">
                <div class="status-icon">
                    ${connectionStatus.status === 'connected' ? '✅' :
            connectionStatus.status === 'testing' ? '⏳' :
                connectionStatus.status === 'failed' || connectionStatus.status === 'error' ? '❌' : '❓'}
                </div>
                <h2>Trạng thái: ${connectionStatus.status.toUpperCase()}</h2>
                <p><strong>${connectionStatus.message}</strong></p>
                ${connectionStatus.timestamp ? `<p><small>Thời gian: ${connectionStatus.timestamp}</small></p>` : ''}
            </div>

            <div style="text-align: center;">
                <button class="test-button" onclick="testConnection()" ${connectionStatus.status === 'testing' ? 'disabled' : ''}>
                    ${connectionStatus.status === 'testing' ? 'Đang kiểm tra...' : '🔄 Kiểm tra kết nối'}
                </button>
                <button class="test-button" onclick="location.reload()">
                    📄 Tải lại trang
                </button>
            </div>

            ${connectionStatus.details ? `
                <div class="details">
                    <h3>📋 Chi tiết kết nối:</h3>
                    <pre>${JSON.stringify(connectionStatus.details, null, 2)}</pre>
                </div>
            ` : ''}

            <div class="details">
                <h3>⚙️ Cấu hình môi trường:</h3>
                <ul>
                    <li><strong>MONGODB_URI:</strong> ${process.env.MONGODB_URI ? '✅ Đã cấu hình' : '❌ Chưa cấu hình'}</li>
                    <li><strong>PORT:</strong> ${PORT}</li>
                    <li><strong>NODE_ENV:</strong> ${process.env.NODE_ENV || 'development'}</li>
                    ${process.env.MONGODB_URI ? `<li><strong>Database:</strong> ${dbClient?.databaseName || 'Chưa xác định'}</li>` : ''}
                </ul>
            </div>
        </div>

        <script>
            async function testConnection() {
                const button = document.querySelector('.test-button');
                button.disabled = true;
                button.textContent = 'Đang kiểm tra...';
                
                try {
                    const response = await fetch('/api/test-connection', { method: 'POST' });
                    const result = await response.json();
                    
                    // Reload page to show updated status
                    setTimeout(() => {
                        location.reload();
                    }, 1000);
                } catch (error) {
                    console.error('Test failed:', error);
                    alert('Lỗi khi kiểm tra kết nối: ' + error.message);
                    button.disabled = false;
                    button.textContent = '🔄 Kiểm tra kết nối';
                }
            }

            // Auto refresh every 30 seconds if testing
            if ('${connectionStatus.status}' === 'testing') {
                setTimeout(() => {
                    location.reload();
                }, 3000);
            }
        </script>
    </body>
    </html>
    `;

    res.send(statusHtml);
});

// API endpoint to trigger connection test
apiRouter.post('/test-connection', async (req, res) => {
    await testDocumentDBConnection();
    res.json(connectionStatus);
});

// API endpoint to get current status
apiRouter.get('/status', (req, res) => {
    res.json(connectionStatus);
});

// Health check endpoint
apiRouter.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        port: PORT,
        env: process.env.NODE_ENV || 'development'
    });
});

// Mount API router at /api
app.use('/api', apiRouter);

// Redirect root to /api
app.get('/', (req, res) => {
    res.redirect('/api');
});

// Start server
async function startServer() {
    try {
        const server = app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 DocumentDB Connection Test Server đang chạy tại:`);
            console.log(`   http://localhost:${PORT}/api`);
            console.log(`   Môi trường: ${process.env.NODE_ENV || 'development'}`);
            console.log('\n📝 Hướng dẫn sử dụng:');
            console.log('   1. Giao diện: http://localhost:' + PORT + '/api');
            console.log('   2. API Status: http://localhost:' + PORT + '/api/status');
            console.log('   3. Health Check: http://localhost:' + PORT + '/api/health');
            console.log('   4. Test Connection: http://localhost:' + PORT + '/api/test-connection');
            console.log('   5. Nhấn nút "Kiểm tra kết nối" để test DocumentDB\n');
        });

        // Initial connection test
        setTimeout(() => {
            testDocumentDBConnection();
        }, 2000);

        // Graceful shutdown
        process.on('SIGTERM', () => {
            console.log('SIGTERM received, shutting down gracefully');
            server.close(() => {
                console.log('HTTP server closed');
                if (dbClient) {
                    dbClient.disconnect();
                }
            });
        });

    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

startServer(); 