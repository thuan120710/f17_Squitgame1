import { copyFileSync, existsSync, mkdirSync } from 'fs'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

const sourceDir = join(__dirname, '../../html/sounds')
const targetDir = join(__dirname, '../public/sounds')

if (!existsSync(targetDir)) {
  mkdirSync(targetDir, { recursive: true })
}

for (const file of ['5count.mp3', 'rightchose.mp3']) {
  const sourcePath = join(sourceDir, file)
  const targetPath = join(targetDir, file)

  if (existsSync(sourcePath)) {
    copyFileSync(sourcePath, targetPath)
  }
}
