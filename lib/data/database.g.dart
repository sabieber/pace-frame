// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, Activity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movingTimeMeta = const VerificationMeta(
    'movingTime',
  );
  @override
  late final GeneratedColumn<int> movingTime = GeneratedColumn<int>(
    'moving_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgWattsMeta = const VerificationMeta(
    'avgWatts',
  );
  @override
  late final GeneratedColumn<double> averageWatts = GeneratedColumn<double>(
    'avg_watts',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgHeartrateMeta = const VerificationMeta(
    'avgHeartrate',
  );
  @override
  late final GeneratedColumn<double> averageHeartRate = GeneratedColumn<double>(
    'avg_heartrate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elevationGainMeta = const VerificationMeta(
    'elevationGain',
  );
  @override
  late final GeneratedColumn<double> elevationGain = GeneratedColumn<double>(
    'elevation_gain',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryPolylineMeta = const VerificationMeta(
    'summaryPolyline',
  );
  @override
  late final GeneratedColumn<String> summaryPolyline = GeneratedColumn<String>(
    'summary_polyline',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    startDate,
    distance,
    movingTime,
    averageWatts,
    averageHeartRate,
    elevationGain,
    summaryPolyline,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<Activity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceMeta);
    }
    if (data.containsKey('moving_time')) {
      context.handle(
        _movingTimeMeta,
        movingTime.isAcceptableOrUnknown(data['moving_time']!, _movingTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_movingTimeMeta);
    }
    if (data.containsKey('avg_watts')) {
      context.handle(
        _avgWattsMeta,
        averageWatts.isAcceptableOrUnknown(data['avg_watts']!, _avgWattsMeta),
      );
    }
    if (data.containsKey('avg_heartrate')) {
      context.handle(
        _avgHeartrateMeta,
        averageHeartRate.isAcceptableOrUnknown(
          data['avg_heartrate']!,
          _avgHeartrateMeta,
        ),
      );
    }
    if (data.containsKey('elevation_gain')) {
      context.handle(
        _elevationGainMeta,
        elevationGain.isAcceptableOrUnknown(
          data['elevation_gain']!,
          _elevationGainMeta,
        ),
      );
    }
    if (data.containsKey('summary_polyline')) {
      context.handle(
        _summaryPolylineMeta,
        summaryPolyline.isAcceptableOrUnknown(
          data['summary_polyline']!,
          _summaryPolylineMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Activity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Activity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      )!,
      movingTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_time'],
      )!,
      avgWatts: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_watts'],
      ),
      avgHeartrate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_heartrate'],
      ),
      elevationGain: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation_gain'],
      ),
      summaryPolyline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_polyline'],
      ),
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }
}

