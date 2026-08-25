// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CatalogEntriesTable extends CatalogEntries
    with TableInfo<$CatalogEntriesTable, CatalogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [barcode, name, category];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {barcode};
  @override
  CatalogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogEntry(
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
    );
  }

  @override
  $CatalogEntriesTable createAlias(String alias) {
    return $CatalogEntriesTable(attachedDatabase, alias);
  }
}

class CatalogEntry extends DataClass implements Insertable<CatalogEntry> {
  /// The decoded barcode value, used as the primary lookup key.
  ///
  /// UREQS: SCAN-1
  final String barcode;

  /// Human-readable product name.
  ///
  /// UREQS: SCAN-1
  final String name;

  /// A coarse category used by the matching engine's synonym/category
  /// fallback (LIST-6).
  ///
  /// UREQS: LIST-6
  final String category;
  const CatalogEntry({
    required this.barcode,
    required this.name,
    required this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['barcode'] = Variable<String>(barcode);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    return map;
  }

  CatalogEntriesCompanion toCompanion(bool nullToAbsent) {
    return CatalogEntriesCompanion(
      barcode: Value(barcode),
      name: Value(name),
      category: Value(category),
    );
  }

  factory CatalogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogEntry(
      barcode: serializer.fromJson<String>(json['barcode']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'barcode': serializer.toJson<String>(barcode),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
    };
  }

  CatalogEntry copyWith({String? barcode, String? name, String? category}) =>
      CatalogEntry(
        barcode: barcode ?? this.barcode,
        name: name ?? this.name,
        category: category ?? this.category,
      );
  CatalogEntry copyWithCompanion(CatalogEntriesCompanion data) {
    return CatalogEntry(
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogEntry(')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(barcode, name, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogEntry &&
          other.barcode == this.barcode &&
          other.name == this.name &&
          other.category == this.category);
}

class CatalogEntriesCompanion extends UpdateCompanion<CatalogEntry> {
  final Value<String> barcode;
  final Value<String> name;
  final Value<String> category;
  final Value<int> rowid;
  const CatalogEntriesCompanion({
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogEntriesCompanion.insert({
    required String barcode,
    required String name,
    required String category,
    this.rowid = const Value.absent(),
  }) : barcode = Value(barcode),
       name = Value(name),
       category = Value(category);
  static Insertable<CatalogEntry> custom({
    Expression<String>? barcode,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (barcode != null) 'barcode': barcode,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogEntriesCompanion copyWith({
    Value<String>? barcode,
    Value<String>? name,
    Value<String>? category,
    Value<int>? rowid,
  }) {
    return CatalogEntriesCompanion(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      category: category ?? this.category,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogEntriesCompanion(')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListItemsTable extends ShoppingListItems
    with TableInfo<$ShoppingListItemsTable, ShoppingListItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ListItemStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ListItemStatus>($ShoppingListItemsTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [id, name, category, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_list_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingListItem> instance, {
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
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingListItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingListItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      status: $ShoppingListItemsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $ShoppingListItemsTable createAlias(String alias) {
    return $ShoppingListItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ListItemStatus, String, String> $converterstatus =
      const EnumNameConverter<ListItemStatus>(ListItemStatus.values);
}

class ShoppingListItem extends DataClass
    implements Insertable<ShoppingListItem> {
  /// Row identifier.
  ///
  /// UREQS: LIST-2
  final int id;

  /// The list item's text as entered/generated (e.g., "Milk").
  ///
  /// UREQS: LIST-2, LIST-6
  final String name;

  /// Coarse category, used the same way as [CatalogEntries.category].
  ///
  /// UREQS: LIST-6
  final String category;

  /// Whether this item has been matched to a basket entry yet.
  ///
  /// UREQS: LIST-2, LIST-4
  final ListItemStatus status;
  const ShoppingListItem({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    {
      map['status'] = Variable<String>(
        $ShoppingListItemsTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  ShoppingListItemsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListItemsCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      status: Value(status),
    );
  }

  factory ShoppingListItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingListItem(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      status: $ShoppingListItemsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'status': serializer.toJson<String>(
        $ShoppingListItemsTable.$converterstatus.toJson(status),
      ),
    };
  }

  ShoppingListItem copyWith({
    int? id,
    String? name,
    String? category,
    ListItemStatus? status,
  }) => ShoppingListItem(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    status: status ?? this.status,
  );
  ShoppingListItem copyWithCompanion(ShoppingListItemsCompanion data) {
    return ShoppingListItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, category, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingListItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.status == this.status);
}

class ShoppingListItemsCompanion extends UpdateCompanion<ShoppingListItem> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> category;
  final Value<ListItemStatus> status;
  const ShoppingListItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
  });
  ShoppingListItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String category,
    required ListItemStatus status,
  }) : name = Value(name),
       category = Value(category),
       status = Value(status);
  static Insertable<ShoppingListItem> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
    });
  }

  ShoppingListItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? category,
    Value<ListItemStatus>? status,
  }) {
    return ShoppingListItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ShoppingListItemsTable.$converterstatus.toSql(status.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $BasketEntriesTable extends BasketEntries
    with TableInfo<$BasketEntriesTable, BasketEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BasketEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _listItemIdMeta = const VerificationMeta(
    'listItemId',
  );
  @override
  late final GeneratedColumn<int> listItemId = GeneratedColumn<int>(
    'list_item_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shopping_list_items (id)',
    ),
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listItemId,
    productName,
    barcode,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'basket_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BasketEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('list_item_id')) {
      context.handle(
        _listItemIdMeta,
        listItemId.isAcceptableOrUnknown(
          data['list_item_id']!,
          _listItemIdMeta,
        ),
      );
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BasketEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BasketEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      listItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}list_item_id'],
      ),
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $BasketEntriesTable createAlias(String alias) {
    return $BasketEntriesTable(attachedDatabase, alias);
  }
}

class BasketEntry extends DataClass implements Insertable<BasketEntry> {
  /// Row identifier.
  ///
  /// UREQS: LIST-4
  final int id;

  /// The shopping list item this entry fulfills, if any. `null` for a
  /// manually-added item with no corresponding list entry.
  ///
  /// UREQS: LIST-2, LIST-5
  final int? listItemId;

  /// The product/item name shown in the basket.
  ///
  /// UREQS: LIST-2, LIST-5
  final String productName;

  /// The barcode that was scanned to produce this entry, if any. `null` for
  /// a manually-added item.
  ///
  /// UREQS: SCAN-1, LIST-5
  final String? barcode;

  /// When this entry was added.
  ///
  /// UREQS: LIST-4
  final DateTime addedAt;
  const BasketEntry({
    required this.id,
    this.listItemId,
    required this.productName,
    this.barcode,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || listItemId != null) {
      map['list_item_id'] = Variable<int>(listItemId);
    }
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  BasketEntriesCompanion toCompanion(bool nullToAbsent) {
    return BasketEntriesCompanion(
      id: Value(id),
      listItemId: listItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(listItemId),
      productName: Value(productName),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      addedAt: Value(addedAt),
    );
  }

  factory BasketEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BasketEntry(
      id: serializer.fromJson<int>(json['id']),
      listItemId: serializer.fromJson<int?>(json['listItemId']),
      productName: serializer.fromJson<String>(json['productName']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'listItemId': serializer.toJson<int?>(listItemId),
      'productName': serializer.toJson<String>(productName),
      'barcode': serializer.toJson<String?>(barcode),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  BasketEntry copyWith({
    int? id,
    Value<int?> listItemId = const Value.absent(),
    String? productName,
    Value<String?> barcode = const Value.absent(),
    DateTime? addedAt,
  }) => BasketEntry(
    id: id ?? this.id,
    listItemId: listItemId.present ? listItemId.value : this.listItemId,
    productName: productName ?? this.productName,
    barcode: barcode.present ? barcode.value : this.barcode,
    addedAt: addedAt ?? this.addedAt,
  );
  BasketEntry copyWithCompanion(BasketEntriesCompanion data) {
    return BasketEntry(
      id: data.id.present ? data.id.value : this.id,
      listItemId: data.listItemId.present
          ? data.listItemId.value
          : this.listItemId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BasketEntry(')
          ..write('id: $id, ')
          ..write('listItemId: $listItemId, ')
          ..write('productName: $productName, ')
          ..write('barcode: $barcode, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, listItemId, productName, barcode, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BasketEntry &&
          other.id == this.id &&
          other.listItemId == this.listItemId &&
          other.productName == this.productName &&
          other.barcode == this.barcode &&
          other.addedAt == this.addedAt);
}

class BasketEntriesCompanion extends UpdateCompanion<BasketEntry> {
  final Value<int> id;
  final Value<int?> listItemId;
  final Value<String> productName;
  final Value<String?> barcode;
  final Value<DateTime> addedAt;
  const BasketEntriesCompanion({
    this.id = const Value.absent(),
    this.listItemId = const Value.absent(),
    this.productName = const Value.absent(),
    this.barcode = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  BasketEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.listItemId = const Value.absent(),
    required String productName,
    this.barcode = const Value.absent(),
    this.addedAt = const Value.absent(),
  }) : productName = Value(productName);
  static Insertable<BasketEntry> custom({
    Expression<int>? id,
    Expression<int>? listItemId,
    Expression<String>? productName,
    Expression<String>? barcode,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listItemId != null) 'list_item_id': listItemId,
      if (productName != null) 'product_name': productName,
      if (barcode != null) 'barcode': barcode,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  BasketEntriesCompanion copyWith({
    Value<int>? id,
    Value<int?>? listItemId,
    Value<String>? productName,
    Value<String?>? barcode,
    Value<DateTime>? addedAt,
  }) {
    return BasketEntriesCompanion(
      id: id ?? this.id,
      listItemId: listItemId ?? this.listItemId,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (listItemId.present) {
      map['list_item_id'] = Variable<int>(listItemId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BasketEntriesCompanion(')
          ..write('id: $id, ')
          ..write('listItemId: $listItemId, ')
          ..write('productName: $productName, ')
          ..write('barcode: $barcode, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CatalogEntriesTable catalogEntries = $CatalogEntriesTable(this);
  late final $ShoppingListItemsTable shoppingListItems =
      $ShoppingListItemsTable(this);
  late final $BasketEntriesTable basketEntries = $BasketEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    catalogEntries,
    shoppingListItems,
    basketEntries,
  ];
}

typedef $$CatalogEntriesTableCreateCompanionBuilder =
    CatalogEntriesCompanion Function({
      required String barcode,
      required String name,
      required String category,
      Value<int> rowid,
    });
typedef $$CatalogEntriesTableUpdateCompanionBuilder =
    CatalogEntriesCompanion Function({
      Value<String> barcode,
      Value<String> name,
      Value<String> category,
      Value<int> rowid,
    });

class $$CatalogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogEntriesTable> {
  $$CatalogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CatalogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogEntriesTable> {
  $$CatalogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogEntriesTable> {
  $$CatalogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);
}

class $$CatalogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogEntriesTable,
          CatalogEntry,
          $$CatalogEntriesTableFilterComposer,
          $$CatalogEntriesTableOrderingComposer,
          $$CatalogEntriesTableAnnotationComposer,
          $$CatalogEntriesTableCreateCompanionBuilder,
          $$CatalogEntriesTableUpdateCompanionBuilder,
          (
            CatalogEntry,
            BaseReferences<_$AppDatabase, $CatalogEntriesTable, CatalogEntry>,
          ),
          CatalogEntry,
          PrefetchHooks Function()
        > {
  $$CatalogEntriesTableTableManager(
    _$AppDatabase db,
    $CatalogEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> barcode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogEntriesCompanion(
                barcode: barcode,
                name: name,
                category: category,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String barcode,
                required String name,
                required String category,
                Value<int> rowid = const Value.absent(),
              }) => CatalogEntriesCompanion.insert(
                barcode: barcode,
                name: name,
                category: category,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CatalogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogEntriesTable,
      CatalogEntry,
      $$CatalogEntriesTableFilterComposer,
      $$CatalogEntriesTableOrderingComposer,
      $$CatalogEntriesTableAnnotationComposer,
      $$CatalogEntriesTableCreateCompanionBuilder,
      $$CatalogEntriesTableUpdateCompanionBuilder,
      (
        CatalogEntry,
        BaseReferences<_$AppDatabase, $CatalogEntriesTable, CatalogEntry>,
      ),
      CatalogEntry,
      PrefetchHooks Function()
    >;
typedef $$ShoppingListItemsTableCreateCompanionBuilder =
    ShoppingListItemsCompanion Function({
      Value<int> id,
      required String name,
      required String category,
      required ListItemStatus status,
    });
typedef $$ShoppingListItemsTableUpdateCompanionBuilder =
    ShoppingListItemsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> category,
      Value<ListItemStatus> status,
    });

final class $$ShoppingListItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ShoppingListItemsTable,
          ShoppingListItem
        > {
  $$ShoppingListItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$BasketEntriesTable, List<BasketEntry>>
  _basketEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.basketEntries,
    aliasName: 'shopping_list_items__id__basket_entries__list_item_id',
  );

  $$BasketEntriesTableProcessedTableManager get basketEntriesRefs {
    final manager = $$BasketEntriesTableTableManager(
      $_db,
      $_db.basketEntries,
    ).filter((f) => f.listItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_basketEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShoppingListItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ListItemStatus, ListItemStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  Expression<bool> basketEntriesRefs(
    Expression<bool> Function($$BasketEntriesTableFilterComposer f) f,
  ) {
    final $$BasketEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.basketEntries,
      getReferencedColumn: (t) => t.listItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BasketEntriesTableFilterComposer(
            $db: $db,
            $table: $db.basketEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShoppingListItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingListItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ListItemStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  Expression<T> basketEntriesRefs<T extends Object>(
    Expression<T> Function($$BasketEntriesTableAnnotationComposer a) f,
  ) {
    final $$BasketEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.basketEntries,
      getReferencedColumn: (t) => t.listItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BasketEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.basketEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShoppingListItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingListItemsTable,
          ShoppingListItem,
          $$ShoppingListItemsTableFilterComposer,
          $$ShoppingListItemsTableOrderingComposer,
          $$ShoppingListItemsTableAnnotationComposer,
          $$ShoppingListItemsTableCreateCompanionBuilder,
          $$ShoppingListItemsTableUpdateCompanionBuilder,
          (ShoppingListItem, $$ShoppingListItemsTableReferences),
          ShoppingListItem,
          PrefetchHooks Function({bool basketEntriesRefs})
        > {
  $$ShoppingListItemsTableTableManager(
    _$AppDatabase db,
    $ShoppingListItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<ListItemStatus> status = const Value.absent(),
              }) => ShoppingListItemsCompanion(
                id: id,
                name: name,
                category: category,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String category,
                required ListItemStatus status,
              }) => ShoppingListItemsCompanion.insert(
                id: id,
                name: name,
                category: category,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ShoppingListItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({basketEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (basketEntriesRefs) db.basketEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (basketEntriesRefs)
                    await $_getPrefetchedData<
                      ShoppingListItem,
                      $ShoppingListItemsTable,
                      BasketEntry
                    >(
                      currentTable: table,
                      referencedTable: $$ShoppingListItemsTableReferences
                          ._basketEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ShoppingListItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).basketEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.listItemId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ShoppingListItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingListItemsTable,
      ShoppingListItem,
      $$ShoppingListItemsTableFilterComposer,
      $$ShoppingListItemsTableOrderingComposer,
      $$ShoppingListItemsTableAnnotationComposer,
      $$ShoppingListItemsTableCreateCompanionBuilder,
      $$ShoppingListItemsTableUpdateCompanionBuilder,
      (ShoppingListItem, $$ShoppingListItemsTableReferences),
      ShoppingListItem,
      PrefetchHooks Function({bool basketEntriesRefs})
    >;
typedef $$BasketEntriesTableCreateCompanionBuilder =
    BasketEntriesCompanion Function({
      Value<int> id,
      Value<int?> listItemId,
      required String productName,
      Value<String?> barcode,
      Value<DateTime> addedAt,
    });
typedef $$BasketEntriesTableUpdateCompanionBuilder =
    BasketEntriesCompanion Function({
      Value<int> id,
      Value<int?> listItemId,
      Value<String> productName,
      Value<String?> barcode,
      Value<DateTime> addedAt,
    });

final class $$BasketEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $BasketEntriesTable, BasketEntry> {
  $$BasketEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ShoppingListItemsTable _listItemIdTable(_$AppDatabase db) => db
      .shoppingListItems
      .createAlias('basket_entries__list_item_id__shopping_list_items__id');

  $$ShoppingListItemsTableProcessedTableManager? get listItemId {
    final $_column = $_itemColumn<int>('list_item_id');
    if ($_column == null) return null;
    final manager = $$ShoppingListItemsTableTableManager(
      $_db,
      $_db.shoppingListItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BasketEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BasketEntriesTable> {
  $$BasketEntriesTableFilterComposer({
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

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ShoppingListItemsTableFilterComposer get listItemId {
    final $$ShoppingListItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listItemId,
      referencedTable: $db.shoppingListItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListItemsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingListItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BasketEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BasketEntriesTable> {
  $$BasketEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShoppingListItemsTableOrderingComposer get listItemId {
    final $$ShoppingListItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listItemId,
      referencedTable: $db.shoppingListItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListItemsTableOrderingComposer(
            $db: $db,
            $table: $db.shoppingListItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BasketEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BasketEntriesTable> {
  $$BasketEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$ShoppingListItemsTableAnnotationComposer get listItemId {
    final $$ShoppingListItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.listItemId,
          referencedTable: $db.shoppingListItems,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ShoppingListItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.shoppingListItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$BasketEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BasketEntriesTable,
          BasketEntry,
          $$BasketEntriesTableFilterComposer,
          $$BasketEntriesTableOrderingComposer,
          $$BasketEntriesTableAnnotationComposer,
          $$BasketEntriesTableCreateCompanionBuilder,
          $$BasketEntriesTableUpdateCompanionBuilder,
          (BasketEntry, $$BasketEntriesTableReferences),
          BasketEntry,
          PrefetchHooks Function({bool listItemId})
        > {
  $$BasketEntriesTableTableManager(_$AppDatabase db, $BasketEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BasketEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BasketEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BasketEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> listItemId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => BasketEntriesCompanion(
                id: id,
                listItemId: listItemId,
                productName: productName,
                barcode: barcode,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> listItemId = const Value.absent(),
                required String productName,
                Value<String?> barcode = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => BasketEntriesCompanion.insert(
                id: id,
                listItemId: listItemId,
                productName: productName,
                barcode: barcode,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BasketEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (listItemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.listItemId,
                        referencedTable: $$BasketEntriesTableReferences
                            ._listItemIdTable(db),
                        referencedColumn: $$BasketEntriesTableReferences
                            ._listItemIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BasketEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BasketEntriesTable,
      BasketEntry,
      $$BasketEntriesTableFilterComposer,
      $$BasketEntriesTableOrderingComposer,
      $$BasketEntriesTableAnnotationComposer,
      $$BasketEntriesTableCreateCompanionBuilder,
      $$BasketEntriesTableUpdateCompanionBuilder,
      (BasketEntry, $$BasketEntriesTableReferences),
      BasketEntry,
      PrefetchHooks Function({bool listItemId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CatalogEntriesTableTableManager get catalogEntries =>
      $$CatalogEntriesTableTableManager(_db, _db.catalogEntries);
  $$ShoppingListItemsTableTableManager get shoppingListItems =>
      $$ShoppingListItemsTableTableManager(_db, _db.shoppingListItems);
  $$BasketEntriesTableTableManager get basketEntries =>
      $$BasketEntriesTableTableManager(_db, _db.basketEntries);
}
