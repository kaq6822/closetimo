// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_patch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ItemPatch {
  String get name => throw _privateConstructorUsedError;
  String? get brand => throw _privateConstructorUsedError;
  Category get category => throw _privateConstructorUsedError;
  CareMethod get careMethod => throw _privateConstructorUsedError;
  int get washCycle => throw _privateConstructorUsedError;
  DateTime? get purchasedAt => throw _privateConstructorUsedError;

  /// 새로 선택한 사진. null이 아니면 sandbox 사본을 교체한다([removePhoto]보다 우선).
  File? get newPhoto => throw _privateConstructorUsedError;

  /// true면 기존 사진을 제거하고 기본 플레이스홀더로 되돌린다.
  bool get removePhoto => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ItemPatchCopyWith<ItemPatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemPatchCopyWith<$Res> {
  factory $ItemPatchCopyWith(ItemPatch value, $Res Function(ItemPatch) then) =
      _$ItemPatchCopyWithImpl<$Res, ItemPatch>;
  @useResult
  $Res call(
      {String name,
      String? brand,
      Category category,
      CareMethod careMethod,
      int washCycle,
      DateTime? purchasedAt,
      File? newPhoto,
      bool removePhoto});
}

/// @nodoc
class _$ItemPatchCopyWithImpl<$Res, $Val extends ItemPatch>
    implements $ItemPatchCopyWith<$Res> {
  _$ItemPatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? brand = freezed,
    Object? category = null,
    Object? careMethod = null,
    Object? washCycle = null,
    Object? purchasedAt = freezed,
    Object? newPhoto = freezed,
    Object? removePhoto = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      brand: freezed == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as Category,
      careMethod: null == careMethod
          ? _value.careMethod
          : careMethod // ignore: cast_nullable_to_non_nullable
              as CareMethod,
      washCycle: null == washCycle
          ? _value.washCycle
          : washCycle // ignore: cast_nullable_to_non_nullable
              as int,
      purchasedAt: freezed == purchasedAt
          ? _value.purchasedAt
          : purchasedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      newPhoto: freezed == newPhoto
          ? _value.newPhoto
          : newPhoto // ignore: cast_nullable_to_non_nullable
              as File?,
      removePhoto: null == removePhoto
          ? _value.removePhoto
          : removePhoto // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItemPatchImplCopyWith<$Res>
    implements $ItemPatchCopyWith<$Res> {
  factory _$$ItemPatchImplCopyWith(
          _$ItemPatchImpl value, $Res Function(_$ItemPatchImpl) then) =
      __$$ItemPatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String? brand,
      Category category,
      CareMethod careMethod,
      int washCycle,
      DateTime? purchasedAt,
      File? newPhoto,
      bool removePhoto});
}

/// @nodoc
class __$$ItemPatchImplCopyWithImpl<$Res>
    extends _$ItemPatchCopyWithImpl<$Res, _$ItemPatchImpl>
    implements _$$ItemPatchImplCopyWith<$Res> {
  __$$ItemPatchImplCopyWithImpl(
      _$ItemPatchImpl _value, $Res Function(_$ItemPatchImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? brand = freezed,
    Object? category = null,
    Object? careMethod = null,
    Object? washCycle = null,
    Object? purchasedAt = freezed,
    Object? newPhoto = freezed,
    Object? removePhoto = null,
  }) {
    return _then(_$ItemPatchImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      brand: freezed == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as Category,
      careMethod: null == careMethod
          ? _value.careMethod
          : careMethod // ignore: cast_nullable_to_non_nullable
              as CareMethod,
      washCycle: null == washCycle
          ? _value.washCycle
          : washCycle // ignore: cast_nullable_to_non_nullable
              as int,
      purchasedAt: freezed == purchasedAt
          ? _value.purchasedAt
          : purchasedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      newPhoto: freezed == newPhoto
          ? _value.newPhoto
          : newPhoto // ignore: cast_nullable_to_non_nullable
              as File?,
      removePhoto: null == removePhoto
          ? _value.removePhoto
          : removePhoto // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ItemPatchImpl extends _ItemPatch {
  const _$ItemPatchImpl(
      {required this.name,
      this.brand,
      required this.category,
      required this.careMethod,
      required this.washCycle,
      this.purchasedAt,
      this.newPhoto,
      this.removePhoto = false})
      : super._();

  @override
  final String name;
  @override
  final String? brand;
  @override
  final Category category;
  @override
  final CareMethod careMethod;
  @override
  final int washCycle;
  @override
  final DateTime? purchasedAt;

  /// 새로 선택한 사진. null이 아니면 sandbox 사본을 교체한다([removePhoto]보다 우선).
  @override
  final File? newPhoto;

  /// true면 기존 사진을 제거하고 기본 플레이스홀더로 되돌린다.
  @override
  @JsonKey()
  final bool removePhoto;

  @override
  String toString() {
    return 'ItemPatch(name: $name, brand: $brand, category: $category, careMethod: $careMethod, washCycle: $washCycle, purchasedAt: $purchasedAt, newPhoto: $newPhoto, removePhoto: $removePhoto)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemPatchImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.careMethod, careMethod) ||
                other.careMethod == careMethod) &&
            (identical(other.washCycle, washCycle) ||
                other.washCycle == washCycle) &&
            (identical(other.purchasedAt, purchasedAt) ||
                other.purchasedAt == purchasedAt) &&
            (identical(other.newPhoto, newPhoto) ||
                other.newPhoto == newPhoto) &&
            (identical(other.removePhoto, removePhoto) ||
                other.removePhoto == removePhoto));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, brand, category,
      careMethod, washCycle, purchasedAt, newPhoto, removePhoto);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemPatchImplCopyWith<_$ItemPatchImpl> get copyWith =>
      __$$ItemPatchImplCopyWithImpl<_$ItemPatchImpl>(this, _$identity);
}

abstract class _ItemPatch extends ItemPatch {
  const factory _ItemPatch(
      {required final String name,
      final String? brand,
      required final Category category,
      required final CareMethod careMethod,
      required final int washCycle,
      final DateTime? purchasedAt,
      final File? newPhoto,
      final bool removePhoto}) = _$ItemPatchImpl;
  const _ItemPatch._() : super._();

  @override
  String get name;
  @override
  String? get brand;
  @override
  Category get category;
  @override
  CareMethod get careMethod;
  @override
  int get washCycle;
  @override
  DateTime? get purchasedAt;
  @override

  /// 새로 선택한 사진. null이 아니면 sandbox 사본을 교체한다([removePhoto]보다 우선).
  File? get newPhoto;
  @override

  /// true면 기존 사진을 제거하고 기본 플레이스홀더로 되돌린다.
  bool get removePhoto;
  @override
  @JsonKey(ignore: true)
  _$$ItemPatchImplCopyWith<_$ItemPatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
