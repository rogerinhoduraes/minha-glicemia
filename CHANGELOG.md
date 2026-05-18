# Changelog

Todas as mudanças relevantes do projeto estão documentadas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).

---

## [1.1.0] — 2026-05-16

### Adicionado
- Tela de Relatório com seleção de período (toque nas datas para alterar, padrão: últimos 30 dias)
- Exportação de PDF diagramado via botão no topo da tela de Relatório
- PDF gerado com: cabeçalho azul, dados do paciente, resumo (média/menor/maior), distribuição por nível com barras de progresso, média por refeição e tabela completa do histórico com linhas alternadas e badges coloridos
- Numeração de páginas e rodapé em todas as páginas do PDF
- Método `buscarRegistrosPorPeriodo` no `GlicemiaService` para consulta filtrada no Firestore

### Corrigido
- Bug de sintaxe em `PacienteScreen` que impedia compilação (parêntese extra na linha 143 e parêntese faltando no `SingleChildScrollView`)
- Atributos estendidos macOS (`@xattr`) nos PNGs de recursos Android que bloqueavam o Gradle

### Alterado
- Campo de entrada de glicemia reduzido em 50% (fonte 64 → 32 pt, padding vertical 20 → 10) para ganhar mais espaço vertical no formulário

---

## [1.0.0] — 2026-05-16

### Adicionado
- Registro de medições de glicemia com valor em mg/dL e tipo de refeição
- Classificação automática por nível: Normal (≤ 140), Alto (141–200), Muito Alto (> 200)
- Histórico em tempo real dos últimos 10 registros via Firestore stream
- Edição e exclusão de registros com confirmação
- Perfil do paciente: nome, peso (kg), data de nascimento, idade calculada
- Gerenciamento de tipos de refeição: adicionar, remover, reordenar por arrastar
- Seis refeições padrão criadas automaticamente no primeiro uso
- Autenticação com Google Sign-In e Facebook Login
- Login anônimo silencioso no startup para acesso imediato
- Banner AdMob adaptativo na base da tela
- Tema Material 3 com fonte Nunito Sans e cores azul (#2563EB)
- Splash screen e ícone gerados via `flutter_native_splash` e `flutter_launcher_icons`
- Localização pt-BR em toda a interface e formatação de datas
