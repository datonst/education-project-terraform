const { MongoClient } = require('mongodb');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

class DocumentDBClient {
    constructor() {
        this.client = null;
        this.db = null;
        this.isConnected = false;

        // Only use MONGODB_URI
        this.uri = process.env.MONGODB_URI;

        if (!this.uri) {
            throw new Error('MONGODB_URI environment variable is required');
        }

        // Extract database name from URI for later use
        this.databaseName = this.extractDatabaseFromURI(this.uri);
    }

    extractDatabaseFromURI(uri) {
        let dbName = 'e-learn'; // Default database name
        try {
            const parsedUrl = new URL(uri);
            if (parsedUrl.pathname && parsedUrl.pathname !== '/') {
                // Remove leading slash and any subsequent segments if they exist (e.g. /admin?xyz -> admin)
                const firstPathSegment = parsedUrl.pathname.substring(1).split('/')[0];
                if (firstPathSegment) {
                    dbName = firstPathSegment;
                }
            }
            // If after parsing, dbName is still the default or empty from a path like "mongodb:///" 
            // and the URI had no explicit path, it means no specific DB was in the URI path.
            // In this case, we stick to the default 'e-learn'.
            if (dbName === 'e-learn' && (!parsedUrl.pathname || parsedUrl.pathname === '/')) {
                console.log(`No specific database found in URI path, using default: ${dbName}`);
            }

            const originalDbName = dbName;
            // Sanitize database name - remove invalid characters
            dbName = dbName.replace(/[\/\\."*<>:|?\s\0]/g, '');

            // Ensure the name is not empty after sanitization
            if (!dbName || dbName.length === 0) {
                console.warn(`Database name "${originalDbName}" became empty after sanitization, using default: e-learn`);
                return 'e-learn';
            }

            // Ensure it doesn't start with a number (MongoDB requirement)
            if (/^\d/.test(dbName)) {
                dbName = 'db' + dbName;
            }

            console.log(`Extracted database name: "${originalDbName}" -> sanitized: "${dbName}"`);
            return dbName;
        } catch (error) {
            console.warn(`Could not parse database name from URI or invalid URI provided, using default: e-learn. URI: ${uri}`);
            // Fallback to default for any parsing error, then sanitize the default.
            // This ensures that even the default name is sanitized if it somehow contains invalid characters (though unlikely for 'e-learn').
            dbName = 'e-learn'.replace(/[\/\\."*<>:|?\s\0]/g, '');
            if (/^\d/.test(dbName)) { // Should not happen with 'e-learn' but good for robustness
                dbName = 'db' + dbName;
            }
            console.log(`Sanitized default database name: "${dbName}"`);
            return dbName;
        }
    }

    // Download DocumentDB SSL certificate if not exists
    async ensureSSLCertificate() {
        const certPath = path.join(__dirname, '..', 'global-bundle.pem');

        try {
            // Check if certificate already exists
            if (fs.existsSync(certPath)) {
                console.log(`SSL certificate found: ${certPath}`);
                return certPath;
            }

            console.log('Downloading AWS DocumentDB SSL certificate...');

            const https = require('https');
            const certUrl = 'https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem';

            return new Promise((resolve, reject) => {
                const file = fs.createWriteStream(certPath);

                https.get(certUrl, (response) => {
                    response.pipe(file);
                    file.on('finish', () => {
                        file.close();
                        console.log(`SSL certificate downloaded: ${certPath}`);
                        resolve(certPath);
                    });
                }).on('error', (err) => {
                    fs.unlink(certPath, () => { }); // Delete the file on error
                    console.error('Failed to download SSL certificate:', err);
                    reject(err);
                });
            });
        } catch (error) {
            console.error('SSL certificate setup error:', error);
            return null;
        }
    }

    async connect() {
        try {
            if (this.isConnected) {
                console.log('Already connected to DocumentDB');
                return this.db;
            }

            console.log('Connecting to DocumentDB...');

            // MongoDB client options for DocumentDB
            const options = {
                maxPoolSize: 10,
                serverSelectionTimeoutMS: 5000,
                socketTimeoutMS: 45000,
                connectTimeoutMS: 10000,
                tls: true,
                retryWrites: false,
                authMechanism: 'SCRAM-SHA-1'  // Explicitly use SCRAM-SHA-1 for DocumentDB
            };

            // Set up SSL certificate
            const certPath = await this.ensureSSLCertificate();
            if (certPath && fs.existsSync(certPath)) {
                options.tlsCAFile = certPath;
                console.log('Using SSL certificate file for DocumentDB connection');
            } else {
                console.warn('SSL certificate not found, connection may fail');
            }

            this.client = new MongoClient(this.uri, options);
            await this.client.connect();

            this.db = this.client.db(this.databaseName);
            this.isConnected = true;

            console.log(`Successfully connected to DocumentDB database: ${this.databaseName}`);

            // Test connection
            await this.db.admin().ping();
            console.log('DocumentDB ping successful');

            return this.db;
        } catch (error) {
            console.error('DocumentDB connection error:', error);

            // Provide helpful error messages
            if (error.message.includes('ENOTFOUND')) {
                console.error('Network error: Cannot resolve DocumentDB hostname. Check your connection settings.');
            } else if (error.message.includes('Authentication failed')) {
                console.error('Authentication error: Please check your username and password.');
            } else if (error.message.includes('ssl') || error.message.includes('tls')) {
                console.error('SSL error: DocumentDB requires SSL connection. Ensure SSL certificate is available.');
            }

            throw error;
        }
    }

    async disconnect() {
        try {
            if (this.client && this.isConnected) {
                await this.client.close();
                this.isConnected = false;
                console.log('Disconnected from DocumentDB');
            }
        } catch (error) {
            console.error('DocumentDB disconnection error:', error);
        }
    }

    // Health check method
    async healthCheck() {
        try {
            if (!this.isConnected) {
                return {
                    status: 'disconnected',
                    error: 'Not connected to DocumentDB'
                };
            }

            await this.db.admin().ping();
            const stats = await this.db.stats();

            return {
                status: 'healthy',
                database: this.databaseName,
                connectionType: 'DocumentDB',
                collections: stats.collections,
                dataSize: stats.dataSize,
                storageSize: stats.storageSize,
                indexes: stats.indexes,
                sslEnabled: true
            };
        } catch (error) {
            return {
                status: 'unhealthy',
                error: error.message,
                connectionType: 'DocumentDB'
            };
        }
    }

    // Test connection
    async testConnection() {
        try {
            await this.connect();
            const health = await this.healthCheck();
            console.log('DocumentDB connection test result:', health);
            return health;
        } catch (error) {
            console.error('DocumentDB connection test failed:', error);
            return { status: 'failed', error: error.message };
        }
    }
}

// Singleton instance
let documentDBClient = null;

function getDocumentDBClient() {
    if (!documentDBClient) {
        documentDBClient = new DocumentDBClient();
    }
    return documentDBClient;
}

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('Received SIGINT. Gracefully shutdown...');
    if (documentDBClient) {
        await documentDBClient.disconnect();
    }
    process.exit(0);
});

process.on('SIGTERM', async () => {
    console.log('Received SIGTERM. Gracefully shutting down...');
    if (documentDBClient) {
        await documentDBClient.disconnect();
    }
    process.exit(0);
});

module.exports = {
    DocumentDBClient,
    getDocumentDBClient
}; 