#!/bin/bash

# Script de instalação rápida do pre-commit hook
# Execute: bash setup-precommit.sh

set -e  # Sair se qualquer comando falhar

echo "🚀 Configurando pre-commit hook para atualizar badges..."
echo ""

# Verificar se está em um repositório git
if [ ! -d .git ]; then
  echo "❌ Erro: Este não é um repositório git!"
  echo "Execute 'git init' primeiro."
  exit 1
fi

# Verificar se package.json existe
if [ ! -f package.json ]; then
  echo "❌ Erro: package.json não encontrado!"
  echo "Este script precisa de um projeto Node.js."
  exit 1
fi

# Verificar se node está instalado
if ! command -v node &> /dev/null; then
  echo "❌ Erro: Node.js não está instalado!"
  echo "Instale Node.js em: https://nodejs.org/"
  exit 1
fi

# Perguntar qual método usar
echo "Escolha o método de instalação:"
echo "1) Husky (recomendado para projetos em equipe)"
echo "2) Git hooks nativos (mais simples, sem dependências)"
echo ""
read -p "Escolha [1-2]: " choice

case $choice in
  1)
    echo ""
    echo "📦 Instalando Husky..."
    
    # Instalar Husky
    npm install --save-dev husky
    
    # Inicializar Husky
    npx husky install
    
    # Adicionar script prepare ao package.json
    echo "📝 Atualizando package.json..."
    node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    if (!pkg.scripts) pkg.scripts = {};
    pkg.scripts.prepare = 'husky install';
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
    "
    
    # Criar diretório .husky se não existir
    mkdir -p .husky
    
    # Criar script de atualização de badges
    cat > .husky/update-badges.js << 'EOFNODE'
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
  try {
    const stagedFiles = execSync('git diff --cached --name-only', { encoding: 'utf8' });
    return stagedFiles.includes('package.json');
  } catch (error) {
    return false;
  }
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
    return;
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
      return;
    }

    readme = readme.replace(/<!-- BADGES:START -->[\s\S]*?<!-- BADGES:END -->/, badgeSection);
    fs.writeFileSync('README.md', readme, 'utf8');
    log.success('Badges atualizadas no README.md');

    execSync('git add README.md', { stdio: 'ignore' });
    log.success('README.md adicionado ao commit');

  } catch (error) {
    console.error(`Erro: ${error.message}`);
  }
}

updateBadges();
EOFNODE
    
    chmod +x .husky/update-badges.js
    
    # Criar hook pre-commit
    npx husky add .husky/pre-commit "node .husky/update-badges.js"
    
    echo ""
    echo "✅ Husky configurado com sucesso!"
    echo ""
    echo "📝 Próximos passos:"
    echo "1. Adicione os marcadores no README.md:"
    echo "   <!-- BADGES:START -->"
    echo "   <!-- BADGES:END -->"
    echo ""
    echo "2. Teste fazendo um commit:"
    echo "   npm version patch"
    echo "   git add package.json"
    echo "   git commit -m 'test: bump version'"
    ;;
    
  2)
    echo ""
    echo "📝 Criando git hook nativo..."
    
    # Garantir que estamos na raiz do repo para .git/hooks
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    HOOKS_DIR="$ROOT_DIR/.git/hooks"
    mkdir -p "$HOOKS_DIR"

    # Criar script
    cat > "$HOOKS_DIR/pre-commit" << 'EOFBASH'
#!/usr/bin/env node

const fs = require('node:fs');
const { execSync } = require('node:child_process');

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
  try {
    // Check for package.json in STAGED changes (--cached)
    const stagedFiles = execSync('git diff --cached --name-only', { encoding: 'utf8' });
    return stagedFiles.includes('package.json');
  } catch (error) {
    return false;
  }
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
    return;
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
      return;
    }

    readme = readme.replace(/<!-- BADGES:START -->[\s\S]*?<!-- BADGES:END -->/, badgeSection);
    fs.writeFileSync('README.md', readme, 'utf8');
    log.success('Badges atualizadas no README.md');

    // Add the updated README to the commit
    execSync('git add README.md', { stdio: 'ignore' });
    log.success('README.md adicionado ao commit');

  } catch (error) {
    console.error(`Erro: ${error.message}`);
    process.exit(1); // Exit with error to abort commit if something goes wrong
  }
}

updateBadges();
EOFBASH
    
    chmod +x "$HOOKS_DIR/pre-commit"
    
    echo ""
    echo "✅ Git hook configurado com sucesso!"
    echo ""
    echo "📝 Próximos passos:"
    echo "1. Adicione os marcadores no README.md:"
    echo "   <!-- BADGES:START -->"
    echo "   <!-- BADGES:END -->"
    echo ""
    echo "2. Teste fazendo um commit:"
    echo "   npm version patch"
    echo "   git add package.json"
    echo "   git commit -m 'test: bump version'"
    echo ""
    echo "⚠️  Lembre-se: hooks nativos não são versionados!"
    echo "   Outros desenvolvedores precisarão rodar este script também."
    ;;
    
  *)
    echo "❌ Opção inválida!"
    exit 1
    ;;
esac

echo ""
echo "🎉 Configuração concluída!"