class Activity extends DataClass implements Insertable<Activity> {
  final int id;
  final String name;
  final String type;
  final DateTime startDate;
  final double distance;
  final int movingTime;
  final double? avgWatts;
  final double? avgHeartrate;
  final double? elevationGain;
  final String? summaryPolyline;
  const Activity({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.distance,
    required this.movingTime,
    this.avgWatts,
    this.avgHeartrate,
    this.elevationGain,
    this.summaryPolyline,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['start_date'] = Variable<DateTime>(startDate);
    map['distance'] = Variable<double>(distance);
    map['moving_time'] = Variable<int>(movingTime);
    if (!nullToAbsent || avgWatts != null) {
      map['avg_watts'] = Variable<double>(avgWatts);
    }
    if (!nullToAbsent || avgHeartrate != null) {
      map['avg_heartrate'] = Variable<double>(avgHeartrate);
    }
    if (!nullToAbsent || elevationGain != null) {
      map['elevation_gain'] = Variable<double>(elevationGain);
    }
    if (!nullToAbsent || summaryPolyline != null) {
      map['summary_polyline'] = Variable<String>(summaryPolyline);
    }
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      startDate: Value(startDate),
      distance: Value(distance),
      movingTime: Value(movingTime),
      avgWatts: avgWatts == null && nullToAbsent
          ? const Value.absent()
          : Value(avgWatts),
      avgHeartrate: avgHeartrate == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHeartrate),
      elevationGain: elevationGain == null && nullToAbsent
          ? const Value.absent()
          : Value(elevationGain),
      summaryPolyline: summaryPolyline == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryPolyline),
    );
  }

  factory Activity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Activity(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      distance: serializer.fromJson<double>(json['distance']),
      movingTime: serializer.fromJson<int>(json['movingTime']),
      avgWatts: serializer.fromJson<double?>(json['avgWatts']),
      avgHeartrate: serializer.fromJson<double?>(json['avgHeartrate']),
      elevationGain: serializer.fromJson<double?>(json['elevationGain']),
      summaryPolyline: serializer.fromJson<String?>(json['summaryPolyline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'startDate': serializer.toJson<DateTime>(startDate),
      'distance': serializer.toJson<double>(distance),
      'movingTime': serializer.toJson<int>(movingTime),
      'avgWatts': serializer.toJson<double?>(avgWatts),
      'avgHeartrate': serializer.toJson<double?>(avgHeartrate),
      'elevationGain': serializer.toJson<double?>(elevationGain),
      'summaryPolyline': serializer.toJson<String?>(summaryPolyline),
    };
  }

  Activity copyWith({
    int? id,
    String? name,
    String? type,
    DateTime? startDate,
    double? distance,
    int? movingTime,
    Value<double?> avgWatts = const Value.absent(),
    Value<double?> avgHeartrate = const Value.absent(),
    Value<double?> elevationGain = const Value.absent(),
    Value<String?> summaryPolyline = const Value.absent(),
  }) => Activity(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    startDate: startDate ?? this.startDate,
    distance: distance ?? this.distance,
    movingTime: movingTime ?? this.movingTime,
    avgWatts: avgWatts.present ? avgWatts.value : this.avgWatts,
    avgHeartrate: avgHeartrate.present ? avgHeartrate.value : this.avgHeartrate,
    elevationGain: elevationGain.present
        ? elevationGain.value
        : this.elevationGain,
    summaryPolyline: summaryPolyline.present
        ? summaryPolyline.value
        : this.summaryPolyline,
  );
  Activity copyWithCompanion(ActivitiesCompanion data) {
    return Activity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      distance: data.distance.present ? data.distance.value : this.distance,
      movingTime: data.movingTime.present
          ? data.movingTime.value
          : this.movingTime,
      avgWatts: data.avgWatts.present ? data.avgWatts.value : this.avgWatts,
      avgHeartrate: data.avgHeartrate.present
          ? data.avgHeartrate.value
          : this.avgHeartrate,
      elevationGain: data.elevationGain.present
          ? data.elevationGain.value
          : this.elevationGain,
      summaryPolyline: data.summaryPolyline.present
          ? data.summaryPolyline.value
          : this.summaryPolyline,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Activity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('startDate: $startDate, ')
          ..write('distance: $distance, ')
          ..write('movingTime: $movingTime, ')
          ..write('avgWatts: $avgWatts, ')
          ..write('avgHeartrate: $avgHeartrate, ')
          ..write('elevationGain: $elevationGain, ')
          ..write('summaryPolyline: $summaryPolyline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    startDate,
    distance,
    movingTime,
    avgWatts,
    avgHeartrate,
    elevationGain,
    summaryPolyline,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Activity &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.startDate == this.startDate &&
          other.distance == this.distance &&
          other.movingTime == this.movingTime &&
          other.avgWatts == this.avgWatts &&
          other.avgHeartrate == this.avgHeartrate &&
          other.elevationGain == this.elevationGain &&
          other.summaryPolyline == this.summaryPolyline);
}

class ActivitiesCompanion extends UpdateCompanion<Activity> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<DateTime> startDate;
  final Value<double> distance;
  final Value<int> movingTime;
  final Value<double?> avgWatts;
  final Value<double?> avgHeartrate;
  final Value<double?> elevationGain;
  final Value<String?> summaryPolyline;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.startDate = const Value.absent(),
    this.distance = const Value.absent(),
    this.movingTime = const Value.absent(),
    this.avgWatts = const Value.absent(),
    this.avgHeartrate = const Value.absent(),
    this.elevationGain = const Value.absent(),
    this.summaryPolyline = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    required DateTime startDate,
    required double distance,
    required int movingTime,
    this.avgWatts = const Value.absent(),
    this.avgHeartrate = const Value.absent(),
    this.elevationGain = const Value.absent(),
    this.summaryPolyline = const Value.absent(),
  }) : name = Value(name),
       type = Value(type),
       startDate = Value(startDate),
       distance = Value(distance),
       movingTime = Value(movingTime);
  static Insertable<Activity> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<DateTime>? startDate,
    Expression<double>? distance,
    Expression<int>? movingTime,
    Expression<double>? avgWatts,
    Expression<double>? avgHeartrate,
    Expression<double>? elevationGain,
    Expression<String>? summaryPolyline,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (startDate != null) 'start_date': startDate,
      if (distance != null) 'distance': distance,
      if (movingTime != null) 'moving_time': movingTime,
      if (avgWatts != null) 'avg_watts': avgWatts,
      if (avgHeartrate != null) 'avg_heartrate': avgHeartrate,
      if (elevationGain != null) 'elevation_gain': elevationGain,
      if (summaryPolyline != null) 'summary_polyline': summaryPolyline,
    });
  }

  ActivitiesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? type,
    Value<DateTime>? startDate,
    Value<double>? distance,
    Value<int>? movingTime,
    Value<double?>? avgWatts,
    Value<double?>? avgHeartrate,
    Value<double?>? elevationGain,
    Value<String?>? summaryPolyline,
  }) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      distance: distance ?? this.distance,
      movingTime: movingTime ?? this.movingTime,
      avgWatts: avgWatts ?? this.avgWatts,
      avgHeartrate: avgHeartrate ?? this.avgHeartrate,
      elevationGain: elevationGain ?? this.elevationGain,
      summaryPolyline: summaryPolyline ?? this.summaryPolyline,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (movingTime.present) {
      map['moving_time'] = Variable<int>(movingTime.value);
    }
    if (avgWatts.present) {
      map['avg_watts'] = Variable<double>(avgWatts.value);
    }
    if (avgHeartrate.present) {
      map['avg_heartrate'] = Variable<double>(avgHeartrate.value);
    }
    if (elevationGain.present) {
      map['elevation_gain'] = Variable<double>(elevationGain.value);
    }
    if (summaryPolyline.present) {
      map['summary_polyline'] = Variable<String>(summaryPolyline.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('startDate: $startDate, ')
          ..write('distance: $distance, ')
          ..write('movingTime: $movingTime, ')
          ..write('avgWatts: $avgWatts, ')
          ..write('avgHeartrate: $avgHeartrate, ')
          ..write('elevationGain: $elevationGain, ')
          ..write('summaryPolyline: $summaryPolyline')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [activities];
}

typedef $$ActivitiesTableCreateCompanionBuilder =
    ActivitiesCompanion Function({
      Value<int> id,
      required String name,
      required String type,
      required DateTime startDate,
      required double distance,
      required int movingTime,
      Value<double?> avgWatts,
      Value<double?> avgHeartrate,
      Value<double?> elevationGain,
      Value<String?> summaryPolyline,
    });
typedef $$ActivitiesTableUpdateCompanionBuilder =
    ActivitiesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> type,
      Value<DateTime> startDate,
      Value<double> distance,
      Value<int> movingTime,
      Value<double?> avgWatts,
      Value<double?> avgHeartrate,
      Value<double?> elevationGain,
      Value<String?> summaryPolyline,
    });

