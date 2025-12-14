import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../services/supabase_contact_service.dart';
import '../models/user.dart';
import '../utils/contact_utils.dart';
import 'profile_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with AutomaticKeepAliveClientMixin {
  final SupabaseContactService _contactService = SupabaseContactService();
  List<User> _contacts = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final appState = context.read<AppState>();
    if (appState.currentUser != null) {
      _contacts = await _contactService.getContacts(appState.currentUser!.id!);
    }
    setState(() => _isLoading = false);
  }

  void _showDeleteConfirmDialog(User contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa liên hệ'),
        content: Text('Bạn có muốn xóa ${contact.nickname} khỏi danh bạ không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeContact(contact);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Có'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeContact(User contact) async {
    final appState = context.read<AppState>();
    if (appState.currentUser == null) return;

    final success = await _contactService.removeContact(
      appState.currentUser!.id!,
      contact.id!,
    );

    if (success && mounted) {
      _loadContacts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa ${contact.nickname} khỏi danh bạ'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final appState = context.watch<AppState>();

    if (!appState.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Danh bạ')),
        body: const Center(
          child: Text('Vui lòng đăng nhập để xem danh bạ'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh bạ'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contacts_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có liên hệ nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadContacts,
                  child: ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.orange,
                          backgroundImage: contact.avatar != null && contact.avatar!.isNotEmpty
                              ? (contact.avatar!.startsWith('http')
                                  ? CachedNetworkImageProvider(contact.avatar!)
                                  : FileImage(File(contact.avatar!)) as ImageProvider)
                              : null,
                          child: contact.avatar == null || contact.avatar!.isEmpty
                              ? Text(
                                  contact.nickname[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 20, color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(
                          contact.name ?? contact.nickname,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  contact.nickname,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  contact.phone,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            if (contact.address != null || contact.province != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${contact.address ?? ''} ${contact.district ?? ''} ${contact.province ?? ''}'.trim(),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.orange),
                          onPressed: () => ContactUtils.makePhoneCall(contact.phone),
                          tooltip: 'Gọi điện',
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(userId: contact.id!),
                            ),
                          );
                        },
                        onLongPress: () {
                          _showDeleteConfirmDialog(contact);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

