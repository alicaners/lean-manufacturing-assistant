import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/core/error/failure_message.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/empty_view.dart';
import 'package:lean_assistant/core/widgets/error_view.dart';
import 'package:lean_assistant/core/widgets/loading_view.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/admin/domain/user_filter.dart';
import 'package:lean_assistant/features/admin/presentation/user_list_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/user_list_state.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:lean_assistant/features/auth/presentation/user_role_label.dart';

/// User management for admins: search, filter and scroll through users.
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserListCubit>(
      create: (_) => getIt<UserListCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.usersTitle)),
        floatingActionButton: const _NewUserButton(),
        body: const Column(
          children: [
            _SearchField(),
            _Filters(),
            Expanded(child: _UserList()),
          ],
        ),
      ),
    );
  }
}

class _NewUserButton extends StatelessWidget {
  const _NewUserButton();

  Future<void> _create(BuildContext context) async {
    // Read everything that needs the context before waiting.
    final cubit = context.read<UserListCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final createdMessage = context.l10n.usersCreated;

    final created = await context.push<bool>(AppRoutes.newUser);
    if (created != true) return;

    messenger.showSnackBar(SnackBar(content: Text(createdMessage)));
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _create(context),
      icon: const Icon(Icons.person_add_alt_1),
      label: Text(context.l10n.usersNew),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: context.read<UserListCubit>().searchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: context.l10n.usersSearchHint,
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<UserListCubit>();
    // Rebuilds only when the filter changes, not on every page load.
    final filter = context.select<UserListCubit, UserFilter>(
      (cubit) => cubit.state.filter,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipRow(
          children: [
            for (final (isActive, label) in <(bool?, String)>[
              (null, l10n.usersAll),
              (true, l10n.usersActive),
              (false, l10n.usersInactive),
            ])
              ChoiceChip(
                label: Text(label),
                selected: filter.isActive == isActive,
                onSelected: (_) => cubit.activeChanged(isActive),
              ),
          ],
        ),
        _ChipRow(
          children: [
            ChoiceChip(
              label: Text(l10n.usersAllRoles),
              selected: filter.role == null,
              onSelected: (_) => cubit.roleChanged(null),
            ),
            for (final role in UserRole.values)
              ChoiceChip(
                label: Text(role.label(l10n)),
                selected: filter.role == role,
                onSelected: (_) => cubit.roleChanged(role),
              ),
          ],
        ),
      ],
    );
  }
}

/// A row of chips that scrolls sideways when it does not fit.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          for (final chip in children)
            Padding(padding: const EdgeInsets.only(right: 8), child: chip),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<UserListCubit>();

    return BlocBuilder<UserListCubit, UserListState>(
      builder: (context, state) {
        if (state.failure case final failure?) {
          return ErrorView(message: failure.message(l10n), onRetry: cubit.load);
        }

        if (state.users.isEmpty) {
          return state.status == UserListStatus.loading
              ? const LoadingView()
              : EmptyView(
                  message: l10n.usersEmpty,
                  icon: Icons.person_search_outlined,
                );
        }

        return Column(
          children: [
            // A new filter is loading; the old list stays until it arrives.
            if (state.status == UserListStatus.loading)
              const LinearProgressIndicator(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: cubit.load,
                child: ListView.builder(
                  // Pull-to-refresh works even when the list is too short to scroll.
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Room for the "New user" button over the last row.
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: state.users.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < state.users.length) {
                      return _UserTile(state.users[index]);
                    }
                    return _LoadMoreFooter(
                      failed: state.loadMoreFailure != null,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile(this.user);

  final ManagedUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(child: Text(_initials(user.fullName))),
      title: Text(user.fullName),
      subtitle: Text('${user.userName} · ${user.role.label(l10n)}'),
      trailing: switch (user) {
        ManagedUser(isActive: false) => Text(
          l10n.usersInactive,
          style: TextStyle(color: theme.colorScheme.error),
        ),
        ManagedUser(mustChangePassword: true) => Tooltip(
          message: l10n.usersTemporaryPassword,
          child: const Icon(Icons.key_outlined),
        ),
        _ => null,
      },
    );
  }

  /// "Ayşe Nur Demir" → "AN".
  static String _initials(String fullName) => fullName
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

/// The last row while more users exist. Being built means the user scrolled
/// near the end, so it asks for the next page.
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.failed});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UserListCubit>();

    if (failed) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: TextButton.icon(
            onPressed: cubit.retryLoadMore,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.commonRetry),
          ),
        ),
      );
    }

    // Not during build: changing state while the list is being drawn is not allowed.
    WidgetsBinding.instance.addPostFrameCallback((_) => cubit.loadMore());

    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
