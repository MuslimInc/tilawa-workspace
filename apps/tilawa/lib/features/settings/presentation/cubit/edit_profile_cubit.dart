import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/auth/data/datasources/profile_avatar_storage.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';

enum EditProfileStatus { editing, saving, success, failure }

class EditProfileState extends Equatable {
  const EditProfileState({
    required this.displayName,
    required this.originalDisplayName,
    this.photoUrl,
    this.originalPhotoUrl,
    this.localImagePath,
    this.removePhoto = false,
    this.status = EditProfileStatus.editing,
    this.nameError = false,
    this.errorMessage,
    this.savedUser,
  });

  final String displayName;
  final String originalDisplayName;
  final String? photoUrl;
  final String? originalPhotoUrl;
  final String? localImagePath;
  final bool removePhoto;
  final EditProfileStatus status;
  final bool nameError;
  final String? errorMessage;
  final UserEntity? savedUser;

  bool get hasPhoto =>
      !removePhoto &&
      ((localImagePath != null && localImagePath!.isNotEmpty) ||
          (photoUrl != null && photoUrl!.trim().isNotEmpty));

  bool get isDirty {
    final bool nameChanged = displayName.trim() != originalDisplayName.trim();
    final bool photoChanged = removePhoto || localImagePath != null;
    return nameChanged || photoChanged;
  }

  bool get canSave => isDirty && status != EditProfileStatus.saving;

  EditProfileState copyWith({
    String? displayName,
    String? originalDisplayName,
    String? photoUrl,
    String? originalPhotoUrl,
    String? localImagePath,
    bool clearLocalImagePath = false,
    bool? removePhoto,
    EditProfileStatus? status,
    bool? nameError,
    String? errorMessage,
    bool clearError = false,
    UserEntity? savedUser,
  }) {
    return EditProfileState(
      displayName: displayName ?? this.displayName,
      originalDisplayName: originalDisplayName ?? this.originalDisplayName,
      photoUrl: photoUrl ?? this.photoUrl,
      originalPhotoUrl: originalPhotoUrl ?? this.originalPhotoUrl,
      localImagePath: clearLocalImagePath
          ? null
          : (localImagePath ?? this.localImagePath),
      removePhoto: removePhoto ?? this.removePhoto,
      status: status ?? this.status,
      nameError: nameError ?? this.nameError,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedUser: savedUser ?? this.savedUser,
    );
  }

  @override
  List<Object?> get props => [
    displayName,
    originalDisplayName,
    photoUrl,
    originalPhotoUrl,
    localImagePath,
    removePhoto,
    status,
    nameError,
    errorMessage,
    savedUser,
  ];
}

