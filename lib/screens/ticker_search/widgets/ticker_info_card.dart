import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../models/ticker.dart';

class TickerInfoCard extends StatelessWidget {
  final Ticker ticker;

  const TickerInfoCard({super.key, required this.ticker});

  @override
  Widget build(BuildContext context) {
    final isPositive = ticker.change >= 0;
    final changeColor = isPositive ? AppColors.profit : AppColors.loss;
    final changeIcon = isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final sign = isPositive ? '+' : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                ticker.symbol,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticker.symbol, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    ticker.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${ticker.lastPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(changeIcon, color: changeColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$sign${ticker.change.toStringAsFixed(2)} ($sign${ticker.changePercent.toStringAsFixed(2)}%)',
                      style: TextStyle(color: changeColor, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
