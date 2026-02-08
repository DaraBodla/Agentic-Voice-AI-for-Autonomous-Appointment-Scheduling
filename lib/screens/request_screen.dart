import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' hide Provider;
import '../models/models.dart';
import '../providers/job_provider.dart';
import '../providers/contact_provider.dart';
import '../utils/theme.dart';

class RequestScreen extends StatefulWidget {
  final VoidCallback onStarted;
  const RequestScreen({super.key, required this.onStarted});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  String _serviceType = 'dentist';
  late DateTime _startDate;
  late DateTime _endDate;
  late TextEditingController _locationCtrl;
  int _maxProviders = 5;
  CampaignMode _mode = CampaignMode.swarm;
  double _earliestWeight = 0.4;
  double _ratingWeight = 0.3;
  double _distanceWeight = 0.3;
  bool _loading = false;
  bool _includeMyContacts = true;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
    // Pre-fill from saved location
    final loc = context.read<ContactProvider>().userLocation;
    _locationCtrl = TextEditingController(text: loc.address.isNotEmpty ? loc.address : 'Downtown');
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _startCampaign() async {
    setState(() => _loading = true);

    final cp = context.read<ContactProvider>();
    final loc = cp.userLocation;

    // Collect user contacts for this service type
    List<Provider> customProviders = [];
    if (_includeMyContacts) {
      customProviders = cp.getProvidersForType(_serviceType);
    }

    final request = UserRequest(
      serviceType: _serviceType,
      timeWindowStart: _startDate,
      timeWindowEnd: _endDate,
      location: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : 'Downtown',
      latitude: loc.latitude,
      longitude: loc.longitude,
      maxProviders: _maxProviders,
      mode: _mode,
      preferences: Preferences(
        earliestWeight: _earliestWeight,
        ratingWeight: _ratingWeight,
        distanceWeight: _distanceWeight,
      ),
      customProviders: customProviders,
    );

    final jobProvider = context.read<JobProvider>();
    jobProvider.startCampaign(request);
    widget.onStarted();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ContactProvider>();
    final myContactsForType = cp.getByType(_serviceType);
    final loc = cp.userLocation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Book an Appointment',
              style: GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 6),
          Text(
            'Tell CallPilot what you need. Our AI agent will call providers simultaneously, negotiate availability, and find the best option.',
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDim, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Main card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('SERVICE TYPE'),
                const SizedBox(height: 8),
                _buildServiceSelector(),
                const SizedBox(height: 20),

                // User contacts badge
                if (myContactsForType.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.contacts, size: 18, color: AppColors.accentLight),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${myContactsForType.length} personal contact${myContactsForType.length > 1 ? 's' : ''} for ${_serviceType}',
                                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentLight),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                myContactsForType.map((c) => c.name).join(', '),
                                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textDim),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _includeMyContacts,
                          onChanged: (v) => setState(() => _includeMyContacts = v),
                          activeColor: AppColors.accent,
                          inactiveThumbColor: AppColors.textMuted,
                          inactiveTrackColor: AppColors.border,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _label('TIME WINDOW'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _dateButton('From', _startDate, (d) => setState(() => _startDate = d))),
                    const SizedBox(width: 12),
                    Expanded(child: _dateButton('To', _endDate, (d) => setState(() => _endDate = d))),
                  ],
                ),
                const SizedBox(height: 20),

                // Location with saved indicator
                Row(
                  children: [
                    Expanded(child: _label('YOUR LOCATION')),
                    if (!loc.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.greenDim,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '✓ saved',
                          style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.green, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationCtrl,
                  style: GoogleFonts.dmSans(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Your address or area...',
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 20),
                    suffixIcon: loc.hasCoordinates
                        ? Tooltip(
                            message: '${loc.latitude?.toStringAsFixed(4)}, ${loc.longitude?.toStringAsFixed(4)}',
                            child: const Icon(Icons.gps_fixed, color: AppColors.green, size: 18),
                          )
                        : null,
                  ),
                ),
                if (loc.hasCoordinates)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Coordinates: ${loc.latitude!.toStringAsFixed(4)}, ${loc.longitude!.toStringAsFixed(4)}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ),
                const SizedBox(height: 20),

                _label('MAX PROVIDERS TO CALL'),
                const SizedBox(height: 8),
                _buildProviderCountSelector(),
                const SizedBox(height: 20),

                _label('CALLING MODE'),
                const SizedBox(height: 8),
                _buildModeSelector(),
                const SizedBox(height: 24),

                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 20),

                _label('PRIORITY WEIGHTS'),
                const SizedBox(height: 16),
                _buildSlider('⏰  Earliest Available', _earliestWeight, (v) => setState(() => _earliestWeight = v)),
                _buildSlider('⭐  Provider Rating', _ratingWeight, (v) => setState(() => _ratingWeight = v)),
                _buildSlider('📍  Proximity', _distanceWeight, (v) => setState(() => _distanceWeight = v)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _startCampaign,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('🚀  Start Campaign', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim, letterSpacing: 1));

  Widget _buildServiceSelector() {
    final services = [('dentist', '🦷', 'Dentist'), ('mechanic', '🔧', 'Mechanic'), ('salon', '💇', 'Salon')];
    return Row(
      children: services.map((s) {
        final selected = _serviceType == s.$1;
        final contactCount = context.watch<ContactProvider>().getByType(s.$1).length;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _serviceType = s.$1),
            child: Container(
              margin: EdgeInsets.only(right: s.$1 != 'salon' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent.withOpacity(0.15) : AppColors.surface2,
                border: Border.all(color: selected ? AppColors.accent : AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(s.$2, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(s.$3, style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.accentLight : AppColors.textDim,
                  )),
                  if (contactCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '$contactCount saved',
                        style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.green),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dateButton(String label, DateTime date, ValueChanged<DateTime> onChanged) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.accent, surface: AppColors.surface),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
                Text('${date.month}/${date.day}/${date.year}',
                    style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCountSelector() {
    return Row(
      children: [3, 5, 8, 10, 15].map((n) {
        final selected = _maxProviders == n;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _maxProviders = n),
            child: Container(
              width: 44,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.surface2,
                border: Border.all(color: selected ? AppColors.accent : AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('$n', style: GoogleFonts.jetBrainsMono(
                  fontSize: 14, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textDim,
                )),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        _modeButton(CampaignMode.single, '📞', 'Single Call', 'sequential'),
        const SizedBox(width: 10),
        _modeButton(CampaignMode.swarm, '🐝', 'Swarm Mode', 'parallel'),
      ],
    );
  }

  Widget _modeButton(CampaignMode mode, String icon, String label, String sub) {
    final selected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withOpacity(0.15) : AppColors.surface2,
            border: Border.all(color: selected ? AppColors.accent : AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppColors.accentLight : AppColors.textDim,
                  )),
                  Text(sub, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim)),
              Text('${(value * 100).round()}%', style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppColors.accentLight)),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.accentLight,
              overlayColor: AppColors.accent.withOpacity(0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(value: value, min: 0, max: 1, divisions: 20, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}