// auth_lambda.js - Lambda@Edge to authenticate access to private S3 content
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

// Configure the JWKS client for your Cognito User Pool
const client = jwksClient({
  jwksUri: 'https://cognito-idp.us-east-1.amazonaws.com/us-east-1_qTwCmTkBP/.well-known/jwks.json'
});

// Get signing key
const getSigningKey = (header, callback) => {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) return callback(err);
    const signingKey = key.publicKey || key.rsaPublicKey;
    callback(null, signingKey);
  });
};

// Authentication handler for GET/HEAD requests
const authHandler = async (request, headers) => {
  // Get the Authorization header
  if (!headers.authorization && !headers.Authorization) {
    return {
      status: '401',
      statusDescription: 'Unauthorized',
      body: JSON.stringify({ message: 'No authorization token provided' })
    };
  }

  // Get token from headers (case insensitive)
  const authHeader = headers.authorization ? headers.authorization[0].value : headers.Authorization[0].value;
  const token = authHeader.replace('Bearer ', '');

  try {
    // Get the path and extract user info from it
    const uri = request.uri;
    const pathParts = uri.split('/');

    // Check if path matches expected format (e.g., /private/user-123/file.jpg)
    if (pathParts.length < 3 || !pathParts[2].startsWith('user-')) {
      return {
        status: '403',
        statusDescription: 'Forbidden',
        body: JSON.stringify({ message: 'Invalid path format' })
      };
    }



    // Extract userId from path
    const pathUserId = pathParts[2].replace('user-', '');

    // Verify JWT token
    const decodedToken = jwt.decode(token, { complete: true });
    if (!decodedToken) {
      return {
        status: '401',
        statusDescription: 'Unauthorized',
        body: JSON.stringify({ message: 'Invalid token format' })
      };
    }

    return new Promise((resolve, reject) => {
      jwt.verify(
        token,
        (header, callback) => getSigningKey(header, callback),
        {
          algorithms: ['RS256']
        },
        (err, decoded) => {
          if (err) {
            console.log('Token verification failed:', err);
            resolve({
              status: '401',
              statusDescription: 'Unauthorized',
              body: JSON.stringify({ message: 'Invalid token' })
            });
            return;
          }

          // Check if user in token matches user in path
          const tokenUserId = decoded.sub;
          if (tokenUserId !== pathUserId) {
            resolve({
              status: '403',
              statusDescription: 'Forbidden',
              body: JSON.stringify({ message: 'User does not have permission to access this resource' })
            });
            return;
          }

          // If everything is okay, allow the request
          resolve(request);
        }
      );
    });
  } catch (err) {
    console.log('Error:', err);
    return {
      status: '500',
      statusDescription: 'Internal Server Error',
      body: JSON.stringify({ message: 'Error processing request' })
    };
  }
};

// Upload handler for PUT/POST requests
const uploadHandler = async (request, headers) => {
  // Get the Authorization header for upload requests
  if (!headers.authorization && !headers.Authorization) {
    return {
      status: '401',
      statusDescription: 'Unauthorized',
      body: JSON.stringify({ message: 'No authorization token provided' })
    };
  }

  // Get token from headers (case insensitive)
  const authHeader = headers.authorization ? headers.authorization[0].value : headers.Authorization[0].value;
  const token = authHeader.replace('Bearer ', '');

  try {
    // Verify token and extract user information
    const decodedToken = jwt.decode(token, { complete: true });
    if (!decodedToken) {
      return {
        status: '401',
        statusDescription: 'Unauthorized',
        body: JSON.stringify({ message: 'Invalid token format' })
      };
    }

    return new Promise((resolve, reject) => {
      jwt.verify(
        token,
        (header, callback) => getSigningKey(header, callback),
        {
          algorithms: ['RS256']
        },
        (err, decoded) => {
          if (err) {
            console.log('Token verification failed:', err);
            resolve({
              status: '401',
              statusDescription: 'Unauthorized',
              body: JSON.stringify({ message: 'Invalid token' })
            });
            return;
          }

          // Get user ID from token
          const userId = decoded.sub;

          // Modify the URI to include user ID in the path
          let uri = request.uri;
          const pathParts = uri.split('/');

          // Ensure the path starts with /private/
          if (pathParts.length > 1 && pathParts[1] !== 'private') {
            pathParts[1] = 'private';
          }

          // Add user-id to the path if not present
          if (pathParts.length > 1 && pathParts[1] === 'private') {
            if (pathParts.length <= 2) {
              pathParts.push("user-" + userId); // /private/ -> /private/user-123/
            } else if (!pathParts[2].startsWith('user-')) {
              pathParts.splice(2, 0, "user-" + userId); // /private/file.jpg -> /private/user-123/file.jpg
            } else {
              // If user-XXX exists but doesn't match the token user, replace it
              const pathUserId = pathParts[2].replace('user-', '');
              if (pathUserId !== userId) {
                pathParts[2] = "user-" + userId;
              }
            }
          }

          // Update URI with new path
          request.uri = pathParts.join('/');

          // Add user ID header for logging and tracking
          if (!headers['x-user-id']) {
            headers['x-user-id'] = [{ key: 'X-User-Id', value: userId }];
          }

          // Allow the modified request to proceed
          resolve(request);
        }
      );
    });
  } catch (err) {
    console.log('Error:', err);
    return {
      status: '500',
      statusDescription: 'Internal Server Error',
      body: JSON.stringify({ message: 'Error processing request' })
    };
  }
};

exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;
  const method = request.method;

  // Route request to appropriate handler based on request method
  if (method === 'PUT' || method === 'POST') {
    // Handle upload requests
    return uploadHandler(request, headers);
  } else if (method === 'GET' || method === 'HEAD') {
    // Handle authentication for GET/HEAD requests
    return authHandler(request, headers);
  } else {
    // For other methods, just pass through the request
    return request;
  }
};
