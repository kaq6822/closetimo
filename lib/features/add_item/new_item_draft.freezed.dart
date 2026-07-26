// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'new_item_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NewItemDraft {

 String get name; String get brand; Category get category; int get washCycle; CareMethod get careMethod; DateTime? get purchasedAt; File? get tempPhoto;
/// Create a copy of NewItemDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewItemDraftCopyWith<NewItemDraft> get copyWith => _$NewItemDraftCopyWithImpl<NewItemDraft>(this as NewItemDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewItemDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.category, category) || other.category == category)&&(identical(other.washCycle, washCycle) || other.washCycle == washCycle)&&(identical(other.careMethod, careMethod) || other.careMethod == careMethod)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.tempPhoto, tempPhoto) || other.tempPhoto == tempPhoto));
}


@override
int get hashCode => Object.hash(runtimeType,name,brand,category,washCycle,careMethod,purchasedAt,tempPhoto);

@override
String toString() {
  return 'NewItemDraft(name: $name, brand: $brand, category: $category, washCycle: $washCycle, careMethod: $careMethod, purchasedAt: $purchasedAt, tempPhoto: $tempPhoto)';
}


}

/// @nodoc
abstract mixin class $NewItemDraftCopyWith<$Res>  {
  factory $NewItemDraftCopyWith(NewItemDraft value, $Res Function(NewItemDraft) _then) = _$NewItemDraftCopyWithImpl;
@useResult
$Res call({
 String name, String brand, Category category, int washCycle, CareMethod careMethod, DateTime? purchasedAt, File? tempPhoto
});




}
/// @nodoc
class _$NewItemDraftCopyWithImpl<$Res>
    implements $NewItemDraftCopyWith<$Res> {
  _$NewItemDraftCopyWithImpl(this._self, this._then);

  final NewItemDraft _self;
  final $Res Function(NewItemDraft) _then;

/// Create a copy of NewItemDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? brand = null,Object? category = null,Object? washCycle = null,Object? careMethod = null,Object? purchasedAt = freezed,Object? tempPhoto = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,washCycle: null == washCycle ? _self.washCycle : washCycle // ignore: cast_nullable_to_non_nullable
as int,careMethod: null == careMethod ? _self.careMethod : careMethod // ignore: cast_nullable_to_non_nullable
as CareMethod,purchasedAt: freezed == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tempPhoto: freezed == tempPhoto ? _self.tempPhoto : tempPhoto // ignore: cast_nullable_to_non_nullable
as File?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewItemDraft].
extension NewItemDraftPatterns on NewItemDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewItemDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewItemDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewItemDraft value)  $default,){
final _that = this;
switch (_that) {
case _NewItemDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewItemDraft value)?  $default,){
final _that = this;
switch (_that) {
case _NewItemDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String brand,  Category category,  int washCycle,  CareMethod careMethod,  DateTime? purchasedAt,  File? tempPhoto)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewItemDraft() when $default != null:
return $default(_that.name,_that.brand,_that.category,_that.washCycle,_that.careMethod,_that.purchasedAt,_that.tempPhoto);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String brand,  Category category,  int washCycle,  CareMethod careMethod,  DateTime? purchasedAt,  File? tempPhoto)  $default,) {final _that = this;
switch (_that) {
case _NewItemDraft():
return $default(_that.name,_that.brand,_that.category,_that.washCycle,_that.careMethod,_that.purchasedAt,_that.tempPhoto);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String brand,  Category category,  int washCycle,  CareMethod careMethod,  DateTime? purchasedAt,  File? tempPhoto)?  $default,) {final _that = this;
switch (_that) {
case _NewItemDraft() when $default != null:
return $default(_that.name,_that.brand,_that.category,_that.washCycle,_that.careMethod,_that.purchasedAt,_that.tempPhoto);case _:
  return null;

}
}

}

/// @nodoc


class _NewItemDraft extends NewItemDraft {
  const _NewItemDraft({this.name = '', this.brand = '', this.category = Category.outer, this.washCycle = 5, this.careMethod = CareMethod.machine, this.purchasedAt, this.tempPhoto}): super._();
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String brand;
@override@JsonKey() final  Category category;
@override@JsonKey() final  int washCycle;
@override@JsonKey() final  CareMethod careMethod;
@override final  DateTime? purchasedAt;
@override final  File? tempPhoto;

/// Create a copy of NewItemDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewItemDraftCopyWith<_NewItemDraft> get copyWith => __$NewItemDraftCopyWithImpl<_NewItemDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewItemDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.category, category) || other.category == category)&&(identical(other.washCycle, washCycle) || other.washCycle == washCycle)&&(identical(other.careMethod, careMethod) || other.careMethod == careMethod)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.tempPhoto, tempPhoto) || other.tempPhoto == tempPhoto));
}


@override
int get hashCode => Object.hash(runtimeType,name,brand,category,washCycle,careMethod,purchasedAt,tempPhoto);

@override
String toString() {
  return 'NewItemDraft(name: $name, brand: $brand, category: $category, washCycle: $washCycle, careMethod: $careMethod, purchasedAt: $purchasedAt, tempPhoto: $tempPhoto)';
}


}

/// @nodoc
abstract mixin class _$NewItemDraftCopyWith<$Res> implements $NewItemDraftCopyWith<$Res> {
  factory _$NewItemDraftCopyWith(_NewItemDraft value, $Res Function(_NewItemDraft) _then) = __$NewItemDraftCopyWithImpl;
@override @useResult
$Res call({
 String name, String brand, Category category, int washCycle, CareMethod careMethod, DateTime? purchasedAt, File? tempPhoto
});




}
/// @nodoc
class __$NewItemDraftCopyWithImpl<$Res>
    implements _$NewItemDraftCopyWith<$Res> {
  __$NewItemDraftCopyWithImpl(this._self, this._then);

  final _NewItemDraft _self;
  final $Res Function(_NewItemDraft) _then;

/// Create a copy of NewItemDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? brand = null,Object? category = null,Object? washCycle = null,Object? careMethod = null,Object? purchasedAt = freezed,Object? tempPhoto = freezed,}) {
  return _then(_NewItemDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,washCycle: null == washCycle ? _self.washCycle : washCycle // ignore: cast_nullable_to_non_nullable
as int,careMethod: null == careMethod ? _self.careMethod : careMethod // ignore: cast_nullable_to_non_nullable
as CareMethod,purchasedAt: freezed == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tempPhoto: freezed == tempPhoto ? _self.tempPhoto : tempPhoto // ignore: cast_nullable_to_non_nullable
as File?,
  ));
}


}

// dart format on
