<!-- BADGES:START -->
![Version](https://img.shields.io/badge/version-3.0.3-blue.svg?style=for-the-badge)
![Node](https://img.shields.io/badge/node-%3E%3D18-brightgreen.svg?style=for-the-badge)
![Front Hub](https://img.shields.io/badge/front--hub-%5E7.2.0-blue.svg?style=for-the-badge)
![Front Hub CLI](https://img.shields.io/badge/front--hub--cli-%5E7.2.0-blue.svg?style=for-the-badge)
![Front Hub Commons](https://img.shields.io/badge/front--hub--commons-%5E7.2.0-blue.svg?style=for-the-badge)
![Tangram](https://img.shields.io/badge/tangram-8.20.0-blue?style=for-the-badge)
<!-- BADGES:END -->

# README com Atualização Automática (Badges)

Projeto de exemplo para configurar **atualizações automáticas do README** por meio de:

- **Pre-commit hooks** — os badges são atualizados localmente antes de cada commit quando o `package.json` é alterado.
- **GitHub Actions** — os badges são atualizados no repositório quando o `package.json` é enviado para a branch `main`.

O README mantém uma seção de badges sincronizada com o `package.json` (versão, licença, versão do Node, quantidade de dependências). O bloco de badges é delimitado por `<!-- BADGES:START -->` e `<!-- BADGES:END -->`; apenas esse bloco é substituído.

O código em `src/` é apenas um app Node mínimo e não é necessário para a configuração da atualização automática.

---

## Pré-requisitos

- Node.js (ex.: 18+)
- Repositório Git
- No seu README, um bloco entre `<!-- BADGES:START -->` e `<!-- BADGES:END -->` (adicione se não existir)

---

## Opção 1: Pre-commit hook

Execute o script de configuração a partir da raiz do projeto. Ele pedirá para você escolher:

1. **Husky** — recomendado para times (o hook é versionado e compartilhado).
2. **Git hooks nativos** — mais simples, sem dependências extras; cada desenvolvedor deve executar o script.

**Comandos:**

```bash
# From the project root
bash bin/setup-precommit.sh
```

Quando solicitado, escolha `1` para Husky ou `2` para hooks nativos. O script instala o hook e cria a lógica de atualização. Você não precisa copiar nenhum do código gerado manualmente.

**Teste rápido após a configuração:**

```bash
npm version patch
git add package.json
git commit -m "chore: bump version"
```

Se o `package.json` estiver no commit, o hook atualizará os badges no README e adicionará o `README.md` ao mesmo commit.

---

## Opção 2: GitHub Actions

Um arquivo de workflow é fornecido como backup para que não seja executado até você habilitá-lo.

**Passos:**

1. Acesse `.github/workflows/`.
2. Renomeie `update-readme-badges.yml.bkp` para `update-readme-badges.yml` (remova a extensão `.bkp`).

Após renomear, o workflow irá:

- Executar em pushes para `main` que alterem o `package.json`, ou quando acionado manualmente (workflow_dispatch).
- Atualizar os badges do README e fazer commit da alteração de volta ao repositório (com uma mensagem como `docs: update README badges [skip ci]`).

### Autor do commit (usuário e e-mail)

O commit automatizado é **atribuído ao usuário que acionou o workflow**:

- **Em push:** o autor do commit é o usuário que fez push para `main` (nome de usuário no GitHub e `username@users.noreply.github.com`).
- **Em execução manual (workflow_dispatch):** o autor do commit é o usuário que clicou em "Run workflow".

Não é necessário definir `user.name` ou `user.email` manualmente no workflow; ele usa `github.actor` e o e-mail no-reply do GitHub para que o commit de atualização dos badges apareça para a pessoa correta.

### Repositórios privados

O workflow também funciona em **repositórios privados**. Por padrão ele usa o `GITHUB_TOKEN` integrado, que tem permissão suficiente para fazer push de volta ao mesmo repositório quando o workflow tem `contents: write`.

**Se sua organização restringe as permissões do `GITHUB_TOKEN`** (ex.: não pode fazer push), use um Personal Access Token (PAT):

1. Crie um PAT com pelo menos o escopo **repo** (ou **contents: read/write** para conteúdo do repositório).
2. No repositório: **Settings → Secrets and variables → Actions**.
3. Adicione um novo segredo do repositório, ex.: **`GH_PAT`**, com o valor do PAT.

O workflow está configurado para usar `GH_PAT` quando presente e fazer fallback para `GITHUB_TOKEN` caso contrário. Nenhuma alteração no arquivo do workflow é necessária após definir o segredo.

---

## Resumo

| Método           | Quando executa                              | Melhor para                    |
|------------------|---------------------------------------------|--------------------------------|
| Pre-commit hook  | Todo commit que inclui package.json         | Atualizações locais e imediatas |
| GitHub Actions   | Push para main que altera package.json      | Atualizações centralizadas via CI |

Você pode usar um ou ambos. O formato dos badges e os placeholders (`<!-- BADGES:START -->` / `<!-- BADGES:END -->`) são os mesmos para qualquer método.