class $$ActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movingTime => $composableBuilder(
    column: $table.movingTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgWatts => $composableBuilder(
    column: $table.averageWatts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgHeartrate => $composableBuilder(
    column: $table.averageHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevationGain => $composableBuilder(
    column: $table.elevationGain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryPolyline => $composableBuilder(
    column: $table.summaryPolyline,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingTime => $composableBuilder(
    column: $table.movingTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgWatts => $composableBuilder(
    column: $table.averageWatts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgHeartrate => $composableBuilder(
    column: $table.averageHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevationGain => $composableBuilder(
    column: $table.elevationGain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryPolyline => $composableBuilder(
    column: $table.summaryPolyline,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<int> get movingTime => $composableBuilder(
    column: $table.movingTime,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgWatts =>
      $composableBuilder(column: $table.averageWatts, builder: (column) => column);

  GeneratedColumn<double> get avgHeartrate => $composableBuilder(
    column: $table.averageHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get elevationGain => $composableBuilder(
    column: $table.elevationGain,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summaryPolyline => $composableBuilder(
    column: $table.summaryPolyline,
    builder: (column) => column,
  );
}

class $$ActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivitiesTable,
          Activity,
          $$ActivitiesTableFilterComposer,
          $$ActivitiesTableOrderingComposer,
          $$ActivitiesTableAnnotationComposer,
          $$ActivitiesTableCreateCompanionBuilder,
          $$ActivitiesTableUpdateCompanionBuilder,
          (Activity, BaseReferences<_$AppDatabase, $ActivitiesTable, Activity>),
          Activity,
          PrefetchHooks Function()
        > {
  $$ActivitiesTableTableManager(_$AppDatabase db, $ActivitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<double> distance = const Value.absent(),
                Value<int> movingTime = const Value.absent(),
                Value<double?> avgWatts = const Value.absent(),
                Value<double?> avgHeartrate = const Value.absent(),
                Value<double?> elevationGain = const Value.absent(),
                Value<String?> summaryPolyline = const Value.absent(),
              }) => ActivitiesCompanion(
                id: id,
                name: name,
                type: type,
                startDate: startDate,
                distance: distance,
                movingTime: movingTime,
                avgWatts: avgWatts,
                avgHeartrate: avgHeartrate,
                elevationGain: elevationGain,
                summaryPolyline: summaryPolyline,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String type,
                required DateTime startDate,
                required double distance,
                required int movingTime,
                Value<double?> avgWatts = const Value.absent(),
                Value<double?> avgHeartrate = const Value.absent(),
                Value<double?> elevationGain = const Value.absent(),
                Value<String?> summaryPolyline = const Value.absent(),
              }) => ActivitiesCompanion.insert(
                id: id,
                name: name,
                type: type,
                startDate: startDate,
                distance: distance,
                movingTime: movingTime,
                avgWatts: avgWatts,
                avgHeartrate: avgHeartrate,
                elevationGain: elevationGain,
                summaryPolyline: summaryPolyline,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivitiesTable,
      Activity,
      $$ActivitiesTableFilterComposer,
      $$ActivitiesTableOrderingComposer,
      $$ActivitiesTableAnnotationComposer,
      $$ActivitiesTableCreateCompanionBuilder,
      $$ActivitiesTableUpdateCompanionBuilder,
      (Activity, BaseReferences<_$AppDatabase, $ActivitiesTable, Activity>),
      Activity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
}
