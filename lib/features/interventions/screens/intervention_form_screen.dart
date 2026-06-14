// lib/features/interventions/screens/intervention_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/intervention_model.dart';
import '../services/intervention_form_service.dart';

class InterventionFormScreen extends StatefulWidget {
  /// null = mode création, non-null = mode édition
  final InterventionModel? intervention;
  const InterventionFormScreen({super.key, this.intervention});
  @override
  State<InterventionFormScreen> createState() => _InterventionFormScreenState();
}

class _InterventionFormScreenState extends State<InterventionFormScreen> {
  final InterventionFormService _service = InterventionFormService();
  final DioClient _dio = DioClient();
  final _formKey = GlobalKey<FormState>();
  final _commentCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');
  final _personNameCtrl = TextEditingController();
  final _personContactCtrl = TextEditingController();
  final _personPostCtrl = TextEditingController();

  List<Map<String, dynamic>> _deployments = [];
  List<Map<String, dynamic>> _evaluations = [];
  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _apps = [];
  List<Map<String, dynamic>> _depItems = [];

  String _typeInter = 'SUR_SITE';
  String _actionInter = 'MAINTENANCE_CURATIVE';
  Map<String, dynamic>? _selectedDeployment;
  Map<String, dynamic>? _selectedEvaluation;
  Map<String, dynamic>? _selectedType;
  Map<String, dynamic>? _selectedApp;
  DateTime _selectedDate = DateTime.now();
  bool _enAttente = false;
  bool _showPerson = false;
  Map<int, bool> _selectedItemIds = {};
  Map<int, String> _etatsAvant = {};
  Map<int, String> _etatsApres = {};

  bool _loading = false;
  bool _submitting = false;

  bool get _isEdit => widget.intervention != null;

