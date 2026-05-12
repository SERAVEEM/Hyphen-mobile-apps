require('dotenv').config();
require('module-alias/register');
const { initAdmin } = require('@/data/users.data');
initAdmin();

const express = require('express');
const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');

const authRoutes = require('@/routes/auth.routes');
const userRoutes = require('@/routes/user.routes');
const productRoutes = require('@/routes/product.routes');
const cartRoutes = require('@/routes/cart.routes');
const orderRoutes = require('@/routes/order.routes');
const paymentRoutes = require('@/routes/payment.routes');
const addressRoutes = require('@/routes/address.routes');



const app = express();

// Swagger docs
const swaggerDocument = YAML.load('./swagger.yaml');
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'API is running' });
});

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/user', userRoutes);
app.use('/api/v1/product', productRoutes);
app.use('/api/v1/cart', cartRoutes);
app.use('/api/v1/order', orderRoutes);
app.use('/api/v1/payment', paymentRoutes);
app.use('/api/v1/address', addressRoutes);

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Internal Server Error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
