import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/contact_provider.dart';
import '../utils/theme.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, cp, _) {
        final contacts = cp.contacts;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Contacts',
                        style: GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add your own doctors, mechanics, salons — CallPilot will call them for you.',
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim, height: 1.4),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Add button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showContactEditor(context, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Add Contact', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentLight,
                    side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location section
              _LocationCard(),
              const SizedBox(height: 20),

              // Contact list
              if (contacts.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Text('📇', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        'No contacts yet',
                        style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDim),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add your dentist, mechanic, or salon\nand CallPilot will include them in campaigns.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                      ),
                    ],
                  ),
                ),

              ...contacts.map((c) => _ContactCard(
                    contact: c,
                    onEdit: () => _showContactEditor(context, c),
                    onDelete: () => _confirmDelete(context, c),
                  )),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _showContactEditor(BuildContext context, UserContact? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ContactEditorSheet(existing: existing),
    );
  }

  void _confirmDelete(BuildContext context, UserContact contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Delete ${contact.name}?', style: GoogleFonts.dmSans(color: AppColors.text)),
        content: Text(
          'This contact will be removed and won\'t be included in future campaigns.',
          style: GoogleFonts.dmSans(color: AppColors.textDim, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () {
              context.read<ContactProvider>().deleteContact(contact.id);
              Navigator.pop(ctx);
            },
            child: Text('Delete', style: GoogleFonts.dmSans(color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Card ───────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final UserContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactCard({required this.contact, required this.onEdit, required this.onDelete});

  String _serviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'dentist': return '🦷';
      case 'mechanic': return '🔧';
      case 'salon': return '💇';
      default: return '📋';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(_serviceIcon(contact.serviceType), style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  contact.phone,
                  style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.accentLight),
                ),
                if (contact.address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      contact.address,
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Rating
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.orangeDim,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '⭐ ${contact.rating}',
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.orange, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 6),

          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
            color: AppColors.surface2,
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text('Edit', style: GoogleFonts.dmSans(color: AppColors.text))),
              PopupMenuItem(value: 'delete', child: Text('Delete', style: GoogleFonts.dmSans(color: AppColors.red))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Location Card ──────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, cp, _) {
        final loc = cp.userLocation;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: loc.isEmpty ? AppColors.orangeDim : AppColors.greenDim),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.my_location,
                    size: 18,
                    color: loc.isEmpty ? AppColors.orange : AppColors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'My Location',
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showLocationEditor(context),
                    child: Text(
                      loc.isEmpty ? 'Set Location' : 'Edit',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.accentLight, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              if (!loc.isEmpty) ...[
                const SizedBox(height: 8),
                if (loc.address.isNotEmpty)
                  Text(loc.address, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim)),
                if (loc.hasCoordinates)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '${loc.latitude!.toStringAsFixed(4)}, ${loc.longitude!.toStringAsFixed(4)}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
              ],
              if (loc.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Set your location so CallPilot can calculate travel times.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showLocationEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _LocationEditorSheet(),
    );
  }
}

// ─── Location Editor Sheet ──────────────────────────────────────────────────

class _LocationEditorSheet extends StatefulWidget {
  const _LocationEditorSheet();

  @override
  State<_LocationEditorSheet> createState() => _LocationEditorSheetState();
}

class _LocationEditorSheetState extends State<_LocationEditorSheet> {
  late TextEditingController _addressCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;

  @override
  void initState() {
    super.initState();
    final loc = context.read<ContactProvider>().userLocation;
    _addressCtrl = TextEditingController(text: loc.address);
    _latCtrl = TextEditingController(text: loc.latitude?.toString() ?? '');
    _lngCtrl = TextEditingController(text: loc.longitude?.toString() ?? '');
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final loc = UserLocation(
      address: _addressCtrl.text.trim(),
      latitude: double.tryParse(_latCtrl.text.trim()),
      longitude: double.tryParse(_lngCtrl.text.trim()),
    );
    context.read<ContactProvider>().setUserLocation(loc);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          Text('My Location', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 4),
          Text(
            'Enter your address or coordinates. This helps CallPilot calculate travel distances to providers.',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _addressCtrl,
            style: GoogleFonts.dmSans(color: AppColors.text),
            decoration: InputDecoration(
              labelText: 'ADDRESS',
              hintText: '123 Main St, City, State',
              prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 20),
              labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'COORDINATES (OPTIONAL)',
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          Text(
            'Tip: search your address on Google Maps, right-click → "What\'s here?" to get lat/lng.',
            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  style: GoogleFonts.jetBrainsMono(color: AppColors.text, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'LATITUDE',
                    hintText: '24.8607',
                    labelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDim, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lngCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  style: GoogleFonts.jetBrainsMono(color: AppColors.text, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'LONGITUDE',
                    hintText: '67.0011',
                    labelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDim, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save Location', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Editor Sheet ───────────────────────────────────────────────────

class _ContactEditorSheet extends StatefulWidget {
  final UserContact? existing;
  const _ContactEditorSheet({this.existing});

  @override
  State<_ContactEditorSheet> createState() => _ContactEditorSheetState();
}

class _ContactEditorSheetState extends State<_ContactEditorSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _notesCtrl;
  late String _serviceType;
  late double _rating;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _serviceType = c?.serviceType ?? 'dentist';
    _rating = c?.rating ?? 4.0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name and phone number are required', style: GoogleFonts.dmSans()),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final contact = UserContact(
      id: widget.existing?.id,
      name: name,
      phone: phone,
      serviceType: _serviceType,
      rating: _rating,
      address: _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt,
    );

    final cp = context.read<ContactProvider>();
    if (isEditing) {
      cp.updateContact(contact);
    } else {
      cp.addContact(contact);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              isEditing ? 'Edit Contact' : 'Add Contact',
              style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a service provider you want CallPilot to call on your behalf.',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim),
            ),
            const SizedBox(height: 20),

            // Service type
            Text(
              'SERVICE TYPE',
              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ('dentist', '🦷', 'Dentist'),
                ('mechanic', '🔧', 'Mechanic'),
                ('salon', '💇', 'Salon'),
                ('other', '📋', 'Other'),
              ].map((s) {
                final selected = _serviceType == s.$1;
                return GestureDetector(
                  onTap: () => setState(() => _serviceType = s.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent.withOpacity(0.15) : AppColors.surface2,
                      border: Border.all(color: selected ? AppColors.accent : AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.$2, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          s.$3,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? AppColors.accentLight : AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.dmSans(color: AppColors.text),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'NAME *',
                hintText: 'Dr. Smith\'s Dental Office',
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted, size: 20),
                labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 14),

            // Phone
            TextField(
              controller: _phoneCtrl,
              style: GoogleFonts.jetBrainsMono(color: AppColors.text),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'PHONE NUMBER *',
                hintText: '+1 555 123 4567',
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textMuted, size: 20),
                labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 14),

            // Address
            TextField(
              controller: _addressCtrl,
              style: GoogleFonts.dmSans(color: AppColors.text),
              decoration: InputDecoration(
                labelText: 'ADDRESS',
                hintText: '456 Oak Ave, Suite 200',
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 20),
                labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 14),

            // Rating
            Row(
              children: [
                Text('RATING', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim, letterSpacing: 1)),
                const Spacer(),
                Text('${_rating.toStringAsFixed(1)} ⭐', style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppColors.orange)),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.orange,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.orange,
                overlayColor: AppColors.orange.withOpacity(0.2),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 8,
                onChanged: (v) => setState(() => _rating = v),
              ),
            ),

            // Notes
            TextField(
              controller: _notesCtrl,
              style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 13),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'NOTES',
                hintText: 'Hours, preferences, special instructions...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(Icons.notes_outlined, color: AppColors.textMuted, size: 20),
                ),
                labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Add Contact',
                  style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}