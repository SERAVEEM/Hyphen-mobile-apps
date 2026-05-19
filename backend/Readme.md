# E-commerce backend HYPEN. 

Struktur folder:
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

Langkah - langkah:

Install :
- npm install 

isi package :
- node.js : runtime env
- express : Framework
- brycpt : Hash pw
- midtrans
- RajaOngkir
- socket.io
- jsonwebtoken : verify JWT Token
- uuid : Generate ID
- dotenv : baca file env
- module-alias : path untuk import (@) contoh : (@/data/product.data)
- nodemailer : 
- swagger-ui-express : Dokumentasi API
# cara run swagger -> http://localhost:3000/api-docs/
# kalau mau refresh/restart wajib save dulu/ ketik rs
- nodemon : Auto restart server saat development

# run:
 $ npm run dev -> mode development (supaya bisa lgsung refresh/restart)
 $ npm run start -> mode production
# tambahkan juga terminal kedua untuk run ngrok -> untuk payment gateway
$ ngrok http 3000

# putusin run :
CTRL + C


# Akun default admin :
Email : admin123@gmail.com
Pw : admin123

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

untuk frontend :
npm install socket.io-client (Buat fitur chat)