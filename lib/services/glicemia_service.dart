import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/paciente.dart';
import '../models/registro_glicemia.dart';
import '../models/tipo_refeicao.dart';

class GlicemiaService {
  final FirebaseFirestore _db;
  final String Function() _uid;

  /// [db] e [uid] são injetáveis para testes; por padrão usam o Firebase real.
  GlicemiaService({FirebaseFirestore? db, String Function()? uid})
      : _db = db ?? FirebaseFirestore.instance,
        _uid = uid ?? (() => FirebaseAuth.instance.currentUser!.uid);

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = _uid();
    return _db.collection('usuarios').doc(uid).collection('registros');
  }

  DocumentReference<Map<String, dynamic>> get _pacienteDoc {
    final uid = _uid();
    return _db.collection('usuarios').doc(uid).collection('perfil').doc('paciente');
  }

  Future<List<RegistroGlicemia>> buscarTodosRegistros() async {
    final snap = await _col.orderBy('dataHora', descending: false).get();
    return snap.docs.map(RegistroGlicemia.fromDoc).toList();
  }

  Future<List<RegistroGlicemia>> buscarRegistrosPorPeriodo(
      DateTime inicio, DateTime fim) async {
    final fimDia = DateTime(fim.year, fim.month, fim.day, 23, 59, 59);
    final snap = await _col
        .where('dataHora', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('dataHora', isLessThanOrEqualTo: Timestamp.fromDate(fimDia))
        .orderBy('dataHora')
        .get();
    return snap.docs.map(RegistroGlicemia.fromDoc).toList();
  }

  Stream<List<RegistroGlicemia>> ultimosRegistros({int limite = 10}) {
    return _col
        .orderBy('dataHora', descending: true)
        .limit(limite)
        .snapshots()
        .map((s) => s.docs.map(RegistroGlicemia.fromDoc).toList());
  }

  Future<void> salvar(RegistroGlicemia r) => _col.add(r.toMap());

  Future<void> editar(RegistroGlicemia r) =>
      _col.doc(r.id).update(r.toMap());

  Future<void> deletar(String id) => _col.doc(id).delete();

  Future<Paciente?> buscarPaciente() async {
    final doc = await _pacienteDoc.get();
    if (!doc.exists) return null;
    return Paciente.fromMap(doc.data()!);
  }

  Future<void> salvarPaciente(Paciente p) =>
      _pacienteDoc.set(p.toMap(), SetOptions(merge: true));

  CollectionReference<Map<String, dynamic>> get _refeicoesCol {
    final uid = _uid();
    return _db.collection('usuarios').doc(uid).collection('refeicoes');
  }

  Stream<List<TipoRefeicao>> streamRefeicoes() {
    return _refeicoesCol
        .orderBy('ordem')
        .snapshots()
        .map((s) => s.docs.map(TipoRefeicao.fromDoc).toList());
  }

  Future<void> adicionarRefeicao(String nome, int ordem, {String? horario}) =>
      _refeicoesCol.add({
        'nome': nome,
        'ordem': ordem,
        'horario': horario,
        'lembreteAtivo': false,
      });

  Future<void> atualizarRefeicao(TipoRefeicao r) =>
      _refeicoesCol.doc(r.id).update(r.toMap());

  Future<void> deletarRefeicao(String id) => _refeicoesCol.doc(id).delete();

  Future<void> reordenarRefeicoes(List<TipoRefeicao> lista) {
    final batch = _db.batch();
    for (var i = 0; i < lista.length; i++) {
      batch.update(_refeicoesCol.doc(lista[i].id), {'ordem': i});
    }
    return batch.commit();
  }

  static const _refeicoesDefault = [
    ('Em jejum', '07:00'),
    ('2h após jejum', '09:00'),
    ('Almoço', '12:00'),
    ('2h após Almoço', '14:00'),
    ('Café da Tarde', '16:00'),
    ('Jantar', '19:00'),
  ];

  /// Refeições criadas no primeiro acesso; não podem ser removidas.
  static final nomesPadrao = {for (final (nome, _) in _refeicoesDefault) nome};

  Future<void> garantirRefeicoesIniciais() async {
    final snap = await _refeicoesCol.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (var i = 0; i < _refeicoesDefault.length; i++) {
      final (nome, horario) = _refeicoesDefault[i];
      batch.set(_refeicoesCol.doc(), {
        'nome': nome,
        'ordem': i,
        'horario': horario,
        'lembreteAtivo': false,
      });
    }
    await batch.commit();
  }

  /// Remove todos os dados do usuário (registros, refeições e perfil).
  Future<void> deletarTodosDados() async {
    final perfil = _db
        .collection('usuarios')
        .doc(_uid())
        .collection('perfil');
    for (final col in [_col, _refeicoesCol, perfil]) {
      while (true) {
        final snap = await col.limit(400).get();
        if (snap.docs.isEmpty) break;
        final batch = _db.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }
  }
}
