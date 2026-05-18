import 'package:cloud_firestore/cloud_firestore.dart';

class Paciente {
  final String nome;
  final DateTime? dataNascimento;
  final double? peso;

  Paciente({required this.nome, this.dataNascimento, this.peso});

  int? get idade {
    if (dataNascimento == null) return null;
    final hoje = DateTime.now();
    int anos = hoje.year - dataNascimento!.year;
    if (hoje.month < dataNascimento!.month ||
        (hoje.month == dataNascimento!.month && hoje.day < dataNascimento!.day)) {
      anos--;
    }
    return anos;
  }

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'dataNascimento': dataNascimento != null ? Timestamp.fromDate(dataNascimento!) : null,
        'peso': peso,
      };

  factory Paciente.fromMap(Map<String, dynamic> map) => Paciente(
        nome: map['nome'] ?? '',
        dataNascimento: (map['dataNascimento'] as Timestamp?)?.toDate(),
        peso: (map['peso'] as num?)?.toDouble(),
      );
}
