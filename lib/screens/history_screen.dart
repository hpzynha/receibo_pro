import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // TODO: PRO
import '../models/recibo.dart';
import '../providers/recibo_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pro_badge.dart';
import '../widgets/pro_gate.dart';
import 'paywall_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  List<Recibo> _filtered = [];
  bool _loadingFiltered = false;

  // Gera os últimos 6 meses para os chips de filtro
  List<DateTime> get _monthOptions {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return d;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadFiltered();
  }

  Future<void> _loadFiltered() async {
    setState(() => _loadingFiltered = true);
    final recibos = await context
        .read<ReciboProvider>()
        .getRecibosByMonth(_selectedYear, _selectedMonth);
    if (mounted) {
      setState(() {
        _filtered = recibos;
        _loadingFiltered = false;
      });
    }
  }

  // TODO: PRO — upload de logo via image_picker
  Future<void> _pickLogo() async {
    final isPro = context.read<UserProvider>().isPro;
    if (!isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      context.read<UserProvider>().setLogoPath(picked.path);
    }
  }

  void _showReciboOptions(BuildContext context, Recibo recibo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.share_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                'Reenviar',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () async {
                Navigator.pop(context);
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abrindo PDF para reenvio...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.copy_rounded,
                color: AppColors.textMuted,
              ),
              title: const Text(
                'Duplicar',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: navegar para FormScreen pré-preenchido com dados do recibo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade em breve!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
              ),
              title: const Text(
                'Excluir',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
              onTap: () async {
                Navigator.pop(context);
                await context
                    .read<ReciboProvider>()
                    .deleteRecibo(recibo.id!);
                _loadFiltered();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<UserProvider>().isPro;
    final logoPath = context.watch<UserProvider>().logoPath;
    final currencyFmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    final monthFmt = DateFormat('MMMM', 'pt_BR');

    // Clientes únicos no mês filtrado
    final clientesUnicos =
        _filtered.map((r) => r.clienteNome.toLowerCase()).toSet().length;
    final totalMesFiltrado =
        _filtered.fold(0.0, (sum, r) => sum + r.valor);

    return Scaffold(
      body: SafeArea(
        child: ProGate(
          message: 'Histórico disponível no plano Pro',
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ───────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
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
                                'Histórico',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const ProBadge(),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Stats row ─────────────────────────────────────
                      Row(
                        children: [
                          _StatMini(
                            value: currencyFmt.format(totalMesFiltrado),
                            label: 'este mês',
                            valueColor: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _StatMini(
                            value: '${_filtered.length}',
                            label: 'recibos',
                          ),
                          const SizedBox(width: 8),
                          _StatMini(
                            value: '$clientesUnicos',
                            label: 'clientes',
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Logo badge (Pro) ──────────────────────────────
                      // TODO: PRO — upload de logo funcional
                      GestureDetector(
                        onTap: _pickLogo,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: logoPath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          logoPath,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.image_outlined,
                                        size: 18,
                                        color: AppColors.textMuted,
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPro
                                        ? (logoPath != null
                                            ? 'Logo configurado'
                                            : 'Adicionar logo ao PDF')
                                        : 'Seu logo no PDF',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    isPro ? 'Toque para alterar' : 'Recurso Pro',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Filtro de meses ───────────────────────────────
                      SizedBox(
                        height: 30,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _monthOptions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 6),
                          itemBuilder: (context, i) {
                            final month = _monthOptions[i];
                            final isSelected = month.year == _selectedYear &&
                                month.month == _selectedMonth;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedYear = month.year;
                                  _selectedMonth = month.month;
                                });
                                _loadFiltered();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryDim
                                      : AppColors.card,
                                  borderRadius: BorderRadius.circular(20),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3),
                                        )
                                      : null,
                                ),
                                child: Text(
                                  i == 0
                                      ? 'Este mês'
                                      : monthFmt
                                          .format(month)
                                          .substring(0, 3)
                                          .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // ── Lista filtrada ────────────────────────────────────────
              if (_loadingFiltered)
                const SliverFillRemaining(
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Nenhum recibo em ${monthFmt.format(DateTime(_selectedYear, _selectedMonth))}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final recibo = _filtered[index];
                        final currFmt = NumberFormat.currency(
                          locale: 'pt_BR',
                          symbol: 'R\$',
                          decimalDigits: 0,
                        );
                        final dateFmt = DateFormat('dd/MM');
                        return GestureDetector(
                          onTap: () => _showReciboOptions(context, recibo),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDim,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recibo.clienteNome,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${recibo.servico} · ${dateFmt.format(recibo.data)}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currFmt.format(recibo.valor),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _StatMini({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
