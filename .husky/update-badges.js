#!/usr/bin/env node

const fs = require('fs');
const { execSync } = require('child_process');

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
};

const log = {
  info: (msg) => console.log(`${colors.blue}ℹ ${msg}${colors.reset}`),
  success: (msg) => console.log(`${colors.green}✓ ${msg}${colors.reset}`),
  warning: (msg) => console.log(`${colors.yellow}⚠ ${msg}${colors.reset}`),
};

function isPackageJsonModified() {
      const lastCommitFiles = execSync('git diff-tree --no-commit-id --name-only -r HEAD', { encoding: 'utf8' });
      return lastCommitFiles.includes('package.json');
}

function updateBadges() {
  log.info('Verificando se package.json foi modificado...');

  if (!isPackageJsonModified()) {
    log.success('package.json não foi modificado, pulando atualização');
    return;
  }

  log.info('package.json modificado, atualizando badges...');

  if (!fs.existsSync('README.md')) {
    log.warning('README.md não encontrado!');
    process.exit(1);
  }

  try {
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));

    const version = pkg.version || '0.0.0';
    const license = pkg.license || 'MIT';
    const nodeVersion = pkg.engines?.node || '>=18';
    const dependencies = Object.keys(pkg.dependencies || {}).length;
    const devDependencies = Object.keys(pkg.devDependencies || {}).length;

    const encode = (str) => encodeURIComponent(str);

    const badges = [
      `![Version](https://img.shields.io/badge/version-${encode(version)}-blue.svg)`,
      `![License](https://img.shields.io/badge/license-${encode(license)}-green.svg)`,
      `![Node](https://img.shields.io/badge/node-${encode(nodeVersion)}-brightgreen.svg)`,
    ];

    if (dependencies > 0) {
      badges.push(`![Dependencies](https://img.shields.io/badge/dependencies-${dependencies}-orange.svg)`);
    }

    if (devDependencies > 0) {
      badges.push(`![Dev Dependencies](https://img.shields.io/badge/dev--dependencies-${devDependencies}-yellow.svg)`);
    }

    const badgeSection = `<!-- BADGES:START -->\n${badges.join('\n')}\n<!-- BADGES:END -->`;
    let readme = fs.readFileSync('README.md', 'utf8');

    if (!readme.includes('<!-- BADGES:START -->')) {
      log.warning('Marcadores <!-- BADGES:START --> e <!-- BADGES:END --> não encontrados');
      log.info('Adicione esses marcadores no README.md');
      process.exit(1);
    }

    readme = readme.replace(/<!-- BADGES:START -->[\s\S]*?<!-- BADGES:END -->/, badgeSection);
    fs.writeFileSync('README.md', readme, 'utf8');
    log.success('Badges atualizadas no README.md');
    log.error('README.md modificado - você precisa fazer commit manualmente');
    process.exit(1);
  } catch (error) {
    console.error(`Erro: ${error.message}`);
  }
}

updateBadges();
