// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_patch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ItemPatch {

 String get name; String? get brand; Category get category; CareMethod get careMethod; int get washCycle;/// 관리 권장 방식(#45). 수정 화면은 원본 값을 그대로 전달한다.
 CareMode get careMode;/// 용도 전체 교체(#41). 빈 목록이면 용도를 모두 제거한다.
 List<ItemPurpose> get purposes; DateTime? get purchasedAt;/// 새로 선택한 사진. null이 아니면 sandbox 사본을 교체한다([removePhoto]보다 우선).
 File? get newPhoto;/// true면 기존 사진을 제거하고 기본 플레이스홀더로 되돌린다.
 bool get removePhoto;/// 태그 전체 교체(#46). null이면 기존 태그를 그대로 두고, 빈 목록이면 모두 제거한다.
 List<String>? get tags;
/// Create a copy of ItemPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemPatchCopyWith<ItemPatch> get copyWith => _$ItemPatchCopyWithImpl<ItemPatch>(this as ItemPatch, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemPatch&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.category, category) || other.category == category)&&(identical(other.careMethod, careMethod) || other.careMethod == careMethod)&&(identical(other.washCycle, washCycle) || other.washCycle == washCycle)&&(identical(other.careMode, careMode) || other.careMode == careMode)&&const DeepCollectionEquality().equals(other.purposes, purposes)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.newPhoto, newPhoto) || other.newPhoto == newPhoto)&&(identical(other.removePhoto, removePhoto) || other.removePhoto == removePhoto)&&const DeepCollectionEquality().equals(other.tags, tags));
}


@override
int get hashCode => Object.hash(runtimeType,name,brand,category,careMethod,washCycle,careMode,const DeepCollectionEquality().hash(purposes),purchasedAt,newPhoto,removePhoto,const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'ItemPatch(name: $name, brand: $brand, category: $category, careMethod: $careMethod, washCycle: $washCycle, careMode: $careMode, purposes: $purposes, purchasedAt: $purchasedAt, newPhoto: $newPhoto, removePhoto: $removePhoto, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $ItemPatchCopyWith<$Res>  {
  factory $ItemPatchCopyWith(ItemPatch value, $Res Function(ItemPatch) _then) = _$ItemPatchCopyWithImpl;
@useResult
$Res call({
 String name, String? brand, Category category, CareMethod careMethod, int washCycle, CareMode careMode, List<ItemPurpose> purposes, DateTime? purchasedAt, File? newPhoto, bool removePhoto, List<String>? tags
});




}
/// @nodoc
class _$ItemPatchCopyWithImpl<$Res>
    implements $ItemPatchCopyWith<$Res> {
  _$ItemPatchCopyWithImpl(this._self, this._then);

  final ItemPatch _self;
  final $Res Function(ItemPatch) _then;

/// Create a copy of ItemPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? brand = freezed,Object? category = null,Object? careMethod = null,Object? washCycle = null,Object? careMode = null,Object? purposes = null,Object? purchasedAt = freezed,Object? newPhoto = freezed,Object? removePhoto = null,Object? tags = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,careMethod: null == careMethod ? _self.careMethod : careMethod // ignore: cast_nullable_to_non_nullable
as CareMethod,washCycle: null == washCycle ? _self.washCycle : washCycle // ignore: cast_nullable_to_non_nullable
as int,careMode: null == careMode ? _self.careMode : careMode // ignore: cast_nullable_to_non_nullable
as CareMode,purposes: null == purposes ? _self.purposes : purposes // ignore: cast_nullable_to_non_nullable
as List<ItemPurpose>,purchasedAt: freezed == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,newPhoto: freezed == newPhoto ? _self.newPhoto : newPhoto // ignore: cast_nullable_to_non_nullable
as File?,removePhoto: null == removePhoto ? _self.removePhoto : removePhoto // ignore: cast_nullable_to_non_nullable
as bool,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemPatch].
extension ItemPatchPatterns on ItemPatch {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemPatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemPatch() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemPatch value)  $default,){
final _that = this;
switch (_that) {
case _ItemPatch():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemPatch value)?  $default,){
final _that = this;
switch (_that) {
case _ItemPatch() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? brand,  Category category,  CareMethod careMethod,  int washCycle,  CareMode careMode,  List<ItemPurpose> purposes,  DateTime? purchasedAt,  File? newPhoto,  bool removePhoto,  List<String>? tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemPatch() when $default != null:
return $default(_that.name,_that.brand,_that.category,_that.careMethod,_that.washCycle,_that.careMode,_that.purposes,_that.purchasedAt,_that.newPhoto,_that.removePhoto,_that.tags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? brand,  Category category,  CareMethod careMethod,  int washCycle,  CareMode careMode,  List<ItemPurpose> purposes,  DateTime? purchasedAt,  File? newPhoto,  bool removePhoto,  List<String>? tags)  $default,) {final _that = this;
switch (_that) {
case _ItemPatch():
return $default(_that.name,_that.brand,_that.category,_that.careMethod,_that.washCycle,_that.careMode,_that.purposes,_that.purchasedAt,_that.newPhoto,_that.removePhoto,_that.tags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? brand,  Category category,  CareMethod careMethod,  int washCycle,  CareMode careMode,  List<ItemPurpose> purposes,  DateTime? purchasedAt,  File? newPhoto,  bool removePhoto,  List<String>? tags)?  $default,) {final _that = this;
switch (_that) {
case _ItemPatch() when $default != null:
return $default(_that.name,_that.brand,_that.category,_that.careMethod,_that.washCycle,_that.careMode,_that.purposes,_that.purchasedAt,_that.newPhoto,_that.removePhoto,_that.tags);case _:
  return null;

}
}

}

/// @nodoc


class _ItemPatch extends ItemPatch {
  const _ItemPatch({required this.name, this.brand, required this.category, required this.careMethod, required this.washCycle, required this.careMode, required final  List<ItemPurpose> purposes, this.purchasedAt, this.newPhoto, this.removePhoto = false, final  List<String>? tags}): _purposes = purposes,_tags = tags,super._();
  

@override final  String name;
@override final  String? brand;
@override final  Category category;
@override final  CareMethod careMethod;
@override final  int washCycle;
/// 관리 권장 방식(#45). 수정 화면은 원본 값을 그대로 전달한다.
@override final  CareMode careMode;
/// 용도 전체 교체(#41). 빈 목록이면 용도를 모두 제거한다.
 final  List<ItemPurpose> _purposes;
/// 용도 전체 교체(#41). 빈 목록이면 용도를 모두 제거한다.
@override List<ItemPurpose> get purposes {
  if (_purposes is EqualUnmodifiableListView) return _purposes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_purposes);
}

@override final  DateTime? purchasedAt;
/// 새로 선택한 사진. null이 아니면 sandbox 사본을 교체한다([removePhoto]보다 우선).
@override final  File? newPhoto;
/// true면 기존 사진을 제거하고 기본 플레이스홀더로 되돌린다.
@override@JsonKey() final  bool removePhoto;
/// 태그 전체 교체(#46). null이면 기존 태그를 그대로 두고, 빈 목록이면 모두 제거한다.
 final  List<String>? _tags;
/// 태그 전체 교체(#46). null이면 기존 태그를 그대로 두고, 빈 목록이면 모두 제거한다.
@override List<String>? get tags {
  final value = _tags;
  if (value == null) return null;
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ItemPatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemPatchCopyWith<_ItemPatch> get copyWith => __$ItemPatchCopyWithImpl<_ItemPatch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemPatch&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.category, category) || other.category == category)&&(identical(other.careMethod, careMethod) || other.careMethod == careMethod)&&(identical(other.washCycle, washCycle) || other.washCycle == washCycle)&&(identical(other.careMode, careMode) || other.careMode == careMode)&&const DeepCollectionEquality().equals(other._purposes, _purposes)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.newPhoto, newPhoto) || other.newPhoto == newPhoto)&&(identical(other.removePhoto, removePhoto) || other.removePhoto == removePhoto)&&const DeepCollectionEquality().equals(other._tags, _tags));
}