@injectable
class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit(
    this._userRepository,
    this._avatarStorage,
  ) : super(
        const EditProfileState(
          displayName: '',
          originalDisplayName: '',
        ),
      );

  final UserRepository _userRepository;
  final ProfileAvatarStorage _avatarStorage;
  final ImagePicker _picker = ImagePicker();

  void init(UserEntity user) {
    emit(
      EditProfileState(
        displayName: user.displayName,
        originalDisplayName: user.displayName,
        photoUrl: user.photoUrl,
        originalPhotoUrl: user.photoUrl,
      ),
    );
  }

  void displayNameChanged(String value) {
    emit(
      state.copyWith(
        displayName: value,
        nameError: false,
        clearError: true,
        status: EditProfileStatus.editing,
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      // Resize + JPEG compress on-device via image_picker — no original upload.
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: ProfileAvatarStorage.maxEdgePx.toDouble(),
        maxHeight: ProfileAvatarStorage.maxEdgePx.toDouble(),
        imageQuality: ProfileAvatarStorage.jpegQuality,
      );
      if (image == null) {
        return;
      }
      await applyPickedImagePath(image.path);
    } on Object {
      emit(
        state.copyWith(
          status: EditProfileStatus.failure,
          errorMessage: 'pickerFailed',
        ),
      );
    }
  }

  /// Applies a local image path after picker selection (testable without
  /// platform channels).
  @visibleForTesting
  Future<void> applyPickedImagePath(String path) async {
    final int length = await File(path).length();
    if (length <= 0 || length > ProfileAvatarStorage.maxUploadBytes) {
      emit(
        state.copyWith(
          status: EditProfileStatus.failure,
          errorMessage: 'avatarTooLarge',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        localImagePath: path,
        removePhoto: false,
        clearError: true,
        status: EditProfileStatus.editing,
      ),
    );
  }

  void removePhoto() {
    emit(
      state.copyWith(
        removePhoto: true,
        clearLocalImagePath: true,
        clearError: true,
        status: EditProfileStatus.editing,
      ),
    );
  }

  Future<void> save(UserEntity currentUser) async {
    final String trimmedName = state.displayName.trim();
    if (trimmedName.isEmpty) {
      emit(state.copyWith(nameError: true, status: EditProfileStatus.editing));
      return;
    }

    final bool nameChanged = trimmedName != currentUser.displayName.trim();
    final bool photoChanged = state.removePhoto || state.localImagePath != null;

    // No Auth / Firestore / Storage / teacher writes when nothing changed.
    if (!nameChanged && !photoChanged) {
      emit(
        state.copyWith(
          status: EditProfileStatus.success,
          savedUser: currentUser,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: EditProfileStatus.saving,
        clearError: true,
        nameError: false,
      ),
    );

    try {
      String? nextPhotoUrl = currentUser.photoUrl;
      if (state.removePhoto) {
        if (ProfileAvatarStorage.isManagedAvatarUrl(
          currentUser.photoUrl,
          currentUser.id,
        )) {
          await _avatarStorage.delete(currentUser.id);
        }
        nextPhotoUrl = null;
      } else if (state.localImagePath != null) {
        nextPhotoUrl = await _avatarStorage.upload(
          userId: currentUser.id,
          localPath: state.localImagePath!,
        );
      }

      final UserEntity updated = await _userRepository.updateAccountProfile(
        displayName: trimmedName,
        photoUrl: nextPhotoUrl,
      );

      await _mirrorTeacherIdentity(
        userId: updated.id,
        displayName: updated.displayName,
        photoUrl: updated.photoUrl,
        nameChanged: nameChanged,
        photoChanged: photoChanged,
      );

      emit(
        state.copyWith(
          status: EditProfileStatus.success,
          savedUser: updated,
          photoUrl: updated.photoUrl,
          originalDisplayName: updated.displayName,
          originalPhotoUrl: updated.photoUrl,
          clearLocalImagePath: true,
          removePhoto: false,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: EditProfileStatus.failure,
          errorMessage: 'saveFailed',
        ),
      );
    }
  }

  Future<void> _mirrorTeacherIdentity({
    required String userId,
    required String displayName,
    required String? photoUrl,
    required bool nameChanged,
    required bool photoChanged,
  }) async {
    if (!nameChanged && !photoChanged) {
      return;
    }
    if (!getIt.isRegistered<TeacherProfileRepository>()) {
      return;
    }
    try {
      final TeacherProfileRepository profiles =
          getIt<TeacherProfileRepository>();
      final result = await profiles.getProfileByUserId(userId);
      await result.fold(
        (_) async {},
        (TeacherProfile profile) async {
          final String? publicName = ValidateTeacherPublicName.normalize(
            displayName,
          );
          final String nextName = publicName ?? profile.displayName;
          final String nextAvatar = photoUrl?.trim().isNotEmpty == true
              ? photoUrl!
              : '';
          final String currentAvatar = profile.avatarUrl?.trim() ?? '';
          final bool teacherNameChanged = nextName != profile.displayName;
          final bool teacherPhotoChanged = nextAvatar != currentAvatar;
          if (!teacherNameChanged && !teacherPhotoChanged) {
            return;
          }
          final TeacherProfile updated = profile.copyWith(
            displayName: nextName,
            avatarUrl: nextAvatar,
            updatedAt: DateTime.now(),
          );
          await profiles.updatePublicProfile(updated);
        },
      );
    } on Object {
      // Account identity already saved; marketplace mirror is best-effort.
    }
  }
}
