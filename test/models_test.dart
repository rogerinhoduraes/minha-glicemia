import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_glicemia/models/paciente.dart';
import 'package:minha_glicemia/models/registro_glicemia.dart';
import 'package:minha_glicemia/models/tipo_refeicao.dart';

Future<DocumentSnapshot<Map<String, dynamic>>> _doc(Map<String, dynamic> data) async {
  final ref = FakeFirebaseFirestore().collection('c').doc('id1');
  await ref.set(data);
  return ref.get();
}

void main() {
  group('RegistroGlicemia', () {
    RegistroGlicemia comValor(int v) =>
        RegistroGlicemia(dataHora: DateTime(2026, 1, 1), refeicao: 'Almoço', valor: v);

    test('nivel respeita os limites 140 e 200', () {
      expect(comValor(70).nivel, NivelGlicemia.normal);
      expect(comValor(140).nivel, NivelGlicemia.normal);
      expect(comValor(141).nivel, NivelGlicemia.alto);
      expect(comValor(200).nivel, NivelGlicemia.alto);
      expect(comValor(201).nivel, NivelGlicemia.muitoAlto);
    });

    test('toMap e fromDoc fazem ida e volta', () async {
      final original = RegistroGlicemia(
          dataHora: DateTime(2026, 3, 15, 7, 30), refeicao: 'Em jejum', valor: 98);
      final r = RegistroGlicemia.fromDoc(await _doc(original.toMap()));
      expect(r.id, 'id1');
      expect(r.dataHora, original.dataHora);
      expect(r.refeicao, 'Em jejum');
      expect(r.valor, 98);
    });

    test('fromDoc aceita valor double e refeição ausente', () async {
      final r = RegistroGlicemia.fromDoc(await _doc({
        'dataHora': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'valor': 120.0,
      }));
      expect(r.valor, 120);
      expect(r.refeicao, '');
    });
  });

  group('TipoRefeicao', () {
    test('fromDoc usa padrões para campos ausentes', () async {
      final r = TipoRefeicao.fromDoc(await _doc({'nome': 'Ceia'}));
      expect(r.id, 'id1');
      expect(r.nome, 'Ceia');
      expect(r.ordem, 0);
      expect(r.horario, isNull);
      expect(r.lembreteAtivo, isFalse);
    });

    test('toMap e fromDoc fazem ida e volta', () async {
      final original =
          TipoRefeicao(nome: 'Jantar', ordem: 5, horario: '19:00', lembreteAtivo: true);
      final r = TipoRefeicao.fromDoc(await _doc(original.toMap()));
      expect(r.nome, 'Jantar');
      expect(r.ordem, 5);
      expect(r.horario, '19:00');
      expect(r.lembreteAtivo, isTrue);
    });

    test('copyWith mantém o horário quando omitido e limpa quando null', () {
      final r = TipoRefeicao(id: 'x', nome: 'Almoço', ordem: 2, horario: '12:00');
      expect(r.copyWith(lembreteAtivo: true).horario, '12:00');
      expect(r.copyWith(horario: null).horario, isNull);
      expect(r.copyWith(horario: '13:00').horario, '13:00');
      expect(r.copyWith(nome: 'Brunch').id, 'x');
    });
  });

  group('Paciente', () {
    test('idade é null sem data de nascimento', () {
      expect(Paciente(nome: 'Ana').idade, isNull);
    });

    test('idade conta só aniversários já feitos no ano', () {
      final hoje = DateTime.now();
      expect(Paciente(nome: 'Ana', dataNascimento: DateTime(hoje.year - 30, 1, 1)).idade, 30);
      final ultimoDia = hoje.month == 12 && hoje.day == 31;
      expect(Paciente(nome: 'Ana', dataNascimento: DateTime(hoje.year - 30, 12, 31)).idade,
          ultimoDia ? 30 : 29);
    });

    test('toMap e fromMap fazem ida e volta', () {
      final original = Paciente(nome: 'Ana', dataNascimento: DateTime(1990, 5, 20), peso: 62.5);
      final p = Paciente.fromMap(original.toMap());
      expect(p.nome, 'Ana');
      expect(p.dataNascimento, DateTime(1990, 5, 20));
      expect(p.peso, 62.5);
    });

    test('fromMap aceita mapa vazio e peso inteiro', () {
      final vazio = Paciente.fromMap({});
      expect(vazio.nome, '');
      expect(vazio.dataNascimento, isNull);
      expect(vazio.peso, isNull);
      expect(Paciente.fromMap({'peso': 70}).peso, 70.0);
    });
  });
}
