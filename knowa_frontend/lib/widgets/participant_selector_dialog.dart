import 'package:flutter/material.dart';

class ParticipantSelectorDialog extends StatefulWidget {
  final List<Map<String, dynamic>> allUsers;
  final List<int> initiallySelectedIds;

  const ParticipantSelectorDialog({
    super.key,
    required this.allUsers,
    required this.initiallySelectedIds,
  });

  @override
  State<ParticipantSelectorDialog> createState() => _ParticipantSelectorDialogState();
}

class _ParticipantSelectorDialogState extends State<ParticipantSelectorDialog> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  // We keep track of selected IDs
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initiallySelectedIds.toSet();
  }

  // Helper to toggle a whole group
  void _toggleGroup(String role, bool select) {
    final usersInRole = widget.allUsers.where((u) => u['role'] == role).map((u) => u['id'] as int).toList();
    setState(() {
      if (select) {
        _selectedIds.addAll(usersInRole);
      } else {
        _selectedIds.removeAll(usersInRole);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter users based on search text
    final filteredUsers = widget.allUsers.where((u) {
      final name = u['name'].toString().toLowerCase();
      final email = u['email'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
    }).toList();

    // 2. Group them for display
    final admins = filteredUsers.where((u) => u['role'] == 'ADMIN').toList();
    final members = filteredUsers.where((u) => u['role'] == 'MEMBER').toList();
    final volunteers = filteredUsers.where((u) => u['role'] == 'VOLUNTEER').toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // --- HEADER ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Select Participants", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search name...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 10),

          // --- LIST ---
          Expanded(
            child: ListView(
              children: [
                if (admins.isNotEmpty) _buildSection("Admins", admins, "ADMIN"),
                if (members.isNotEmpty) _buildSection("NGO Members", members, "MEMBER"),
                if (volunteers.isNotEmpty) _buildSection("Volunteers", volunteers, "VOLUNTEER"),
              ],
            ),
          ),

          // --- FOOTER BUTTONS ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedIds.toList()),
                  child: Text("Done (${_selectedIds.length})"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> users, String roleKey) {
    // Check if ALL visible users in this section are selected
    bool allSelected = users.every((u) => _selectedIds.contains(u['id']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Header with "Select All" checkbox
        Container(
          color: Colors.grey[100],
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
              Spacer(),
              Text("Select All", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Checkbox(
                value: allSelected,
                onChanged: (val) => _toggleGroup(roleKey, val ?? false),
              ),
            ],
          ),
        ),
        // User List
        ...users.map((u) {
          bool isSelected = _selectedIds.contains(u['id']);
          return CheckboxListTile(
            title: Text(u['name'], style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(u['email'], style: TextStyle(fontSize: 12)),
            value: isSelected,
            dense: true,
            onChanged: (val) {
              setState(() {
                if (val == true) _selectedIds.add(u['id']);
                else _selectedIds.remove(u['id']);
              });
            },
          );
        }).toList(),
      ],
    );
  }
}