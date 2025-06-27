# DocumentDB Connection Test

Ứng dụng đơn giản để kiểm tra trạng thái kết nối đến AWS DocumentDB. Chỉ tập trung vào việc test kết nối, không có API CRUD phức tạp.

## 🚀 Cài đặt

1. **Cài đặt dependencies:**
   ```bash
   npm install
   ```

2. **Cấu hình biến môi trường:**
   
   Tạo file `.env` trong thư mục gốc với nội dung:
   ```env
   # DocumentDB Connection - Chỉ cần MONGODB_URI
   MONGODB_URI=mongodb://username:password@your-documentdb-endpoint:27017/database?ssl=true&tlsCAFile=global-bundle.pem
   
   # Server Configuration  
   PORT=80
   NODE_ENV=development
   ```

## 🔧 Chạy ứng dụng

### Chế độ phát triển (với nodemon):
```bash
npm run dev
```

### Chế độ production:
```bash
npm start
```

## 🌐 Sử dụng

1. **Mở trình duyệt và truy cập:** `http://localhost:80`

2. **Trên giao diện web, bạn sẽ thấy:**
   - Trạng thái kết nối hiện tại
   - Nút "Kiểm tra kết nối" để test DocumentDB
   - Chi tiết kết nối (nếu có)
   - Thông tin cấu hình môi trường

3. **Nhấn nút "Kiểm tra kết nối"** để thực hiện test kết nối đến DocumentDB

## 📊 Các trạng thái kết nối

- **NOT_TESTED** ❓ - Chưa kiểm tra kết nối
- **TESTING** ⏳ - Đang thực hiện kiểm tra
- **CONNECTED** ✅ - Kết nối thành công
- **FAILED** ❌ - Kết nối thất bại
- **ERROR** ❌ - Lỗi trong quá trình kết nối

## 🔍 API Endpoints

- `GET /` - Giao diện web hiển thị trạng thái kết nối
- `POST /test-connection` - API để thực hiện test kết nối
- `GET /status` - API trả về trạng thái kết nối hiện tại

## 📁 Cấu trúc project

```
project-master/
├── app/
│   ├── index.js              # Server chính - giao diện test kết nối
│   └── database/
│       └── documentdb.js     # DocumentDB client (chỉ test kết nối)
├── package.json              # Dependencies tối thiểu
├── README.md                 # Hướng dẫn sử dụng
└── .env                      # Cấu hình MONGODB_URI
```

## 🛠️ Troubleshooting

### Lỗi SSL Certificate:
- Ứng dụng sẽ tự động download SSL certificate từ AWS
- Nếu gặp lỗi, check quyền ghi file trong thư mục

### Lỗi kết nối:
- Kiểm tra cấu hình biến môi trường trong file `.env`
- Đảm bảo DocumentDB cluster đang chạy
- Kiểm tra security group và network access

### Lỗi authentication:
- Xác nhận username/password chính xác
- Kiểm tra user có quyền truy cập database không

## 📝 Ghi chú

- Ứng dụng này chỉ để test kết nối, không có API CRUD phức tạp
- Sử dụng cho môi trường phát triển và debug
- Có thể mở rộng thêm chức năng test query nếu cần

## ✨ Tính năng

- ✅ Kiểm tra kết nối DocumentDB qua giao diện web
- ✅ Hiển thị trạng thái kết nối real-time  
- ✅ Tự động download SSL certificate
- ✅ Chỉ cần cấu hình MONGODB_URI
- ✅ Giao diện đơn giản, dễ sử dụng