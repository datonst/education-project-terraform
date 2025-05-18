# Hướng dẫn triển khai Cognito CloudFront Authentication

Đây là hướng dẫn về cách triển khai và sử dụng giải pháp phân quyền xác thực người dùng với Amazon Cognito, CloudFront và Lambda@Edge. Giải pháp này cho phép:

1. Xác thực người dùng thông qua Amazon Cognito
2. Chỉ cho phép người dùng truy cập vào file của họ trên S3
3. Upload file trực tiếp lên S3 thông qua CloudFront với xác thực

## Kiến trúc hệ thống

![System Architecture](https://imgur.com/placeholder-for-diagram.png)

Hệ thống bao gồm các thành phần sau:

- **Amazon Cognito**: Quản lý người dùng và xác thực
- **Amazon CloudFront**: Phân phối nội dung và trung gian xác thực
- **Lambda@Edge**: Xác thực token JWT và kiểm soát quyền truy cập
- **Amazon S3**: Lưu trữ file của người dùng

## Cách triển khai

### 1. Tạo Cognito User Pool

```terraform
module "cognito" {
  source = "../cognito"

  prefix        = "your-app-name"
  domain_prefix = "your-auth-domain"
  callback_urls = ["https://your-domain.com/callback"]
  logout_urls   = ["https://your-domain.com"]
}
```

### 2. Tạo Lambda@Edge Authentication

```terraform
module "lambda_auth" {
  source = "../lambda_auth"
  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  prefix               = "your-app-name"
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_jwks_uri     = module.cognito.jwks_uri
  s3_bucket_arn        = module.s3_bucket.arn
}
```

### 3. Cấu hình CloudFront

```terraform
module "cloudfront" {
  source = "../cloudfront"

  domain_names          = ["your-domain.com"]
  regional_domain_name  = "your-alb-domain.region.elb.amazonaws.com"
  origin_id             = "your-app-name"
  s3_bucket_domain_name = module.s3_bucket.domain_name
  s3_bucket_arn         = module.s3_bucket.arn
  s3_bucket_id          = module.s3_bucket.id
  
  auth_lambda_arn       = module.lambda_auth.auth_lambda_arn
  upload_auth_lambda_arn = module.lambda_auth.upload_auth_lambda_arn
}
```

## Cách sử dụng

### Upload files

1. **Đăng nhập qua Cognito** và lấy Access Token (JWT)
2. **Upload file** bằng cách gửi request tới CloudFront endpoint `/private/{filename}`:

```javascript
// Ví dụ JavaScript
async function uploadFile(file) {
  const response = await fetch('https://your-cdn.com/private/' + file.name, {
    method: 'PUT',
    headers: {
      'Authorization': 'Bearer ' + cognitoAccessToken,
      'Content-Type': file.type
    },
    body: file
  });
  
  if (response.ok) {
    console.log('Upload successful');
  }
}
```

Lambda@Edge sẽ tự động:
- Xác thực token
- Chuyển đổi đường dẫn thành `/private/user-{userId}/{filename}`
- Thêm metadata `user-id` vào file
- Thêm timestamp để audit

### Truy cập files

1. **Đăng nhập qua Cognito** và lấy Access Token (JWT)
2. **Truy cập file** thông qua CloudFront với token:

```javascript
// Ví dụ JavaScript
function getFile(filename) {
  fetch('https://your-cdn.com/private/user-' + userId + '/' + filename, {
    headers: {
      'Authorization': 'Bearer ' + cognitoAccessToken
    }
  })
  .then(response => response.blob())
  .then(blob => {
    // Xử lý file
  });
}
```

Lambda@Edge sẽ:
- Xác thực token
- Kiểm tra `userId` trong token có khớp với `userId` trong đường dẫn không
- Chỉ cho phép truy cập nếu người dùng có quyền

### Cấu trúc đường dẫn

Tất cả file của người dùng đều được lưu trữ với cấu trúc thống nhất: `/private/user-{userId}/{filename}`
- Dùng một endpoint duy nhất `/private/` cho cả upload và truy cập
- Lambda@Edge tự động thêm `user-id` vào đường dẫn để đảm bảo phân quyền

## Lưu ý bảo mật

1. **ACM Certificate**: Luôn sử dụng HTTPS để bảo vệ dữ liệu khi truyền tải
2. **Token JWT**: Cấu hình thời gian hết hạn ngắn cho tokens (1-2 giờ)
3. **S3 Bucket Policy**: Chỉ cho phép truy cập thông qua CloudFront OAI
4. **Web Application Firewall (WAF)**: Xem xét sử dụng AWS WAF với CloudFront để bảo vệ chống lại các cuộc tấn công web phổ biến

## Best Practices

1. **Kiểm tra dung lượng file** trước khi upload
2. **Sử dụng multipart upload** cho file lớn (>100MB) 
3. **Thêm rate limiting** để tránh lạm dụng
4. **Sử dụng Cache-Control** phù hợp cho các file tĩnh 