  final List<String> _typeInterOptions = ['SUR_SITE', 'EN_LIGNE'];
  final List<String> _actionInterOptions = [
    'MAINTENANCE_CURATIVE',
    'MAINTENANCE_PREVENTIVE',
    'INSTALLATION'
  ];
  final List<String> _etatsOptions = [
    'FONCTIONNEL',
    'DEGRADE',
    'EN_PANNE',
    'HORS_SERVICE'
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final inter = widget.intervention!;
      _typeInter = inter.typeInter;
      _actionInter = inter.actionInter;
      _enAttente = inter.enAttenteMaintenance;
      _commentCtrl.text = inter.commentInter ?? '';
      _durationCtrl.text = '${inter.durationMinutes ?? 30}';
      if (inter.dateInter != null) {
        try {
          _selectedDate = DateTime.parse(inter.dateInter!.substring(0, 10));
        } catch (_) {}
      }
      if (inter.personName != null) {
        _showPerson = true;
        _personNameCtrl.text = inter.personName!;
        _personContactCtrl.text = inter.personContact ?? '';
        _personPostCtrl.text = inter.personPost ?? '';
      }
    }
    _initData();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _durationCtrl.dispose();
    _personNameCtrl.dispose();
    _personContactCtrl.dispose();
    _personPostCtrl.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getDeployments(),
        _service.getEvaluations(),
        _service.getTypes(),
        _service.getApps(),
      ]);
      setState(() {
        _deployments = results[0];
        _evaluations = results[1];
        _types = results[2];
        _apps = results[3];
        _loading = false;
      });
      if (_isEdit) await _preselectForEdit();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _preselectForEdit() async {
    final inter = widget.intervention!;
    setState(() {
      _selectedEvaluation =
          _evaluations.where((e) => e['evlName'] == inter.evlName).firstOrNull;
      _selectedType =
          _types.where((t) => t['typeName'] == inter.typeName).firstOrNull;
      _selectedApp =
          _apps.where((a) => a['appName'] == inter.appName).firstOrNull;
    });
    // Déploiement par code
    final dep = _deployments
        .where((d) => d['codeDep'] == inter.deploymentCode)
        .firstOrNull;
    if (dep != null) {
      setState(() => _selectedDeployment = dep);
      try {
        final items = await _service.getDeploymentItems(dep['id'] as int);
        setState(() => _depItems = items);
      } catch (_) {}
    }
  }

  Future<void> _onDeploymentChanged(Map<String, dynamic>? dep) async {
    setState(() {
      _selectedDeployment = dep;
      _depItems = [];
      _selectedItemIds = {};
      _etatsAvant = {};
      _etatsApres = {};
    });
    if (dep == null) return;
    try {
      final items = await _service.getDeploymentItems(dep['id'] as int);
      setState(() => _depItems = items);
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeployment == null) {
      _showError('Veuillez sélectionner un déploiement.');
      return;
    }
    if (_selectedEvaluation == null) {
      _showError('Veuillez sélectionner une évaluation.');
      return;
    }
    if (!_isEdit && _selectedItemIds.values.every((v) => !v)) {
      _showError('Veuillez sélectionner au moins un équipement.');
      return;
    }

    final connectivity = context.read<ConnectivityService>();
    final sync = context.read<SyncService>();
    setState(() => _submitting = true);

    final dep = _selectedDeployment!;
    final selectedIds = _selectedItemIds.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    final etatsAvant = <String, String>{};
    final etatsApres = <String, String>{};
    for (final id in selectedIds) {
      if (_etatsAvant[id] != null) etatsAvant[id.toString()] = _etatsAvant[id]!;
      if (_etatsApres[id] != null) etatsApres[id.toString()] = _etatsApres[id]!;
    }

    final body = <String, dynamic>{
      'typeInter': _typeInter,
      'actionInter': _actionInter,
      'commentInter': _commentCtrl.text.trim(),
      'dateInter': _selectedDate.toIso8601String(),
      'durationMinutes': int.tryParse(_durationCtrl.text) ?? 30,
      'regionId': dep['regionId'],
      'districtId': dep['districtId'],
      'healthId': dep['healthId'],
      'deploymentId': dep['id'],
      'evaluationId': _selectedEvaluation!['id'],
      'typesId': _selectedType?['id'],
      'appsId': _selectedApp?['id'] ?? dep['appsId'],
      'enAttenteMaintenance': _enAttente,
      if (!_isEdit) ...{
        'selectedItemIds': selectedIds,
        'etatsAvant': etatsAvant,
        'etatsApres': etatsApres
      },
    };
    if (_showPerson && _personNameCtrl.text.isNotEmpty) {
      body['manualPersonName'] = _personNameCtrl.text.trim();
      body['manualPersonContact'] = _personContactCtrl.text.trim();
      body['manualPersonPost'] = _personPostCtrl.text.trim();
    }

    try {
      if (_isEdit) {
        await _dio.put(
            '${ApiConstants.INTERVENTIONS}/${widget.intervention!.id}',
            data: body);
        if (!mounted) return;
        _showDialog(Icons.edit_note, AppTheme.primary,
            'Intervention mise à jour !', '');
      } else if (connectivity.isOffline) {
        await sync.saveOffline(module: 'interventions', data: body);
        if (!mounted) return;
        _showDialog(Icons.cloud_upload_outlined, Colors.orange,
            'Sauvegardé hors ligne !', 'Sera synchronisé à la reconnexion');
      } else {
        await _service.createIntervention(body);
        if (!mounted) return;
        _showDialog(Icons.check_circle_outline, AppTheme.success,
            'Intervention créée !', '');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur : $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showDialog(IconData icon, Color color, String title, String subtitle) =>
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 40)),
                  const SizedBox(height: 16),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(subtitle,
                        style: const TextStyle(color: AppTheme.gray),
                        textAlign: TextAlign.center)
                  ],
                ]),
                actions: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child: const Text('OK',
                          style: TextStyle(color: Colors.white)))
                ],
              ));

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<ConnectivityService>().isOffline;
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title:
            Text(_isEdit ? 'Modifier intervention' : 'Nouvelle intervention'),
        actions: [
          if (isOffline && !_isEdit)
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: [
                  Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text('Hors ligne',
                      style: TextStyle(color: Colors.orange, fontSize: 12))
                ])),
          if (_submitting)
            const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)))
          else
            TextButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined, color: Colors.white),
                label: Text(_isEdit ? 'Mettre à jour' : 'Enregistrer',
                    style: const TextStyle(color: Colors.white))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isOffline && !_isEdit) _offlineBanner(),
                        _sectionTitle(
                            'Type d\'intervention', Icons.tune_outlined),
                        _card([
                          Row(
                              children: _typeInterOptions.map((t) {
                            final sel = _typeInter == t;
                            final label =
                                t == 'EN_LIGNE' ? 'En ligne' : 'Sur site';
                            final icon = t == 'EN_LIGNE'
                                ? Icons.wifi
                                : Icons.location_on_outlined;
                            return Expanded(
                                child: GestureDetector(
                                    onTap: () => setState(() => _typeInter = t),
                                    child: Container(
                                        margin: EdgeInsets.only(
                                            right: t == 'EN_LIGNE' ? 8 : 0),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        decoration: BoxDecoration(
                                            color: sel
                                                ? AppTheme.primary
                                                : AppTheme.primary
                                                    .withOpacity(0.07),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(icon,
                                                  size: 16,
                                                  color: sel
                                                      ? Colors.white
                                                      : AppTheme.primary),
                                              const SizedBox(width: 6),
                                              Text(label,
                                                  style: TextStyle(
                                                      color: sel
                                                          ? Colors.white
                                                          : AppTheme.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13)),
                                            ]))));
                          }).toList()),
                          const SizedBox(height: 12),
                          _buildDropdown<String>(
                              label: 'Action *',
                              icon: Icons.build_outlined,
                              value: _actionInter,
                              items: _actionInterOptions,
                              display: (a) {
                                switch (a) {
                                  case 'MAINTENANCE_CURATIVE':
                                    return 'Maintenance curative';
                                  case 'MAINTENANCE_PREVENTIVE':
                                    return 'Maintenance préventive';
                                  case 'INSTALLATION':
                                    return 'Installation';
                                  default:
                                    return a;
                                }
                              },
                              onChanged: (v) =>
                                  setState(() => _actionInter = v!)),
                        ]),
                        _sectionTitle('Déploiement concerné',
                            Icons.local_shipping_outlined),
                        _card([
                          _buildDropdown<Map<String, dynamic>>(
                              label: 'Déploiement *',
                              icon: Icons.alt_route_outlined,
                              value: _selectedDeployment,
                              items: _deployments,
                              display: (d) =>
                                  '${d['codeDep']} — ${d['healthDeploy'] ?? ''}',
                              onChanged: _onDeploymentChanged),
                          if (_selectedDeployment != null) ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 13, color: AppTheme.gray),
                              const SizedBox(width: 4),
                              Text(
                                  '${_selectedDeployment!['districtDeploy'] ?? ''} • ${_selectedDeployment!['regionDeploy'] ?? ''}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppTheme.gray))
                            ]),
                          ],
                        ]),
                        if (_depItems.isNotEmpty && !_isEdit) ...[
                          _sectionTitle(
                              'Équipements (${_selectedItemIds.values.where((v) => v).length} sélectionné(s))',
                              Icons.devices_outlined),
                          ..._depItems.map((item) => _buildItemTile(item)),
                        ],
                        _sectionTitle('Détails', Icons.info_outline),
                        _card([
                          GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Row(children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 18, color: AppTheme.gray),
                                    const SizedBox(width: 10),
                                    Text(
                                        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                        style: const TextStyle(
                                            color: AppTheme.dark))
                                  ]))),
                          const SizedBox(height: 12),
                          TextFormField(
                              controller: _durationCtrl,
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Requis' : null,
                              decoration: InputDecoration(
                                  labelText: 'Durée (minutes) *',
                                  prefixIcon: const Icon(Icons.timer_outlined,
                                      size: 18, color: AppTheme.gray),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none))),
                          const SizedBox(height: 12),
                          _buildDropdown<Map<String, dynamic>>(
                              label: 'Type équipement',
                              icon: Icons.devices_outlined,
                              value: _selectedType,
                              items: _types,
                              display: (t) =>
                                  '${t['typeName']} — ${t['marque'] ?? ''}',
                              onChanged: (v) =>
                                  setState(() => _selectedType = v)),
                          const SizedBox(height: 12),
                          _buildDropdown<Map<String, dynamic>>(
                              label: 'Application',
                              icon: Icons.apps_outlined,
                              value: _selectedApp,
                              items: _apps,
                              display: (a) => a['appName'] as String? ?? '',
                              onChanged: (v) =>
                                  setState(() => _selectedApp = v)),
                          const SizedBox(height: 12),
                          _buildDropdown<Map<String, dynamic>>(
                              label: 'Évaluation *',
                              icon: Icons.star_outline,
                              value: _selectedEvaluation,
                              items: _evaluations,
                              display: (e) => e['evlName'] as String? ?? '',
                              onChanged: (v) =>
                                  setState(() => _selectedEvaluation = v)),
                          const SizedBox(height: 12),
                          TextFormField(
                              controller: _commentCtrl,
                              maxLines: 3,
                              validator: (v) => v!.isEmpty ? 'Requis' : null,
                              decoration: InputDecoration(
                                  labelText: 'Commentaire *',
                                  prefixIcon: const Icon(Icons.comment_outlined,
                                      size: 18, color: AppTheme.gray),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none))),
                          const SizedBox(height: 12),
                          SwitchListTile(
                              value: _enAttente,
                              onChanged: (v) => setState(() => _enAttente = v),
                              title: const Text('En attente de maintenance',
                                  style: TextStyle(
                                      fontSize: 13, color: AppTheme.dark)),
                              activeColor: AppTheme.primary,
                              contentPadding: EdgeInsets.zero),
                        ]),
                        _sectionTitle('Personne assistée (optionnel)',
                            Icons.person_outline),
                        _card([
                          SwitchListTile(
                              value: _showPerson,
                              onChanged: (v) => setState(() => _showPerson = v),
                              title: const Text('Renseigner une personne',
                                  style: TextStyle(
                                      fontSize: 13, color: AppTheme.dark)),
                              activeColor: AppTheme.primary,
                              contentPadding: EdgeInsets.zero),
                          if (_showPerson) ...[
                            const SizedBox(height: 8),
                            _buildSimpleField(
                                controller: _personNameCtrl,
                                label: 'Nom complet',
                                icon: Icons.person_outline),
                            const SizedBox(height: 10),
                            _buildSimpleField(
                                controller: _personContactCtrl,
                                label: 'Contact',
                                icon: Icons.phone_outlined),
                            const SizedBox(height: 10),
                            _buildSimpleField(
                                controller: _personPostCtrl,
                                label: 'Poste',
                                icon: Icons.work_outline),
                          ],
                        ]),
                        const SizedBox(height: 80),
                      ]))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitting ? null : _submit,
        icon: Icon(
            isOffline && !_isEdit
                ? Icons.cloud_upload_outlined
                : Icons.save_outlined,
            color: Colors.white),
        label: Text(
            _isEdit
                ? 'Mettre à jour'
                : (isOffline ? 'Sauvegarder hors ligne' : 'Enregistrer'),
            style: const TextStyle(color: Colors.white)),
        backgroundColor: _isEdit
            ? AppTheme.primary
            : (isOffline ? Colors.orange : AppTheme.primary),
      ),
    );
  }

  Widget _offlineBanner() => Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withOpacity(0.3))),
      child: const Row(children: [
        Icon(Icons.wifi_off, color: Colors.orange, size: 18),
        SizedBox(width: 8),
        Expanded(
            child: Text('Mode hors ligne — sera synchronisé à la reconnexion',
                style: TextStyle(color: Colors.orange, fontSize: 12)))
      ]));

  Widget _sectionTitle(String title, IconData icon) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.dark)))
      ]));

  Widget _card(List<Widget> children) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children));

  Widget _buildSimpleField(
          {required TextEditingController controller,
          required String label,
          required IconData icon}) =>
      TextFormField(
          controller: controller,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, size: 18, color: AppTheme.gray),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none)));

  Widget _buildDropdown<T>(
          {required String label,
          required IconData icon,
          required T? value,
          required List<T> items,
          required String Function(T) display,
          required void Function(T?)? onChanged}) =>
      DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(display(item),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, size: 18, color: AppTheme.gray),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: AppTheme.primary, width: 1.5))));

  Widget _buildItemTile(Map<String, dynamic> item) {
    final id = item['id'] as int;
    final selected = _selectedItemIds[id] ?? false;
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? AppTheme.primary : Colors.grey[200]!,
                width: selected ? 1.5 : 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            GestureDetector(
                onTap: () => setState(() => _selectedItemIds[id] = !selected),
                child: Icon(
                    selected
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    color: selected ? AppTheme.primary : AppTheme.gray,
                    size: 22)),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item['tag'] as String? ?? '',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: selected ? AppTheme.primary : AppTheme.dark)),
                  Text(item['typeName'] as String? ?? '',
                      style:
                          const TextStyle(fontSize: 11, color: AppTheme.gray)),
                ])),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _statusColor(item['status'] as String? ?? '')
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(item['status'] as String? ?? '',
                    style: TextStyle(
                        color: _statusColor(item['status'] as String? ?? ''),
                        fontSize: 10))),
          ]),
          if (selected) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _buildDropdown<String>(
                      label: 'État avant',
                      icon: Icons.arrow_back_outlined,
                      value: _etatsAvant[id],
                      items: _etatsOptions,
                      display: (e) => e,
                      onChanged: (v) => setState(() => _etatsAvant[id] = v!))),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildDropdown<String>(
                      label: 'État après',
                      icon: Icons.arrow_forward_outlined,
                      value: _etatsApres[id],
                      items: _etatsOptions,
                      display: (e) => e,
                      onChanged: (v) => setState(() => _etatsApres[id] = v!))),
            ]),
          ],
        ]));
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'FONCTIONNEL':
        return AppTheme.success;
      case 'DEGRADE':
        return AppTheme.warning;
      case 'EN_PANNE':
        return Colors.red;
      default:
        return AppTheme.gray;
    }
  }
}
