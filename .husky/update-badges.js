#!/usr/bin/env node

const fs = require('fs');
const { execSync } = require('child_process');

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  red: '\x1b[31m',
};

const log = {
  info: (msg) => console.log(`${colors.blue}ℹ ${msg}${colors.reset}`),
  success: (msg) => console.log(`${colors.green}✓ ${msg}${colors.reset}`),
  warning: (msg) => console.log(`${colors.yellow}⚠ ${msg}${colors.reset}`),
  error: (msg) => console.log(`${colors.red}✗ ${msg}${colors.reset}`),
};

/**
 * Checks if package.json was modified in the commits being pushed.
 * When running from pre-push hook, reads refs from stdin (local_ref local_sha remote_ref remote_sha per line).
 * When run manually (no stdin / TTY), checks HEAD.
 */
function isPackageJsonModifiedInPush() {
  const hasStdin = !process.stdin.isTTY;
  const stdin = hasStdin ? fs.readFileSync(0, 'utf8').trim() : '';
  if (stdin) {
    const lines = stdin.split('\n').filter(Boolean);
    for (const line of lines) {
      const parts = line.split(/\s+/);
      const localSha = parts[1];
      const remoteSha = parts[3];
      if (!localSha || localSha === '0'.repeat(40)) continue;
      const remote = remoteSha && remoteSha !== '0'.repeat(40) ? remoteSha : '4b825dc6422cb36eb226b2fb725e94e7c71386b';
      const files = execSync(`git diff --name-only ${remote} ${localSha}`, { encoding: 'utf8' });
      if (files.includes('package.json')) return true;
    }
    return false;
  }
  const lastCommitFiles = execSync('git diff-tree --no-commit-id --name-only -r HEAD', { encoding: 'utf8' });
  return lastCommitFiles.includes('package.json');
}

function updateReadmeBadges() {
  if (!fs.existsSync('README.md')) {
    log.warning('README.md não encontrado!');
    process.exit(1);
  }

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
}

function main() {
  log.info('Verificando se package.json foi modificado nos commits do push...');

  if (!isPackageJsonModifiedInPush()) {
    log.success('package.json não foi modificado, push permitido');
    process.exit(0);
  }

  log.info('package.json modificado nos commits do push. Atualizando README.md...');

  try {
    updateReadmeBadges();
  } catch (error) {
    console.error(`Erro: ${error.message}`);
    process.exit(1);
  }

  log.error('Push interrompido: README.md foi atualizado.');
  console.log('');
  console.log('  Próximos passos:');
  console.log('    1. git add README.md');
  console.log('    2. git commit -m "docs: atualiza badges do README"');
  console.log('    3. git push');
  console.log('');
  process.exit(1);
}

main();
