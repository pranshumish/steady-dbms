import {writeFileSync,existsSync} from 'node:fs';
import {randomBytes} from 'node:crypto';
const path=new URL('../.env',import.meta.url);
if(existsSync(path)){console.log('.env already exists; preserved.');process.exit(0)}
writeFileSync(path,`POSTGRES_PASSWORD=${randomBytes(24).toString('hex')}\nMONGO_PASSWORD=${randomBytes(24).toString('hex')}\nAPP_PORT=3000\nAPP_ORIGIN=http://localhost:3000\n`,{mode:0o600});
console.log('Created .env with random database passwords. Run: docker compose up --build -d');
