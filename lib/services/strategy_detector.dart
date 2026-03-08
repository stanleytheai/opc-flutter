import '../models/option.dart';
import '../providers/options_provider.dart';

/// Detected option strategy name and description.
class DetectedStrategy {
  final String name;
  final String description;
  final String sentiment; // 'bullish', 'bearish', 'neutral', 'volatile'

  const DetectedStrategy({
    required this.name,
    this.description = '',
    this.sentiment = 'neutral',
  });
}

class StrategyDetector {
  /// Detect the strategy from a list of selected option entries.
  ///
  /// Returns null if no recognized strategy is detected.
  static DetectedStrategy? detect(List<SelectedOptionEntry> entries) {
    if (entries.isEmpty) return null;
    if (entries.length == 1) return _detectSingleLeg(entries.first);
    if (entries.length == 2) return _detectTwoLeg(entries);
    if (entries.length == 3) return _detectThreeLeg(entries);
    if (entries.length == 4) return _detectFourLeg(entries);
    return DetectedStrategy(
      name: 'Custom ${entries.length}-Leg',
      description: '${entries.length}-leg custom strategy',
    );
  }

  static DetectedStrategy _detectSingleLeg(SelectedOptionEntry e) {
    final type = e.option.callOrPut == OptionType.call ? 'Call' : 'Put';
    final action = e.action == BuyOrSell.buy ? 'Long' : 'Short';
    final sentiment = e.option.callOrPut == OptionType.call
        ? (e.action == BuyOrSell.buy ? 'bullish' : 'bearish')
        : (e.action == BuyOrSell.buy ? 'bearish' : 'bullish');
    return DetectedStrategy(
      name: '$action $type',
      description: '${e.action == BuyOrSell.buy ? "Buy" : "Sell"} ${e.quantity} $type at \$${e.option.strike}',
      sentiment: sentiment,
    );
  }

  static DetectedStrategy? _detectTwoLeg(List<SelectedOptionEntry> entries) {
    final a = entries[0];
    final b = entries[1];
    final sameExpiry = a.option.expiry == b.option.expiry;

    // Straddle: same strike, same expiry, one call one put, both buy or both sell
    if (sameExpiry &&
        a.option.strike == b.option.strike &&
        a.option.callOrPut != b.option.callOrPut &&
        a.action == b.action) {
      final action = a.action == BuyOrSell.buy ? 'Long' : 'Short';
      return DetectedStrategy(
        name: '$action Straddle',
        description: '${a.action == BuyOrSell.buy ? "Buy" : "Sell"} call + put at \$${a.option.strike}',
        sentiment: a.action == BuyOrSell.buy ? 'volatile' : 'neutral',
      );
    }

    // Strangle: different strikes, same expiry, one call one put, both buy or both sell
    if (sameExpiry &&
        a.option.strike != b.option.strike &&
        a.option.callOrPut != b.option.callOrPut &&
        a.action == b.action) {
      final action = a.action == BuyOrSell.buy ? 'Long' : 'Short';
      return DetectedStrategy(
        name: '$action Strangle',
        description: '${a.action == BuyOrSell.buy ? "Buy" : "Sell"} call + put at different strikes',
        sentiment: a.action == BuyOrSell.buy ? 'volatile' : 'neutral',
      );
    }

    // Vertical spreads: same type, same expiry, different strikes, one buy one sell
    if (sameExpiry &&
        a.option.callOrPut == b.option.callOrPut &&
        a.option.strike != b.option.strike &&
        a.action != b.action) {
      final buyLeg = a.action == BuyOrSell.buy ? a : b;
      final sellLeg = a.action == BuyOrSell.sell ? a : b;

      if (a.option.callOrPut == OptionType.call) {
        if (buyLeg.option.strike < sellLeg.option.strike) {
          return const DetectedStrategy(
            name: 'Bull Call Spread',
            description: 'Buy lower call, sell higher call',
            sentiment: 'bullish',
          );
        } else {
          return const DetectedStrategy(
            name: 'Bear Call Spread',
            description: 'Sell lower call, buy higher call',
            sentiment: 'bearish',
          );
        }
      } else {
        if (buyLeg.option.strike > sellLeg.option.strike) {
          return const DetectedStrategy(
            name: 'Bear Put Spread',
            description: 'Buy higher put, sell lower put',
            sentiment: 'bearish',
          );
        } else {
          return const DetectedStrategy(
            name: 'Bull Put Spread',
            description: 'Sell higher put, buy lower put',
            sentiment: 'bullish',
          );
        }
      }
    }

    // Calendar spread: same strike, same type, different expiry, one buy one sell
    if (!sameExpiry &&
        a.option.strike == b.option.strike &&
        a.option.callOrPut == b.option.callOrPut &&
        a.action != b.action) {
      return DetectedStrategy(
        name: 'Calendar Spread',
        description: '${a.option.callOrPut == OptionType.call ? "Call" : "Put"} calendar at \$${a.option.strike}',
        sentiment: 'neutral',
      );
    }

    return DetectedStrategy(
      name: 'Custom 2-Leg',
      description: '2-leg custom strategy',
    );
  }

