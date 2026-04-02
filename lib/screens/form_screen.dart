import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/recibo.dart';
import '../providers/recibo_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import 'paywall_screen.dart';
import 'success_screen.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _prestadorNomeCtrl = TextEditingController();
  final _prestadorCpfCtrl = TextEditingController();
  final _clienteNomeCtrl = TextEditingController();
  final _servicoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController(); // TODO: PRO

  DateTime _selectedDate = DateTime.now();
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadPrestadorSalvo();
  }

  Future<void> _loadPrestadorSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('prestador_nome') ?? '';
    final cpf = prefs.getString('prestador_cpf') ?? '';
    if (nome.isNotEmpty) {
      _prestadorNomeCtrl.text = nome;
      _prestadorCpfCtrl.text = cpf;
    }
  }

  Future<void> _salvarPrestador() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prestador_nome', _prestadorNomeCtrl.text.trim());
    await prefs.setString('prestador_cpf', _prestadorCpfCtrl.text.trim());
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.card,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _gerarPdf() async {
    if (!_formKey.currentState!.validate()) return;

    final reciboProvider = context.read<ReciboProvider>();
    final userProvider = context.read<UserProvider>();

    // Verificar limite free
    if (!userProvider.isPro && reciboProvider.isAtFreeLimit) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }

    setState(() => _generating = true);

    // Salvar dados do prestador para reutilizar
    await _salvarPrestador();

    final numeracao = await reciboProvider.getNextNumeracao();

    // Parsear valor (remove R$, espaços e troca vírgula por ponto)
    final valorStr = _valorCtrl.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final valor = double.tryParse(valorStr) ?? 0.0;

    final recibo = Recibo(
      numeracao: numeracao,
      prestadorNome: _prestadorNomeCtrl.text.trim(),
      prestadorCpf: _prestadorCpfCtrl.text.trim(),
      clienteNome: _clienteNomeCtrl.text.trim(),
      servico: _servicoCtrl.text.trim(),
      valor: valor,
      data: _selectedDate,
      // TODO: PRO — observacoes: _observacoesCtrl.text.trim()
      tema: 'minimalista',
      criadoEm: DateTime.now(),
    );

    final saved = await reciboProvider.saveRecibo(recibo);

    if (!mounted) return;
    setState(() => _generating = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SuccessScreen(recibo: saved)),
    );
  }

  String _formatarData(DateTime date) {
    return DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(date);
  }

  @override
  void dispose() {
    _prestadorNomeCtrl.dispose();
    _prestadorCpfCtrl.dispose();
    _clienteNomeCtrl.dispose();
    _servicoCtrl.dispose();
    _valorCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<UserProvider>().isPro;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Novo Recibo',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Formulário ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _FormField(
                        label: 'SEU NOME',
                        controller: _prestadorNomeCtrl,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 8),
                      _FormField(
                        label: 'CPF OU CNPJ',
                        controller: _prestadorCpfCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.\-/]'),
                          ),
                          LengthLimitingTextInputFormatter(18),
                        ],
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 8),
                      _FormField(
                        label: 'NOME DO CLIENTE',
                        controller: _clienteNomeCtrl,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 8),
                      _FormField(
                        label: 'SERVIÇO PRESTADO',
                        controller: _servicoCtrl,
                        keyboardType: TextInputType.multiline,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 8),
                      _FormField(
                        label: 'VALOR EM R\$',
                        controller: _valorCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\d,.]'),
                          ),
                        ],
                        accentValue: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obrigatório';
                          final parsed = double.tryParse(
                            v.replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // ── Campo data (tap abre DatePicker) ──────────────
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DATA',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.7,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatarData(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Observações (Pro) ─────────────────────────────
                      // TODO: PRO — campo observações desbloqueado para Pro
                      GestureDetector(
                        onTap: isPro
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PaywallScreen(),
                                  ),
                                ),
                        child: Stack(
                          children: [
                            AbsorbPointer(
                              absorbing: !isPro,
                              child: _FormField(
                                label: 'OBSERVAÇÕES',
                                controller: _observacoesCtrl,
                                keyboardType: TextInputType.multiline,
                                maxLines: 2,
                                textCapitalization: TextCapitalization.sentences,
                              ),
                            ),
                            if (!isPro)
                              Positioned(
                                right: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_rounded,
                                        size: 9,
                                        color: AppColors.amber,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'PRO',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Botão gerar ───────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _generating ? null : _gerarPdf,
                          child: _generating
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Gerar PDF →'),
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        'Compartilhe via WhatsApp após gerar',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int? maxLines;
  final bool accentValue;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.accentValue = false,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(
        fontSize: accentValue ? 17 : 13,
        fontWeight: accentValue ? FontWeight.w700 : FontWeight.w500,
        color: accentValue ? AppColors.primary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 9,
          color: AppColors.textMuted,
          letterSpacing: 0.7,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
