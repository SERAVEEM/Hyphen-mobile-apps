# 🛒 HYPEN E-Commerce Backend

Backend API untuk aplikasi E-Commerce **HYPEN** menggunakan Node.js dan Express.

---

## 📦 Tech Stack

* **Node.js** — Runtime environment
* **Express.js** — Backend framework
* **bcrypt** — Hash password
* **jsonwebtoken** — Verifikasi JWT Token
* **socket.io** — Real-time chat
* **Midtrans** — Payment gateway
* **RajaOngkir** — Cek ongkir & pengiriman
* **uuid** — Generate unique ID
* **dotenv** — Membaca file `.env`
* **module-alias** — Mempermudah import path
* **nodemailer** — Email service
* **swagger-ui-express** — Dokumentasi API
* **nodemon** — Auto restart server saat development

---

# 📁 Struktur Folder

```bash
MHSBe2/
├── src/
│   ├── index.js
│   ├── config/
│   ├── controllers/
│   ├── data/
│   ├── helpers/
│   ├── middleware/
│   ├── models/
│   └── routes/
│
├── node_modules/
├── .env
├── .gitignore
├── package.json
└── README.md
```

---

# ⚙️ Instalasi

## 1. Clone Repository

```bash
git clone https://github.com/SERAVEEM/Hyphen-mobile-apps.git
cd backend
```

## 2. Install Dependencies

```bash
npm install
```

---

# ▶️ Menjalankan Project

## Development Mode

```bash
npm run dev
```

Mode development menggunakan **nodemon** sehingga server akan otomatis restart saat ada perubahan file.

> Jika server tidak refresh otomatis, coba simpan file terlebih dahulu atau ketik:

```bash
rs
```

---

## Production Mode

```bash
npm run start
```

---

# 🌐 Menjalankan Ngrok (Untuk Midtrans Callback)

Jalankan terminal kedua:

```bash
ngrok http 3000
```

Gunakan URL dari Ngrok untuk kebutuhan callback/payment gateway.

---

# 📘 API Documentation (Swagger)

Setelah server berjalan, buka:

```bash
http://localhost:3000/api-docs/
```

---

# 🔐 Default Admin Account

```txt
Email : admin123@gmail.com
Password : admin123
```

---

# ⚡ Environment Variables

Buat file `.env` lalu isi seperti berikut:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=hypen_db
PORT=3000

SECRET_KEY=
REFRESH_SECRET_KEY=

MIDTRANS_SERVER_KEY=
MIDTRANS_CLIENT_KEY=

CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=

SMTP_USER=
SMTP_PASS=
```

---

# 📡 Socket.io Client (Frontend)

Untuk fitur chat realtime pada frontend:

```bash
npm install socket.io-client
```

---

# 📥 Import Path Alias

Contoh penggunaan alias import:

```js
import productData from '@/data/product.data'
```

---

# 🛑 Menghentikan Server

```bash
CTRL + C
```

---

# 🚀 Features

* Authentication & Authorization
* JWT Access & Refresh Token
* Realtime Chat
* Payment Gateway Integration (Midtrans)
* Shipping Cost Integration (RajaOngkir)
* API Documentation dengan Swagger
* Upload Image dengan Cloudinary
* Email Notification

---

# 👨‍💻 Author

Developed for learning and backend development practice.
