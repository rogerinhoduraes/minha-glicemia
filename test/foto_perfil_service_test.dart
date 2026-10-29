import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minha_glicemia/services/foto_perfil_service.dart';

void main() {
  late Directory pasta;
  late File origem;
  var uid = 'u1';
  late FotoPerfilService service;

  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('foto_perfil');
    origem = File('${pasta.path}/camera.jpg')..writeAsBytesSync([1, 2, 3]);
    uid = 'u1';
    service = FotoPerfilService(pasta: () async => pasta, uid: () => uid);
  });

  tearDown(() => pasta.delete(recursive: true));

  test('sem foto salva retorna null', () async {
    expect(await service.buscar(), isNull);
  });

  test('salva uma cópia por uid e a troca substitui a anterior', () async {
    final salva = await service.salvar(origem.path);
    expect(salva.path, endsWith('perfil_u1.jpg'));
    expect(salva.readAsBytesSync(), [1, 2, 3]);

    origem.writeAsBytesSync([9]);
    await service.salvar(origem.path);
    expect((await service.buscar())!.readAsBytesSync(), [9]);
  });

  test('cada uid tem a própria foto', () async {
    await service.salvar(origem.path);
    uid = 'u2';
    expect(await service.buscar(), isNull);
  });

  test('remover apaga o arquivo', () async {
    await service.salvar(origem.path);
    await service.remover();
    expect(await service.buscar(), isNull);
  });
}
