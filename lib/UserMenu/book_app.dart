import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookAppointmentPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const BookAppointmentPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _appointmentMethod = 'Face to Face';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final appointment = {
      'doctorId': widget.doctorId,
      'doctorName': widget.doctorName,
      'fullName': _fullNameController.text.trim(),
      'date': _selectedDate!.toIso8601String(),
      'time': _selectedTime!.format(context),
      'method': _appointmentMethod,
      'reason': _reasonController.text.trim(),
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .add(appointment);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment booked')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book with Dr. ${widget.doctorName}'),
        backgroundColor: const Color(0xFF18FFFF),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF18FFFF), Color(0xFF18FFFF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  tileColor: Colors.white,
                  title: Text(_selectedDate == null
                      ? 'Pick a Date'
                      : 'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                ListTile(
                  tileColor: Colors.white,
                  title: Text(_selectedTime == null
                      ? 'Pick a Time'
                      : 'Time: ${_selectedTime!.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pickTime,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _appointmentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Method of Appointment',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: ['Face to Face', 'Online'].map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _appointmentMethod = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Appointment',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Enter a reason' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[800],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Confirm Appointment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
