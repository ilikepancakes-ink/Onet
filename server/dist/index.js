"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const yaml = __importStar(require("js-yaml"));
const mime = __importStar(require("mime-types"));
// Load config
const config = yaml.load(fs.readFileSync(path.join(__dirname, '../config.yml'), 'utf8'));
const app = (0, express_1.default)();
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Middleware to verify JWT
const verifyToken = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
        console.log('No token provided');
        return res.status(401).json({ error: 'No token provided' });
    }
    const token = authHeader.split(' ')[1];
    jsonwebtoken_1.default.verify(token, config.auth.jwt_secret, (err) => {
        if (err) {
            console.log('Invalid token:', err.message);
            return res.status(403).json({ error: 'Invalid token' });
        }
        next();
    });
};
// Check server endpoint
app.get('/init/check', (req, res) => {
    res.json({
        server_name: config.server.name,
        version: config.server.version,
        country: config.server.country,
    });
});
// Authenticate endpoint
app.post('/init/auth', async (req, res) => {
    const { username, password } = req.body;
    if (username !== config.auth.username || password !== config.auth.password) {
        return res.status(401).json({ error: 'Invalid credentials' });
    }
    const token = jsonwebtoken_1.default.sign({ username }, config.auth.jwt_secret, { expiresIn: '24h' });
    res.json({ token });
});
// Get content endpoint
app.get('/main/content', verifyToken, (req, res) => {
    const reqPath = req.query.path || '';
    if (reqPath === '') {
        // List root folders
        const content = config.folders.map(folder => ({
            name: path.basename(folder),
            is_folder: true,
        }));
        return res.json(content);
    }
    // Find the folder that matches the path
    let baseFolder = '';
    let relativePath = '';
    for (const folder of config.folders) {
        const folderName = path.basename(folder);
        if (reqPath.startsWith(folderName)) {
            baseFolder = folder;
            relativePath = reqPath.substring(folderName.length).replace(/^\/+/, '');
            break;
        }
    }
    if (!baseFolder) {
        console.log('Access denied for path:', reqPath);
        return res.status(403).json({ error: 'Access denied' });
    }
    const fullPath = path.resolve(baseFolder, relativePath);
    // Ensure the resolved path is within the base folder
    if (!fullPath.startsWith(path.resolve(baseFolder))) {
        return res.status(403).json({ error: 'Access denied' });
    }
    try {
        const items = fs.readdirSync(fullPath);
        const content = items.map(item => {
            const itemPath = path.join(fullPath, item);
            const stats = fs.statSync(itemPath);
            return {
                name: item,
                is_folder: stats.isDirectory(),
                size: stats.isFile() ? stats.size : undefined,
            };
        });
        res.json(content);
    }
    catch (error) {
        console.log('Failed to read directory:', fullPath, error);
        res.status(500).json({ error: 'Failed to read directory' });
    }
});
app.get('/main/file', verifyToken, (req, res) => {
    const reqPath = req.query.path;
    if (!reqPath) {
        return res.status(400).json({ error: 'Path required' });
    }
    // Find the folder that matches the path
    let baseFolder = '';
    let relativePath = '';
    for (const folder of config.folders) {
        const folderName = path.basename(folder);
        if (reqPath.startsWith(folderName)) {
            baseFolder = folder;
            relativePath = reqPath.substring(folderName.length).replace(/^\/+/, '');
            break;
        }
    }
    if (!baseFolder) {
        return res.status(403).json({ error: 'Access denied' });
    }
    const fullPath = path.resolve(baseFolder, relativePath);
    // Ensure the resolved path is within the base folder
    if (!fullPath.startsWith(path.resolve(baseFolder))) {
        return res.status(403).json({ error: 'Access denied' });
    }
    try {
        const stats = fs.statSync(fullPath);
        if (!stats.isFile()) {
            return res.status(400).json({ error: 'Not a file' });
        }
        const mimeType = mime.lookup(fullPath) || 'application/octet-stream';
        const isText = mimeType.startsWith('text/') || mimeType === 'application/json' || mimeType.includes('javascript') || mimeType.includes('xml');
        const isImage = mimeType.startsWith('image/');
        const isVideo = mimeType.startsWith('video/');
        if (isText) {
            const content = fs.readFileSync(fullPath, 'utf8');
            res.json({ type: 'text', content });
        }
        else if (isImage || isVideo) {
            res.json({ type: isImage ? 'image' : 'video', url: `/main/file/download?path=${encodeURIComponent(reqPath)}` });
        }
        else {
            res.json({ type: 'unknown' });
        }
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to read file' });
    }
});
app.get('/main/file/download', verifyToken, (req, res) => {
    const reqPath = req.query.path;
    if (!reqPath) {
        return res.status(400).json({ error: 'Path required' });
    }
    // Find the folder that matches the path
    let baseFolder = '';
    let relativePath = '';
    for (const folder of config.folders) {
        const folderName = path.basename(folder);
        if (reqPath.startsWith(folderName)) {
            baseFolder = folder;
            relativePath = reqPath.substring(folderName.length).replace(/^\/+/, '');
            break;
        }
    }
    if (!baseFolder) {
        return res.status(403).json({ error: 'Access denied' });
    }
    const fullPath = path.resolve(baseFolder, relativePath);
    // Ensure the resolved path is within the base folder
    if (!fullPath.startsWith(path.resolve(baseFolder))) {
        return res.status(403).json({ error: 'Access denied' });
    }
    try {
        const stats = fs.statSync(fullPath);
        if (!stats.isFile()) {
            return res.status(400).json({ error: 'Not a file' });
        }
        const mimeType = mime.lookup(fullPath) || 'application/octet-stream';
        res.setHeader('Content-Type', mimeType);
        res.setHeader('Content-Length', stats.size);
        const stream = fs.createReadStream(fullPath);
        stream.pipe(res);
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to read file' });
    }
});
// Upload file endpoint
app.post('/main/upload', verifyToken, (req, res) => {
    const { path: reqPath, filename, data, chunkIndex, totalChunks } = req.body;
    if (!reqPath || !filename || !data || chunkIndex === undefined || totalChunks === undefined) {
        return res.status(400).json({ error: 'Missing required fields' });
    }
    // Find the folder that matches the path
    let baseFolder = '';
    let relativePath = '';
    for (const folder of config.folders) {
        const folderName = path.basename(folder);
        if (reqPath.startsWith(folderName)) {
            baseFolder = folder;
            relativePath = reqPath.substring(folderName.length).replace(/^\/+/, '');
            break;
        }
    }
    if (!baseFolder) {
        return res.status(403).json({ error: 'Access denied' });
    }
    const fullPath = path.resolve(baseFolder, relativePath, filename);
    // Ensure the resolved path is within the base folder
    if (!fullPath.startsWith(path.resolve(baseFolder))) {
        return res.status(403).json({ error: 'Access denied' });
    }
    try {
        // Ensure directory exists
        const dir = path.dirname(fullPath);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        // Write chunk
        const buffer = Buffer.from(data, 'base64');
        const writeStream = fs.createWriteStream(fullPath, { flags: chunkIndex === 0 ? 'w' : 'a' });
        writeStream.write(buffer);
        writeStream.end();
        writeStream.on('finish', () => {
            if (chunkIndex === totalChunks - 1) {
                res.json({ message: 'File uploaded successfully' });
            }
            else {
                res.json({ message: 'Chunk uploaded' });
            }
        });
        writeStream.on('error', (err) => {
            res.status(500).json({ error: 'Failed to write chunk' });
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to upload file' });
    }
});
app.listen(config.server.port, () => {
    console.log(`Server running on port ${config.server.port}`);
});
// flutter build ios --release
