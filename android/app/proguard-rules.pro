# Regras do R8 para release (Flutter já inclui as suas próprias).

# WorkManager/Room (via google_mobile_ads): o R8 removia WorkDatabase_Impl e o app crashava ao abrir.
-keep class * extends androidx.room.RoomDatabase
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-dontwarn androidx.room.paging.**