@override
int get hashCode => Object.hash(runtimeType,name,brand,category,careMethod,washCycle,careMode,const DeepCollectionEquality().hash(_purposes),purchasedAt,newPhoto,removePhoto,const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'ItemPatch(name: $name, brand: $brand, category: $category, careMethod: $careMethod, washCycle: $washCycle, careMode: $careMode, purposes: $purposes, purchasedAt: $purchasedAt, newPhoto: $newPhoto, removePhoto: $removePhoto, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$ItemPatchCopyWith<$Res> implements $ItemPatchCopyWith<$Res> {
  factory _$ItemPatchCopyWith(_ItemPatch value, $Res Function(_ItemPatch) _then) = __$ItemPatchCopyWithImpl;
@override @useResult
$Res call({
 String name, String? brand, Category category, CareMethod careMethod, int washCycle, CareMode careMode, List<ItemPurpose> purposes, DateTime? purchasedAt, File? newPhoto, bool removePhoto, List<String>? tags
});




}
/// @nodoc
class __$ItemPatchCopyWithImpl<$Res>
    implements _$ItemPatchCopyWith<$Res> {
  __$ItemPatchCopyWithImpl(this._self, this._then);

  final _ItemPatch _self;
  final $Res Function(_ItemPatch) _then;

/// Create a copy of ItemPatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? brand = freezed,Object? category = null,Object? careMethod = null,Object? washCycle = null,Object? careMode = null,Object? purposes = null,Object? purchasedAt = freezed,Object? newPhoto = freezed,Object? removePhoto = null,Object? tags = freezed,}) {
  return _then(_ItemPatch(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,careMethod: null == careMethod ? _self.careMethod : careMethod // ignore: cast_nullable_to_non_nullable
as CareMethod,washCycle: null == washCycle ? _self.washCycle : washCycle // ignore: cast_nullable_to_non_nullable
as int,careMode: null == careMode ? _self.careMode : careMode // ignore: cast_nullable_to_non_nullable
as CareMode,purposes: null == purposes ? _self._purposes : purposes // ignore: cast_nullable_to_non_nullable
as List<ItemPurpose>,purchasedAt: freezed == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,newPhoto: freezed == newPhoto ? _self.newPhoto : newPhoto // ignore: cast_nullable_to_non_nullable
as File?,removePhoto: null == removePhoto ? _self.removePhoto : removePhoto // ignore: cast_nullable_to_non_nullable
as bool,tags: freezed == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
