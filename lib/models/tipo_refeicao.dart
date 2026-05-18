import 'package:cloud_firestore/cloud_firestore.dart';

class TipoRefeicao {
  final String? id;
  final String nome;
  final int ordem;
  final String? horario;       // "HH:mm", ex: "07:00"
  final bool lembreteAtivo;

  TipoRefeicao({
    this.id,
    required this.nome,
    required this.ordem,
    this.horario,
    this.lembreteAtivo = false,
  });

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'ordem': ordem,
        'horario': horario,
        'lembreteAtivo': lembreteAtivo,
      };

  factory TipoRefeicao.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return TipoRefeicao(
      id: doc.id,
      nome: m['nome'] ?? '',
      ordem: (m['ordem'] as num?)?.toInt() ?? 0,
      horario: m['horario'] as String?,
      lembreteAtivo: m['lembreteAtivo'] as bool? ?? false,
    );
  }

  TipoRefeicao copyWith({
    String? nome,
    int? ordem,
    Object? horario = _sentinel,
    bool? lembreteAtivo,
  }) =>
      TipoRefeicao(
        id: id,
        nome: nome ?? this.nome,
        ordem: ordem ?? this.ordem,
        horario: horario == _sentinel ? this.horario : horario as String?,
        lembreteAtivo: lembreteAtivo ?? this.lembreteAtivo,
      );
}

const _sentinel = Object();
