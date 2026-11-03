import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/models.dart';
import '../theme.dart';

/// ตัวควบคุมช่องกรอกข้อมูลลูกค้า (ใช้ร่วมกันในหน้าสั่งซื้อและหน้าเพิ่ม/แก้ไขลูกค้า)
class CustomerFormFields {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final note = TextEditingController();

  void fill(Customer c) {
    name.text = c.name;
    phone.text = c.phone;
    address.text = c.address;
    note.text = c.note;
  }

  Customer toCustomer([Customer? base]) {
    final values = (
      name: name.text.trim(),
      phone: phone.text.trim(),
      address: address.text.trim(),
      note: note.text.trim(),
    );
    if (base != null) {
      return base.copyWith(
        name: values.name,
        phone: values.phone,
        address: values.address,
        note: values.note,
      );
    }
    return Customer(
      name: values.name,
      phone: values.phone,
      address: values.address,
      note: values.note,
    );
  }

  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    note.dispose();
  }
}

class CustomerFormBody extends StatelessWidget {
  final CustomerFormFields fields;
  const CustomerFormBody({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: fields.name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'ชื่อลูกค้า *',
            prefixIcon: Icon(Icons.person, color: AppColors.caramel),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: fields.phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'เบอร์โทร *',
            prefixIcon: Icon(Icons.phone, color: AppColors.caramel),
          ),
          validator: (v) {
            final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.isEmpty) return 'กรุณากรอกเบอร์โทร';
            if (digits.length < 9 || digits.length > 10) return 'เบอร์โทรไม่ถูกต้อง';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: fields.address,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'ที่อยู่จัดส่ง',
            prefixIcon: Icon(Icons.location_on, color: AppColors.caramel),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: fields.note,
          decoration: const InputDecoration(
            labelText: 'หมายเหตุ (เช่น แพ้ถั่ว, ไม่หวานมาก)',
            prefixIcon: Icon(Icons.sticky_note_2, color: AppColors.caramel),
          ),
        ),
      ],
    );
  }
}

/// หน้าเพิ่ม / แก้ไขข้อมูลลูกค้า
class CustomerFormPage extends StatefulWidget {
  final Customer? customer;
  const CustomerFormPage({super.key, this.customer});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _fields = CustomerFormFields();

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _fields.fill(widget.customer!);
  }

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = DatabaseHelper.instance;
    if (_isEdit) {
      await db.updateCustomer(_fields.toCustomer(widget.customer));
    } else {
      await db.insertCustomer(_fields.toCustomer());
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'แก้ไขข้อมูลลูกค้า' : 'เพิ่มลูกค้าใหม่')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.butter,
                child: Icon(Icons.person, size: 44, color: AppColors.caramel),
              ),
            ),
            const SizedBox(height: 20),
            CustomerFormBody(fields: _fields),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('บันทึก'),
          ),
        ),
      ),
    );
  }
}

