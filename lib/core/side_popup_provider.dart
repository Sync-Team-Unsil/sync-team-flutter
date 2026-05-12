import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SidePopupType {
  none,
  notifications,
  createTeam,
  teamDetail,
  manageApplicants,
  editProfile,
}

class SidePopupState {
  final SidePopupType type;
  final dynamic data;

  SidePopupState({required this.type, this.data});

  SidePopupState copyWith({SidePopupType? type, dynamic data}) {
    return SidePopupState(
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }
}

class SidePopupNotifier extends StateNotifier<SidePopupState> {
  SidePopupNotifier() : super(SidePopupState(type: SidePopupType.none));

  void show(SidePopupType type, {dynamic data}) {
    state = SidePopupState(type: type, data: data);
  }

  void hide() {
    state = SidePopupState(type: SidePopupType.none);
  }
}

final sidePopupProvider = StateNotifierProvider<SidePopupNotifier, SidePopupState>((ref) {
  return SidePopupNotifier();
});
