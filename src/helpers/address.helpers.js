const validatePhone = (phone) => {
    const phoneRegex = /^(\+62|62|0)[0-9]{8,12}$/;

    return phoneRegex.test(phone);
};

const validatePostalCode = (postalCode) => {
    return /^\d{5}$/.test(postalCode);
};

module.exports = {validatePhone,validatePostalCode};