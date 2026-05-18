// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'new_item_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NewItemDraft {
  String get name => throw _privateConstructorUsedError;
  String get brand => throw _privateConstructorUsedError;
  Category get category => throw _privateConstructorUsedError;
  int get washCycle => throw _privateConstructorUsedError;
  CareMethod get careMethod => throw _privateConstructorUsedError;
  DateTime? get purchasedAt => throw _privateConstructorUsedError;
  File? get tempPhoto => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $NewItemDraftCopyWith<NewItemDraft> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NewItemDraftCopyWith<$Res> {
  factory $NewItemDraftCopyWith(
          NewItemDraft value, $Res Function(NewItemDraft) then) =
      _$NewItemDraftCopyWithImpl<$Res, NewItemDraft>;
  @useResult
  $Res call(
      {String name,
      String brand,
      Category category,
      int washCycle,
      CareMethod careMethod,
      DateTime? purchasedAt,
      File? tempPhoto});
}

/// @nodoc
class _$NewItemDraftCopyWithImpl<$Res, $Val extends NewItemDraft>
    implements $NewItemDraftCopyWith<$Res> {
  _$NewItemDraftCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? brand = null,
    Object? category = null,
    Object? washCycle = null,
    Object? careMethod = null,
    Object? purchasedAt = freezed,
    Object? tempPhoto = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      brand: null == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as Category,
      washCycle: null == washCycle
          ? _value.washCycle
          : washCycle // ignore: cast_nullable_to_non_nullable
              as int,
      careMethod: null == careMethod
          ? _value.careMethod
          : careMethod // ignore: cast_nullable_to_non_nullable
              as CareMethod,
      purchasedAt: freezed == purchasedAt
          ? _value.purchasedAt
          : purchasedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      tempPhoto: freezed == tempPhoto
          ? _value.tempPhoto
          : tempPhoto // ignore: cast_nullable_to_non_nullable
              as File?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NewItemDraftImplCopyWith<$Res>
    implements $NewItemDraftCopyWith<$Res> {
  factory _$$NewItemDraftImplCopyWith(
          _$NewItemDraftImpl value, $Res Function(_$NewItemDraftImpl) then) =
      __$$NewItemDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String brand,
      Category category,
      int washCycle,
      CareMethod careMethod,
      DateTime? purchasedAt,
      File? tempPhoto});
}

/// @nodoc
class __$$NewItemDraftImplCopyWithImpl<$Res>
    extends _$NewItemDraftCopyWithImpl<$Res, _$NewItemDraftImpl>
    implements _$$NewItemDraftImplCopyWith<$Res> {
  __$$NewItemDraftImplCopyWithImpl(
      _$NewItemDraftImpl _value, $Res Function(_$NewItemDraftImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? brand = null,
    Object? category = null,
    Object? washCycle = null,
    Object? careMethod = null,
    Object? purchasedAt = freezed,
    Object? tempPhoto = freezed,
  }) {
    return _then(_$NewItemDraftImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      brand: null == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as Category,
      washCycle: null == washCycle
          ? _value.washCycle
          : washCycle // ignore: cast_nullable_to_non_nullable
              as int,
      careMethod: null == careMethod
          ? _value.careMethod
          : careMethod // ignore: cast_nullable_to_non_nullable
              as CareMethod,
      purchasedAt: freezed == purchasedAt
          ? _value.purchasedAt
          : purchasedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      tempPhoto: freezed == tempPhoto
          ? _value.tempPhoto
          : tempPhoto // ignore: cast_nullable_to_non_nullable
              as File?,
    ));
  }
}

/// @nodoc

class _$NewItemDraftImpl extends _NewItemDraft {
  const _$NewItemDraftImpl(
      {this.name = '',
      this.brand = '',
      this.category = Category.outer,
      this.washCycle = 5,
      this.careMethod = CareMethod.machine,
      this.purchasedAt,
      this.tempPhoto})
      : super._();

  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String brand;
  @override
  @JsonKey()
  final Category category;
  @override
  @JsonKey()
  final int washCycle;
  @override
  @JsonKey()
  final CareMethod careMethod;
  @override
  final DateTime? purchasedAt;
  @override
  final File? tempPhoto;

  @override
  String toString() {
    return 'NewItemDraft(name: $name, brand: $brand, category: $category, washCycle: $washCycle, careMethod: $careMethod, purchasedAt: $purchasedAt, tempPhoto: $tempPhoto)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NewItemDraftImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.washCycle, washCycle) ||
                other.washCycle == washCycle) &&
            (identical(other.careMethod, careMethod) ||
                other.careMethod == careMethod) &&
            (identical(other.purchasedAt, purchasedAt) ||
                other.purchasedAt == purchasedAt) &&
            (identical(other.tempPhoto, tempPhoto) ||
                other.tempPhoto == tempPhoto));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, brand, category, washCycle,
      careMethod, purchasedAt, tempPhoto);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NewItemDraftImplCopyWith<_$NewItemDraftImpl> get copyWith =>
      __$$NewItemDraftImplCopyWithImpl<_$NewItemDraftImpl>(this, _$identity);
}

abstract class _NewItemDraft extends NewItemDraft {
  const factory _NewItemDraft(
      {final String name,
      final String brand,
      final Category category,
      final int washCycle,
      final CareMethod careMethod,
      final DateTime? purchasedAt,
      final File? tempPhoto}) = _$NewItemDraftImpl;
  const _NewItemDraft._() : super._();

  @override
  String get name;
  @override
  String get brand;
  @override
  Category get category;
  @override
  int get washCycle;
  @override
  CareMethod get careMethod;
  @override
  DateTime? get purchasedAt;
  @override
  File? get tempPhoto;
  @override
  @JsonKey(ignore: true)
  _$$NewItemDraftImplCopyWith<_$NewItemDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
