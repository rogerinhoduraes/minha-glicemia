import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_glicemia/models/paciente.dart';
import 'package:minha_glicemia/models/registro_glicemia.dart';
import 'package:minha_glicemia/services/glicemia_service.dart';

void main() {
  late FakeFirebaseFirestore db;
  late GlicemiaService service;

  RegistroGlicemia registro(DateTime dataHora, {int valor = 100}) =>
      RegistroGlicemia(dataHora: dataHora, refeicao: 'Almoço', valor: valor);

  setUp(() {
    db = FakeFirebaseFirestore();
    service = GlicemiaService(db: db, uid: () => 'u1');
  });

  group('registros', () {
    test('salva em usuarios/{uid}/registros e lista em ordem cronológica', () async {
      await service.salvar(registro(DateTime(2026, 1, 3)));
      await service.salvar(registro(DateTime(2026, 1, 1)));
      await service.salvar(registro(DateTime(2026, 1, 2)));

      final todos = await service.buscarTodosRegistros();
      expect(todos.map((r) => r.dataHora.day), [1, 2, 3]);
      final snap = await db.collection('usuarios').doc('u1').collection('registros').get();
      expect(snap.docs, hasLength(3));
    });

    test('busca por período inclui o dia final inteiro', () async {
      await service.salvar(registro(DateTime(2026, 1, 9, 23, 59)));
      await service.salvar(registro(DateTime(2026, 1, 10, 0, 0)));
      await service.salvar(registro(DateTime(2026, 1, 15, 23, 59)));
      await service.salvar(registro(DateTime(2026, 1, 16, 0, 0)));

      final periodo =
          await service.buscarRegistrosPorPeriodo(DateTime(2026, 1, 10), DateTime(2026, 1, 15));
      expect(periodo.map((r) => r.dataHora),
          [DateTime(2026, 1, 10, 0, 0), DateTime(2026, 1, 15, 23, 59)]);
    });

    test('últimos registros vêm do mais recente, respeitando o limite', () async {
      for (var d = 1; d <= 5; d++) {
        await service.salvar(registro(DateTime(2026, 1, d)));
      }
      final ultimos = await service.ultimosRegistros(limite: 3).first;
      expect(ultimos.map((r) => r.dataHora.day), [5, 4, 3]);
    });

    test('edita e deleta pelo id', () async {
      await service.salvar(registro(DateTime(2026, 1, 1), valor: 100));
      final salvo = (await service.buscarTodosRegistros()).single;

      await service.editar(RegistroGlicemia(
          id: salvo.id, dataHora: salvo.dataHora, refeicao: 'Jantar', valor: 180));
      final editado = (await service.buscarTodosRegistros()).single;
      expect(editado.valor, 180);
      expect(editado.refeicao, 'Jantar');

      await service.deletar(salvo.id!);
      expect(await service.buscarTodosRegistros(), isEmpty);
    });

    test('não enxerga registros de outro usuário', () async {
      final outro = GlicemiaService(db: db, uid: () => 'u2');
      await outro.salvar(registro(DateTime(2026, 1, 1)));
      expect(await service.buscarTodosRegistros(), isEmpty);
    });
  });

  group('paciente', () {
    test('retorna null quando não há perfil', () async {
      expect(await service.buscarPaciente(), isNull);
    });

    test('salva e busca o perfil', () async {
      await service.salvarPaciente(
          Paciente(nome: 'Ana', dataNascimento: DateTime(1990, 5, 20), peso: 62.5));
      final p = await service.buscarPaciente();
      expect(p!.nome, 'Ana');
      expect(p.dataNascimento, DateTime(1990, 5, 20));
      expect(p.peso, 62.5);
    });
  });

  group('refeições', () {
    test('cria as 6 refeições padrão uma única vez', () async {
      await service.garantirRefeicoesIniciais();
      await service.garantirRefeicoesIniciais();

      final lista = await service.streamRefeicoes().first;
      expect(lista.map((r) => r.nome), [
        'Em jejum', '2h após jejum', 'Almoço', '2h após Almoço', 'Café da Tarde', 'Jantar',
      ]);
      expect(lista.first.horario, '07:00');
      expect(lista.every((r) => !r.lembreteAtivo), isTrue);
    });

    test('mantém refeições cadastradas e acrescenta as padrão no fim', () async {
      await service.adicionarRefeicao('Ceia', 0, horario: '22:00');
      await service.garantirRefeicoesIniciais();
      final lista = await service.streamRefeicoes().first;
      expect(lista.first.nome, 'Ceia');
      expect(lista.first.horario, '22:00');
      expect(lista, hasLength(7));
    });

    test('recria no fim só as refeições padrão que faltam', () async {
      await service.garantirRefeicoesIniciais();
      final antes = await service.streamRefeicoes().first;
      final almoco = antes.firstWhere((r) => r.nome == 'Almoço');
      await service.deletarRefeicao(almoco.id!);

      await service.garantirRefeicoesIniciais();
      final depois = await service.streamRefeicoes().first;
      expect(depois, hasLength(6));
      expect(depois.last.nome, 'Almoço');
      expect(depois.last.horario, '12:00');
      expect(depois.where((r) => r.nome == 'Jantar'), hasLength(1));
    });

    test('reordena gravando a nova posição em ordem', () async {
      await service.garantirRefeicoesIniciais();
      final lista = await service.streamRefeicoes().first;

      await service.reordenarRefeicoes(lista.reversed.toList());
      final reordenada = await service.streamRefeicoes().first;
      expect(reordenada.map((r) => r.nome), lista.reversed.map((r) => r.nome));
      expect(reordenada.map((r) => r.ordem), [0, 1, 2, 3, 4, 5]);
    });

    test('atualiza e deleta uma refeição', () async {
      await service.adicionarRefeicao('Ceia', 0);
      final ceia = (await service.streamRefeicoes().first).single;

      await service.atualizarRefeicao(ceia.copyWith(horario: '22:30', lembreteAtivo: true));
      final atualizada = (await service.streamRefeicoes().first).single;
      expect(atualizada.horario, '22:30');
      expect(atualizada.lembreteAtivo, isTrue);

      await service.deletarRefeicao(ceia.id!);
      expect(await service.streamRefeicoes().first, isEmpty);
    });
  });

  test('deletarTodosDados apaga só os dados do usuário atual', () async {
    await service.salvar(registro(DateTime(2026, 1, 1)));
    await service.garantirRefeicoesIniciais();
    await service.salvarPaciente(Paciente(nome: 'Ana'));
    final outro = GlicemiaService(db: db, uid: () => 'u2');
    await outro.salvar(registro(DateTime(2026, 1, 1)));

    await service.deletarTodosDados();

    expect(await service.buscarTodosRegistros(), isEmpty);
    expect(await service.streamRefeicoes().first, isEmpty);
    expect(await service.buscarPaciente(), isNull);
    expect(await outro.buscarTodosRegistros(), hasLength(1));
  });
}
