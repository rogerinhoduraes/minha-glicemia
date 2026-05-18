# Arquitetura — Minha Glicemia

## Camadas

```
┌─────────────────────────────────────────┐
│               Screens / Widgets          │  UI · Flutter Widgets
├─────────────────────────────────────────┤
│               Services                   │  Lógica de negócio + acesso a dados
├─────────────────────────────────────────┤
│               Models                     │  Entidades de domínio
├─────────────────────────────────────────┤
│    Firebase Auth  │  Cloud Firestore     │  Infraestrutura externa
└─────────────────────────────────────────┘
```

Sem gerenciador de estado externo — o app usa `StreamBuilder` + `setState`. Adequado para o escopo atual; se crescer, considerar `Riverpod` ou `Bloc`.

---

## Modelos

### `RegistroGlicemia`
| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `String?` | ID do documento Firestore (null antes de salvar) |
| `dataHora` | `DateTime` | Momento da medição |
| `refeicao` | `String` | Nome do tipo de refeição |
| `valor` | `int` | Glicemia em mg/dL (20–600) |
| `nivel` | `NivelGlicemia` | Calculado: Normal ≤ 140 / Alto ≤ 200 / Muito Alto > 200 |

### `Paciente`
| Campo | Tipo | Descrição |
|---|---|---|
| `nome` | `String` | Nome completo |
| `dataNascimento` | `DateTime?` | Opcional |
| `peso` | `double?` | Em kg, opcional |
| `idade` | `int?` | Calculado a partir de `dataNascimento` |

### `TipoRefeicao`
| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `String?` | ID do documento Firestore |
| `nome` | `String` | Ex: "Em jejum", "Almoço" |
| `ordem` | `int` | Posição na lista (para reordenação) |

---

## Estrutura do Firestore

```
usuarios/
  {uid}/
    perfil/
      paciente          ← documento único com dados do paciente
        nome: string
        dataNascimento: timestamp | null
        peso: number | null

    registros/          ← coleção de medições
      {id}/
        dataHora: timestamp
        refeicao: string
        valor: number

    refeicoes/          ← coleção de tipos de refeição
      {id}/
        nome: string
        ordem: number
```

Cada usuário tem seus dados totalmente isolados sob o seu `{uid}`. As regras do Firestore garantem que só o próprio usuário pode ler e escrever (`firestore.rules`).

---

## Fluxo de autenticação

```
App inicia
    │
    ├─ currentUser == null?
    │       └─ signInAnonymously()  ← acesso imediato sem login
    │
    └─ runApp()
           │
           └─ StreamBuilder(authStateChanges)
                  │
                  ├─ user != null ──→ HomeScreen
                  └─ user == null ──→ LoginScreen
                                          │
                                          ├─ Google Sign-In ──→ HomeScreen
                                          └─ Facebook Login ──→ HomeScreen
```

> **Atenção**: o login anônimo cria um UID diferente do que seria gerado pelo login social. Se o usuário usar o app anonimamente e depois fizer login com Google/Facebook, os dados anônimos **não migram automaticamente**. Para implementar migração, use `linkWithCredential` do Firebase Auth antes de fazer o login social.

---

## Serviços

### `AuthService`
Encapsula `FirebaseAuth`, `GoogleSignIn` e `FacebookAuth`. Expõe:
- `signInWithGoogle()` / `signInWithFacebook()` / `signOut()`
- `currentUser` e `userStream`

### `GlicemiaService`
Único ponto de acesso ao Firestore. Todos os métodos são escopados ao `uid` do usuário atual.

| Método | Descrição |
|---|---|
| `ultimosRegistros({limite})` | Stream dos N registros mais recentes |
| `salvar(r)` / `editar(r)` / `deletar(id)` | CRUD de registros |
| `buscarPaciente()` / `salvarPaciente(p)` | Leitura/escrita do perfil |
| `streamRefeicoes()` | Stream dos tipos de refeição ordenados |
| `adicionarRefeicao` / `deletarRefeicao` | Gestão de tipos |
| `reordenarRefeicoes(lista)` | Batch update de todos os campos `ordem` |
| `garantirRefeicoesIniciais()` | Cria as 6 refeições padrão se a coleção estiver vazia |

---

## AdMob

O widget `AdBanner` carrega um banner adaptativo usando `didChangeDependencies` para garantir que o `MediaQuery` esteja disponível. O banner só ocupa espaço na tela após ser carregado com sucesso (`_carregado == true`). Em caso de falha, o widget retorna `SizedBox.shrink()`.

IDs de teste usados em desenvolvimento:
- Android: `ca-app-pub-3940256099942544/6300978111`
- iOS: `ca-app-pub-3940256099942544/2934735716`

Substituir pelos IDs de produção em `lib/widgets/ad_banner.dart` antes de publicar.

---

## Decisões de design notáveis

| Decisão | Motivo |
|---|---|
| `StreamBuilder` em vez de gerenciador de estado | Escopo pequeno; evita dependência extra |
| `SetOptions(merge: true)` no perfil do paciente | Permite atualizar campos parcialmente sem sobrescrever campos futuros |
| Batch write na reordenação de refeições | Atualização atômica; evita estado inconsistente se a operação for interrompida |
| `garantirRefeicoesIniciais()` no `initState` da HomeScreen | Garante dados padrão sem bloquear a UI (não usa `await`) |
| Login anônimo no startup | Permite uso imediato sem atrito; tradeoff: dados não migram com login social posterior |
