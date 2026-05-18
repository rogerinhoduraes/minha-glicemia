import 'package:cloud_firestore/cloud_firestore.dart';

enum NivelGlicemia { normal, alto, muitoAlto }

class RegistroGlicemia {
  final String? id;
  final DateTime dataHora;
  final String refeicao;
  final int valor;

  RegistroGlicemia({
    this.id,
    required this.dataHora,
    required this.refeicao,
    required this.valor,
  });

  NivelGlicemia get nivel {
    if (valor <= 140) return NivelGlicemia.normal;
    if (valor <= 200) return NivelGlicemia.alto;
    return NivelGlicemia.muitoAlto;
  }

  Map<String, dynamic> toMap() => {
        'dataHora': Timestamp.fromDate(dataHora),
        'refeicao': refeicao,
        'valor': valor,
      };

  factory RegistroGlicemia.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return RegistroGlicemia(
      id: doc.id,
      dataHora: (m['dataHora'] as Timestamp).toDate(),
      refeicao: m['refeicao'] ?? '',
      valor: (m['valor'] as num).toInt(),
    );
  }
}
