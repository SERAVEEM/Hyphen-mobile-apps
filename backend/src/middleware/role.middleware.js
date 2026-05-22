const roleMiddleware = (req, res, next) => {
  const user = req.user;

  if(!req.user) {
    return res.status(401).json({
      message: 'Unauthorized'
    });
  }
  if (req.user.role === 'admin') {
    next();
  } else {
    return res.status(403).json({
      message: 'Akses tidak diizinkan'
    });
  }
};

module.exports = { roleMiddleware };
