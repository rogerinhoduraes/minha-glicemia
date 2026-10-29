import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

/// Foto do paciente guardada só no aparelho, um arquivo por usuário.
class FotoPerfilService {
  final Future<Directory> Function() _pasta;
  final String Function() _uid;

  FotoPerfilService({
    Future<Directory> Function()? pasta,
    String Function()? uid,
  })  : _pasta = pasta ?? getApplicationDocumentsDirectory,
        _uid = uid ?? (() => FirebaseAuth.instance.currentUser!.uid);

  Future<File> _arquivo() async =>
      File('${(await _pasta()).path}/perfil_${_uid()}.jpg');

  Future<File?> buscar() async {
    final f = await _arquivo();
    return await f.exists() ? f : null;
  }

  /// Copia a imagem escolhida para a pasta do app, substituindo a anterior.
  Future<File> salvar(String origem) async =>
      File(origem).copy((await _arquivo()).path);

  Future<void> remover() async {
    final f = await _arquivo();
    if (await f.exists()) await f.delete();
  }
}
