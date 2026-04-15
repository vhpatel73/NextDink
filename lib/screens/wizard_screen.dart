import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';
import 'map_screen.dart';

class CreateGameWizardScreen extends StatefulWidget {
  const CreateGameWizardScreen({super.key});

  @override
  State<CreateGameWizardScreen> createState() => _CreateGameWizardScreenState();
}

class _CreateGameWizardScreenState extends State<CreateGameWizardScreen> {
  int _currentStep = 0;
  
  // Form Data
  String? _selectedLocation;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  final _locationController = TextEditingController();

  bool get isLocalhost {
    if (!kIsWeb) return false;
    final host = Uri.base.host;
    return host == 'localhost' || host == '127.0.0.1';
  }

  void _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen(pickingMode: true)),
    );
    if (result != null && result is String) {
      setState(() {
        _selectedLocation = result;
        _locationController.text = result;
      });
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (_selectedDate != null) {
        final now = DateTime.now();
        final selectedDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          picked.hour,
          picked.minute,
        );
        if (selectedDateTime.isBefore(now)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot pick a time in the past!')),
            );
          }
          return;
        }
      }
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitAndShare() async {
    if (_selectedLocation == null || _selectedDate == null || _selectedTime == null) return;
    
    // Combine Date and Time
    final scheduledTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (scheduledTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait! You cannot schedule a game in the past.')),
      );
      return;
    }

    // Show booking indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating match...')),
    );

    final gameId = await FirestoreService().createGameAndGetId(_selectedLocation!, scheduledTime);

    if (context.mounted) {
      Navigator.pop(context); // Close the wizard entirely
      // Instantly pop the native share sheet
      final String baseUrl = kIsWeb ? Uri.base.origin : 'https://nextdink-11.web.app';
      final inviteLink = '$baseUrl/join?gameId=$gameId';
      Share.share('Dink with me! Join my game at $_selectedLocation\n\nTap here to accept: $inviteLink');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scheduled game at $_selectedLocation!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Game', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Stepper(
            currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && _selectedLocation == null && _locationController.text.trim().isEmpty) return;
          if (_currentStep == 0 && _selectedLocation == null) {
             _selectedLocation = _locationController.text.trim();
          }

          if (_currentStep == 1 && (_selectedDate == null || _selectedTime == null)) return;
          
          if (_currentStep == 2) {
            _submitAndShare();
          } else {
            setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          final isLastStep = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(isLastStep ? 'Book & Share Invites' : 'Continue'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: Text(_currentStep == 0 ? 'Cancel' : 'Back', style: const TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Court Location', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: _selectedLocation != null && _currentStep > 0
                ? Text(_selectedLocation!, style: const TextStyle(color: Color(0xFFD4F82B), fontSize: 13))
                : null,
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLocalhost)
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Court Name (Local Testing)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => _selectedLocation = val,
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.map),
                    label: Text(_selectedLocation ?? 'Pick Location from Map'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: _selectedDate != null && _selectedTime != null && _currentStep > 1
                ? Text(
                    '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year} at ${_selectedTime!.format(context)}',
                    style: const TextStyle(color: Color(0xFFD4F82B), fontSize: 13),
                  )
                : null,
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_selectedDate != null 
                        ? "${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}"
                        : 'Select Date'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime != null 
                        ? _selectedTime!.format(context)
                        : 'Select Time'),
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Confirm & Invite', style: TextStyle(fontWeight: FontWeight.bold)),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Ready to book! Once you finish, your systems\'s native share sheet will immediately pop up so you can group text the Invite Deep-Link to your friends!', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFD4F82B)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_selectedLocation ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 8),
                       Row(
                        children: [
                          const Icon(Icons.schedule, color: Color(0xFFD4F82B)),
                          const SizedBox(width: 8),
                          Text(_selectedDate != null && _selectedTime != null 
                            ? "${_selectedDate!.month}/${_selectedDate!.day} at ${_selectedTime!.format(context)}" 
                            : ''),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
