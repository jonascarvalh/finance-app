# Fluxo · finanças pessoais em Flutter

[![CI](https://github.com/jonascarvalh/finance-app/actions/workflows/ci.yml/badge.svg)](https://github.com/jonascarvalh/finance-app/actions/workflows/ci.yml)

O Fluxo é um app de finanças pessoais para registrar **entradas e saídas de dinheiro** e acompanhar o saldo com gráficos. Ele tem tema **claro e escuro**, interface em português e todos os dados ficam salvos **no próprio aparelho**.

É um projeto de estudo e portfólio, focado em **Clean Architecture**, gerenciamento de estado com **BLoC/Cubit**, testes automatizados e boas práticas de Flutter.

---

## Sumário

- [Funcionalidades](#funcionalidades)
- [Como o projeto funciona](#como-o-projeto-funciona)
- [Estrutura de pastas](#estrutura-de-pastas)
- [Tecnologias](#tecnologias)
- [Pré-requisitos](#pré-requisitos)
- [Rodando no Windows](#rodando-no-windows)
- [Rodando no Linux](#rodando-no-linux)
- [Rodando em um celular Android](#rodando-em-um-celular-android)
- [Testes e qualidade](#testes-e-qualidade)
- [Gerando versões de distribuição](#gerando-versões-de-distribuição)
- [Onde os dados ficam salvos](#onde-os-dados-ficam-salvos)
- [Solução de problemas](#solução-de-problemas)
- [Próximos passos](#próximos-passos)
- [Licença](#licença)

---

## Funcionalidades

**Início**
- Saldo acumulado, total de entradas e de saídas do mês e o resultado do mês.
- Gráfico de barras comparando entradas e saídas dos **últimos 6 meses**.
- Gráfico de rosca com os **gastos por categoria**. Tocar em uma fatia destaca a categoria e mostra valor e percentual.
- Lista das movimentações mais recentes.

**Extrato**
- Transações do mês agrupadas por dia, com o saldo de cada dia.
- Filtro por **Todas**, **Entradas** ou **Saídas**.
- Arrastar para o lado exclui a transação, com opção de **desfazer**.

**Nova transação / edição**
- Campo de valor com máscara de moeda: os dígitos entram como centavos (`1250` → `R$ 12,50`).
- Tipo (entrada ou saída), categoria com ícones, data e observação opcional.
- Validação com mensagens claras nos campos.

**Ajustes**
- Tema **Sistema**, **Claro** ou **Escuro**, que continua salvo ao fechar o app.
- **Carregar dados de exemplo**: preenche seis meses de movimentações fictícias para explorar os gráficos.
- **Apagar todos os dados**, com confirmação.

Também é possível navegar entre os meses, sem ir além do mês atual.

---

## Como o projeto funciona

### Camadas (Clean Architecture)

Cada funcionalidade (`transactions` e `settings`) é dividida em três camadas. A regra principal é que **as dependências apontam para dentro**: o domínio não conhece nada das outras camadas.

```
┌──────────────────────────┐
│       presentation       │  Telas, widgets, gráficos e Cubits
│   (Flutter, flutter_bloc)│
└────────────┬─────────────┘
             │ chama casos de uso
┌────────────▼─────────────┐
│          domain          │  Entidades, regras de negócio, casos de uso
│        (Dart puro)       │  e o *contrato* do repositório
└────────────▲─────────────┘
             │ implementa o contrato
┌────────────┴─────────────┐
│           data           │  SQLite, SharedPreferences, modelos
│   (sqflite, prefs, etc.) │  e a implementação do repositório
└──────────────────────────┘
```

- **domain**: o coração do app, em Dart puro, sem Flutter e sem banco de dados. Contém as entidades (`TransactionEntity`, `FinancialSummary`), a interface `TransactionRepository` e os **casos de uso**, cada um responsável por uma única ação (`AddTransaction`, `GetFinancialSummary`, `DeleteTransaction`...).
- **data**: sabe *como* guardar os dados. O `TransactionLocalDataSource` conversa com o SQLite e o `TransactionRepositoryImpl` implementa o contrato do domínio, convertendo modelos em entidades e erros técnicos em falhas de negócio.
- **presentation**: telas e estado. Os Cubits chamam os casos de uso e expõem um estado imutável que a interface desenha.

As dependências são montadas em `lib/injection_container.dart` com o `get_it`.

### Exemplo: o que acontece ao salvar uma transação

1. O usuário preenche o formulário. O `TransactionFormCubit` guarda os campos digitados.
2. Ao tocar em **Adicionar**, o Cubit chama o caso de uso `AddTransaction`.
3. O caso de uso **valida** os dados com o `TransactionValidator` (descrição obrigatória, valor maior que zero, categoria compatível com o tipo...), gera um id e chama o repositório.
4. O repositório converte a entidade em `TransactionModel` e pede ao data source que grave no SQLite.
5. O resultado volta como `Result<T>`, que é `Ok` (sucesso) ou `Err` (falha). Nenhuma exceção atravessa as camadas.
6. O formulário fecha e o `TransactionsCubit` recarrega o mês. Home e Extrato são atualizados juntos.

### Decisões importantes

| Decisão | Por quê |
| --- | --- |
| Valores em **centavos** (`int`) | Evita erros de arredondamento de `double`, como `0.1 + 0.2 = 0.30000000000000004`. A formatação para `R$` acontece só na tela. |
| `Result<T>` com *sealed classes* | Obriga quem chama a tratar sucesso e falha com um `switch` exaustivo, sem `try/catch` espalhado pela interface. |
| Resumo calculado no domínio | `GetFinancialSummary` monta o histórico mensal e os gastos por categoria. Por ser Dart puro, é testado sem banco e sem interface. |
| Saldo calculado no SQLite | O saldo acumulado usa `SUM` no banco, sem carregar todas as transações na memória. |
| Relógio e gerador de id injetáveis | `Clock` e `IdGenerator` deixam os testes determinísticos, sem depender da data real. |
| Rótulos e ícones na apresentação | O domínio conhece só `TransactionCategory.food`. O texto "Alimentação", o ícone e a cor ficam numa extensão da camada de apresentação. |
| Tema com `ThemeExtension` | As cores de entrada e saída variam entre os temas claro e escuro sem cores fixas espalhadas pelos widgets. |

---

## Estrutura de pastas

```
lib/
├── app/
│   ├── app.dart                 # MaterialApp, tema, idioma e Cubits globais
│   └── home_shell.dart          # Navegação inferior (Início, Extrato, Ajustes)
├── core/                        # Código compartilhado entre funcionalidades
│   ├── error/                   # Failures (domínio) e Exceptions (dados)
│   ├── presentation/            # Widgets reutilizáveis e máscara de moeda
│   ├── result/                  # Result<T> = Ok | Err
│   ├── theme/                   # AppTheme (Material 3) e FinanceColors
│   ├── usecase/                 # Contrato base dos casos de uso
│   └── utils/                   # Dinheiro, datas, ids e relógio
├── features/
│   ├── transactions/
│   │   ├── domain/              # entities/, repositories/, usecases/
│   │   ├── data/                # datasources/, models/, repositories/
│   │   └── presentation/        # cubit/, pages/, widgets/, models/
│   └── settings/
│       ├── domain/
│       ├── data/
│       └── presentation/
├── injection_container.dart     # Registro das dependências (get_it)
└── main.dart                    # Ponto de entrada

test/                            # Mesma organização de lib/
├── core/
├── features/
├── helpers/                     # Dados de teste e mocks
└── widget/                      # Testes de interface
```

---

## Tecnologias

| Finalidade | Pacote |
| --- | --- |
| Gerenciamento de estado | [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) e [`equatable`](https://pub.dev/packages/equatable) |
| Injeção de dependência | [`get_it`](https://pub.dev/packages/get_it) |
| Banco de dados local | [`sqflite`](https://pub.dev/packages/sqflite) (Android/iOS/macOS) e [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi) (Windows/Linux) |
| Preferências | [`shared_preferences`](https://pub.dev/packages/shared_preferences) |
| Gráficos | [`fl_chart`](https://pub.dev/packages/fl_chart) |
| Datas e moeda em pt-BR | [`intl`](https://pub.dev/packages/intl) e `flutter_localizations` |
| Testes | `flutter_test`, [`bloc_test`](https://pub.dev/packages/bloc_test) e [`mocktail`](https://pub.dev/packages/mocktail) |

---

## Pré-requisitos

- **Flutter 3.32 ou superior** (canal *stable*). Veja o [guia oficial de instalação](https://docs.flutter.dev/get-started/install).
- **Git**.
- Para rodar em **Android**: [Android Studio](https://developer.android.com/studio) com o Android SDK e um emulador, ou um celular com depuração USB ativada.
- Para rodar como **app de desktop**, veja os requisitos específicos de cada sistema abaixo.

Depois de instalar, confira se está tudo certo:

```bash
flutter doctor
```

> **Sobre as pastas `android/`, `windows/` e `linux/`**
> O repositório guarda só o código Dart (`lib/` e `test/`). Os projetos nativos de cada plataforma são gerados na sua máquina com `flutter create`, como mostram os passos abaixo. Assim eles ficam sempre compatíveis com a versão do Flutter que você tem instalada.

---

## Rodando no Windows

### 1. Requisitos do Windows

- Flutter e Git instalados e no `PATH`.
- Para rodar como **app de Windows**: [Visual Studio 2022](https://visualstudio.microsoft.com/) (não é o VS Code) com a carga de trabalho **"Desenvolvimento para desktop com C++"**.
- **Modo de Desenvolvedor** ativado, que o Flutter exige para usar plugins. No PowerShell, abra a tela de configuração com:

  ```powershell
  start ms-settings:developers
  ```

### 2. Clonar e preparar (PowerShell)

```powershell
git clone https://github.com/jonascarvalh/finance-app.git
cd finance-app

# Gera os projetos nativos (apenas na primeira vez)
flutter create . --empty --org com.jonascarvalh --project-name fluxo --platforms=android,windows

flutter pub get
```

### 3. Executar

```powershell
# Como app de desktop do Windows
flutter run -d windows

# Ou em um emulador/celular Android conectado
flutter devices          # lista os dispositivos disponíveis
flutter run -d <id-do-dispositivo>
```

---

## Rodando no Linux

Os comandos abaixo são para Ubuntu/Debian. Em outras distribuições, instale os pacotes equivalentes.

### 1. Dependências do sistema

```bash
# Ferramentas para compilar apps Flutter de desktop
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev

# SQLite, usado pelo app no desktop e pelos testes
sudo apt-get install -y libsqlite3-0 libsqlite3-dev
```

### 2. Clonar e preparar

```bash
git clone https://github.com/jonascarvalh/finance-app.git
cd finance-app

# Gera os projetos nativos (apenas na primeira vez)
flutter create . --empty --org com.jonascarvalh --project-name fluxo --platforms=android,linux

flutter pub get
```

### 3. Executar

```bash
# Como app de desktop do Linux
flutter run -d linux

# Ou em um emulador/celular Android conectado
flutter devices
flutter run -d <id-do-dispositivo>
```

> **Por que `--empty`?** O `flutter create` não sobrescreve arquivos que já existem (`lib/`, `test/`, `pubspec.yaml`). O `--empty` também evita que ele crie um teste de exemplo que não combina com este projeto.

---

## Rodando em um celular Android

1. No celular, ative as **Opções do desenvolvedor**: em *Sobre o telefone*, toque 7 vezes em *Número da versão*.
2. Em *Opções do desenvolvedor*, ative a **Depuração USB**.
3. Conecte o celular ao computador por cabo e aceite a autorização que aparece na tela.
4. Rode `flutter devices` para confirmar que ele aparece e depois `flutter run`.

Para usar um **emulador**, crie um no *Device Manager* do Android Studio e abra-o com:

```bash
flutter emulators                     # lista os emuladores
flutter emulators --launch <nome>
flutter run
```

> **iOS e macOS** só podem ser compilados em um Mac com Xcode. Nesse caso, inclua `ios` e/ou `macos` em `--platforms`.

---

## Testes e qualidade

```bash
flutter analyze   # análise estática com regras de lint rigorosas
flutter test      # roda todos os testes
dart format .     # formata o código (largura de 100 colunas)
```

O que os testes cobrem:

- **Domínio**: validação, criação e edição de transações, cálculo do resumo financeiro e geração dos dados de exemplo.
- **Dados**: conversão entre modelo e entidade, tradução de exceções em falhas e testes de integração com um **SQLite real em memória**.
- **Apresentação**: os Cubits (`TransactionsCubit`, `TransactionFormCubit` e `ThemeCubit`) com `bloc_test`, mais testes de widget da tela inicial (nos temas claro e escuro) e do formulário.

Os testes de SQLite precisam da biblioteca `libsqlite3` instalada. No Linux, use o comando da seção de dependências. No Windows e no macOS, funciona sem configuração extra.

A cada *push* ou *pull request*, o GitHub Actions roda análise e testes automaticamente (`.github/workflows/ci.yml`).

---

## Gerando versões de distribuição

| Plataforma | Comando | Resultado |
| --- | --- | --- |
| Android (APK) | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| Android (Play Store) | `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` |
| Windows | `flutter build windows --release` | `build\windows\x64\runner\Release\` |
| Linux | `flutter build linux --release` | `build/linux/x64/release/bundle/` |

O APK pode ser instalado direto em qualquer Android ou anexado a uma *Release* do GitHub para outras pessoas baixarem. Sem configurar uma chave de assinatura própria, o build de release usa a chave de depuração. Isso serve para testes, mas não para publicar na Play Store.

---

## Onde os dados ficam salvos

Tudo fica **somente no dispositivo**: não há servidor, conta nem envio de dados pela internet.

- **Transações**: banco SQLite `fluxo.db`.
  - Android/iOS: na pasta privada do app.
  - Windows: na pasta de dados do app, dentro de `%APPDATA%`.
  - Linux: na pasta de dados do app, dentro de `~/.local/share`.
- **Tema escolhido**: preferências do sistema (`shared_preferences`).

Para começar do zero, use **Ajustes → Apagar todos os dados** ou desinstale o app.

---

## Solução de problemas

| Problema | Solução |
| --- | --- |
| `Building with plugins requires symlink support` (Windows) | Ative o **Modo de Desenvolvedor** (`start ms-settings:developers`). |
| `Unable to find suitable Visual Studio toolchain` (Windows) | Instale o Visual Studio 2022 com "Desenvolvimento para desktop com C++" e rode `flutter doctor` de novo. |
| Erro ao carregar `libsqlite3.so` (Linux) | `sudo apt-get install -y libsqlite3-0 libsqlite3-dev` |
| `CMake was unable to find a build program` (Linux) | Instale as dependências de desktop listadas na seção do Linux. |
| `No supported devices connected` | Rode `flutter devices`. Confira se a plataforma foi criada (`flutter create . --platforms=...`) e se o emulador está aberto. |
| Erros estranhos depois de atualizar o Flutter | `flutter clean` e depois `flutter pub get`. |
| Datas ou moeda fora do padrão brasileiro | O app força o idioma `pt_BR`. Confirme que `initializeDateFormatting('pt_BR')` continua em `main.dart`. |

---

## Próximos passos

Ideias para evoluir o projeto:

- Versão **web**, trocando o banco no navegador por `sqflite_common_ffi_web` e publicando no GitHub Pages.
- Orçamento mensal por categoria, com alerta ao ultrapassar o limite.
- Transações recorrentes (salário, aluguel, assinaturas).
- Busca por descrição e filtro por categoria no extrato.
- Exportação para CSV e backup.
- Testes de integração de ponta a ponta com `integration_test`.

---

## Licença

Distribuído sob a licença MIT. Veja o arquivo [LICENSE](LICENSE).
