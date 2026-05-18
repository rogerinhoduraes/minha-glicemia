import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/tipo_refeicao.dart';

class NotificacaoService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'lembretes_glicemia';
  static const _channelName = 'Lembretes de Glicemia';

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static int _idPara(TipoRefeicao r) => r.id.hashCode.abs() % 100000;

  static Future<void> agendarLembrete(TipoRefeicao r) async {
    if (r.horario == null || !r.lembreteAtivo) {
      await cancelarLembrete(r);
      return;
    }

    try {
      final parts = r.horario!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = tz.TZDateTime.now(tz.local);
      var scheduled =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _idPara(r),
        'Hora de medir a glicemia',
        '${r.nome} — registre sua medição agora',
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Lembretes para medir a glicemia',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Silencia erros de permissão
    }
  }

  static Future<void> cancelarLembrete(TipoRefeicao r) async {
    await _plugin.cancel(_idPara(r));
  }

  static Future<void> sincronizarTodos(List<TipoRefeicao> refeicoes) async {
    for (final r in refeicoes) {
      await agendarLembrete(r);
    }
  }
}
