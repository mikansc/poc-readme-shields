<!-- BADGES:START -->
![Version](https://img.shields.io/badge/version-3.0.3-blue.svg?style=for-the-badge)
![Node](https://img.shields.io/badge/node-%3E%3D18-brightgreen.svg?style=for-the-badge)
![Front Hub](https://img.shields.io/badge/front--hub-%5E7.2.0-blue.svg?style=for-the-badge)
![Front Hub CLI](https://img.shields.io/badge/front--hub--cli-%5E7.2.0-blue.svg?style=for-the-badge)
![Front Hub Commons](https://img.shields.io/badge/front--hub--commons-%5E7.2.0-blue.svg?style=for-the-badge)
![Tangram](https://img.shields.io/badge/tangram-8.20.0-blue?style=for-the-badge)
<!-- BADGES:END -->

# README com Atualização Automática (Badges)

Projeto de exemplo para configurar **atualizações automáticas do README** por meio de **GitHub Actions**: os badges são atualizados no repositório quando o `package.json` é enviado para a branch `main` (ou quando o workflow é acionado manualmente).

O README mantém uma seção de badges sincronizada com o `package.json` (versão, versão do Node, dependências como Front Hub e Tangram quando presentes). O bloco de badges é delimitado por `<!-- BADGES:START -->` e `<!-- BADGES:END -->`; apenas esse bloco é substituído.

O código em `src/` é apenas um app Node mínimo e não é necessário para a configuração da atualização automática.

---

## Pré-requisitos

- Node.js (ex.: 18+)
- Repositório Git
- No seu README, um bloco entre `<!-- BADGES:START -->` e `<!-- BADGES:END -->` (adicione se não existir)

---

## GitHub Actions

O workflow está em `.github/workflows/update-readme-badges.yml`. Ele irá:

- Executar em pushes para `main` que alterem o `package.json`, ou quando acionado manualmente (workflow_dispatch).
- Atualizar os badges do README e fazer commit da alteração de volta ao repositório (com uma mensagem como `docs: update README badges [skip ci]`).

### Autor do commit

O commit automatizado é feito pelo **readme-bot** (`readme-bot@users.noreply.github.com`), configurado no próprio workflow, com mensagem `docs: update README badges [skip ci]` para evitar novo ciclo de CI.

### Repositórios privados

O workflow também funciona em **repositórios privados**. Por padrão ele usa o `GITHUB_TOKEN` integrado, que tem permissão suficiente para fazer push de volta ao mesmo repositório quando o workflow tem `contents: write`.

**Se sua organização restringe as permissões do `GITHUB_TOKEN`** (ex.: não pode fazer push), use um Personal Access Token (PAT):

1. Crie um PAT com pelo menos o escopo **repo** (ou **contents: read/write** para conteúdo do repositório).
2. No repositório: **Settings → Secrets and variables → Actions**.
3. Adicione um novo segredo do repositório, ex.: **`GH_PAT`**, com o valor do PAT.

O workflow está configurado para usar `GH_PAT` quando presente e fazer fallback para `GITHUB_TOKEN` caso contrário. Nenhuma alteração no arquivo do workflow é necessária após definir o segredo.

---

## Resumo

| Quando executa | Comportamento |
|----------------|---------------|
| Push para `main` que altera `package.json` | O workflow atualiza os badges no README e faz commit da alteração. |
| Execução manual (workflow_dispatch) | O mesmo: atualização dos badges e commit. |

O formato dos badges e os placeholders (`<!-- BADGES:START -->` / `<!-- BADGES:END -->`) são definidos no workflow.
