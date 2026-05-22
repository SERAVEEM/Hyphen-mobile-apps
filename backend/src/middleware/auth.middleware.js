const { jwt, SECRET_KEY } = require('@/config/jwt');

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers['authorization'];

  if (!authHeader) {
    return res.status(401).json({
      message: 'Token tidak ada'
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, SECRET_KEY);
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({
        message: 'Access token expired, gunakan refresh token'
      });
    }
    return res.status(403).json({
      message: 'Token tidak valid'
    });
  }
};


module.exports = {authMiddleware};