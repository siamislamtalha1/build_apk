import 'package:Bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final cubit = context.read<SettingsCubit>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(context, "Audio Engine"),
              _buildDropdownTile(
                context,
                title: "Audio Decoder",
                value: state.audioDecoderMode, // Ensure this exists in state
                items: const ["system", "ffmpeg", "hybrid"],
                onChanged: (val) {
                  if (val != null) cubit.setAudioDecoderMode(val);
                },
              ),
              SwitchListTile(
                title: const Text("Hardware Offload (Android)"),
                subtitle: const Text(
                    "Use DSP for audio processing. May reduce battery usage."),
                value: state.hardwareOffloadEnabled, // Ensure field exists
                onChanged: (val) => cubit.setHardwareOffloadEnabled(val),
              ),
              SwitchListTile(
                title: const Text("Gapless Offload"),
                value: state.gaplessOffloadEnabled,
                onChanged: (val) => cubit.setGaplessOffloadEnabled(val),
              ),
              const Divider(),
              _buildSectionHeader(context, "Queue Management"),
              SwitchListTile(
                title: const Text("Persistent Queue"),
                subtitle: const Text("Save and restore queue on app restart"),
                value: state.persistentQueueEnabled,
                onChanged: (val) => cubit.setPersistentQueueEnabled(val),
              ),
              ListTile(
                title: const Text("Max Saved Queues"),
                subtitle: Text("${state.maxSavedQueues} queues"),
                trailing: Slider(
                  min: 5,
                  max: 50,
                  divisions: 45,
                  value: state.maxSavedQueues.toDouble(),
                  onChanged: (val) => cubit.setMaxSavedQueues(val.toInt()),
                ),
              ),
              const Divider(),
              _buildSectionHeader(context, "Performance & System"),
              SwitchListTile(
                title: const Text("Keep Alive Service"),
                subtitle: const Text(
                    "Prevent app from being killed by system (Experimental)"),
                value: state.keepAliveEnabled,
                onChanged: (val) => cubit.setKeepAliveEnabled(val),
              ),
              SwitchListTile(
                title: const Text("Stop on Task Clear"),
                subtitle: const Text("Stop playback when app is swiped away"),
                value: state.stopOnTaskClear,
                onChanged: (val) => cubit.setStopOnTaskClear(val),
              ),
              const Divider(),
              _buildSectionHeader(context, "Database Maintenance"),
              ListTile(
                leading: const Icon(EvaIcons.trash_2, color: Colors.red),
                title: const Text("Nuke Local Artists"),
                onTap: () =>
                    _confirmAction(context, "Delete all artist metadata?", () {
                  BloomeeDBService.nukeLocalArtists();
                }),
              ),
              ListTile(
                leading: const Icon(EvaIcons.trash_2, color: Colors.red),
                title: const Text("Nuke Lyrics"),
                onTap: () =>
                    _confirmAction(context, "Delete all cached lyrics?", () {
                  BloomeeDBService.nukeLyrics();
                }),
              ),
              ListTile(
                leading: const Icon(EvaIcons.brush, color: Colors.orange),
                title: const Text("Clean Dangling Entities"),
                onTap: () => _confirmAction(context, "Clean up database?", () {
                  BloomeeDBService.nukeDanglingEntities();
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDropdownTile(
    BuildContext context, {
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _confirmAction(
      BuildContext context, String message, Function onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm"),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Action completed")));
              },
              child: const Text("Confirm")),
        ],
      ),
    );
  }
}
