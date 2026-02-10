import 'package:flutter_test/flutter_test.dart';
import 'package:opc_flutter/models/ticker.dart';
import 'package:opc_flutter/models/option.dart';
import 'package:opc_flutter/models/option_chain.dart';
import 'package:opc_flutter/models/profit_table.dart';

void main() {
  group('Ticker', () {
    test('fromTradierJson parses all fields', () {
      final json = {
        'symbol': 'AAPL',
        'description': 'Apple Inc',
        'last': 185.50,
        'change': 2.30,
        'change_percentage': 1.25,
      };
      final t = Ticker.fromTradierJson(json);
      expect(t.symbol, 'AAPL');
      expect(t.description, 'Apple Inc');
      expect(t.lastPrice, 185.50);
      expect(t.change, 2.30);
      expect(t.changePercent, 1.25);
    });

    test('fromTradierJson handles nulls gracefully', () {
      final t = Ticker.fromTradierJson({});
      expect(t.symbol, '');
      expect(t.lastPrice, 0);
    });
  });

  group('TickerSearchResult', () {
    test('fromTradierJson parses correctly', () {
      final json = {'symbol': 'TSLA', 'description': 'Tesla Inc'};
      final r = TickerSearchResult.fromTradierJson(json);
      expect(r.symbol, 'TSLA');
      expect(r.description, 'Tesla Inc');
    });
  });

  group('Option', () {
    test('fromTradierJson parses call with greeks', () {
      final json = {
        'symbol': 'AAPL240315C00185000',
        'underlying': 'AAPL',
        'strike': 185.0,
        'expiration_date': '2024-03-15',
        'bid': 5.20,
        'ask': 5.40,
        'last': 5.30,
        'open_interest': 1500,
        'option_type': 'call',
        'greeks': {
          'delta': '0.55',
          'gamma': '0.03',
          'vega': '0.15',
          'theta': '-0.05',
          'smv_vol': '0.25',
        },
      };
      final o = Option.fromTradierJson(json);
      expect(o.symbol, 'AAPL240315C00185000');
      expect(o.ticker, 'AAPL');
      expect(o.strike, 185.0);
      expect(o.expiry, '2024-03-15');
      expect(o.callOrPut, OptionType.call);
      expect(o.bid, 5.20);
      expect(o.ask, 5.40);
      expect(o.delta, closeTo(0.55, 0.001));
      expect(o.impliedVolatility, closeTo(25.0, 0.1));
      expect(o.openInterest, 1500);
    });

    test('fromTradierJson parses put without greeks', () {
      final json = {
        'symbol': 'SPY240315P00450000',
        'root_symbol': 'SPY',
        'strike': 450.0,
        'expiration_date': '2024-03-15',
        'bid': 3.0,
        'ask': 3.20,
        'option_type': 'put',
      };
      final o = Option.fromTradierJson(json);
      expect(o.callOrPut, OptionType.put);
      expect(o.ticker, 'SPY');
      expect(o.delta, isNull);
      expect(o.impliedVolatility, 0);
    });

    test('premium is midpoint * 100', () {
      final o = Option(
        strike: 100,
        expiry: '2024-03-15',
        callOrPut: OptionType.call,
        bid: 2.0,
        ask: 2.50,
      );
      expect(o.premium, 225.0); // (2.0 + 2.5) / 2 * 100
      expect(o.premiumPerShare, 2.25);
    });

    test('cost is negative for buy, positive for sell', () {
      final o = Option(
        strike: 100, expiry: '2024-03-15', callOrPut: OptionType.call,
        bid: 2.0, ask: 2.50,
      );
      expect(o.cost(BuyOrSell.buy), lessThan(0));
      expect(o.cost(BuyOrSell.sell), greaterThan(0));
    });

    test('optionMapKey format', () {
      final o = Option(strike: 100, expiry: '2024-03-15', callOrPut: OptionType.call);
      expect(o.optionMapKey, '2024-03-15:100.0:C');
      final p = Option(strike: 95.5, expiry: '2024-04-19', callOrPut: OptionType.put);
      expect(p.optionMapKey, '2024-04-19:95.5:P');
    });
  });

  group('OptionType extensions', () {
    test('code returns C or P', () {
      expect(OptionType.call.code, 'C');
      expect(OptionType.put.code, 'P');
    });

    test('fromCode parses correctly', () {
      expect(OptionTypeCode.fromCode('C'), OptionType.call);
      expect(OptionTypeCode.fromCode('P'), OptionType.put);
      expect(OptionTypeCode.fromCode('c'), OptionType.call);
    });
  });

  group('OptionsChain', () {
    test('getOption retrieves by key', () {
      final opt = Option(
        strike: 100, expiry: '2024-03-15', callOrPut: OptionType.call,
        bid: 5.0, ask: 5.5,
      );
      final chain = OptionsChain(
        underlyingStockPrice: 100,
        expirations: ['2024-03-15'],
        strikes: [100.0],
        optionMap: {opt.optionMapKey: opt},
      );
      expect(chain.getOption('2024-03-15', 100.0, OptionType.call), isNotNull);
      expect(chain.getOption('2024-03-15', 100.0, OptionType.put), isNull);
    });

    test('callsForExpiry and putsForExpiry filter correctly', () {
      final call = Option(strike: 100, expiry: '2024-03-15', callOrPut: OptionType.call);
      final put = Option(strike: 100, expiry: '2024-03-15', callOrPut: OptionType.put);
      final chain = OptionsChain(
        underlyingStockPrice: 100,
        optionMap: {call.optionMapKey: call, put.optionMapKey: put},
      );
      expect(chain.callsForExpiry('2024-03-15').length, 1);
      expect(chain.putsForExpiry('2024-03-15').length, 1);
      expect(chain.callsForExpiry('2024-04-19').length, 0);
    });
  });

  group('ProfitTable', () {
    test('getValue and generateKey', () {
      final table = ProfitTable(
        xAxis: ['2024-03-01', '2024-03-15'],
        yAxis: [90.0, 100.0, 110.0],
        data: {
          '2024-03-01:90.0': -500.0,
          '2024-03-01:100.0': 0.0,
          '2024-03-01:110.0': 500.0,
          '2024-03-15:90.0': -1000.0,
          '2024-03-15:100.0': 0.0,
          '2024-03-15:110.0': 1000.0,
        },
      );
      expect(table.getValue('2024-03-01', 90.0), -500.0);
      expect(table.getValue('2024-03-15', 110.0), 1000.0);
      expect(table.maxValue, 1000.0);
      expect(table.minValue, -1000.0);
    });

    test('parseKey round-trips with generateKey', () {
      final key = ProfitTable.generateKey('2024-03-15', 105.5);
      final parsed = ProfitTable.parseKey(key);
      expect(parsed.date, '2024-03-15');
      expect(parsed.price, 105.5);
    });

    test('dates/prices aliases and 2D values accessor', () {
      final table = ProfitTable(
        xAxis: ['2024-03-01', '2024-03-15'],
        yAxis: [90.0, 100.0],
        data: {
          '2024-03-01:90.0': -100.0,
          '2024-03-01:100.0': 50.0,
          '2024-03-15:90.0': -200.0,
          '2024-03-15:100.0': 150.0,
        },
      );
      expect(table.dates, table.xAxis);
      expect(table.prices, table.yAxis);
      expect(table.values[0][0], -100.0); // row=0 (price 90), col=0 (date 03-01)
      expect(table.values[1][1], 150.0);  // row=1 (price 100), col=1 (date 03-15)
    });

    test('empty data returns zero min/max', () {
      final table = ProfitTable(xAxis: [], yAxis: []);
      expect(table.maxValue, 0);
      expect(table.minValue, 0);
    });
  });

  group('HypotheticalOption', () {
    test('profit for buy is hypothetical - original', () {
      final opt = Option(
        strike: 100, expiry: '2024-03-15', callOrPut: OptionType.call,
        bid: 5.0, ask: 5.0, buyOrSell: BuyOrSell.buy,
      );
      final hyp = HypotheticalOption(
        originalOption: opt,
        hypotheticalPremium: 700.0,
        timeToMaturity: 10,
        multiplier: 2,
      );
      // premium = (5+5)/2 * 100 = 500
      expect(hyp.profit, 200.0); // 700 - 500
      expect(hyp.totalProfit, 400.0); // 200 * 2
    });

    test('profit for sell is original - hypothetical', () {
      final opt = Option(
        strike: 100, expiry: '2024-03-15', callOrPut: OptionType.call,
        bid: 5.0, ask: 5.0, buyOrSell: BuyOrSell.sell,
      );
      final hyp = HypotheticalOption(
        originalOption: opt,
        hypotheticalPremium: 300.0,
        timeToMaturity: 10,
      );
      expect(hyp.profit, 200.0); // 500 - 300
    });
  });
}
