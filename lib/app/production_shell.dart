import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:material_ui/material_ui.dart';

import 'ui_kit.dart';

class ProductionShell extends StatefulWidget {
  const ProductionShell({required this.user, super.key});

  final User user;

  @override
  State<ProductionShell> createState() => _ProductionShellState();
}

class _ProductionShellState extends State<ProductionShell> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  DocumentReference<Map<String, dynamic>> get _profileRef =>
      FirebaseFirestore.instance.collection('users').doc(widget.user.uid);

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _configureMessaging();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final snapshot = await _profileRef.get();
      final data = snapshot.data();
      _name.text =
          data?['name'] as String? ?? widget.user.displayName ?? 'Jugador';
      _bio.text = data?['bio'] as String? ?? '';
      if (!snapshot.exists) {
        await _profileRef.set({
          'uid': widget.user.uid,
          'name': _name.text.trim(),
          'bio': _bio.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _configureMessaging() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await FirebaseMessaging.instance.register();
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Escribí un nombre de al menos 2 caracteres.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _profileRef.set({
        'uid': widget.user.uid,
        'name': name,
        'bio': _bio.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await widget.user.updateDisplayName(name);
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Esta acción elimina tu perfil y cierra la sesión. Esta operación '
          'requiere reautenticación reciente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _profileRef.delete();
      await widget.user.delete();
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? error.code)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hay Equipo'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: PageBody(
        children: [
          Text(
            'Mi perfil',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const LocalDemoBadge(
            label: 'Cuenta conectada · datos reales',
            icon: Icons.cloud_done_outlined,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bio,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _saveProfile,
            child: Text(_saving ? 'Guardando…' : 'Guardar perfil'),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
  }
}
