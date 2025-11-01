import 'package:flutter/material.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/router/app_router_config.dart';
import 'package:muzakri/shared/models/reciter_model.dart';

class ReciterCard extends StatelessWidget {
  final Reciter reciter;

  const ReciterCard({super.key, required this.reciter});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          reciter.letter,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        reciter.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(
              context,
            )!.recitationsAvailable(reciter.moshaf.length),
          ),
          if (reciter.moshaf.isNotEmpty)
            Text(
              reciter.moshaf.first.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        ReciterDetailsRoute(
          reciter: reciter,
          reciterId: reciter.id.toString(),
        ).push(context);
      },
    );
  }
}
