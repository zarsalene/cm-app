import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Help / FAQ screen: common questions and a contact action.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.help),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageGutter),
        children: [
          Text(
            Strings.faqTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._faqs.map((faq) => _FaqItem(question: faq.$1, answer: faq.$2)),
          const SizedBox(height: AppSpacing.xl),
          _ContactCard(),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            0,
            AppSpacing.pageGutter,
            AppSpacing.md,
          ),
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.support_agent, size: 40, color: scheme.onPrimaryContainer),
          const SizedBox(height: AppSpacing.vertical16),
          Text(
            Strings.contactTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Strings.contactBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: AppSpacing.vertical16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.email),
            label: const Text('support@z-smart-cm.tn'),
          ),
        ],
      ),
    );
  }
}

final List<(String, String)> _faqs = [
  (
    'Comment r\u00e9pondre \u00e0 un client ?',
    "Ouvrez la conversation depuis la liste des escalades, \u00e9crivez votre r\u00e9ponse et appuyez sur Envoyer.",
  ),
  (
    'Que signifie "Rendre au bot" ?',
    'Cela remet la conversation au bot automatique. Le client ne sera plus pris en charge par un humain.',
  ),
  (
    'Pourquoi je ne re\u00e7ois pas d\u2019alertes ?',
    'V\u00e9rifiez que les notifications sont activ\u00e9es dans Param\u00e8tres et dans les r\u00e9glages de votre t\u00e9l\u00e9phone.',
  ),
  (
    'Une escalade dispara\u00eet de la liste',
    'Une escalade passe en "Ferm\u00e9e" quand vous rendez la conversation au bot ou qu\u2019elle est r\u00e9solue.',
  ),
  (
    'Puis-je utiliser l\u2019application hors ligne ?',
    'Vous pouvez consulter les derni\u00e8res donn\u00e9es charg\u00e9es, mais l\u2019envoi de r\u00e9ponses n\u00e9cessite une connexion.',
  ),
];
