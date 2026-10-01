part of '../../main.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final premium = PremiumEntitlementService.instance;

  @override
  void initState() {
    super.initState();
    if (premium.configured) {
      unawaited(premium.refresh());
    }
  }

  Future<void> _purchase(PremiumStoreProduct product) async {
    final strings = AnnaStrings.of(context);
    final result = await premium.purchase(product);
    if (!mounted) return;

    final message = switch (result) {
      PremiumPurchaseOutcome.success => strings.premiumPurchaseSuccess,
      PremiumPurchaseOutcome.cancelled => strings.premiumPurchaseCancelled,
      PremiumPurchaseOutcome.unavailable => strings.premiumStoreUnavailable,
      PremiumPurchaseOutcome.unsupported => strings.premiumOperationUnsupported,
      PremiumPurchaseOutcome.failed => strings.premiumPurchaseFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _restore() async {
    final strings = AnnaStrings.of(context);
    final result = await premium.restorePurchases();
    if (!mounted) return;

    final message = switch (result) {
      PremiumPurchaseOutcome.success => strings.premiumRestoreSuccess,
      PremiumPurchaseOutcome.cancelled => strings.premiumPurchaseCancelled,
      PremiumPurchaseOutcome.unavailable => strings.premiumStoreUnavailable,
      PremiumPurchaseOutcome.unsupported => strings.premiumWebRestoreUnsupported,
      PremiumPurchaseOutcome.failed => strings.premiumRestoreNotFound,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: premium,
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              strings.premiumTitle,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primaryContainer,
                      scheme.tertiaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 42,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      strings.premiumHeroTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(strings.premiumHeroDescription),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _statusCard(context, strings),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.premiumIncludes,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _benefit(
                        context,
                        Icons.insights_outlined,
                        strings.premiumBenefitInsights,
                      ),
                      _benefit(
                        context,
                        Icons.monitor_heart_outlined,
                        strings.premiumBenefitAdvancedCycle,
                      ),
                      _benefit(
                        context,
                        Icons.tune_outlined,
                        strings.premiumBenefitCustomTracking,
                      ),
                      _benefit(
                        context,
                        Icons.description_outlined,
                        strings.premiumBenefitPrivateReports,
                      ),
                      _benefit(
                        context,
                        Icons.auto_awesome_outlined,
                        strings.premiumBenefitFuture,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                strings.premiumPlans,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              if (premium.configured && premium.products.isNotEmpty)
                for (final product in premium.products) ...[
                  _productCard(context, strings, product),
                  const SizedBox(height: 10),
                ]
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          premium.configured
                              ? Icons.storefront_outlined
                              : Icons.construction_outlined,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            premium.configured
                                ? strings.premiumNoProducts
                                : strings.premiumStoreNotConfigured,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              if (premium.configured)
                OutlinedButton.icon(
                  onPressed: premium.busy ? null : () => premium.refresh(),
                  icon: const Icon(Icons.refresh),
                  label: Text(strings.premiumRefreshStore),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    premium.canRestorePurchases && !premium.busy ? _restore : null,
                icon: const Icon(Icons.restore_outlined),
                label: Text(strings.premiumRestorePurchases),
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 8),
                Text(
                  strings.premiumWebRestoreUnsupported,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 18),
              Text(
                strings.premiumFreeCorePromise,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusCard(BuildContext context, AnnaStrings strings) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, title, body) = premium.paidEntitlement
        ? (
            Icons.verified_rounded,
            strings.premiumActive,
            strings.premiumActiveDescription,
          )
        : premium.previewMode
            ? (
                Icons.science_outlined,
                strings.premiumPreview,
                strings.premiumPreviewDescription,
              )
            : (
                Icons.lock_outline,
                strings.premiumFree,
                strings.premiumFreeDescription,
              );

    return Semantics(
      container: true,
      label: '$title. $body',
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            child: Icon(icon),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(body),
          trailing: premium.busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
      ),
    );
  }

  Widget _benefit(
    BuildContext context,
    IconData icon,
    String text,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 21),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      );

  Widget _productCard(
    BuildContext context,
    AnnaStrings strings,
    PremiumStoreProduct product,
  ) {
    final recommended = product.kind == PremiumProductKind.lifetime;
    final title = switch (product.kind) {
      PremiumProductKind.monthly => strings.premiumMonthly,
      PremiumProductKind.lifetime => strings.premiumLifetime,
      PremiumProductKind.other => product.title,
    };
    final description = switch (product.kind) {
      PremiumProductKind.monthly => strings.premiumMonthlyDescription,
      PremiumProductKind.lifetime => strings.premiumLifetimeDescription,
      PremiumProductKind.other => product.description,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recommended)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Chip(
                  avatar: const Icon(Icons.star_outline, size: 18),
                  label: Text(strings.premiumBestValue),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  product.price,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(description),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: premium.busy ? null : () => _purchase(product),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: Text(strings.premiumChoosePlan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