  static DetectedStrategy? _detectThreeLeg(List<SelectedOptionEntry> entries) {
    // Butterfly spread detection
    // A butterfly is buy 1 low, sell 2 middle, buy 1 high (or inverse)
    final allCalls = entries.every((e) => e.option.callOrPut == OptionType.call);
    final allPuts = entries.every((e) => e.option.callOrPut == OptionType.put);
    final sameExpiry = entries.every((e) => e.option.expiry == entries[0].option.expiry);

    if ((allCalls || allPuts) && sameExpiry) {
      final sorted = List<SelectedOptionEntry>.from(entries)
        ..sort((a, b) => a.option.strike.compareTo(b.option.strike));

      // Check for butterfly pattern with 3 legs (when middle has qty=2)
      if (sorted[0].action == sorted[2].action &&
          sorted[1].action != sorted[0].action &&
          sorted[1].quantity == 2 &&
          sorted[0].quantity == 1 &&
          sorted[2].quantity == 1) {
        final type = allCalls ? 'Call' : 'Put';
        final action = sorted[0].action == BuyOrSell.buy ? 'Long' : 'Short';
        return DetectedStrategy(
          name: '$action $type Butterfly',
          description: 'Butterfly spread at \$${sorted[1].option.strike}',
          sentiment: sorted[0].action == BuyOrSell.buy ? 'neutral' : 'volatile',
        );
      }
    }

    return DetectedStrategy(
      name: 'Custom 3-Leg',
      description: '3-leg custom strategy',
    );
  }

  static DetectedStrategy? _detectFourLeg(List<SelectedOptionEntry> entries) {
    final sameExpiry = entries.every((e) => e.option.expiry == entries[0].option.expiry);
    if (!sameExpiry) {
      return DetectedStrategy(name: 'Custom 4-Leg', description: '4-leg custom strategy');
    }

    final calls = entries.where((e) => e.option.callOrPut == OptionType.call).toList();
    final puts = entries.where((e) => e.option.callOrPut == OptionType.put).toList();

    // Iron Condor: sell 1 put, buy 1 lower put, sell 1 call, buy 1 higher call
    if (calls.length == 2 && puts.length == 2) {
      final buyCall = calls.where((e) => e.action == BuyOrSell.buy).toList();
      final sellCall = calls.where((e) => e.action == BuyOrSell.sell).toList();
      final buyPut = puts.where((e) => e.action == BuyOrSell.buy).toList();
      final sellPut = puts.where((e) => e.action == BuyOrSell.sell).toList();

      if (buyCall.length == 1 && sellCall.length == 1 &&
          buyPut.length == 1 && sellPut.length == 1) {
        // Iron Butterfly: sell call and put at same strike (check before condor)
        if (sellCall.first.option.strike == sellPut.first.option.strike) {
          return const DetectedStrategy(
            name: 'Iron Butterfly',
            description: 'Sell straddle + buy strangle for protection',
            sentiment: 'neutral',
          );
        }
        // Iron Condor: sell put > buy put, sell call < buy call
        if (sellPut.first.option.strike > buyPut.first.option.strike &&
            sellCall.first.option.strike < buyCall.first.option.strike) {
          return const DetectedStrategy(
            name: 'Iron Condor',
            description: 'Sell OTM put spread + sell OTM call spread',
            sentiment: 'neutral',
          );
        }
        // Reverse Iron Condor
        if (buyPut.first.option.strike > sellPut.first.option.strike &&
            buyCall.first.option.strike < sellCall.first.option.strike) {
          return const DetectedStrategy(
            name: 'Reverse Iron Condor',
            description: 'Buy OTM put spread + buy OTM call spread',
            sentiment: 'volatile',
          );
        }
      }
    }

    // 4-leg butterfly with same type
    final allCalls = entries.every((e) => e.option.callOrPut == OptionType.call);
    final allPuts = entries.every((e) => e.option.callOrPut == OptionType.put);
    if (allCalls || allPuts) {
      final sorted = List<SelectedOptionEntry>.from(entries)
        ..sort((a, b) => a.option.strike.compareTo(b.option.strike));

      // Butterfly: buy 1 low, sell 1 mid, sell 1 mid, buy 1 high
      if (sorted[0].action == sorted[3].action &&
          sorted[1].action == sorted[2].action &&
          sorted[0].action != sorted[1].action &&
          sorted[1].option.strike == sorted[2].option.strike) {
        final type = allCalls ? 'Call' : 'Put';
        final action = sorted[0].action == BuyOrSell.buy ? 'Long' : 'Short';
        return DetectedStrategy(
          name: '$action $type Butterfly',
          description: 'Butterfly spread at \$${sorted[1].option.strike}',
          sentiment: sorted[0].action == BuyOrSell.buy ? 'neutral' : 'volatile',
        );
      }

      // Condor: buy 1 low, sell 1 mid-low, sell 1 mid-high, buy 1 high
      if (sorted[0].action == sorted[3].action &&
          sorted[1].action == sorted[2].action &&
          sorted[0].action != sorted[1].action) {
        final type = allCalls ? 'Call' : 'Put';
        final action = sorted[0].action == BuyOrSell.buy ? 'Long' : 'Short';
        return DetectedStrategy(
          name: '$action $type Condor',
          description: '$type condor spread',
          sentiment: sorted[0].action == BuyOrSell.buy ? 'neutral' : 'volatile',
        );
      }
    }

    return DetectedStrategy(
      name: 'Custom 4-Leg',
      description: '4-leg custom strategy',
    );
  }
}
