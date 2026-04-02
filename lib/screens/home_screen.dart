import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/recibo_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/free_banner.dart';
import '../widgets/recibo_card.dart';
import 'form_screen.dart';
import 'history_screen.dart';
import 'paywall_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReciboProvider>().loadRecibos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reciboProvider = context.watch<ReciboProvider>();
    final userProvider = context.watch<UserProvider>();
    final isPro = userProvider.isPro;
    final currencyFmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── App bar ───────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Recibo',
                                style: TextStyle(
                                  fontFamily: 'Sora',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Pro',
                                style: TextStyle(
                                  fontFamily: 'Sora',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: AppColors.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          ),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Free banner (oculto se Pro) ───────────────────────
                    if (!isPro) ...[
                      FreeBanner(
                        used: reciboProvider.mesCount,
                        limit: ReciboProvider.freeLimit,
                        onUpgradeTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaywallScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Stats Pro ─────────────────────────────────────────
                    // TODO: PRO — stats de faturamento
                    if (isPro) ...[
                      Row(
                        children: [
                          _StatCard(
                            label: 'este mês',
                            value: currencyFmt.format(reciboProvider.totalMes),
                            valueColor: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            label: 'recibos',
                            value: '${reciboProvider.recibos.where((r) {
                              final now = DateTime.now();
                              return r.criadoEm.year == now.year &&
                                  r.criadoEm.month == now.month;
                            }).length}',
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            label: 'clientes',
                            value: '${reciboProvider.clientesUnicosMes}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Novo Recibo ───────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FormScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Novo Recibo'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'RECENTES',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // ── Lista de recibos ─────────────────────────────────────────
            if (reciboProvider.loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (reciboProvider.recibos.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          size: 30,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Nenhum recibo ainda.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Crie o primeiro!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ReciboCard(
                      recibo: reciboProvider.recibos[index],
                    ),
                    childCount: reciboProvider.recibos.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

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
