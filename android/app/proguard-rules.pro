# ---------------------------------------------------------------------------
# Room / WorkManager 反射入口保护
#
# Room 通过反射实例化数据库实现类：
#   Class.forName("$canonicalName" + "_Impl").newInstance()
# room-runtime 自带的 consumer 规则只有：
#   -keep class * extends androidx.room.RoomDatabase
# 该规则仅保留类名本身、不保留成员。R8 9.x（AGP 9.0.1 自带）会据此删除没有
# 静态引用的无参构造函数，导致 WorkManager 启动时抛 InstantiationException：
#
#   FATAL EXCEPTION: Unable to get provider androidx.startup.InitializationProvider:
#     Failed to create an instance of class ...WorkDatabase.canonicalName
#
# 崩溃发生在 Application 初始化阶段（handleBindApplication），Flutter 引擎尚未
# 启动，因此表现为应用一直白屏。旧版 AGP 8.2 自带的 R8 不会删除该构造函数，
# 所以升级构建链之前一切正常。
# ---------------------------------------------------------------------------
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
