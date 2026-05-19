const axios = require('axios');
const qs = require('qs');

const RAJAONGKIR_API_KEY  = process.env.RAJAONGKIR_API_KEY;
const RAJAONGKIR_BASE_URL = process.env.RAJAONGKIR_BASE_URL;

const rajaongkirGet = async (path, params = {}) => {
    try {
        const response = await axios.get(`${RAJAONGKIR_BASE_URL}${path}`, {
            headers: { key: RAJAONGKIR_API_KEY },
            params,
        });
        const { meta, data } = response.data;
        if (meta.code !== 200) throw new Error(meta.message);
        return data;
    } catch (err) {
        console.log('❌ GET ERROR:', JSON.stringify(err.response?.data));
        throw err;
    }
};

const rajaongkirPost = async (path, payload = {}) => {
    try {
        const stringified = qs.stringify(payload);
        const response = await axios.post(
            `${RAJAONGKIR_BASE_URL}${path}`,
            stringified,
            {
                headers: {
                    key: RAJAONGKIR_API_KEY,
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
            }
        );
        const { meta, data } = response.data;
        if (meta.code !== 200) throw new Error(meta.message);
        return data;
    } catch (err) {
        console.log('❌ POST ERROR:', JSON.stringify(err.response?.data));
        throw err;
    }
};

module.exports = { rajaongkirGet, rajaongkirPost };